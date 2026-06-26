#!/usr/bin/env bash
# nanopm v0.22.1+ — ingest-agent target path confinement
#
# Regression for the bug where pm-personas (and any entity-ingest skill) wrote pages
# to .nanopm/entities/<type>/ instead of .nanopm/wiki/entities/<type>/: the ingest
# prompt told the agent to use a bare "entities/<type>/<slug>.md", and resolve_target
# resolved it relative to .nanopm/ — so the page escaped the wiki and the viewer
# dumped it into OTHERS. Fixed by confining resolve_target to .nanopm/wiki/ and
# normalizing the wiki/ prefix in.
#
# Deterministic: drives the real bin, no LLM, no network.
set -uo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_BIN="$_REPO_ROOT/bin/nanopm-ingest-agent"
_TMP=$(mktemp -d /tmp/nanopm-ingest-path-XXXXXX)
cleanup() { rm -rf "$_TMP"; }
trap cleanup EXIT

_PASS=0; _FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm tests: ingest-agent path confinement"
echo "  ==========================================="
echo

_P="$_TMP/proj"
mkdir -p "$_P/.nanopm/wiki/entities"

apply() { echo "# x" | python3 "$_BIN" --project "$_P" apply --target "$1" >/dev/null 2>&1; }

# 1. Bare entities/ path (the bug) lands UNDER wiki/, never at .nanopm/entities/
apply "entities/personas/sam.md"
if [ -f "$_P/.nanopm/wiki/entities/personas/sam.md" ]; then
  ok "bare 'entities/personas/sam.md' → .nanopm/wiki/entities/personas/sam.md"
else
  fail "bare entities/ path did not land under wiki/"
fi
if [ -e "$_P/.nanopm/entities" ]; then
  fail "page escaped to .nanopm/entities/ (outside the wiki)"
else
  ok "nothing written outside .nanopm/wiki/"
fi

# 2. wiki/-prefixed and .nanopm/wiki/-prefixed forms resolve to the same place
apply "wiki/entities/personas/mia.md"
apply ".nanopm/wiki/entities/personas/pat.md"
if [ -f "$_P/.nanopm/wiki/entities/personas/mia.md" ] && [ -f "$_P/.nanopm/wiki/entities/personas/pat.md" ]; then
  ok "'wiki/…' and '.nanopm/wiki/…' forms both resolve under the wiki"
else
  fail "prefixed forms did not resolve under the wiki"
fi

# 3. docs/ pages also confined under wiki/
apply "docs/strategy.md"
if [ -f "$_P/.nanopm/wiki/docs/strategy.md" ]; then
  ok "bare 'docs/strategy.md' → .nanopm/wiki/docs/strategy.md"
else
  fail "bare docs/ path did not land under wiki/"
fi

# 4. Traversal escape is refused
_OUT=$(echo "x" | python3 "$_BIN" --project "$_P" apply --target "../../../etc/evil.md" 2>&1)
if echo "$_OUT" | grep -q "refused" && [ ! -f "$_TMP/etc/evil.md" ]; then
  ok "traversal target '../../../etc/evil.md' refused"
else
  fail "traversal escape not refused: $_OUT"
fi

echo
echo "  ─────────────────────────────"
printf '  Passed: %d  Failed: %d\n' "$_PASS" "$_FAIL"
echo
if [ "$_FAIL" -gt 0 ]; then
  echo "  RESULT: FAILED"; exit 1
else
  echo "  RESULT: PASSED — ingest path confinement OK"; exit 0
fi
