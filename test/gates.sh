#!/usr/bin/env bash
# nanopm v0.6.0+ — ETHOS structural gate tests
#
# Verifies the gate pattern is wired into the three gated skills:
#   - pm-audit: gates "The Question You're Avoiding" (kind=question)
#   - pm-roadmap: gates each committed NOW item (kind=target)
#   - pm-prd: gates the Falsification section (kind=bet) + writes prd record
#
# Pattern per gate:
#   1. Adversarial subagent dispatch with structured rubric output
#   2. Local rubric validation step
#   3. State write via nanopm_state_log — schema validator is the structural gate
#
# This is a static test — no LLM. We verify the gate is wired into the skill.
# The actual quality of the subagent output is covered by adversarial.e2e.sh.
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_PASS=0
_FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm tests: ETHOS structural gates"
echo "  ====================================="
echo

# ── pm-audit gate: question ───────────────────────────────────────────────────
echo "  pm-audit — gates The Question You're Avoiding (kind=question)"
_F="$_REPO_ROOT/pm-audit/SKILL.md"

if grep -q "Phase 5: Adversarial gate" "$_F"; then
  ok "Phase 5 renamed to 'Adversarial gate'"
else
  fail "Phase 5 not renamed (gate not installed)"
fi

if grep -q "QUESTION:" "$_F" && grep -q "KEY:" "$_F" && grep -q "CONFIDENCE:" "$_F" && grep -q "RATIONALE:" "$_F"; then
  ok "Rubric output format declared (QUESTION/KEY/CONFIDENCE/RATIONALE)"
else
  fail "Rubric output format incomplete in pm-audit"
fi

if grep -q "Is / Does / Will / Would / Can / Should / Are" "$_F"; then
  ok "Falsifiability marker list present"
else
  fail "Question starter rubric missing (Is/Does/Will/...)"
fi

if grep -q "nanopm_state_log --type decision" "$_F"; then
  ok "State write via nanopm_state_log present"
else
  fail "State write missing — gate is not structural"
fi

if grep -q "'kind': 'question'" "$_F"; then
  ok "Writes kind=question"
else
  fail "kind=question not written"
fi

if grep -q "'source': 'adversarial'" "$_F"; then
  ok "source=adversarial set on state write"
else
  fail "source=adversarial not set in pm-audit"
fi

# ── pm-roadmap gate: target per NOW item ──────────────────────────────────────
echo
echo "  pm-roadmap — gates each NOW item (kind=target)"
_F="$_REPO_ROOT/pm-roadmap/SKILL.md"

if grep -q "Phase 4b: Adversarial gate" "$_F"; then
  ok "Phase 4b 'Adversarial gate' installed"
else
  fail "Phase 4b not installed in pm-roadmap"
fi

if grep -q "SEGMENT" "$_F" && grep -q "BEHAVIOR" "$_F" && grep -q "METRIC" "$_F" && grep -q "TIMEFRAME" "$_F"; then
  ok "4-element rubric declared (SEGMENT/BEHAVIOR/METRIC/TIMEFRAME)"
else
  fail "4-element rubric incomplete in pm-roadmap"
fi

if grep -q "ITEM:" "$_F" && grep -q "VERDICT: PASS | FAIL" "$_F" && grep -q "REWRITE:" "$_F"; then
  ok "Batched output format declared (ITEM/VERDICT/REWRITE)"
else
  fail "Batched output format missing in pm-roadmap"
fi

if grep -q "nanopm_state_log --type decision" "$_F"; then
  ok "State write via nanopm_state_log present"
else
  fail "State write missing in pm-roadmap"
fi

if grep -q "'kind': 'target'" "$_F"; then
  ok "Writes kind=target"
else
  fail "kind=target not written in pm-roadmap"
fi

if grep -q "rewritten by gate" "$_F"; then
  ok "Failed-item rewrite tagging present (⚠ rewritten by gate)"
else
  fail "Failed-item rewrite tag missing"
fi

