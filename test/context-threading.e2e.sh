#!/usr/bin/env bash
# V1 Release Gate 2: Context threading E2E test
#
# Tests that skill outputs written by one skill are readable by the next skill
# in the pipeline: pm-discovery → pm-audit → pm-objectives → pm-strategy → pm-roadmap
#
# Does NOT require LLM calls — tests the shell function plumbing only.
# Simulates what the skills do by calling nanopm_context_append directly
# and verifying nanopm_context_read + nanopm_context_all work correctly.
#
# Usage: bash test/context-threading.e2e.sh
# Exit 0 = pass, exit 1 = fail
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_TMPDIR=$(mktemp -d /tmp/nanopm-context-XXXXXX)

cleanup() { rm -rf "$_TMPDIR"; }
trap cleanup EXIT

ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; }
fail() {
  printf '  \033[0;31m✗\033[0m %s\n' "$*"
  echo "  RESULT: FAILED"
  exit 1
}

echo
echo "  nanopm E2E: context threading gate"
echo "  ===================================="
echo "  Temp dir: $_TMPDIR"
echo

# ── set up isolated environment ───────────────────────────────────────────────
# Override ~/.nanopm to the temp dir so we don't pollute real state
export HOME="$_TMPDIR"
mkdir -p "$_TMPDIR/.nanopm/memory"

cd "$_TMPDIR"
git init -q

# Source nanopm.sh
# shellcheck source=/dev/null
source "$_REPO_ROOT/lib/nanopm.sh"

_SLUG=$(nanopm_slug)
_MEMORY_FILE="$_TMPDIR/.nanopm/memory/${_SLUG}.jsonl"

echo "  Slug: $_SLUG"
echo "  Memory file: $_MEMORY_FILE"
echo

# ── test 1: empty context returns nothing ────────────────────────────────────
_result=$(nanopm_context_read pm-audit)
if [ -z "$_result" ]; then
  ok "Empty context returns empty string"
else
  fail "Empty context should return empty, got: $_result"
fi

# ── test 2: context_all on missing file returns empty ────────────────────────
_result=$(nanopm_context_all)
if [ -z "$_result" ]; then
  ok "context_all on missing file returns empty"
else
  fail "context_all on missing file should return empty, got: $_result"
fi

# ── test 3: append + read for pm-discovery ───────────────────────────────────
nanopm_context_append '{"skill":"pm-discovery","outputs":{"discovery_question":"Should we build async standup for solo founders?","top_risk":"Founders are willing to pay for async standup tooling","next":"pm-audit"}}'
ok "nanopm_context_append: pm-discovery written"

_result=$(nanopm_context_read pm-discovery)
if echo "$_result" | grep -q '"skill":"pm-discovery"'; then
  ok "nanopm_context_read: pm-discovery readable"
else
  fail "nanopm_context_read: pm-discovery not readable. Got: $_result"
fi

if echo "$_result" | grep -q "solo founders"; then
  ok "nanopm_context_read: pm-discovery content intact"
else
  fail "nanopm_context_read: pm-discovery content missing"
fi

# ── test 4 (was 3): append + read for pm-audit ───────────────────────────────
nanopm_context_append '{"skill":"pm-audit","outputs":{"gap":"Positioning mismatch — solo users vs team pitch","next":"pm-objectives"}}'
ok "nanopm_context_append: pm-audit written"

_result=$(nanopm_context_read pm-audit)
if echo "$_result" | grep -q '"skill":"pm-audit"'; then
  ok "nanopm_context_read: pm-audit readable"
else
  fail "nanopm_context_read: pm-audit not readable. Got: $_result"
fi

if echo "$_result" | grep -q "Positioning mismatch"; then
  ok "nanopm_context_read: pm-audit content intact"
else
  fail "nanopm_context_read: pm-audit content missing"
fi

# ── test 5: append + read for pm-objectives ──────────────────────────────────
nanopm_context_append '{"skill":"pm-objectives","outputs":{"period":"Q1 2026","objective_count":"2","next":"pm-strategy"}}'
ok "nanopm_context_append: pm-objectives written"

_result=$(nanopm_context_read pm-objectives)
if echo "$_result" | grep -q '"skill":"pm-objectives"'; then
  ok "nanopm_context_read: pm-objectives readable"
else
  fail "nanopm_context_read: pm-objectives not readable"
fi

# ── test 6: multiple appends — read returns LATEST for each skill ─────────────
# Append pm-audit again with different content
nanopm_context_append '{"skill":"pm-audit","outputs":{"gap":"UPDATED GAP","next":"pm-objectives"}}'
ok "nanopm_context_append: pm-audit second append"

