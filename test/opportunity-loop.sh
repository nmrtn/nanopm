#!/usr/bin/env bash
# nanopm — discover→plan loop: the "decide what to build" skills read the ranked
# opportunity DB, and a fresh opportunity run refreshes the always-loaded plan brief.
#
# Static (grep) assertions — no LLM, no network. Locks in that the opportunity entities
# (the headline compounding artifact) are actually consumed downstream, not write-only.
set -uo pipefail

_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_PASS=0; _FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm tests: discover→plan opportunity loop"
echo "  ==========================================="
echo

# 1. The "decide what to build" skills' query questions name opportunities.
for s in pm-objectives pm-strategy pm-roadmap pm-discovery; do
  if grep -hE 'nanopm_query_prompt "[^"]*opportunit' "$_REPO/$s/SKILL.md" >/dev/null 2>&1; then
    ok "$s query asks for opportunities"
  else
    fail "$s query does NOT mention opportunities — loop open"
  fi
done

# 2. The plan brief prompt reads the opportunity INDEX and carries a section for it.
if grep -q "entities/opportunities/INDEX.md" "$_REPO/lib/nanopm.sh" \
   && grep -q "Top open opportunities" "$_REPO/lib/nanopm.sh"; then
  ok "nanopm_plan_brief_prompt reads the opportunity INDEX + has a 'Top open opportunities' section"
else
  fail "plan brief prompt missing the opportunity INDEX / section"
fi

# 3. pm-opportunities regenerates the plan brief at the end (freshest signal → baseline).
if grep -q "nanopm_plan_brief_prompt" "$_REPO/pm-opportunities/SKILL.md"; then
  ok "pm-opportunities dispatches the plan-brief regen"
else
  fail "pm-opportunities does not refresh the plan brief"
fi

echo
echo "  ─────────────────────────────"
printf '  Passed: %d  Failed: %d\n' "$_PASS" "$_FAIL"
echo
if [ "$_FAIL" -gt 0 ]; then echo "  RESULT: FAILED"; exit 1
else echo "  RESULT: PASSED — discover→plan loop wired"; exit 0; fi
