#!/usr/bin/env bash
# nanopm v0.6.3+ — AskUserQuestion portability test
#
# Mistral Vibe's ask_user_question tool validates:
#   - header ≤ 12 chars
#   - options list MUST have ≥ 2 items (no free-text-only questions)
# Claude Code is more permissive. To be portable across hosts, SKILL.md
# files must respect both rules.
#
# This test parses each SKILL.md and finds lines of the form:
#   - **header:** `<value>`
#   - **header:** "<value>"
#   - header: "<value>"   (in JSON-like blocks)
# and warns if the value exceeds 12 chars.
#
# When the SKILL.md doesn't prescribe an explicit header, this test can't catch
# it — the LLM picks one at runtime. To prevent the runtime failure, every
# AskUserQuestion call in a SKILL.md SHOULD have an explicit header prescribed.
set -uo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_PASS=0
_FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm tests: AskUserQuestion header portability"
echo "  ==================================================="
echo "  Vibe constraint: header field MUST be ≤12 chars"
echo

# ── 1. Audit every prescribed header in every SKILL.md ────────────────────────
echo "  Prescribed headers (across all SKILL.md files)"
_FOUND=0
_OFFENDERS=""

# Patterns matched (in priority order):
#   `header:` `Foo`                 — markdown bold + backticks
#   **header:** `Foo`               — bold-prefix + backticks
#   **header:** "Foo"               — bold-prefix + quotes
#   header: "Foo"                   — JSON-like
#   "header": "Foo"                 — JSON
# Extracts the value between the delimiters.
while IFS= read -r line; do
  file=$(echo "$line" | cut -d: -f1)
  num=$(echo "$line" | cut -d: -f2)
  text=$(echo "$line" | cut -d: -f3-)
  # Try to extract value from any of: `value` "value" 'value'
  hdr=$(echo "$text" | sed -nE '
    s/.*\*\*header:\*\*[[:space:]]*`([^`]+)`.*/\1/p
    s/.*\*\*header:\*\*[[:space:]]*"([^"]+)".*/\1/p
    s/.*\*\*header:\*\*[[:space:]]*'\''([^'\'']+)'\''.*/\1/p
    s/.*"header"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p
    s/^[[:space:]]*header:[[:space:]]*"([^"]+)".*/\1/p
    s/^[[:space:]]*-[[:space:]]*header:[[:space:]]*`([^`]+)`.*/\1/p
  ' | head -1)
  [ -z "$hdr" ] && continue
  _FOUND=$(( _FOUND + 1 ))
  len=${#hdr}
  if [ "$len" -gt 12 ]; then
    fail "$file:$num — header '$hdr' is $len chars (Vibe limit: 12)"
    _OFFENDERS="$_OFFENDERS $file"
  else
    ok "$file:$num — '$hdr' ($len chars)"
  fi
done < <(grep -rn -E "(\*\*header:\*\*|^\s*header:|\"header\"\s*:)" \
           "$_REPO_ROOT"/pm-*/SKILL.md 2>/dev/null)

if [ "$_FOUND" -eq 0 ]; then
  fail "No prescribed headers found in any SKILL.md. Every AskUserQuestion call should prescribe a header explicitly."
fi

# ── 2. AskUserQuestion blocks SHOULD prescribe a header ──────────────────────
# Warning-level check: count invocations vs prescribed headers per skill.
# A mismatch means some calls leave header-picking to the LLM (which can pick
# something >12 chars on Vibe).
echo
echo "  Coverage: invocations vs prescribed headers per skill"
for f in "$_REPO_ROOT"/pm-*/SKILL.md; do
  [ -f "$f" ] || continue
  _NAME=$(basename "$(dirname "$f")")
  _HEADERS=$(grep -cE "(\*\*header:\*\*|^[[:space:]]*header:|\"header\"[[:space:]]*:)" "$f" 2>/dev/null | tr -d '[:space:]')
  _INVOCATIONS=$(grep -cE "(Ask via AskUserQuestion|Use AskUserQuestion|AskUserQuestion call)" "$f" 2>/dev/null | tr -d '[:space:]')
  _HEADERS=${_HEADERS:-0}
  _INVOCATIONS=${_INVOCATIONS:-0}
  if [ "$_INVOCATIONS" -gt 0 ] 2>/dev/null && [ "$_HEADERS" -lt "$_INVOCATIONS" ] 2>/dev/null; then
    printf '  \033[0;33m⚠\033[0m  %-30s — %s invocations, %s prescribed headers (LLM picks the rest)\n' \
      "$_NAME" "$_INVOCATIONS" "$_HEADERS"
  fi
done

# ── 3. Spot-check the regression: pm-run Phase 0b prescribes a short header ──
echo
echo "  Regression: pm-run Phase 0b 'Starting point' bug"
# Look in the ~20 lines after Phase 0b heading
if awk '/^## Phase 0b/{found=1; n=0} found && n<20 {print; n++}' \
      "$_REPO_ROOT/pm-run/SKILL.md" | grep -qE "header.*Start"; then
  ok "pm-run Phase 0b prescribes a short header (regression fixed)"
else
  fail "pm-run Phase 0b has no short prescribed header (Vibe will rebreak on 'Starting point')"
fi

# ── 4. Regression: pm-discovery Phase 1 has ≥2 options (no free-text crash) ──
echo
echo "  Regression: pm-discovery Phase 1 'options=[]' bug"
# Phase 1 should now use a multi-choice scoping question instead of pure free-text.
if awk '/^## Phase 1: Scope the discovery/{found=1; n=0} found && n<30 {print; n++}' \
      "$_REPO_ROOT/pm-discovery/SKILL.md" | grep -qiE "options:|^[[:space:]]*- A\)|^[[:space:]]*- B\)"; then
  ok "pm-discovery Phase 1 provides ≥2 options (regression fixed)"
else
  fail "pm-discovery Phase 1 still uses free-text-only question (Vibe will reject options=[])"
fi

# ── 5. Portability rule is v2 (covers both header and options constraints) ──
echo
echo "  Portability rule version"
_V2_COUNT=$(grep -l "portability-v2" "$_REPO_ROOT"/pm-*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
_V1_REMAINING=$(grep -l "portability-v1" "$_REPO_ROOT"/pm-*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$_V2_COUNT" -ge 17 ]; then
  ok "All 17 skills carry portability-v2 rule (header + options constraints)"
else
  fail "Only $_V2_COUNT/17 skills have portability-v2 (rest are still on v1 or missing)"
fi
if [ "$_V1_REMAINING" -gt 0 ]; then
  fail "$_V1_REMAINING skill(s) still on portability-v1 — should be upgraded to v2"
else
  ok "No leftover portability-v1 blocks"
fi

# ── 6. Lib source is present in bash blocks that call nanopm_* functions ──
echo
echo "  Bash blocks source the lib before calling nanopm_* functions"
_MISSING=0
for skill in "$_REPO_ROOT"/pm-*/SKILL.md; do
  _NAME=$(basename "$(dirname "$skill")")
  # python3 inline check
  _N=$(python3 - "$skill" <<'PYEOF'
import re, sys
text = open(sys.argv[1]).read()
n = 0
for block in re.findall(r'```bash\s*\n(.*?)\n```', text, re.DOTALL):
    calls = re.search(r'\bnanopm_[a-z_]+\b', block)
    has_source = re.search(r'^\s*(?:source|\.)\s+[^\n]*nanopm\.sh', block, re.MULTILINE)
    is_preamble = 'nanopm_preamble' in block and 'source' in block
    if calls and not has_source and not is_preamble:
        n += 1
print(n)
PYEOF
)
  if [ "$_N" != "0" ]; then
    fail "$_NAME: $_N bash block(s) call nanopm_* without sourcing the lib (Vibe will fail)"
    _MISSING=$(( _MISSING + 1 ))
  fi
done
if [ "$_MISSING" = "0" ]; then
  ok "All bash blocks that use nanopm_* functions source the lib"
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
  echo "  RESULT: PASSED — AskUserQuestion headers within Vibe limit"
  exit 0
fi
