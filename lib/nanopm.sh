#!/usr/bin/env bash
# nanopm runtime library v0.2.0
# Source this from every skill preamble:
#   source ~/.nanopm/lib/nanopm.sh
#
# Provides: config, context/memory, connectors, browser, gitignore check

# ── Host detection ───────────────────────────────────────────────────────────
# Detects which AI coding agent is running nanopm and exports NANOPM_HOST.
# Skills can use $NANOPM_HOST to branch on host-specific behavior.
# Currently informational — all skill bodies run as-is on every host.

if [ -n "${VIBE_VERSION:-}" ] || [ -n "${VIBE_SKILLS_DIR:-}" ]; then
  export NANOPM_HOST="vibe"
  export NANOPM_SKILLS_DIR="${VIBE_SKILLS_DIR:-$HOME/.vibe/skills}"
elif [ -n "${CODEX_VERSION:-}" ] || [ -n "${CODEX_SKILLS_DIR:-}" ]; then
  export NANOPM_HOST="codex"
  export NANOPM_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
else
  export NANOPM_HOST="claude"
  export NANOPM_SKILLS_DIR="$HOME/.claude/skills"
fi

# Resolve absolute path to a sibling skill's SKILL.md for the current host.
# Skills that orchestrate other skills inline must use this instead of
# hardcoding ~/.claude/skills/, otherwise the pipeline breaks on Vibe/Codex.
#
# Usage: source "$(nanopm_skill_path pm-audit)"  # or just read/follow it
nanopm_skill_path() {
  local skill="$1"
  echo "$NANOPM_SKILLS_DIR/$skill/SKILL.md"
}

# ── Config ──────────────────────────────────────────────────────────────────
# Key-value store in ~/.nanopm/config (one KEY=VALUE per line)

_NANOPM_CONFIG_FILE="$HOME/.nanopm/config"

nanopm_config_get() {
  local key="$1"
  [ -f "$_NANOPM_CONFIG_FILE" ] || return 0
  grep "^${key}=" "$_NANOPM_CONFIG_FILE" 2>/dev/null | tail -1 | cut -d= -f2-
}

nanopm_config_set() {
  local key="$1" value="$2"
  mkdir -p "$(dirname "$_NANOPM_CONFIG_FILE")"
  local tmp
  tmp=$(mktemp "${_NANOPM_CONFIG_FILE}.tmp.XXXXXX") || {
    echo "nanopm: error: could not write config (disk full?)" >&2; return 1
  }
  # Copy existing lines except the key being set
  grep -v "^${key}=" "$_NANOPM_CONFIG_FILE" 2>/dev/null > "$tmp" || true
  echo "${key}=${value}" >> "$tmp"
  mv "$tmp" "$_NANOPM_CONFIG_FILE" || {
    rm -f "$tmp"
    echo "nanopm: error: could not update config" >&2; return 1
  }
}

# ── Slug ─────────────────────────────────────────────────────────────────────
# Project identifier: git repo name, or current directory name

nanopm_slug() {
  basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
}

# ── Memory / Context ─────────────────────────────────────────────────────────
# Global append-only JSONL at ~/.nanopm/memory/{slug}.jsonl
# Per-project outputs live in .nanopm/ (gitignored)

_nanopm_memory_file() {
  echo "$HOME/.nanopm/memory/$(nanopm_slug).jsonl"
}

