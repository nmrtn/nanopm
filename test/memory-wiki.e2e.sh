#!/usr/bin/env bash
# Memory-wiki ingest-loop E2E test (Phase 2 pilot)
#
# Proves the mechanical "fuel enters the engine" loop that the pm-personas ingest
# subagent drives — WITHOUT an LLM. Simulates the deterministic steps the subagent
# runs: scaffold -> citation-check (dedup) -> apply (direct locked write) -> reindex
# -> log. There is no confidence gate (NANOPM-WIKI.md §11): writes apply directly and
# quality is enforced after the fact by the judgment lint pass.
#
# Covers nanopm-ingest-agent (citation dedup / apply / reindex / log) and the
# nanopm_wiki_ensure scaffold.
#
# Usage: bash test/memory-wiki.e2e.sh
# Exit 0 = pass, exit 1 = fail
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_TMPDIR=$(mktemp -d /tmp/nanopm-wiki-XXXXXX)
_INGEST="$_REPO_ROOT/bin/nanopm-ingest-agent"

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

# ── 3. apply (direct locked write) -> page lands, no review queue ─────────────
cat > /tmp/nanopm-wiki-page.$$ <<MD
---
id: theo
type: persona
title: "Theo — solo founder in the terminal"
status: active
provenance: evidence-backed
sources: []
relates_to: []
last_updated: 2026-06-23
---

## Who
A solo founder who does product management in the same terminal as their code.

## Evidence
- $_CIT
MD
_out=$("$_INGEST" apply --target "$_PAGE" < /tmp/nanopm-wiki-page.$$)
rm -f /tmp/nanopm-wiki-page.$$
case "$_out" in APPLIED*) ;; *) fail "apply: expected APPLIED, got '$_out'";; esac
[ -f ".nanopm/$_PAGE" ] || fail "apply: entity page not written to .nanopm/$_PAGE"
[ ! -d ".nanopm/wiki/_review" ] || fail "apply: no confidence gate — there must be no _review queue"
ok "apply: write lands directly on the entity page (no confidence gate, no _review)"

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

# ── 7. apply has no confidence concept: every write lands; traversal refused ──
# The gate is gone (NANOPM-WIKI.md §11): apply never holds a write for review.
_newpage="wiki/entities/personas/dana.md"
_out=$(printf '%s\n' '# Dana' | "$_INGEST" apply --target "$_newpage")
case "$_out" in APPLIED*) ;; *) fail "apply (second page): expected APPLIED, got '$_out'";; esac
[ -f ".nanopm/$_newpage" ] || fail "apply: second write must land directly on the page"
[ ! -d ".nanopm/wiki/_review" ] || fail "apply: still no _review queue after a second write"
ok "apply: a second write also lands directly — there is no held-for-review state"

# apply confines writes to .nanopm/ (no traversal escape)
set +e
printf 'x\n' | "$_INGEST" apply --target "../../../etc/nanopm-evil.md" >/dev/null 2>&1; _rc=$?
set -e
[ "$_rc" != "0" ] || fail "apply: a traversal target must be refused"
[ ! -f "/etc/nanopm-evil.md" ] || fail "apply: traversal target escaped .nanopm/"
ok "apply: refuses a path that escapes .nanopm/"

# ── 9. lint sleep pass: runs once, then throttles ────────────────────────────
nanopm_wiki_lint_check >/dev/null 2>&1 || fail "nanopm_wiki_lint_check returned non-zero"
[ -f ".nanopm/wiki/.last-lint" ] || fail "lint sleep pass: throttle marker not written"
_out2=$(nanopm_wiki_lint_check)   # second call same day -> throttled, no output
[ -z "$_out2" ] || fail "lint sleep pass: second call should be throttled (silent), got '$_out2'"
ok "lint sleep pass: runs once, writes throttle marker, then stays quiet for the day"

# ── 10. lock: concurrent log appends don't lose lines ─────────────────────────
# log.md is read-modify-write; without the wiki lock, parallel runs clobber each
# other and lines vanish. Fire 10 at once and require all 10 to survive.
_before=$(grep -c "^## \[" .nanopm/wiki/log.md 2>/dev/null || echo 0)
for i in $(seq 1 10); do
  "$_INGEST" log --op ingest --title "concurrent-$i" >/dev/null &
done
wait
_after=$(grep -c "^## \[" .nanopm/wiki/log.md 2>/dev/null || echo 0)
_added=$(( _after - _before ))
[ "$_added" = "10" ] || fail "lock: expected 10 concurrent log lines to all land, got $_added"
ok "lock: 10 concurrent log appends all survive (no lost lines under contention)"

echo
echo "  ─────────────────────────────"
echo "  RESULT: PASSED — memory-wiki ingest loop OK"
echo "  ─────────────────────────────"
