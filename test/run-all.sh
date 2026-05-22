#!/usr/bin/env bash
# nanopm — run the full local test suite (no LLM, no network)
#
# Excludes adversarial.e2e.sh by default since it calls the live `claude` CLI
# and burns API tokens. Pass --with-llm to include it.
set -uo pipefail

_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_WITH_LLM=0
for arg in "$@"; do
  case "$arg" in
    --with-llm) _WITH_LLM=1 ;;
  esac
done

_TESTS=(
  "skill-syntax.sh"
  "state-layer.sh"
  "multi-host.sh"
  "gates.sh"
  "update-check.sh"
  "context-threading.e2e.sh"
  "website-bootstrap.e2e.sh"
)

[ "$_WITH_LLM" = "1" ] && _TESTS+=("adversarial.e2e.sh")

_FAILED=()
echo
echo "  nanopm test suite"
echo "  ==================="
echo

for t in "${_TESTS[@]}"; do
  echo "  → Running $t..."
  if bash "$_DIR/$t" >/tmp/nanopm-test-out 2>&1; then
    _LAST_LINE=$(grep -E "RESULT|Passed" /tmp/nanopm-test-out | tail -1 | sed 's/^[[:space:]]*//')
    printf '    \033[0;32m✓\033[0m %s — %s\n' "$t" "$_LAST_LINE"
  else
    printf '    \033[0;31m✗\033[0m %s — FAILED (see output below)\n' "$t"
    cat /tmp/nanopm-test-out | tail -20
    _FAILED+=("$t")
  fi
  echo
done

rm -f /tmp/nanopm-test-out

echo "  ─────────────────────────────"
if [ "${#_FAILED[@]}" -eq 0 ]; then
  printf '  \033[0;32mALL %d SUITES PASSED\033[0m\n' "${#_TESTS[@]}"
  exit 0
else
  printf '  \033[0;31m%d / %d SUITES FAILED:\033[0m %s\n' "${#_FAILED[@]}" "${#_TESTS[@]}" "${_FAILED[*]}"
  exit 1
fi