nanopm_context_append() {
  # Usage: nanopm_context_append '{"skill":"pm-audit","outputs":{...}}'
  local json="$1"
  local file
  file=$(_nanopm_memory_file)
  mkdir -p "$(dirname "$file")"
  local entry
  entry=$(printf '%s' "$json" | \
    python3 -c "
import sys, json, datetime
d = json.loads(sys.stdin.read())
d.setdefault('ts', datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'))
d.setdefault('slug', '$(nanopm_slug)')
print(json.dumps(d, separators=(',', ':')))
" 2>/dev/null) || entry="$json"
  echo "$entry" >> "$file" || {
    echo "nanopm: error: could not write memory (disk full?)" >&2; return 1
  }
}

nanopm_context_read() {
  # Usage: nanopm_context_read pm-audit
  # Returns: latest JSONL entry for that skill in this project
  local skill="$1"
  local file
  file=$(_nanopm_memory_file)
  [ -f "$file" ] || return 0
  grep '"skill":"'"$skill"'"' "$file" 2>/dev/null | tail -1
}

nanopm_context_all() {
  # Returns all entries for this project (full history)
  local file
  file=$(_nanopm_memory_file)
  [ -f "$file" ] && cat "$file" || true
}

# ── Typed state (v0.6.0+) ────────────────────────────────────────────────────
# Schema-validated JSONL under ~/.nanopm/projects/{slug}/{type}.jsonl
# Types: timeline | decision | prd | handoff
# Skills should prefer these over the legacy nanopm_context_append above.

nanopm_state_log() {
  # Usage: nanopm_state_log --type TYPE '{"...":"..."}'
  # Validates against the schema in bin/nanopm-state-log and appends on success.
  # Exits 0 on success, non-zero with stderr on validation failure.
  if [ -x "$HOME/.nanopm/bin/nanopm-state-log" ]; then
    "$HOME/.nanopm/bin/nanopm-state-log" "$@"
  else
    echo "nanopm: bin/nanopm-state-log not installed; run setup" >&2
    return 127
  fi
}

nanopm_state_read() {
  # Usage: nanopm_state_read --type TYPE [--filter KEY=VAL] [--latest] [--limit N]
  # Prints matching records as JSONL. Empty output = no matches.
  #
  # Side effect (v0.6.5+): when reading type=decision, this wrapper checks whether
  # any returned record was written in a DIFFERENT session than the current one.
  # If yes, it emits a `memory-read` event to timeline.jsonl. This instruments the
  # validation experiment's success metric (PRD: validation-experiment).
  if [ ! -x "$HOME/.nanopm/bin/nanopm-state-read" ]; then
    echo "nanopm: bin/nanopm-state-read not installed; run setup" >&2
    return 127
  fi

  local output
  output=$("$HOME/.nanopm/bin/nanopm-state-read" "$@")
  printf '%s' "$output"
  # Ensure trailing newline (preserves caller expectations)
  [ -n "$output" ] && [ "${output: -1}" != $'\n' ] && printf '\n'

  # Auto-emit memory-read for decision reads only.
  # Skip if no current session (called outside a skill invocation).
  local args="$*"
  case "$args" in
    *"--type decision"*)
      [ -z "${NANOPM_SESSION_ID:-}" ] && return 0
      [ -z "$output" ] && return 0
      _nanopm_maybe_emit_memory_read "$output"
      ;;
  esac
  return 0
}

# Internal: scan state-read output for records from a different session than the
# current one. If any found, emit a single memory-read timeline event with a
# hashed project slug (NFR1: raw slug never appears in the event).
# Output is passed via stdin to avoid heredoc quoting issues with embedded JSON.
_nanopm_maybe_emit_memory_read() {
  printf '%s' "$1" | NANOPM_CURRENT_SESSION="$NANOPM_SESSION_ID" python3 -c '
import hashlib, json, os, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

current = os.environ.get("NANOPM_CURRENT_SESSION", "")
if not current:
    sys.exit(0)

found_other = False
emitting_skill = None
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        r = json.loads(line)
    except Exception:
        continue
    sess = r.get("session")
    if sess and sess != current:
        found_other = True
        emitting_skill = r.get("skill") or emitting_skill

if not found_other:
    sys.exit(0)

try:
    root = subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL
    ).decode().strip()
    slug = os.path.basename(root) if root else os.path.basename(os.getcwd())
except Exception:
    slug = os.path.basename(os.getcwd())

slug_hash = hashlib.sha256(slug.encode()).hexdigest()[:16]
try:
    branch = subprocess.check_output(
        ["git", "branch", "--show-current"], stderr=subprocess.DEVNULL
    ).decode().strip() or "unknown"
except Exception:
    branch = "unknown"

emitting_skill = emitting_skill or "unknown"

home = os.environ.get("HOME") or os.path.expanduser("~")
out_file = Path(home) / ".nanopm" / "projects" / slug / "timeline.jsonl"
out_file.parent.mkdir(parents=True, exist_ok=True)
event = {
    "skill": emitting_skill,
    "event": "memory-read",
    "branch": branch,
    "project_slug_hash": slug_hash,
    "session": current,
    "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "slug": slug,
}
with open(out_file, "a", encoding="utf-8") as f:
    f.write(json.dumps(event, separators=(",", ":"), ensure_ascii=False) + "\n")
' 2>/dev/null
}

