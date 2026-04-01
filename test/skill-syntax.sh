#!/usr/bin/env bash
# Tier 1 static checks — run in CI, no LLM calls needed
# Tests: SKILL.md frontmatter, lib/nanopm.sh syntax, setup syntax,
#        connector file structure, gitignore safety
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_PASS=0
_FAIL=0
_WARN=0

ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }
warn() { printf '  \033[0;33m⚠\033[0m %s\n' "$*"; _WARN=$(( _WARN + 1 )); }

echo
echo "  nanopm static checks"
echo "  ====================="

# ── 1. lib/nanopm.sh bash syntax ─────────────────────────────────────────────
echo
echo "  lib/"
if bash -n "$_REPO_ROOT/lib/nanopm.sh" 2>/dev/null; then
  ok "lib/nanopm.sh — syntax valid"
else
  fail "lib/nanopm.sh — syntax error"
fi

# ── 2. setup bash syntax ──────────────────────────────────────────────────────
echo
echo "  setup"
if bash -n "$_REPO_ROOT/setup" 2>/dev/null; then
  ok "setup — syntax valid"
else
  fail "setup — syntax error"
fi

# ── 3. SKILL.md frontmatter validation ───────────────────────────────────────
echo
echo "  SKILL.md frontmatter"
_SKILLS=(pm-scan pm-discovery pm-audit pm-objectives pm-strategy pm-roadmap pm-prd pm-breakdown pm-retro pm-run pm-upgrade pm-user-feedback pm-competitors-intel)
for skill in "${_SKILLS[@]}"; do
  _FILE="$_REPO_ROOT/$skill/SKILL.md"
  if [ ! -f "$_FILE" ]; then
    fail "$skill/SKILL.md — file missing"
    continue
  fi

  # Check frontmatter block exists (--- at line 1)
  _L1=$(head -1 "$_FILE")
  if [ "$_L1" != "---" ]; then
    fail "$skill/SKILL.md — no frontmatter (expected '---' at line 1)"
    continue
  fi

  # Required frontmatter fields
  _has_name=0; _has_version=0; _has_desc=0; _has_tools=0
  grep -q "^name:" "$_FILE"         && _has_name=1    || true
  grep -q "^version:" "$_FILE"      && _has_version=1 || true
  grep -q "^description:" "$_FILE"  && _has_desc=1    || true
  grep -q "^allowed-tools:" "$_FILE" && _has_tools=1  || true

  _issues=()
  [ "$_has_name" -eq 0 ]    && _issues+=("missing name:")
  [ "$_has_version" -eq 0 ] && _issues+=("missing version:")
  [ "$_has_desc" -eq 0 ]    && _issues+=("missing description:")
  [ "$_has_tools" -eq 0 ]   && _issues+=("missing allowed-tools:")

  if [ "${#_issues[@]}" -eq 0 ]; then
    ok "$skill/SKILL.md — frontmatter OK"
  else
    fail "$skill/SKILL.md — ${_issues[*]}"
  fi
done

# ── 4. Preamble pattern present in each skill ─────────────────────────────────
echo
echo "  Preamble pattern"
for skill in "${_SKILLS[@]}"; do
  _FILE="$_REPO_ROOT/$skill/SKILL.md"
  [ ! -f "$_FILE" ] && continue
  if grep -q "nanopm_preamble" "$_FILE"; then
    ok "$skill — nanopm_preamble present"
  else
    fail "$skill — nanopm_preamble missing"
  fi
done

# ── 5. nanopm_context_append present (context threading) ─────────────────────
# pm-watch is excluded — it's a hook installer, not a PM analysis skill
_CONTEXT_SKILLS=(pm-discovery pm-audit pm-objectives pm-strategy pm-roadmap pm-prd pm-breakdown pm-retro)
echo
echo "  Context threading"
for skill in "${_CONTEXT_SKILLS[@]}"; do
  _FILE="$_REPO_ROOT/$skill/SKILL.md"
  [ ! -f "$_FILE" ] && continue
  if grep -q "nanopm_context_append" "$_FILE"; then
    ok "$skill — nanopm_context_append present"
  else
    fail "$skill — nanopm_context_append missing (context not threaded)"
  fi
done

# ── 6. Adversarial subagent in pm-strategy ───────────────────────────────────
echo
echo "  Adversarial subagent (pm-strategy)"
_FILE="$_REPO_ROOT/pm-strategy/SKILL.md"
if [ -f "$_FILE" ]; then
  if grep -q "Agent tool" "$_FILE" && grep -q "adversarial" "$_FILE"; then
    ok "pm-strategy — adversarial Agent dispatch present"
  else
    fail "pm-strategy — adversarial Agent dispatch missing"
  fi
  if grep -q "Challenged by adversarial review" "$_FILE"; then
    ok "pm-strategy — STRATEGY.md section gate present"
  else
    fail "pm-strategy — STRATEGY.md 'Challenged by adversarial review' section missing (V1 gate)"
  fi
fi

# ── 7. Connector files ────────────────────────────────────────────────────────
echo
echo "  Connectors"
_CONNECTORS=(linear notion dovetail github)
for c in "${_CONNECTORS[@]}"; do
  _FILE="$_REPO_ROOT/connectors/${c}.md"
  if [ ! -f "$_FILE" ]; then
    fail "connectors/$c.md — missing"
    continue
  fi
  # Each connector must have all 4 tiers documented
  _tiers=0
  for t in "## Tier 1" "## Tier 2" "## Tier 3" "## Tier 4"; do
    grep -q "$t" "$_FILE" && _tiers=$(( _tiers + 1 )) || true
  done
  if [ "$_tiers" -eq 4 ]; then
    ok "connectors/$c.md — all 4 tiers present"
  else
    fail "connectors/$c.md — only $_tiers/4 tiers present"
  fi
done

# ── 8. .gitignore safety ──────────────────────────────────────────────────────
echo
echo "  Gitignore safety"
if [ -f "$_REPO_ROOT/.gitignore" ]; then
  if grep -q "^\.nanopm/" "$_REPO_ROOT/.gitignore"; then
    ok ".gitignore — .nanopm/ excluded"
  else
    warn ".gitignore — .nanopm/ not excluded (setup script handles this, but warn)"
  fi
else
  warn ".gitignore — file missing (setup script will create it)"
fi

# ── 9. VERSION file ───────────────────────────────────────────────────────────
echo
echo "  VERSION"
if [ -f "$_REPO_ROOT/VERSION" ]; then
  _V=$(cat "$_REPO_ROOT/VERSION")
  if echo "$_V" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    ok "VERSION — $_V (semver OK)"
  else
    fail "VERSION — '$_V' is not semver"
  fi
else
  fail "VERSION — file missing"
fi

# ── summary ───────────────────────────────────────────────────────────────────
echo
echo "  ─────────────────────────────"
printf '  Passed: %d  Failed: %d  Warnings: %d\n' "$_PASS" "$_FAIL" "$_WARN"
echo

if [ "$_FAIL" -gt 0 ]; then
  echo "  RESULT: FAILED"
  exit 1
else
  echo "  RESULT: PASSED"
  exit 0
fi
