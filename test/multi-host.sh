#!/usr/bin/env bash
# nanopm v0.6.0+ — multi-host path resolution tests
#
# Verifies:
#   - Host detection sets NANOPM_HOST + NANOPM_SKILLS_DIR correctly per agent
#   - nanopm_skill_path resolves to the right host's skills dir
#   - VIBE_SKILLS_DIR and CODEX_SKILLS_DIR overrides are honored
#   - pm-run no longer hardcodes ~/.claude/skills/ paths
#
# No LLM. Pure shell function test.
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_TMPDIR=$(mktemp -d /tmp/nanopm-multihost-XXXXXX)

cleanup() { rm -rf "$_TMPDIR"; }
trap cleanup EXIT

_PASS=0
_FAIL=0
ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm tests: multi-host paths"
echo "  ================================"
echo

# ── 1. Default (Claude) ───────────────────────────────────────────────────────
echo "  Default host detection (no Vibe/Codex env vars)"
# Need a subshell to avoid polluting environment between tests
_OUT=$(env -i HOME="$_TMPDIR" PATH="$PATH" bash -c "
  source '$_REPO_ROOT/lib/nanopm.sh'
  echo \"HOST=\$NANOPM_HOST\"
  echo \"DIR=\$NANOPM_SKILLS_DIR\"
  echo \"PATH=\$(nanopm_skill_path pm-audit)\"
")

if echo "$_OUT" | grep -q "HOST=claude"; then
  ok "Default → NANOPM_HOST=claude"
else
  fail "Default host wrong. Got: $_OUT"
fi
if echo "$_OUT" | grep -q "DIR=$_TMPDIR/.claude/skills"; then
  ok "Default → NANOPM_SKILLS_DIR=\$HOME/.claude/skills"
else
  fail "Default skills dir wrong. Got: $_OUT"
fi
if echo "$_OUT" | grep -q "PATH=$_TMPDIR/.claude/skills/pm-audit/SKILL.md"; then
  ok "Default → nanopm_skill_path pm-audit resolves to ~/.claude/skills/"
else
  fail "skill_path wrong on Claude. Got: $_OUT"
fi

# ── 2. Vibe via VIBE_VERSION ──────────────────────────────────────────────────
echo
echo "  Vibe host detection (VIBE_VERSION set)"
_OUT=$(env -i HOME="$_TMPDIR" PATH="$PATH" VIBE_VERSION="1.0.0" bash -c "
  source '$_REPO_ROOT/lib/nanopm.sh'
  echo \"HOST=\$NANOPM_HOST\"
  echo \"DIR=\$NANOPM_SKILLS_DIR\"
  echo \"PATH=\$(nanopm_skill_path pm-strategy)\"
")

if echo "$_OUT" | grep -q "HOST=vibe"; then
  ok "VIBE_VERSION → NANOPM_HOST=vibe"
else
  fail "Vibe host wrong. Got: $_OUT"
fi
if echo "$_OUT" | grep -q "DIR=$_TMPDIR/.vibe/skills"; then
  ok "Vibe → NANOPM_SKILLS_DIR=\$HOME/.vibe/skills"
else
  fail "Vibe skills dir wrong. Got: $_OUT"
fi
if echo "$_OUT" | grep -q "PATH=$_TMPDIR/.vibe/skills/pm-strategy/SKILL.md"; then
  ok "Vibe → skill_path resolves to ~/.vibe/skills/"
else
  fail "Vibe skill_path wrong. Got: $_OUT"
fi

# ── 3. Codex via CODEX_VERSION ────────────────────────────────────────────────
echo
echo "  Codex host detection (CODEX_VERSION set)"
_OUT=$(env -i HOME="$_TMPDIR" PATH="$PATH" CODEX_VERSION="2.0.0" bash -c "
  source '$_REPO_ROOT/lib/nanopm.sh'
  echo \"HOST=\$NANOPM_HOST\"
  echo \"DIR=\$NANOPM_SKILLS_DIR\"
  echo \"PATH=\$(nanopm_skill_path pm-roadmap)\"
")

if echo "$_OUT" | grep -q "HOST=codex"; then
  ok "CODEX_VERSION → NANOPM_HOST=codex"
else
  fail "Codex host wrong. Got: $_OUT"
fi
if echo "$_OUT" | grep -q "DIR=$_TMPDIR/.codex/skills"; then
  ok "Codex → NANOPM_SKILLS_DIR=\$HOME/.codex/skills"
else
  fail "Codex skills dir wrong. Got: $_OUT"
fi
if echo "$_OUT" | grep -q "PATH=$_TMPDIR/.codex/skills/pm-roadmap/SKILL.md"; then
  ok "Codex → skill_path resolves to ~/.codex/skills/"
else
  fail "Codex skill_path wrong. Got: $_OUT"
fi

# ── 4. VIBE_SKILLS_DIR override ───────────────────────────────────────────────
echo
echo "  Custom dir override (VIBE_SKILLS_DIR)"
_OUT=$(env -i HOME="$_TMPDIR" PATH="$PATH" VIBE_VERSION="1.0.0" VIBE_SKILLS_DIR="/custom/vibe/path" bash -c "
  source '$_REPO_ROOT/lib/nanopm.sh'
  echo \"DIR=\$NANOPM_SKILLS_DIR\"
  echo \"PATH=\$(nanopm_skill_path pm-prd)\"
")

if echo "$_OUT" | grep -q "DIR=/custom/vibe/path"; then
  ok "VIBE_SKILLS_DIR override honored"
else
  fail "Override not honored. Got: $_OUT"
fi
if echo "$_OUT" | grep -q "PATH=/custom/vibe/path/pm-prd/SKILL.md"; then
  ok "skill_path uses overridden dir"
else
  fail "skill_path didn't use override. Got: $_OUT"
fi

# ── 5. pm-run no longer hardcodes ~/.claude/skills/ ───────────────────────────
echo
echo "  pm-run uses nanopm_skill_path (no hardcoded ~/.claude/skills/)"
_HARDCODED=$(grep -c '~/\.claude/skills/' "$_REPO_ROOT/pm-run/SKILL.md" || true)
if [ "$_HARDCODED" = "0" ]; then
  ok "pm-run has 0 hardcoded ~/.claude/skills/ references"
else
  fail "pm-run still has $_HARDCODED hardcoded ~/.claude/skills/ references"
fi

_NSP_REFS=$(grep -c 'nanopm_skill_path' "$_REPO_ROOT/pm-run/SKILL.md" || true)
if [ "$_NSP_REFS" -ge 6 ]; then
  ok "pm-run uses nanopm_skill_path ($_NSP_REFS references)"
else
  fail "pm-run only has $_NSP_REFS nanopm_skill_path refs (expected ≥6 for the orchestrated skills)"
fi

# ── 6. nanopm_skill_path is a function in lib ─────────────────────────────────
echo
echo "  nanopm_skill_path is defined in lib/nanopm.sh"
if grep -q '^nanopm_skill_path()' "$_REPO_ROOT/lib/nanopm.sh"; then
  ok "nanopm_skill_path() defined"
else
  fail "nanopm_skill_path() not defined in lib"
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
  echo "  RESULT: PASSED — multi-host paths OK"
  exit 0
fi