# Convenience: log a skill 'started' timeline event. Skills should call this
# from their preamble after nanopm_preamble. Best-effort — failure is silent.
#
# Usage in a skill: nanopm_skill_started pm-audit
nanopm_skill_started() {
  local skill="$1"
  [ -z "$skill" ] && return 0
  [ -x "$HOME/.nanopm/bin/nanopm-state-log" ] || return 0
  local branch
  branch=$(git branch --show-current 2>/dev/null || echo "unknown")
  "$HOME/.nanopm/bin/nanopm-state-log" --type timeline \
    "{\"skill\":\"$skill\",\"event\":\"started\",\"branch\":\"$branch\"}" \
    >/dev/null 2>&1 || true
}

# Convenience: log a skill 'completed' timeline event with duration.
# Pass the start timestamp captured at preamble time.
#
# Usage in a skill: nanopm_skill_completed pm-audit "$_SKILL_START" success
nanopm_skill_completed() {
  local skill="$1" start_ts="$2" outcome="${3:-success}"
  [ -z "$skill" ] && return 0
  [ -x "$HOME/.nanopm/bin/nanopm-state-log" ] || return 0
  local now duration branch
  now=$(date +%s)
  duration=$(( now - ${start_ts:-now} ))
  branch=$(git branch --show-current 2>/dev/null || echo "unknown")
  "$HOME/.nanopm/bin/nanopm-state-log" --type timeline \
    "{\"skill\":\"$skill\",\"event\":\"completed\",\"branch\":\"$branch\",\"outcome\":\"$outcome\",\"duration_s\":$duration}" \
    >/dev/null 2>&1 || true
}

nanopm_context_summary() {
  # Returns one-line summary per skill: skill → last run ts + key output
  local file
  file=$(_nanopm_memory_file)
  [ -f "$file" ] || { echo "(no context yet)"; return 0; }
  python3 - "$file" << 'EOF'
import sys, json
seen = {}
with open(sys.argv[1]) as f:
    for line in f:
        try:
            d = json.loads(line)
            seen[d.get('skill','?')] = d
        except Exception:
            pass
for skill, d in seen.items():
    ts = d.get('ts','?')
    outputs = d.get('outputs', {})
    summary = next(iter(outputs.values()), '') if outputs else ''
    if isinstance(summary, str) and len(summary) > 80:
        summary = summary[:77] + '...'
    print(f"  {skill} ({ts}): {summary}")
EOF
}

# ── Gitignore check ──────────────────────────────────────────────────────────

nanopm_check_gitignore() {
  # Warn once if .nanopm/ is not gitignored in the current project
  if [ -d ".git" ]; then
    if ! grep -q '\.nanopm' .gitignore 2>/dev/null && \
       ! git check-ignore -q .nanopm 2>/dev/null; then
      echo ""
      echo "⚠  nanopm: .nanopm/ is not in .gitignore"
      echo "   Your product strategy (AUDIT.md, STRATEGY.md, etc.) may be committed."
      echo "   Fix: echo '.nanopm/' >> .gitignore"
      echo ""
    fi
  fi
}

# ── Browser ─────────────────────────────────────────────────────────────────

nanopm_find_browse() {
  # Sets global B to a headless browser binary, or empty if not found.
  # Checks nanopm-native locations first; falls back to gstack if present.
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null)
  B=""

  # 1. nanopm's own browse binary (global install)
  [ -z "$B" ] && [ -x "$HOME/.nanopm/browse/dist/browse" ] && \
    B="$HOME/.nanopm/browse/dist/browse"

  # 2. nanopm's own browse binary (project-local install)
  [ -z "$B" ] && [ -n "$root" ] && \
    [ -x "$root/.nanopm/browse/dist/browse" ] && \
    B="$root/.nanopm/browse/dist/browse"

  # 3. User-installed binary at ~/.nanopm/bin/browse
  [ -z "$B" ] && [ -x "$HOME/.nanopm/bin/browse" ] && \
    B="$HOME/.nanopm/bin/browse"

  # 4. gstack browse binary (silent convenience — not required, not advertised)
  [ -z "$B" ] && [ -x "$HOME/.claude/skills/gstack/browse/dist/browse" ] && \
    B="$HOME/.claude/skills/gstack/browse/dist/browse"
  [ -z "$B" ] && [ -n "$root" ] && \
    [ -x "$root/.claude/skills/gstack/browse/dist/browse" ] && \
    B="$root/.claude/skills/gstack/browse/dist/browse"

  [ -n "$B" ] && echo "BROWSE_READY: $B" || echo "BROWSE_NOT_AVAILABLE"
}