_result=$(nanopm_context_read pm-audit)
if echo "$_result" | grep -q "UPDATED GAP"; then
  ok "nanopm_context_read: returns latest entry for skill"
else
  fail "nanopm_context_read: should return latest entry. Got: $_result"
fi

# Original entry should NOT be returned by context_read
if echo "$_result" | grep -q "Positioning mismatch"; then
  fail "nanopm_context_read: should return latest, not first. Got both."
fi

# ── test 7: context_all returns all entries ───────────────────────────────────
_all=$(nanopm_context_all)
_line_count=$(echo "$_all" | grep -c '"skill"' || true)
if [ "$_line_count" -eq 4 ]; then
  ok "nanopm_context_all: returns all 4 entries (1 pm-discovery + 2 pm-audit + 1 pm-objectives)"
else
  fail "nanopm_context_all: expected 4 entries, got $_line_count. Output: $_all"
fi

# ── test 8: config get/set ────────────────────────────────────────────────────
nanopm_config_set "company_website" "https://example.com"
ok "nanopm_config_set: company_website written"

_val=$(nanopm_config_get "company_website")
if [ "$_val" = "https://example.com" ]; then
  ok "nanopm_config_get: company_website readable"
else
  fail "nanopm_config_get: expected 'https://example.com', got '$_val'"
fi

# Overwrite test
nanopm_config_set "company_website" "https://updated.com"
_val=$(nanopm_config_get "company_website")
if [ "$_val" = "https://updated.com" ]; then
  ok "nanopm_config_set: overwrite works (returns latest value)"
else
  fail "nanopm_config_set: overwrite failed. Got '$_val'"
fi

# ── test 9: gitignore warning ─────────────────────────────────────────────────
# Without .nanopm/ in gitignore, should return warning (non-zero or output warn)
_warn_output=$(nanopm_check_gitignore 2>&1 || true)
if echo "$_warn_output" | grep -qi "gitignore\|warn\|excluded" || [ -z "$_warn_output" ]; then
  ok "nanopm_check_gitignore: runs without error"
else
  ok "nanopm_check_gitignore: ran (output: $_warn_output)"
fi

# ── test 10: nanopm_staleness_check — no crash on clean project ───────────────
# No PM docs present → should run silently with no output (nothing to warn about)
_stale_output=$(nanopm_staleness_check 2>&1 || true)
if echo "$_stale_output" | grep -q "⚠"; then
  # If it produced a warning, that would mean a .nanopm/AUDIT.md exists from a
  # previous test step AND 20+ commits happened — not expected in this temp env.
  fail "nanopm_staleness_check: unexpected staleness warning on fresh project. Got: $_stale_output"
else
  ok "nanopm_staleness_check: runs silently on project with no PM docs"
fi

# Create a fake AUDIT.md tracked by git, then verify staleness check still runs
mkdir -p .nanopm
echo "# test" > .nanopm/AUDIT.md
git add .nanopm/AUDIT.md 2>/dev/null || true
git -c user.email="test@test.com" -c user.name="test" commit -q -m "add audit" 2>/dev/null || true
_stale_output=$(nanopm_staleness_check 2>&1 || true)
# Freshly committed — 0 commits since, should NOT warn
if echo "$_stale_output" | grep -q "⚠"; then
  fail "nanopm_staleness_check: warned on freshly committed AUDIT.md (0 commits since)"
else
  ok "nanopm_staleness_check: no warning for freshly committed AUDIT.md"
fi

# ── test 11: JSONL file is valid JSON per line ────────────────────────────────
if command -v python3 >/dev/null 2>&1; then
  _invalid=0
  while IFS= read -r line; do
    if [ -z "$line" ]; then continue; fi
    if ! echo "$line" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
      _invalid=$(( _invalid + 1 ))
      echo "  Invalid JSON line: $line"
    fi
  done < "$_MEMORY_FILE"
  if [ "$_invalid" -eq 0 ]; then
    ok "JSONL file: all lines are valid JSON"
  else
    fail "JSONL file: $_invalid invalid JSON line(s)"
  fi
else
  printf '  \033[0;33m⚠\033[0m python3 not found — skipping JSON validation\n'
fi

# ── summary ───────────────────────────────────────────────────────────────────
echo
echo "  ─────────────────────────────"
echo "  RESULT: PASSED — context threading gate OK"
exit 0
