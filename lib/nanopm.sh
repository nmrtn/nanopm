#!/usr/bin/env bash
# nanopm runtime library v0.1.0
# Source this from every skill preamble:
#   source ~/.claude/skills/nanopm/lib/nanopm.sh
#
# Provides: config, context/memory, connectors, browser, gitignore check

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
  [ -z "$B" ] && [ -x "$HOME/.claude/skills/nanopm/browse/dist/browse" ] && \
    B="$HOME/.claude/skills/nanopm/browse/dist/browse"

  # 2. nanopm's own browse binary (project-local install)
  [ -z "$B" ] && [ -n "$root" ] && \
    [ -x "$root/.claude/skills/nanopm/browse/dist/browse" ] && \
    B="$root/.claude/skills/nanopm/browse/dist/browse"

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

# ── Standard preamble helper ─────────────────────────────────────────────────
#
# Call nanopm_preamble from every skill's bash preamble block.
# Sets: _SLUG, _BRANCH, _VERSION, B (browse binary)

nanopm_preamble() {
  _SLUG=$(nanopm_slug)
  _BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  _VERSION=$(cat ~/.claude/skills/nanopm/VERSION 2>/dev/null || \
             cat "$(dirname "$0")/../VERSION" 2>/dev/null || echo "unknown")
  mkdir -p ~/.nanopm/memory
  mkdir -p .nanopm
  nanopm_find_browse > /dev/null  # sets $B
  nanopm_check_gitignore
  nanopm_staleness_check
  echo "SLUG: $_SLUG"
  echo "BRANCH: $_BRANCH"
  echo "VERSION: $_VERSION"
  echo "BROWSE: ${B:-not available}"
  # Voice directive — all nanopm skills follow this register
  echo "VOICE: Direct, adversarial PM advisor. No hedging, no corporate speak. Name the real problem, not the comfortable one. Call out gaps specifically. If the answer is obvious from context, skip the question. Short sentences."
}