nanopm_browse_website() {
  # Usage: nanopm_browse_website <url>
  # Returns: plain text ARIA snapshot of the page
  local url="$1"
  [ -z "$B" ] && { echo "BROWSE_NOT_AVAILABLE"; return 1; }
  "$B" goto "$url" 2>/dev/null || { echo "BROWSE_FAILED: could not load $url"; return 1; }
  "$B" snapshot 2>/dev/null
}

# ── Connector tier resolution ─────────────────────────────────────────────────
#
# Each tool (linear, notion, dovetail, github) is fetched via the highest
# available tier:
#   Tier 1: MCP tool call  (mcp__<tool>__ functions available in Claude)
#   Tier 2: Direct API     (API key in environment)
#   Tier 3: Browser scrape (browse binary + stored URL)
#   Tier 4: Manual         (CONTEXT.md — caller handles prompting)
#
# nanopm_has_connector TOOL  →  prints tier (1/2/3/4) or "none"
# nanopm_fetch_connector is implemented inside each SKILL.md using Claude's
# native tool-calling — the SKILL.md prompt instructs Claude to call MCP tools
# or use $B based on the tier detected here.

nanopm_has_connector() {
  local tool="$1"
  local claude_md=""
  [ -f "CLAUDE.md" ]       && claude_md="CLAUDE.md"
  [ -f ".claude/CLAUDE.md" ] && claude_md=".claude/CLAUDE.md"

  # Tier 1: MCP
  if [ -n "$claude_md" ] && grep -q "mcp__${tool}__" "$claude_md" 2>/dev/null; then
    echo "1"; return
  fi

  # Tier 2: API key (use eval for safe indirect expansion under set -u)
  # GitHub uses GITHUB_TOKEN; others use {TOOL}_API_KEY
  local key_var api_val
  case "$tool" in
    github) key_var="GITHUB_TOKEN" ;;
    *)      key_var=$(echo "${tool}_api_key" | tr '[:lower:]' '[:upper:]') ;;
  esac
  api_val=$(eval echo "\${${key_var}:-}")
  if [ -n "$api_val" ]; then
    echo "2"; return
  fi

  # Tier 3: Browser + stored URL
  if [ -n "${B:-}" ]; then
    local url_key="${tool}_url"
    local stored_url
    stored_url=$(nanopm_config_get "$url_key")
    if [ -n "$stored_url" ]; then
      echo "3"; return
    fi
    # Browser available but no URL stored yet — discovery needed
    echo "3-discover"; return
  fi

  # Tier 4: manual
  echo "4"
}

nanopm_connector_url_key() {
  # Returns the config key used to store the discovered URL for a tool
  echo "${1}_url"
}

# ── Website bootstrap ─────────────────────────────────────────────────────────
#
# Used by /pm-audit intake. Browses company website to pre-fill context.

nanopm_website_extract() {
  # Usage: nanopm_website_extract <url>
  # Browses the URL and returns a snapshot for Claude to parse.
  # Claude extracts: product tagline (Q1), target user (Q2), key features (Q3).
  local url="$1"
  [ -z "$url" ] && return 1
  [ -z "$B"   ] && { echo "BROWSE_NOT_AVAILABLE"; return 1; }

  # Store URL for future use
  nanopm_config_set "company_website" "$url"

  echo "Browsing $url for context..."
  local snapshot
  snapshot=$(nanopm_browse_website "$url") || {
    echo "BROWSE_FAILED"
    return 1
  }
  echo "$snapshot"
}

# ── Staleness check ──────────────────────────────────────────────────────────
#
# Warns if AUDIT.md or STRATEGY.md hasn't been regenerated in N commits.
# Called from nanopm_preamble so every skill run surfaces the signal.

