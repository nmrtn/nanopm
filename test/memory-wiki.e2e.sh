#!/usr/bin/env bash
# Memory-wiki ingest-loop E2E test (Phase 2 pilot)
#
# Proves the mechanical "fuel enters the engine" loop that the pm-personas ingest
# subagent drives — WITHOUT an LLM. Simulates the deterministic steps the subagent
# runs: scaffold -> citation-check (dedup) -> confidence-gate apply (gated write)
# -> reindex -> log, plus the review-queue routing for low-confidence writes.
#
# Covers the bins shipped in #110 (nanopm-ingest-agent, nanopm-confidence-gate) and
# the nanopm_wiki_ensure scaffold added in Phase 2.
#
# Usage: bash test/memory-wiki.e2e.sh
# Exit 0 = pass, exit 1 = fail
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_TMPDIR=$(mktemp -d /tmp/nanopm-wiki-XXXXXX)
_INGEST="$_REPO_ROOT/bin/nanopm-ingest-agent"
_GATE="$_REPO_ROOT/bin/nanopm-confidence-gate"

cleanup() { rm -rf "$_TMPDIR"; }
trap cleanup EXIT

ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; }
fail() {
  printf '  \033[0;31m✗\033[0m %s\n' "$*"
  echo "  RESULT: FAILED"
  exit 1
}

echo
echo "  nanopm E2E: memory-wiki ingest loop"
echo "  ===================================="
echo "  Temp dir: $_TMPDIR"
echo

command -v python3 >/dev/null 2>&1 || fail "python3 not found (hard dependency)"

export HOME="$_TMPDIR"
cd "$_TMPDIR"
git init -q
# shellcheck source=/dev/null
source "$_REPO_ROOT/lib/nanopm.sh"

_PAGE="wiki/entities/personas/theo.md"
_CIT='"I live in the terminal" — interview, 2026-06-23'

# ── 1. scaffold ───────────────────────────────────────────────────────────────
nanopm_wiki_ensure || fail "nanopm_wiki_ensure returned non-zero"
[ -d ".nanopm/wiki/entities/personas" ] || fail "scaffold: entities/personas dir missing"
[ -d ".nanopm/raw/interviews" ]          || fail "scaffold: raw/interviews dir missing"
[ -f ".nanopm/NANOPM-WIKI.md" ]          || fail "scaffold: NANOPM-WIKI.md not written"
ok "scaffold: nanopm_wiki_ensure creates wiki/raw tree + NANOPM-WIKI.md"

# idempotent: a second call must not error or clobber the schema
_schema_before=$(cat .nanopm/NANOPM-WIKI.md)
nanopm_wiki_ensure || fail "nanopm_wiki_ensure not idempotent (second call failed)"
[ "$_schema_before" = "$(cat .nanopm/NANOPM-WIKI.md)" ] || fail "scaffold: second call overwrote NANOPM-WIKI.md"
ok "scaffold: idempotent (re-run is a no-op, schema preserved)"

# ── 2. citation-check on an absent page -> NEW ────────────────────────────────
set +e
_out=$("$_INGEST" citation-check --target "$_PAGE" --citation "$_CIT"); _rc=$?
set -e
[ "$_rc" = "1" ] && [ "$_out" = "NEW" ] || fail "citation-check (absent page): expected NEW/exit1, got '$_out'/exit$_rc"
ok "citation-check: NEW when the page doesn't exist yet"

# ── 3. confidence-gate apply (high confidence) -> auto-applies ────────────────
cat > /tmp/nanopm-wiki-page.$$ <<MD
---
title: "Theo — solo founder in the terminal"
status: active
provenance: evidence-backed
sources: []
last_updated: 2026-06-23
---

## Who
A solo founder who does product management in the same terminal as their code.

## Evidence
- $_CIT
MD
_out=$("$_GATE" apply --target "$_PAGE" --confidence 8 < /tmp/nanopm-wiki-page.$$)
rm -f /tmp/nanopm-wiki-page.$$
case "$_out" in APPLIED*) ;; *) fail "gate apply (conf 8): expected APPLIED, got '$_out'";; esac
[ -f ".nanopm/$_PAGE" ] || fail "gate apply: entity page not written to .nanopm/$_PAGE"
ok "confidence-gate: high-confidence write auto-applies to the entity page"

# ── 4. reindex picks the page up by frontmatter ───────────────────────────────
"$_INGEST" reindex >/dev/null || fail "reindex returned non-zero"
[ -f ".nanopm/wiki/index.md" ] || fail "reindex: wiki/index.md not created"
grep -q "Theo — solo founder in the terminal" .nanopm/wiki/index.md \
  || fail "reindex: index.md does not list the persona page title"
ok "reindex: index.md lists the new persona page (read from frontmatter title)"

# ── 5. log appends a heartbeat ────────────────────────────────────────────────
"$_INGEST" log --op ingest --title "Theo persona (pm-personas)" >/dev/null || fail "log returned non-zero"
[ -f ".nanopm/wiki/log.md" ] || fail "log: wiki/log.md not created"
grep -q "Theo persona (pm-personas)" .nanopm/wiki/log.md || fail "log: heartbeat line missing"
ok "log: ingest heartbeat appended to wiki/log.md"

# ── 6. citation-check is now DUPLICATE (anchored dedup, not substring) ────────
set +e
_out=$("$_INGEST" citation-check --target "$_PAGE" --citation "$_CIT"); _rc=$?
set -e
[ "$_rc" = "0" ] && [ "$_out" = "DUPLICATE" ] || fail "citation-check (written): expected DUPLICATE/exit0, got '$_out'/exit$_rc"
ok "citation-check: DUPLICATE once the citation is on the page"

# a short substring of an existing citation must NOT false-match (the bug Phase 2 fixed)
set +e
_out=$("$_INGEST" citation-check --target "$_PAGE" --citation 'terminal'); _rc=$?
set -e
[ "$_rc" = "1" ] && [ "$_out" = "NEW" ] || fail "citation-check (substring): 'terminal' must be NEW, got '$_out'/exit$_rc"
ok "citation-check: short substring of an existing quote is NOT a false duplicate"

# ── 7. low-confidence write is held for review, not applied ───────────────────
_newpage="wiki/entities/personas/dana.md"
_out=$(printf '%s\n' '# Dana (shaky)' | "$_GATE" apply --target "$_newpage" --confidence 3 --reason "weak signal")
case "$_out" in REVIEW*) ;; *) fail "gate apply (conf 3): expected REVIEW, got '$_out'";; esac
[ ! -f ".nanopm/$_newpage" ] || fail "gate apply (conf 3): low-confidence write must NOT touch the page"
_review_count=$(ls .nanopm/wiki/_review/*.json 2>/dev/null | wc -l | tr -d ' ')
[ "$_review_count" = "1" ] || fail "gate: expected 1 held review, found $_review_count"
"$_GATE" list | grep -q "$_newpage" || fail "gate list: held write not surfaced"
ok "confidence-gate: low-confidence write held in _review/ (not applied), surfaced by list"

echo
echo "  ─────────────────────────────"
echo "  RESULT: PASSED — memory-wiki ingest loop OK"
echo "  ─────────────────────────────"
