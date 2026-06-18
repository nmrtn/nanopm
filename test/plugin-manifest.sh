#!/usr/bin/env bash
# Tier 1 static checks for the Claude Code plugin packaging.
#
# The plugin (.claude-plugin/plugin.json) and the curl/bash installer (setup's
# _SKILL_LIST) are two independent sources of truth for the skill roster and the
# version. This test fails the moment they drift, so a release can't ship a
# plugin that lists a different set of skills — or a stale version — than the
# installer. Pure JSON + text parsing; no LLM, no network.
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_PASS=0
_FAIL=0

ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm plugin manifest checks"
echo "  ============================="

_PLUGIN="$_REPO_ROOT/.claude-plugin/plugin.json"
_MARKET="$_REPO_ROOT/.claude-plugin/marketplace.json"
_HOOKS="$_REPO_ROOT/hooks/hooks.json"

# Resolve a JSON parser: prefer python3, fall back to node.
if command -v python3 >/dev/null 2>&1; then
  _json() { python3 -c "$1" "${@:2}"; }
elif command -v node >/dev/null 2>&1; then
  _json() { node -e "$1" "${@:2}"; }
else
  echo "  RESULT: FAILED (no python3 or node to parse JSON)"
  exit 1
fi

# ── 1. all three files exist and are valid JSON ──────────────────────────────
echo
echo "  files present + valid JSON"
for f in "$_PLUGIN" "$_MARKET" "$_HOOKS"; do
  _rel="${f#"$_REPO_ROOT"/}"
  if [ ! -f "$f" ]; then
    fail "$_rel — missing"
  elif python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>/dev/null \
       || node -e 'JSON.parse(require("fs").readFileSync(process.argv[1]))' "$f" 2>/dev/null; then
    ok "$_rel — valid JSON"
  else
    fail "$_rel — invalid JSON"
  fi
done

# Bail early if the manifest itself didn't parse — later checks need it.
if [ "$_FAIL" -gt 0 ]; then
  echo; echo "  RESULT: FAILED"; exit 1
fi

# ── 2. skills roster parity: plugin.json vs setup's _SKILL_LIST ──────────────
echo
echo "  skills roster parity (plugin.json ⇄ setup)"

# Skill names from plugin.json (basename of each "./<skill>" path), sorted.
_PLUGIN_SKILLS=$(python3 -c '
import json,sys,os
d=json.load(open(sys.argv[1]))
print("\n".join(sorted(os.path.basename(s.rstrip("/")) for s in d.get("skills",[]))))
' "$_PLUGIN" 2>/dev/null || node -e '
const d=JSON.parse(require("fs").readFileSync(process.argv[1]));
console.log((d.skills||[]).map(s=>s.replace(/\/+$/,"").split("/").pop()).sort().join("\n"))
' "$_PLUGIN")

# Skill names from setup's _SKILL_LIST, sorted.
_SETUP_LINE=$(grep -E '^_SKILL_LIST=' "$_REPO_ROOT/setup" | head -1)
_SETUP_SKILLS=$(printf '%s\n' "$_SETUP_LINE" \
  | sed -E 's/^_SKILL_LIST="//; s/"$//' \
  | tr ' ' '\n' | grep . | sort)

if [ "$_PLUGIN_SKILLS" = "$_SETUP_SKILLS" ]; then
  _n=$(printf '%s\n' "$_PLUGIN_SKILLS" | grep -c .)
  ok "rosters match ($_n skills)"
else
  fail "roster drift between plugin.json and setup _SKILL_LIST:"
  diff <(printf '%s\n' "$_SETUP_SKILLS") <(printf '%s\n' "$_PLUGIN_SKILLS") \
    | sed 's/^/      /' || true
fi

# Each listed skill directory must actually contain a SKILL.md.
echo
echo "  skill paths resolve to real SKILL.md files"
_missing=0
while IFS= read -r _s; do
  [ -z "$_s" ] && continue
  if [ ! -f "$_REPO_ROOT/$_s/SKILL.md" ]; then
    fail "$_s — listed in plugin.json but $_s/SKILL.md missing"
    _missing=$(( _missing + 1 ))
  fi
done <<< "$_PLUGIN_SKILLS"
[ "$_missing" -eq 0 ] && ok "all listed skill dirs contain SKILL.md"

# ── 3. version parity: plugin.json vs VERSION file ───────────────────────────
echo
echo "  version parity (plugin.json ⇄ VERSION)"
_FILE_VER=$(tr -d '[:space:]' < "$_REPO_ROOT/VERSION")
_PLUGIN_VER=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("version",""))' "$_PLUGIN" 2>/dev/null \
  || node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1])).version||"")' "$_PLUGIN")
if [ "$_FILE_VER" = "$_PLUGIN_VER" ]; then
  ok "version $_PLUGIN_VER matches VERSION file"
else
  fail "plugin.json version ($_PLUGIN_VER) != VERSION file ($_FILE_VER) — bump both on release"
fi

# ── 4. marketplace references the plugin ─────────────────────────────────────
echo
echo "  marketplace.json references the nanopm plugin"
_HAS_PLUGIN=$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
print("yes" if any(p.get("name")=="nanopm" for p in d.get("plugins",[])) else "no")
' "$_MARKET" 2>/dev/null || node -e '
const d=JSON.parse(require("fs").readFileSync(process.argv[1]));
console.log((d.plugins||[]).some(p=>p.name==="nanopm")?"yes":"no")
' "$_MARKET")
if [ "$_HAS_PLUGIN" = "yes" ]; then
  ok "marketplace lists the 'nanopm' plugin"
else
  fail "marketplace.json has no plugin named 'nanopm'"
fi

# ── 5. hooks.json wires a SessionStart bootstrap to setup --deps-only ────────
echo
echo "  SessionStart hook bootstraps the runtime"
if grep -q 'SessionStart' "$_HOOKS" && grep -q -- '--deps-only' "$_HOOKS"; then
  ok "hooks.json runs setup --deps-only on SessionStart"
else
  fail "hooks.json missing SessionStart → setup --deps-only wiring"
fi
# setup must actually accept --deps-only.
if grep -q -- '--deps-only)' "$_REPO_ROOT/setup"; then
  ok "setup handles the --deps-only flag"
else
  fail "setup does not parse --deps-only (hook would no-op)"
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
  echo "  RESULT: PASSED"
  exit 0
fi