nanopm_staleness_check() {
  [ -d ".git" ] || return 0
  local threshold=20
  for doc in AUDIT STRATEGY; do
    local file=".nanopm/${doc}.md"
    [ -f "$file" ] || continue
    local last_commit
    last_commit=$(git log --oneline -1 -- "$file" 2>/dev/null | awk '{print $1}')
    [ -z "$last_commit" ] && continue
    local count
    count=$(git rev-list --count "${last_commit}..HEAD" 2>/dev/null || echo 0)
    if [ "$count" -gt "$threshold" ]; then
      local skill
      skill=$(echo "$doc" | tr '[:upper:]' '[:lower:]')
      echo ""
      echo "⚠  nanopm: ${doc}.md is ${count} commits old — consider re-running /pm-${skill}"
      echo ""
    fi
  done
}

# ── Update check ─────────────────────────────────────────────────────────────
#
# Checks GitHub for a newer version of nanopm. Cached for 24h to avoid
# hitting the network on every skill invocation.
#
# Outputs (to stdout, for the skill preamble to capture):
#   UPGRADE_AVAILABLE {local_ver} {remote_ver}  — if a newer version exists
#   (nothing)                                   — if up to date or network unavailable
#
# Snooze state: ~/.nanopm/update-snoozed  format: "{version} {level} {timestamp}"
#   Level 1 → 24h backoff, level 2 → 48h, level 3+ → 1 week

# Compare two semver strings. Returns 0 (true) if $1 is strictly greater than $2.
# Handles versions like "0.6.1", "1.42.2", "0.10.0". Non-numeric components
# (e.g. pre-release suffixes) compare as 0.
nanopm_semver_gt() {
  local a="$1" b="$2"
  [ -z "$a" ] && return 1
  [ -z "$b" ] && return 0
  python3 - "$a" "$b" <<'PYEOF' 2>/dev/null
import sys
def parts(v):
    out = []
    for p in v.split("."):
        try:
            out.append(int(p))
        except ValueError:
            # Strip any non-digit tail (e.g. "1-rc1" → 1)
            num = ""
            for ch in p:
                if ch.isdigit():
                    num += ch
                else:
                    break
            out.append(int(num) if num else 0)
    return out
pa, pb = parts(sys.argv[1]), parts(sys.argv[2])
maxlen = max(len(pa), len(pb))
pa += [0] * (maxlen - len(pa))
pb += [0] * (maxlen - len(pb))
sys.exit(0 if pa > pb else 1)
PYEOF
}

nanopm_update_check() {
  # Outputs (to stdout, for skill preambles to capture):
  #   UPGRADE_AVAILABLE {local_ver} {remote_ver}   when remote > local AND not snoozed
  #   (nothing)                                    otherwise
  #
  # Order matters: we resolve remote first, then compare, then check snooze
  # against the resolved remote version. Earlier versions of this function
  # compared snooze against local, which silenced upgrades incorrectly.

  # 1. Respect disable flag
  local _disabled
  _disabled=$(nanopm_config_get "update_check_disabled" 2>/dev/null || true)
  [ "$_disabled" = "1" ] && return 0

  local _now
  _now=$(date +%s)
  local _local_ver
  _local_ver=$(cat "$HOME/.nanopm/VERSION" 2>/dev/null || echo "0.0.0")

  # 2. Resolve remote version: cache if fresh (<24h), else fetch
  local _cache="$HOME/.nanopm/last-update-check"
  local _remote_ver=""

  if [ -f "$_cache" ]; then
    local _cts _crv
    _cts=$(awk '{print $1}' "$_cache" 2>/dev/null || echo "0")
    _crv=$(awk '{print $2}' "$_cache" 2>/dev/null || echo "")
    case "$_cts" in *[!0-9]*) _cts=0 ;; esac
    if [ $(( _now - _cts )) -lt 86400 ] && [ -n "$_crv" ]; then
      _remote_ver="$_crv"
    fi
  fi

  if [ -z "$_remote_ver" ]; then
    _remote_ver=$(curl -fsSL --max-time 3 \
      "https://raw.githubusercontent.com/nmrtn/nanopm/main/VERSION" 2>/dev/null \
      | tr -d '[:space:]' || echo "")
    [ -z "$_remote_ver" ] && return 0
    mkdir -p "$HOME/.nanopm"
    echo "$_now $_remote_ver" > "$_cache"
  fi

  # 3. No upgrade if remote is not strictly newer (semver, not string compare)
  if ! nanopm_semver_gt "$_remote_ver" "$_local_ver"; then
    return 0
  fi

  # 4. Snooze: suppress notification if the user previously dismissed THIS
  #    remote version and we're within the backoff window.
  local _snooze="$HOME/.nanopm/update-snoozed"
  if [ -f "$_snooze" ]; then
    local _sv _sl _st
    _sv=$(awk '{print $1}' "$_snooze" 2>/dev/null || echo "")
    _sl=$(awk '{print $2}' "$_snooze" 2>/dev/null || echo "0")
    _st=$(awk '{print $3}' "$_snooze" 2>/dev/null || echo "0")
    case "$_sl" in *[!0-9]*) _sl=0 ;; esac
    case "$_st" in *[!0-9]*) _st=0 ;; esac
    local _backoff=86400
    case "$_sl" in 2) _backoff=172800 ;; 3) _backoff=604800 ;; esac
    if [ "$_sv" = "$_remote_ver" ] && [ $(( _now - _st )) -lt $_backoff ]; then
      return 0  # snoozed this specific version, still in backoff
    fi
  fi

  echo "UPGRADE_AVAILABLE $_local_ver $_remote_ver"
  return 0
}

