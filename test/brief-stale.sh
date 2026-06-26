#!/usr/bin/env bash
# nanopm v0.22+ — brief staleness signal tests
#
# Covers the post-migration cold-start bug: nanopm-migrate-to-wiki relocates flat
# docs into wiki/docs/ but only RELOCATES a pre-existing CONTEXT-SUMMARY/PLAN-SUMMARY
# (it can't author briefs — deterministic Python, no LLM). So a migrated project can
# have the source docs but empty always-loaded briefs, and the first skill run starts
# cold. nanopm_brief_stale_check surfaces that gap (mirroring UPGRADE_AVAILABLE) so a
# skill — notably /pm-run Phase 0c — can regenerate the brief up front.
#
# The signal must fire ONLY when source docs exist but the brief is empty, must use
# -s (not -f) so a zero-byte failed regen still reads as stale, and must never nag a
# virgin project. No LLM, no network.
set -uo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_TMPDIR=$(mktemp -d /tmp/nanopm-brief-XXXXXX)
cleanup() { rm -rf "$_TMPDIR"; }
trap cleanup EXIT

_PASS=0
_FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm tests: brief staleness signal"
echo "  ====================================="
echo

export HOME="$_TMPDIR/home"
mkdir -p "$HOME/.nanopm"

# A git-init'd project so _nanopm_project_root resolves deterministically to it
# (git rev-parse --show-toplevel), regardless of where the test runs from.
_PROJ="$_TMPDIR/proj"
mkdir -p "$_PROJ"
git -C "$_PROJ" init -q
cd "$_PROJ"

source "$_REPO_ROOT/lib/nanopm.sh"

# Reset .nanopm to a clean wiki scaffold (no docs, no briefs) before each scenario.
reset_wiki() {
  rm -rf "$_PROJ/.nanopm"
  mkdir -p "$_PROJ/.nanopm/wiki/overview" "$_PROJ/.nanopm/wiki/docs"
}

# ── 1. Plan doc exists, plan brief missing → fires current-work ───────────────
echo "  Stale plan brief"
reset_wiki
printf '# Objectives\nstuff\n' > "$_PROJ/.nanopm/wiki/docs/objectives.md"
_OUT=$(nanopm_brief_stale_check)
if echo "$_OUT" | grep -q "BRIEF_STALE current-work"; then
  ok "objectives.md present + current-work.md absent → BRIEF_STALE current-work"
else
  fail "expected BRIEF_STALE current-work. Got: '$_OUT'"
fi
if echo "$_OUT" | grep -q "BRIEF_STALE company"; then
  fail "false BRIEF_STALE company (no Define docs present)"
else
  ok "no false company signal when only Plan docs exist"
fi

# ── 2. Define doc exists, company brief missing → fires company ───────────────
echo
echo "  Stale company brief"
reset_wiki
printf '# Product\nstuff\n' > "$_PROJ/.nanopm/wiki/docs/product.md"
_OUT=$(nanopm_brief_stale_check)
if echo "$_OUT" | grep -q "BRIEF_STALE company"; then
  ok "product.md present + company.md absent → BRIEF_STALE company"
else
  fail "expected BRIEF_STALE company. Got: '$_OUT'"
fi

# ── 3. Both briefs present → silent (warm case) ──────────────────────────────
echo
echo "  Warm briefs stay silent"
reset_wiki
printf '# Objectives\nx\n'  > "$_PROJ/.nanopm/wiki/docs/objectives.md"
printf '# Product\nx\n'     > "$_PROJ/.nanopm/wiki/docs/product.md"
printf '# Plan Brief\nx\n'  > "$_PROJ/.nanopm/wiki/overview/current-work.md"
printf '# Company\nx\n'     > "$_PROJ/.nanopm/wiki/overview/company.md"
_OUT=$(nanopm_brief_stale_check)
if [ -z "$_OUT" ]; then
  ok "both briefs non-empty → no signal"
else
  fail "warm briefs fired '$_OUT' — should be silent"
fi

# ── 4. Virgin project → silent (no nag) ──────────────────────────────────────
echo
echo "  Virgin project never nags"
reset_wiki  # wiki dirs exist but no source docs at all
_OUT=$(nanopm_brief_stale_check)
if [ -z "$_OUT" ]; then
  ok "wiki scaffold with no source docs → no signal"
else
  fail "virgin project fired '$_OUT' — should be silent"
fi
rm -rf "$_PROJ/.nanopm"  # no wiki dir at all
_OUT=$(nanopm_brief_stale_check)
if [ -z "$_OUT" ]; then
  ok "no wiki dir → no signal"
else
  fail "no-wiki project fired '$_OUT' — should be silent"
fi

# ── 5. Zero-byte brief + source doc → still fires (proves -s not -f) ──────────
echo
echo "  Zero-byte brief is stale (-s not -f)"
reset_wiki
printf '# Objectives\nx\n' > "$_PROJ/.nanopm/wiki/docs/objectives.md"
: > "$_PROJ/.nanopm/wiki/overview/current-work.md"  # zero-byte file exists
_OUT=$(nanopm_brief_stale_check)
if echo "$_OUT" | grep -q "BRIEF_STALE current-work"; then
  ok "zero-byte current-work.md still reads as stale"
else
  fail "zero-byte brief not detected (used -f instead of -s?). Got: '$_OUT'"
fi

# ── 6. Legacy flat summary counts as present → silent ────────────────────────
echo
echo "  Legacy flat summary suppresses signal"
reset_wiki
printf '# Objectives\nx\n' > "$_PROJ/.nanopm/wiki/docs/objectives.md"
printf '# Plan\nx\n'       > "$_PROJ/.nanopm/PLAN-SUMMARY.md"  # un-migrated fallback
_OUT=$(nanopm_brief_stale_check)
if echo "$_OUT" | grep -q "BRIEF_STALE current-work"; then
  fail "fired despite legacy PLAN-SUMMARY.md present. Got: '$_OUT'"
else
  ok "legacy PLAN-SUMMARY.md counts as present → no signal"
fi

# ── summary ──────────────────────────────────────────────────────────────────
echo
echo "  ─────────────────────────────"
printf '  Passed: %d  Failed: %d\n' "$_PASS" "$_FAIL"
echo

if [ "$_FAIL" -gt 0 ]; then
  echo "  RESULT: FAILED"
  exit 1
else
  echo "  RESULT: PASSED — brief staleness signal OK"
  exit 0
fi
