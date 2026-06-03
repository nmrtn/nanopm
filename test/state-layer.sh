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

_SLUG_DIR="$_TMPDIR/.nanopm/projects/$_SLUG"
_DEC_FILE="$_SLUG_DIR/decision.jsonl"
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

# ── 6. Session field validation + auto-injection (v0.6.5+) ───────────────────
echo
echo "  Session field (v0.6.5+ memory-read instrumentation)"

# Reject obviously invalid session strings
if "$_LOG" --type decision \
  '{"kind":"bet","key":"sess-bad","insight":"x","confidence":5,"source":"observed","session":"not-hex-not-16"}' 2>/dev/null; then
  fail "decision: accepted invalid session string (should reject — must be 16-char hex)"
else
  ok "decision: rejected invalid session string"
fi

# Accept valid 16-hex session
_VALID_SESS="abcdef0123456789"
if "$_LOG" --type decision \
  "{\"kind\":\"bet\",\"key\":\"sess-good\",\"insight\":\"x\",\"confidence\":5,\"source\":\"observed\",\"session\":\"$_VALID_SESS\"}"; then
  ok "decision: accepted valid 16-hex session string"
else
  fail "decision: rejected valid 16-hex session string"
fi

# Auto-inject from NANOPM_SESSION_ID env var
_AUTO_SESS=$(python3 -c "import uuid; print(uuid.uuid4().hex[:16])")
NANOPM_SESSION_ID="$_AUTO_SESS" "$_LOG" --type decision \
  '{"kind":"bet","key":"sess-auto","insight":"x","confidence":5,"source":"observed"}' >/dev/null
_LAST_LINE=$(tail -1 "$_DEC_FILE")
if echo "$_LAST_LINE" | grep -q "\"session\":\"$_AUTO_SESS\""; then
  ok "decision: auto-injected session from NANOPM_SESSION_ID env var"
else
  fail "decision: env-var session not auto-injected. Got: $_LAST_LINE"
fi

# Auto-inject from .current_session file (Vibe subprocess case)
_FILE_SESS=$(python3 -c "import uuid; print(uuid.uuid4().hex[:16])")
mkdir -p "$_SLUG_DIR"
echo "$_FILE_SESS" > "$_SLUG_DIR/.current_session"
# Note: with NANOPM_SESSION_ID unset, falls through to file lookup
env -u NANOPM_SESSION_ID "$_LOG" --type decision \
  '{"kind":"bet","key":"sess-file","insight":"x","confidence":5,"source":"observed"}' >/dev/null
_LAST_LINE=$(tail -1 "$_DEC_FILE")
if echo "$_LAST_LINE" | grep -q "\"session\":\"$_FILE_SESS\""; then
  ok "decision: auto-injected session from .current_session file (env var unset)"
else
  fail "decision: file-based session not auto-injected. Got: $_LAST_LINE"
fi

# Env var trumps file
echo "wrong-but-file-says-this-x" > "$_SLUG_DIR/.current_session"
_ENV_SESS=$(python3 -c "import uuid; print(uuid.uuid4().hex[:16])")
NANOPM_SESSION_ID="$_ENV_SESS" "$_LOG" --type decision \
  '{"kind":"bet","key":"sess-precedence","insight":"x","confidence":5,"source":"observed"}' >/dev/null
_LAST_LINE=$(tail -1 "$_DEC_FILE")
if echo "$_LAST_LINE" | grep -q "\"session\":\"$_ENV_SESS\""; then
  ok "decision: NANOPM_SESSION_ID env var takes precedence over file"
else
  fail "decision: env var precedence broken. Got: $_LAST_LINE"
fi

# Clean up the malformed marker file from the precedence test so subsequent test
# runs in the same TMPDIR don't read it
rm -f "$_SLUG_DIR/.current_session"

# Session optional on all 4 types (decision tested above)
NANOPM_SESSION_ID="$_AUTO_SESS" "$_LOG" --type timeline \
  '{"skill":"sess-t","event":"started"}' >/dev/null
NANOPM_SESSION_ID="$_AUTO_SESS" "$_LOG" --type prd \
  '{"feature":"sess-test","status":"draft"}' >/dev/null
NANOPM_SESSION_ID="$_AUTO_SESS" "$_LOG" --type handoff \
  '{"feature":"sess-test","target":"human","path":"x"}' >/dev/null