# ── Standard preamble helper ─────────────────────────────────────────────────
#
# Call nanopm_preamble from every skill's bash preamble block.
# Sets: _SLUG, _BRANCH, _VERSION, B (browse binary)
# Also runs update check — if output contains UPGRADE_AVAILABLE, tell the user
# "nanopm v{new} is available. Run /pm-upgrade to update." before proceeding.

nanopm_preamble() {
  _SLUG=$(nanopm_slug)
  _BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  _VERSION=$(cat ~/.nanopm/VERSION 2>/dev/null || \
             cat "$(dirname "$0")/../VERSION" 2>/dev/null || echo "unknown")
  mkdir -p ~/.nanopm/memory
  mkdir -p ~/.nanopm/projects/"$_SLUG"
  mkdir -p .nanopm
  nanopm_find_browse > /dev/null  # sets $B
  nanopm_check_gitignore
  nanopm_staleness_check
  nanopm_update_check             # prints UPGRADE_AVAILABLE if a new version exists

  # Fresh session id per skill invocation (v0.6.5+).
  # Written to .current_session so every bash subprocess within this invocation
  # — including Vibe's fresh-subshell-per-block model — reads the same UUID.
  # State-log calls auto-inject this id into every record.
  NANOPM_SESSION_ID=$(python3 -c "import uuid; print(uuid.uuid4().hex[:16])" 2>/dev/null || echo "")
  export NANOPM_SESSION_ID
  if [ -n "$NANOPM_SESSION_ID" ]; then
    echo "$NANOPM_SESSION_ID" > "$HOME/.nanopm/projects/$_SLUG/.current_session" 2>/dev/null || true
  fi

  echo "SLUG: $_SLUG"
  echo "BRANCH: $_BRANCH"
  echo "VERSION: $_VERSION"
  echo "HOST: $NANOPM_HOST"
  echo "SESSION: ${NANOPM_SESSION_ID:-unavailable}"
  echo "BROWSE: ${B:-not available}"
  # Multi-host portability hint — Mistral Vibe rejects AskUserQuestion calls
  # with header field >12 chars. Claude tolerates longer but renders better short.
  # Use a short noun-phrase header per call.
  echo "PORTABILITY: AskUserQuestion 'header' MUST be a short noun phrase ≤12 chars"
  # Voice directive — all nanopm skills follow this register
  # Load ethos (shapes advisor voice across all skills)
  # Installed at ~/.nanopm/ETHOS.md by setup
  if [ -f "$HOME/.nanopm/ETHOS.md" ]; then
    echo "ETHOS_LOADED: ~/.nanopm/ETHOS.md"
    cat "$HOME/.nanopm/ETHOS.md"
  else
    echo "VOICE: Direct, adversarial PM advisor. No hedging, no corporate speak. Name the real problem, not the comfortable one. Call out gaps specifically. If the answer is obvious from context, skip the question. Short sentences."
  fi
}
