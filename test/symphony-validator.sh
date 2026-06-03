#!/usr/bin/env bash
# nanopm v0.7.1+ — Symphony WORKFLOW.md validator behavioral test
#
# Verifies that bin/nanopm-symphony-validate correctly accepts spec-compliant
# WORKFLOW.md files and rejects non-compliant ones.
#
# Positive cases (must exit 0):
#   - Minimal valid WORKFLOW.md with all required fields
#   - WORKFLOW.md that nanopm /pm-breakdown --target=symphony would produce
#
# Negative cases (must exit non-zero):
#   - Missing tracker.kind
#   - Missing tracker.api_key
#   - Missing tracker.project_slug when kind=linear
#   - Frontmatter that's not a YAML map
#   - File without --- delimiter
set -uo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_TMPDIR=$(mktemp -d /tmp/nanopm-symphony-XXXXXX)
trap 'rm -rf "$_TMPDIR"' EXIT

_PASS=0
_FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

_VALIDATOR="$_REPO_ROOT/bin/nanopm-symphony-validate"

echo
echo "  nanopm tests: Symphony WORKFLOW.md validator"
echo "  =============================================="
echo

if [ ! -x "$_VALIDATOR" ]; then
  fail "validator binary not executable: $_VALIDATOR"
  exit 1
fi
ok "validator binary exists and is executable"

# ── Positive case 1: minimal valid WORKFLOW.md ────────────────────────────────
echo
echo "  Positive cases (must pass)"

cat > "$_TMPDIR/minimal-valid.md" <<'EOF'
---
tracker:
  kind: linear
  api_key: $LINEAR_API_KEY
  project_slug: test-project
---

# Workflow

Process issue {{ issue.identifier }}: {{ issue.title }}

{% if attempt %}This is retry attempt {{ attempt }}.{% endif %}
EOF

if "$_VALIDATOR" "$_TMPDIR/minimal-valid.md" >/dev/null 2>&1; then
  ok "minimal valid WORKFLOW.md accepted (only required fields)"
else
  fail "minimal valid WORKFLOW.md rejected (should pass)"
fi

# ── Positive case 2: full WORKFLOW.md mirroring nanopm's pm-breakdown output ─

cat > "$_TMPDIR/full-valid.md" <<'EOF'
---
tracker:
  kind: linear
  api_key: $LINEAR_API_KEY
  project_slug: production-board
  active_states:
    - Todo
    - In Progress
  terminal_states:
    - Done
    - Cancelled
    - Canceled

polling:
  interval_ms: 30000

workspace:
  root: ~/.symphony/workspaces

agent:
  max_concurrent_agents: 3
  max_turns: 20

codex:
  command: codex app-server
  turn_timeout_ms: 3600000
  read_timeout_ms: 5000
  stall_timeout_ms: 300000
---

# Workflow: Test Feature

Issue {{ issue.identifier }}: {{ issue.title }}
Attempt: {% if attempt %}{{ attempt }}{% else %}1{% endif %}

Read the PRD and implement.
EOF

if "$_VALIDATOR" "$_TMPDIR/full-valid.md" >/dev/null 2>&1; then
  ok "full WORKFLOW.md accepted (all sections, mirrors nanopm output)"
else
  fail "full WORKFLOW.md rejected (should pass)"
fi

# ── Negative case 1: missing tracker.kind ─────────────────────────────────────
echo
echo "  Negative cases (must reject with non-zero exit)"

cat > "$_TMPDIR/no-tracker-kind.md" <<'EOF'
---
tracker:
  api_key: $LINEAR_API_KEY
  project_slug: x
---

# Workflow

{{ issue.title }}
EOF

_EXIT=0
"$_VALIDATOR" "$_TMPDIR/no-tracker-kind.md" >/dev/null 2>&1 || _EXIT=$?
if [ "$_EXIT" -ne 0 ]; then
  ok "missing tracker.kind rejected (exit=$_EXIT)"
else
  fail "missing tracker.kind incorrectly accepted"
fi

# ── Negative case 2: missing tracker.api_key ──────────────────────────────────

cat > "$_TMPDIR/no-api-key.md" <<'EOF'
---
tracker:
  kind: linear
  project_slug: x
---

# Workflow

{{ issue.title }}
EOF

_EXIT=0
"$_VALIDATOR" "$_TMPDIR/no-api-key.md" >/dev/null 2>&1 || _EXIT=$?
if [ "$_EXIT" -ne 0 ]; then
  ok "missing tracker.api_key rejected (exit=$_EXIT)"
else
  fail "missing tracker.api_key incorrectly accepted"
fi

# ── Negative case 3: missing project_slug when kind=linear ───────────────────

cat > "$_TMPDIR/no-project-slug.md" <<'EOF'
---
tracker:
  kind: linear
  api_key: $LINEAR_API_KEY
---

# Workflow

{{ issue.title }}
EOF

_EXIT=0
"$_VALIDATOR" "$_TMPDIR/no-project-slug.md" >/dev/null 2>&1 || _EXIT=$?
if [ "$_EXIT" -ne 0 ]; then
  ok "missing tracker.project_slug rejected when kind=linear (exit=$_EXIT)"
else
  fail "missing tracker.project_slug incorrectly accepted"
fi

# ── Negative case 4: no frontmatter delimiter ────────────────────────────────

cat > "$_TMPDIR/no-frontmatter.md" <<'EOF'
# Workflow

No frontmatter at all. Should reject.
EOF

_EXIT=0
"$_VALIDATOR" "$_TMPDIR/no-frontmatter.md" >/dev/null 2>&1 || _EXIT=$?
if [ "$_EXIT" -ne 0 ]; then
  ok "missing frontmatter delimiter rejected (exit=$_EXIT)"
else
  fail "missing frontmatter incorrectly accepted"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo
echo "  ─────────────────────────────"
printf '  Passed: %d  Failed: %d\n' "$_PASS" "$_FAIL"
echo

if [ "$_FAIL" -gt 0 ]; then
  echo "  RESULT: FAILED"
  exit 1
else
  echo "  RESULT: PASSED — Symphony validator accepts compliant, rejects non-compliant"
  exit 0
fi
