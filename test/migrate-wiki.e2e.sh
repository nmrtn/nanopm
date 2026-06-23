#!/usr/bin/env bash
# Memory-wiki migration E2E test (Phase 2 hardening)
#
# Exercises bin/nanopm-migrate-to-wiki on a project with legacy artifacts:
#   - scaffolds the wiki + raw tree and writes NANOPM-WIKI.md
#   - seeds wiki/overview/{company,current-work}.md from the legacy summaries
#   - migrates + repairs the legacy global event log into raw/events.jsonl
#   - is NON-DESTRUCTIVE in copy mode (legacy files preserved)
#   - is IDEMPOTENT (a second run never clobbers post-migration edits)
#   - --finalize removes the legacy summaries only once a non-empty wiki copy exists
#
# Runs migrate from the repo root (so find_lib() resolves lib/nanopm.sh) with
# --project pointing at an isolated temp, and a SEPARATE HOME so the project's
# .nanopm/ never collides with ~/.nanopm/.
#
# Usage: bash test/migrate-wiki.e2e.sh   ·   exit 0 = pass, 1 = fail
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_PROJ=$(mktemp -d /tmp/nanopm-mig-proj-XXXXXX)
_FAKEHOME=$(mktemp -d /tmp/nanopm-mig-home-XXXXXX)
_SLUG="migtest"
_MIGRATE="$_REPO_ROOT/bin/nanopm-migrate-to-wiki"

cleanup() { rm -rf "$_PROJ" "$_FAKEHOME"; }
trap cleanup EXIT

ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; echo "  RESULT: FAILED"; exit 1; }

echo
echo "  nanopm E2E: memory-wiki migration"
echo "  ===================================="
echo "  Project: $_PROJ"
echo

command -v python3 >/dev/null 2>&1 || fail "python3 not found (hard dependency)"

# run migrate from repo root so find_lib() sees lib/nanopm.sh; project + HOME isolated
migrate() { ( cd "$_REPO_ROOT" && HOME="$_FAKEHOME" python3 "$_MIGRATE" --project "$_PROJ" --slug "$_SLUG" "$@" ); }

# ── legacy fixture ────────────────────────────────────────────────────────────
( cd "$_PROJ" && git init -q )
mkdir -p "$_PROJ/.nanopm" "$_FAKEHOME/.nanopm/memory"
printf '# PM Context Brief\n\nLegacy company summary.\n'      > "$_PROJ/.nanopm/CONTEXT-SUMMARY.md"
printf '# Plan Brief\n\nLegacy current-work summary.\n'       > "$_PROJ/.nanopm/PLAN-SUMMARY.md"
# legacy global event log: 2 valid lines + 1 corrupt (tests repair)
_log="$_FAKEHOME/.nanopm/memory/${_SLUG}.jsonl"
printf '{"skill":"pm-strategy","outputs":{"bet":"x"},"ts":"2026-01-01T00:00:00Z","slug":"%s"}\n' "$_SLUG" > "$_log"
printf '{"skill":"pm-roadmap","outputs":{"now":"y"},"ts":"2026-01-02T00:00:00Z","slug":"%s"}\n' "$_SLUG" >> "$_log"
printf 'this is not valid json at all\n' >> "$_log"

# ── 1. migrate (copy mode) scaffolds + seeds ──────────────────────────────────
migrate >/dev/null || fail "migrate exited non-zero"
[ -d "$_PROJ/.nanopm/wiki/entities/personas" ] || fail "scaffold: entities/personas missing"
[ -f "$_PROJ/.nanopm/NANOPM-WIKI.md" ]          || fail "schema: NANOPM-WIKI.md not written (lib not found?)"
[ -f "$_PROJ/.nanopm/wiki/overview/company.md" ]      || fail "overview: company.md not seeded from CONTEXT-SUMMARY"
[ -f "$_PROJ/.nanopm/wiki/overview/current-work.md" ] || fail "overview: current-work.md not seeded from PLAN-SUMMARY"
grep -q "Legacy company summary" "$_PROJ/.nanopm/wiki/overview/company.md" || fail "overview: company.md missing legacy content"
ok "migrate: scaffolds wiki + schema, seeds overviews from legacy summaries"

# ── 2. event log migrated + repaired ──────────────────────────────────────────
[ -f "$_PROJ/.nanopm/raw/events.jsonl" ] || fail "events: raw/events.jsonl not seeded"
_valid=$(grep -c '"skill"' "$_PROJ/.nanopm/raw/events.jsonl" 2>/dev/null || echo 0)
[ "$_valid" -ge 2 ] || fail "events: expected >=2 repaired lines, got $_valid"
ok "migrate: legacy global log migrated + repaired into raw/events.jsonl ($_valid valid lines)"

# ── 3. non-destructive: legacy files still present in copy mode ───────────────
[ -f "$_PROJ/.nanopm/CONTEXT-SUMMARY.md" ] && [ -f "$_PROJ/.nanopm/PLAN-SUMMARY.md" ] \
  || fail "copy mode should NOT delete legacy summaries"
ok "migrate: non-destructive in copy mode (legacy summaries preserved)"

# ── 4. idempotent: a hand edit survives a second run ─────────────────────────
printf '\n<!-- HAND EDIT -->\n' >> "$_PROJ/.nanopm/wiki/overview/company.md"
migrate >/dev/null || fail "second migrate exited non-zero"
grep -q "HAND EDIT" "$_PROJ/.nanopm/wiki/overview/company.md" \
  || fail "idempotency: second run clobbered a post-migration edit"
ok "migrate: idempotent — re-run preserves post-migration edits (no clobber)"

# ── 5. --finalize removes legacy summaries (wiki replacement is non-empty) ────
migrate --finalize >/dev/null || fail "migrate --finalize exited non-zero"
[ ! -f "$_PROJ/.nanopm/CONTEXT-SUMMARY.md" ] || fail "finalize: CONTEXT-SUMMARY.md should be removed"
[ ! -f "$_PROJ/.nanopm/PLAN-SUMMARY.md" ]    || fail "finalize: PLAN-SUMMARY.md should be removed"
[ -f "$_PROJ/.nanopm/wiki/overview/company.md" ] || fail "finalize: must keep the wiki replacement"
ok "migrate --finalize: removes legacy summaries, keeps the wiki overviews"

echo
echo "  ─────────────────────────────"
echo "  RESULT: PASSED — memory-wiki migration OK"
echo "  ─────────────────────────────"