# ── pm-prd gate: Falsification → bet + prd record ─────────────────────────────
echo
echo "  pm-prd — gates Falsification (kind=bet) + writes prd record"
_F="$_REPO_ROOT/pm-prd/SKILL.md"

if grep -q "Phase 4b: Adversarial gate" "$_F"; then
  ok "Phase 4b 'Adversarial gate' installed"
else
  fail "Phase 4b not installed in pm-prd"
fi

# Falsification section in BOTH formats (Shape Up + standard)
_FALSIF_COUNT=$(grep -c "^## Falsification" "$_F" || true)
if [ "$_FALSIF_COUNT" -ge 2 ]; then
  ok "## Falsification section present in both Shape Up and standard formats ($_FALSIF_COUNT)"
else
  fail "## Falsification section present in only $_FALSIF_COUNT format(s) (expected 2)"
fi

if grep -q "NUMBER" "$_F" && grep -q "NAMED SEGMENT" "$_F" && grep -q "OBSERVABLE BEHAVIOR" "$_F" && grep -q "TIMEFRAME" "$_F"; then
  ok "4-element falsification rubric declared"
else
  fail "Falsification rubric incomplete in pm-prd"
fi

if grep -q "nanopm_state_log --type decision" "$_F"; then
  ok "State write decision via nanopm_state_log present"
else
  fail "decision state write missing in pm-prd"
fi

if grep -q "'kind': 'bet'" "$_F"; then
  ok "Writes kind=bet"
else
  fail "kind=bet not written in pm-prd"
fi

if grep -q "nanopm_state_log --type prd" "$_F"; then
  ok "State write prd via nanopm_state_log present"
else
  fail "prd state write missing"
fi

if grep -q "'status': 'ready'" "$_F"; then
  ok "Writes prd status=ready on successful gate"
else
  fail "prd status=ready not set"
fi

# ── pm-strategy regression: adversarial pattern still intact ──────────────────
echo
echo "  pm-strategy — adversarial pattern (regression check, not new gate)"
_F="$_REPO_ROOT/pm-strategy/SKILL.md"

if grep -q "ASSUMPTION:" "$_F" && grep -q "FALSIFICATION:" "$_F" && grep -q "CHEAPEST TEST:" "$_F"; then
  ok "3-question rubric still intact (ASSUMPTION/FALSIFICATION/CHEAPEST TEST)"
else
  fail "pm-strategy 3-question rubric broke"
fi

if grep -q "## Challenged by adversarial review" "$_F"; then
  ok "STRATEGY.md adversarial section still required"
else
  fail "pm-strategy adversarial section requirement broke"
fi

# ── pm-breakdown handoff write ────────────────────────────────────────────────
echo
echo "  pm-breakdown — logs handoff via state validator"
_F="$_REPO_ROOT/pm-breakdown/SKILL.md"

if grep -q "nanopm_state_log --type handoff" "$_F"; then
  ok "Handoff state write present"
else
  fail "Handoff state write missing in pm-breakdown"
fi

if grep -q "nanopm_state_log --type prd" "$_F"; then
  ok "PRD status update to handed-off present"
else
  fail "PRD status update missing in pm-breakdown"
fi

# All 5 targets enumerated
for t in linear github openspec gstack human; do
  if grep -qE "_TARGET=$t\b|TARGET=$t\b|target=$t\b" "$_F" || grep -qE "_TARGET\)\s*\$_TARGET\" in" "$_F"; then
    ok "pm-breakdown handles target '$t'"
  fi
done
# Simpler: just check all 5 appear as case branches
_TARGETS_OK=0
for t in linear github openspec gstack human; do
  if grep -qE "^\s*$t\)" "$_F"; then
    _TARGETS_OK=$(( _TARGETS_OK + 1 ))
  fi
done
if [ "$_TARGETS_OK" -ge 5 ]; then
  ok "All 5 handoff targets are case branches in pm-breakdown"
else
  fail "Only $_TARGETS_OK / 5 handoff targets found as case branches"
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
  echo "  RESULT: PASSED — ETHOS structural gates wired"
  exit 0
fi
