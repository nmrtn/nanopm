#!/usr/bin/env bash
# nanopm v0.6.2+ — update check / semver tests
#
# Covers the auto-upgrade bug discovered post-v0.6.1:
#   - nanopm_update_check used `!=` comparison, so a stale cache with an OLDER
#     remote version would fire UPGRADE_AVAILABLE telling the user to downgrade.
#   - Fixed by adding nanopm_semver_gt and switching the check to strict greater-than.
#
# Also exercises:
#   - The update_check_disabled flag is honored.
#   - Cache hit path (no remote fetch when timestamp is fresh).
#   - Snooze respect.
#
# No LLM, no network (we never let it reach curl by pre-seeding the cache).
set -uo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_TMPDIR=$(mktemp -d /tmp/nanopm-update-XXXXXX)

cleanup() { rm -rf "$_TMPDIR"; }
trap cleanup EXIT

_PASS=0
_FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm tests: update check / semver"
echo "  ====================================="
echo

export HOME="$_TMPDIR"
mkdir -p "$_TMPDIR/.nanopm"

source "$_REPO_ROOT/lib/nanopm.sh"

# ── 1. Semver helper ──────────────────────────────────────────────────────────
echo "  Semver comparisons"
_cases=(
  "0.6.1|0.6.0|0"  # newer > older → true (exit 0)
  "0.6.0|0.6.1|1"  # older > newer → false
  "0.6.0|0.6.0|1"  # equal → false (strict)
  "0.5.2|0.6.0|1"  # the actual bug scenario
  "1.42.2|0.15.16|0"   # major bump
  "0.10.0|0.9.0|0"     # double-digit minor > single-digit (string compare would fail)
  "1.0.0|0.99.99|0"
  "|0.6.0|1"          # empty a → false
  "0.6.0||0"           # empty b → true
)
for case in "${_cases[@]}"; do
  IFS='|' read -r a b expected <<< "$case"
  nanopm_semver_gt "$a" "$b"
  _actual=$?
  if [ "$_actual" = "$expected" ]; then
    ok "nanopm_semver_gt '$a' '$b' → exit $_actual"
  else
    fail "nanopm_semver_gt '$a' '$b' → exit $_actual (expected $expected)"
  fi
done

# ── 2. Cache hit path — older cached remote does NOT fire upgrade ─────────────
echo
echo "  Stale-cache downgrade bug (regression)"

# Set up: local=0.6.0, cached remote=0.5.2 (stale from before a local bump)
echo "0.6.0" > "$_TMPDIR/.nanopm/VERSION"
echo "$(date +%s) 0.5.2" > "$_TMPDIR/.nanopm/last-update-check"

_OUT=$(nanopm_update_check)
if [ -z "$_OUT" ]; then
  ok "Stale cache (remote=0.5.2 < local=0.6.0) stays silent"
else
  fail "Stale cache fired '$_OUT' — should be silent (bug not fixed)"
fi

# ── 3. Cache hit path — newer cached remote DOES fire upgrade ─────────────────
echo
echo "  Cache hit fires correctly when remote IS newer"
echo "0.6.0" > "$_TMPDIR/.nanopm/VERSION"
echo "$(date +%s) 0.7.0" > "$_TMPDIR/.nanopm/last-update-check"

_OUT=$(nanopm_update_check)
if echo "$_OUT" | grep -q "UPGRADE_AVAILABLE 0.6.0 0.7.0"; then
  ok "Cache hit: remote=0.7.0 > local=0.6.0 fires UPGRADE_AVAILABLE"
else
  fail "Cache hit didn't fire. Got: '$_OUT'"
fi

# ── 4. Equal versions stay silent ─────────────────────────────────────────────
echo
echo "  Equal versions"
echo "0.6.0" > "$_TMPDIR/.nanopm/VERSION"
echo "$(date +%s) 0.6.0" > "$_TMPDIR/.nanopm/last-update-check"

_OUT=$(nanopm_update_check)
if [ -z "$_OUT" ]; then
  ok "Equal versions (remote=local=0.6.0) stay silent"
else
  fail "Equal versions fired '$_OUT' — should be silent"
fi

# ── 5. update_check_disabled flag ─────────────────────────────────────────────
echo
echo "  update_check_disabled flag"
echo "0.6.0" > "$_TMPDIR/.nanopm/VERSION"
echo "$(date +%s) 0.9.0" > "$_TMPDIR/.nanopm/last-update-check"
nanopm_config_set "update_check_disabled" "1"

_OUT=$(nanopm_update_check)
if [ -z "$_OUT" ]; then
  ok "update_check_disabled=1 silences the check even with newer remote"
else
  fail "Disabled flag ignored. Got: '$_OUT'"
fi

# Re-enable for next tests
nanopm_config_set "update_check_disabled" "0"

# ── 6. Snooze respect ──────────────────────────────────────────────────────────
echo
echo "  Snooze respect"
echo "0.6.0" > "$_TMPDIR/.nanopm/VERSION"
echo "$(date +%s) 0.7.0" > "$_TMPDIR/.nanopm/last-update-check"
# Snooze the 0.7.0 upgrade, level 1, just now
echo "0.7.0 1 $(date +%s)" > "$_TMPDIR/.nanopm/update-snoozed"

_OUT=$(nanopm_update_check)
if [ -z "$_OUT" ]; then
  ok "Active snooze suppresses the check"
else
  fail "Snooze ignored. Got: '$_OUT'"
fi

# Snooze expired (>24h ago for level 1)
echo "0.7.0 1 $(( $(date +%s) - 90000 ))" > "$_TMPDIR/.nanopm/update-snoozed"
_OUT=$(nanopm_update_check)
if echo "$_OUT" | grep -q "UPGRADE_AVAILABLE"; then
  ok "Expired snooze releases the check"
else
  fail "Expired snooze didn't release. Got: '$_OUT'"
fi

# ── 7. nanopm_semver_gt is exported as a function ─────────────────────────────
echo
echo "  Helper visibility"
if grep -q '^nanopm_semver_gt()' "$_REPO_ROOT/lib/nanopm.sh"; then
  ok "nanopm_semver_gt() defined in lib"
else
  fail "nanopm_semver_gt() not in lib"
fi

# ── summary ───────────────────────────────────────────────────────────────────
echo
echo "  ─────────────────────────────"
printf '  Passed: %d  Failed: %d\n' "$_PASS" "$_FAIL"
echo

if [ "$_FAIL" -gt 0 ]; then
  echo "  RESULT: FAILED"
  exit 1
else
  echo "  RESULT: PASSED — update check / semver OK"
  exit 0
fi
