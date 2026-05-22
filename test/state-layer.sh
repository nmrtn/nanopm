#!/usr/bin/env bash
# nanopm v0.6.0+ — typed state layer tests
#
# Verifies bin/nanopm-state-log and bin/nanopm-state-read against the schema:
#   - Valid records are accepted for each type (timeline, decision, prd, handoff)
#   - Invalid records are rejected with non-zero exit and stderr message
#   - Read helper returns latest / filtered / limited matches
#   - ts and slug are injected automatically
#
# No LLM, no network. Pure binary + schema test.
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_TMPDIR=$(mktemp -d /tmp/nanopm-state-XXXXXX)

cleanup() { rm -rf "$_TMPDIR"; }
trap cleanup EXIT

_PASS=0
_FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm tests: typed state layer"
echo "  ================================="
echo "  Temp HOME: $_TMPDIR"
echo

# Isolated HOME so we don't touch real state
export HOME="$_TMPDIR"
mkdir -p "$_TMPDIR/.nanopm/projects"

# Initialize a git repo so slug() resolves to repo basename
cd "$_TMPDIR"
git init -q
mv .git .gitkeep  # keep the dir but disable git lookup so slug = cwd basename
mv .gitkeep .git  # restore — slug will be temp dir basename, that's fine
_SLUG=$(basename "$_TMPDIR")

_LOG="$_REPO_ROOT/bin/nanopm-state-log"
_READ="$_REPO_ROOT/bin/nanopm-state-read"

[ -x "$_LOG" ]  || { fail "bin/nanopm-state-log not executable"; exit 1; }
[ -x "$_READ" ] || { fail "bin/nanopm-state-read not executable"; exit 1; }
ok "Binaries exist and are executable"

# ── 1. Valid records for each type ────────────────────────────────────────────
echo
echo "  Valid writes (one per type)"

if "$_LOG" --type timeline '{"skill":"smoke","event":"started","branch":"main","outcome":"unknown"}'; then
  ok "timeline: valid record accepted"
else
  fail "timeline: rejected a valid record"
fi

if "$_LOG" --type decision '{"kind":"bet","key":"go-enterprise-first","insight":"Enterprise CTOs will pay $X/mo before SMB founders do","confidence":7,"source":"adversarial","skill":"pm-strategy"}'; then
  ok "decision: valid record accepted"
else
  fail "decision: rejected a valid record"
fi

if "$_LOG" --type prd '{"feature":"export-panel","status":"ready","skill":"pm-prd"}'; then
  ok "prd: valid record accepted"
else
  fail "prd: rejected a valid record"
fi

if "$_LOG" --type handoff '{"feature":"export-panel","target":"openspec","path":"openspec/changes/export-panel/"}'; then
  ok "handoff: valid record accepted"
else
  fail "handoff: rejected a valid record"
fi

# ── 2. Metadata injection ─────────────────────────────────────────────────────
echo
echo "  Auto-injected metadata"

_DEC_FILE="$_TMPDIR/.nanopm/projects/$_SLUG/decision.jsonl"
if [ -f "$_DEC_FILE" ]; then
  _LINE=$(tail -1 "$_DEC_FILE")
  if echo "$_LINE" | grep -q '"ts":"20'; then
    ok "ts auto-injected on write"
  else
    fail "ts not injected. Line: $_LINE"
  fi
  if echo "$_LINE" | grep -q '"slug":"'"$_SLUG"'"'; then
    ok "slug auto-injected on write"
  else
    fail "slug not injected. Line: $_LINE"
  fi
else
  fail "decision.jsonl not created at $_DEC_FILE"
fi

# ── 3. Invalid records are rejected ───────────────────────────────────────────
echo
echo "  Invalid writes (must be rejected)"

# Missing required field
if "$_LOG" --type decision '{"kind":"bet","key":"x","insight":"y","source":"observed"}' 2>/dev/null; then
  fail "decision: accepted record missing 'confidence' (should reject)"
else
  ok "decision: rejected missing required field"
fi

# Bad enum
if "$_LOG" --type decision '{"kind":"vibe-check","key":"x","insight":"y","confidence":5,"source":"observed"}' 2>/dev/null; then
  fail "decision: accepted invalid kind 'vibe-check' (should reject)"
else
  ok "decision: rejected invalid enum"
fi

# Bad key chars
if "$_LOG" --type decision '{"kind":"bet","key":"bad key with spaces","insight":"y","confidence":5,"source":"observed"}' 2>/dev/null; then
  fail "decision: accepted key with spaces (should reject)"
else
  ok "decision: rejected invalid key chars"
fi

# Confidence out of range
if "$_LOG" --type decision '{"kind":"bet","key":"x","insight":"y","confidence":99,"source":"observed"}' 2>/dev/null; then
  fail "decision: accepted confidence=99 (should reject, max 10)"
else
  ok "decision: rejected confidence out of range"
fi