_TIMELINE_HAS_SESS=$(tail -1 "$_TMPDIR/.nanopm/projects/$_SLUG/timeline.jsonl" | grep -c '"session":' || true)
_PRD_HAS_SESS=$(tail -1 "$_TMPDIR/.nanopm/projects/$_SLUG/prd.jsonl" | grep -c '"session":' || true)
_HANDOFF_HAS_SESS=$(tail -1 "$_TMPDIR/.nanopm/projects/$_SLUG/handoff.jsonl" | grep -c '"session":' || true)
if [ "$_TIMELINE_HAS_SESS" = "1" ] && [ "$_PRD_HAS_SESS" = "1" ] && [ "$_HANDOFF_HAS_SESS" = "1" ]; then
  ok "session auto-injected into timeline / prd / handoff records"
else
  fail "session NOT injected into all 4 types (timeline=$_TIMELINE_HAS_SESS prd=$_PRD_HAS_SESS handoff=$_HANDOFF_HAS_SESS)"
fi

# ── 7. Cross-session memory-read emission via lib wrapper ────────────────────
echo
echo "  Memory-read emission (lib wrapper nanopm_state_read)"
# Source the lib NOW (rest of this test file uses the binaries directly via $_LOG/$_READ
# and never sourced lib). The wrapper looks at $HOME/.nanopm/bin/ — symlink the binaries.
# shellcheck source=/dev/null
source "$_REPO_ROOT/lib/nanopm.sh"
mkdir -p "$_TMPDIR/.nanopm/bin"
ln -sf "$_REPO_ROOT/bin/nanopm-state-log" "$_TMPDIR/.nanopm/bin/"
ln -sf "$_REPO_ROOT/bin/nanopm-state-read" "$_TMPDIR/.nanopm/bin/"

# Clear timeline to isolate the test
> "$_TMPDIR/.nanopm/projects/$_SLUG/timeline.jsonl"

# Decision.jsonl already has records from multiple sessions (sessions injected above)
# Set current session to something different than all of them
_S_CURRENT=$(python3 -c "import uuid; print(uuid.uuid4().hex[:16])")
NANOPM_SESSION_ID="$_S_CURRENT" nanopm_state_read --type decision >/dev/null

# Check timeline.jsonl for a memory-read event
_MEMREAD_COUNT=$(grep -c '"event":"memory-read"' "$_TMPDIR/.nanopm/projects/$_SLUG/timeline.jsonl" 2>/dev/null || echo 0)
_MEMREAD_COUNT=$(echo "$_MEMREAD_COUNT" | tr -d '[:space:]')
if [ "$_MEMREAD_COUNT" -ge 1 ] 2>/dev/null; then
  ok "memory-read emitted when reading decisions from prior sessions ($_MEMREAD_COUNT event(s))"
else
  fail "memory-read NOT emitted on cross-session read (count=$_MEMREAD_COUNT)"
fi

# Verify the emitted event has hashed slug, not raw slug
if grep -q "\"project_slug_hash\":\"[a-f0-9]" "$_TMPDIR/.nanopm/projects/$_SLUG/timeline.jsonl" 2>/dev/null; then
  ok "memory-read event uses hashed slug (privacy: NFR1)"
else
  fail "memory-read event missing project_slug_hash field"
fi

# Same-session read should NOT emit
_TMPDIR2=$(mktemp -d /tmp/nanopm-singlesess-XXXXXX)
mkdir -p "$_TMPDIR2/.nanopm/projects/test/" "$_TMPDIR2/.nanopm/bin"
ln -sf "$_REPO_ROOT/bin/nanopm-state-log" "$_TMPDIR2/.nanopm/bin/"
ln -sf "$_REPO_ROOT/bin/nanopm-state-read" "$_TMPDIR2/.nanopm/bin/"
_S_SINGLE=$(python3 -c "import uuid; print(uuid.uuid4().hex[:16])")
cd "$_TMPDIR2"
HOME="$_TMPDIR2" NANOPM_SESSION_ID="$_S_SINGLE" \
  "$_REPO_ROOT/bin/nanopm-state-log" --type decision \
  '{"kind":"bet","key":"same","insight":"x","confidence":5,"source":"observed"}' >/dev/null
HOME="$_TMPDIR2" NANOPM_SESSION_ID="$_S_SINGLE" nanopm_state_read --type decision >/dev/null
_SAMESESS_MEMREAD=$(find "$_TMPDIR2" -name "timeline.jsonl" -exec grep -c '"event":"memory-read"' {} \; 2>/dev/null | head -1)
_SAMESESS_MEMREAD=${_SAMESESS_MEMREAD:-0}
if [ "$_SAMESESS_MEMREAD" = "0" ]; then
  ok "same-session read does NOT emit memory-read"
else
  fail "same-session read incorrectly emitted memory-read ($_SAMESESS_MEMREAD events)"
fi
cd "$_TMPDIR"
rm -rf "$_TMPDIR2"

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