# Insight too long
_BIG=$(python3 -c "print('x' * 1500)")
if "$_LOG" --type decision "{\"kind\":\"bet\",\"key\":\"x\",\"insight\":\"$_BIG\",\"confidence\":5,\"source\":\"observed\"}" 2>/dev/null; then
  fail "decision: accepted insight >1000 chars (should reject)"
else
  ok "decision: rejected oversized insight"
fi

# Invalid event enum for timeline
if "$_LOG" --type timeline '{"skill":"x","event":"vibing"}' 2>/dev/null; then
  fail "timeline: accepted invalid event (should reject)"
else
  ok "timeline: rejected invalid event enum"
fi

# Bad target for handoff
if "$_LOG" --type handoff '{"feature":"x","target":"airtable","path":"y"}' 2>/dev/null; then
  fail "handoff: accepted invalid target 'airtable' (should reject)"
else
  ok "handoff: rejected invalid target enum"
fi

# Invalid status for prd
if "$_LOG" --type prd '{"feature":"x","status":"shipping-soon"}' 2>/dev/null; then
  fail "prd: accepted invalid status (should reject)"
else
  ok "prd: rejected invalid status enum"
fi

# Bad JSON
if echo "not json" | "$_LOG" --type decision 2>/dev/null; then
  fail "decision: accepted non-JSON input (should reject)"
else
  ok "decision: rejected non-JSON input"
fi

# Unknown type
if "$_LOG" --type wisdom '{"x":"y"}' 2>/dev/null; then
  fail "accepted unknown type 'wisdom' (should reject)"
else
  ok "rejected unknown record type"
fi

# Unknown field in record
if "$_LOG" --type decision '{"kind":"bet","key":"x","insight":"y","confidence":5,"source":"observed","extra_field":"oops"}' 2>/dev/null; then
  fail "decision: accepted unknown field (should reject)"
else
  ok "decision: rejected unknown field"
fi

# ── 4. Read helper ────────────────────────────────────────────────────────────
echo
echo "  Reader: nanopm-state-read"

# Latest decision
_LATEST=$("$_READ" --type decision --latest)
if echo "$_LATEST" | grep -q '"key":"go-enterprise-first"'; then
  ok "--latest returns most recent record"
else
  fail "--latest returned wrong record. Got: $_LATEST"
fi

# Filter by kind
"$_LOG" --type decision '{"kind":"antigoal","key":"no-enterprise","insight":"Never build for >500-person companies in v1","confidence":9,"source":"user-stated","skill":"pm-strategy"}' >/dev/null
_COUNT=$("$_READ" --type decision --filter kind=bet | wc -l | tr -d ' ')
if [ "$_COUNT" = "1" ]; then
  ok "--filter kind=bet returns 1 record"
else
  fail "--filter kind=bet returned $_COUNT records (expected 1)"
fi

# Multiple filters AND together
_COUNT=$("$_READ" --type decision --filter kind=antigoal --filter source=user-stated | wc -l | tr -d ' ')
if [ "$_COUNT" = "1" ]; then
  ok "--filter (kind AND source) returns 1 record"
else
  fail "--filter (kind AND source) returned $_COUNT records (expected 1)"
fi

# Limit
"$_LOG" --type timeline '{"skill":"smoke","event":"completed","outcome":"success"}' >/dev/null
"$_LOG" --type timeline '{"skill":"smoke2","event":"completed","outcome":"success"}' >/dev/null
_COUNT=$("$_READ" --type timeline --limit 2 | wc -l | tr -d ' ')
if [ "$_COUNT" = "2" ]; then
  ok "--limit 2 returns 2 records"
else
  fail "--limit 2 returned $_COUNT records"
fi

# Missing file returns empty (no crash)
if "$_READ" --type decision --filter key=does-not-exist >/dev/null; then
  ok "missing filter match returns empty (no crash)"
else
  fail "missing filter match should not error"
fi

# ── 5. Validator exits non-zero on bad write (CRITICAL — gates rely on this) ─
echo
echo "  Validator exit codes (gates depend on this)"
# Note: must `|| _EXIT=$?` to avoid `set -e` killing the script when validator
# correctly exits non-zero on a bad record.
_EXIT=0
"$_LOG" --type decision '{"kind":"bet","key":"x","insight":"y","confidence":99,"source":"observed"}' 2>/dev/null || _EXIT=$?
if [ "$_EXIT" -ne 0 ]; then
  ok "validator exits non-zero on bad record (exit=$_EXIT)"
else
  fail "validator exited 0 on bad record — gates will not fail loud"
fi

# Stderr message is present (always ok with the || true at the end)
_STDERR=$("$_LOG" --type decision '{"kind":"vibe","key":"x","insight":"y","confidence":5,"source":"observed"}' 2>&1 1>/dev/null || true)
if echo "$_STDERR" | grep -q "nanopm-state-log:"; then
  ok "validator writes nanopm-state-log: prefix to stderr"
else
  fail "validator stderr missing prefix. Got: $_STDERR"
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
  echo "  RESULT: PASSED — state layer schema enforcement OK"
  exit 0
fi
