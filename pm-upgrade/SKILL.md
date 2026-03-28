---
name: pm-upgrade
version: 0.2.0
description: "Upgrade nanopm to the latest version. Detects install type, runs the upgrade, shows what's new. Also handles inline upgrade prompts when UPGRADE_AVAILABLE appears in any skill preamble."
allowed-tools: Bash, Read, AskUserQuestion
---

## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
```

## Inline upgrade flow

This section is followed by all skill preambles when they detect `UPGRADE_AVAILABLE {old} {new}` in the preamble output.

### Step 1: Ask or auto-upgrade

Check if auto-upgrade is configured:

```bash
_AUTO=$(nanopm_config_get "auto_upgrade")
echo "AUTO_UPGRADE=${_AUTO:-false}"
```

**If `AUTO_UPGRADE=true`:** skip AskUserQuestion. Log "Auto-upgrading nanopm v{old} → v{new}..." and proceed to Step 2.

**Otherwise**, ask via AskUserQuestion:
- Question: "nanopm **v{new}** is available (you have v{old}). Upgrade now?"
- Options:
  - "Yes, upgrade now"
  - "Always keep me up to date (auto-upgrade)"
  - "Not now (remind me later)"
  - "Never ask again"

**If "Yes, upgrade now":** proceed to Step 2.

**If "Always keep me up to date":**
```bash
nanopm_config_set "auto_upgrade" "true"
```
Tell user: "Auto-upgrade enabled — future updates will install automatically." Then proceed to Step 2.

**If "Not now":** write snooze state with escalating backoff. Then continue with the originally invoked skill without upgrading.
```bash
_SNOOZE="$HOME/.nanopm/update-snoozed"
_REMOTE_VER="{new}"
_CUR_LEVEL=0
if [ -f "$_SNOOZE" ]; then
  _SV=$(awk '{print $1}' "$_SNOOZE")
  if [ "$_SV" = "$_REMOTE_VER" ]; then
    _CUR_LEVEL=$(awk '{print $2}' "$_SNOOZE")
    case "$_CUR_LEVEL" in *[!0-9]*) _CUR_LEVEL=0 ;; esac
  fi
fi
_NEW_LEVEL=$(( _CUR_LEVEL + 1 ))
[ "$_NEW_LEVEL" -gt 3 ] && _NEW_LEVEL=3
echo "$_REMOTE_VER $_NEW_LEVEL $(date +%s)" > "$_SNOOZE"
```
Tell user the snooze duration: level 1 → "next reminder in 24h"; level 2 → "48h"; level 3 → "1 week".

**If "Never ask again":**
```bash
nanopm_config_set "update_check_disabled" "1"
rm -f "$HOME/.nanopm/update-snoozed"
```
Tell user: "Update checks disabled. Re-enable with: `nanopm_config_set update_check_disabled 0` in your shell."

### Step 2: Detect install type

```bash
_LOCAL_REPO=""
# Check if we're inside the nanopm source repo
if [ -f "$(git rev-parse --show-toplevel 2>/dev/null)/pm-upgrade/SKILL.md" ] 2>/dev/null; then
  _LOCAL_REPO=$(git rev-parse --show-toplevel)
fi
# Check common clone locations
[ -z "$_LOCAL_REPO" ] && [ -f "$HOME/Code/nanopm/pm-upgrade/SKILL.md" ] && \
  _LOCAL_REPO="$HOME/Code/nanopm"
echo "LOCAL_REPO=${_LOCAL_REPO:-none}"
```

### Step 3: Save current version

```bash
_OLD_VER=$(cat ~/.nanopm/VERSION 2>/dev/null || echo "unknown")
echo "OLD_VERSION=$_OLD_VER"
```

### Step 4: Run upgrade

**If `LOCAL_REPO` is set (git install):**
```bash
cd "$_LOCAL_REPO"
git pull origin main
bash setup
```

**If `LOCAL_REPO` is not set (curl / vendored install):**
```bash
curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash
```

If the upgrade fails, tell the user: "Upgrade failed. Your current version (v{old}) is still active. Check your network connection or run the setup script manually."

### Step 5: Clear update cache

```bash
rm -f ~/.nanopm/last-update-check
rm -f ~/.nanopm/update-snoozed
```

### Step 6: Show what's new

Read `~/.claude/skills/pm-upgrade/../CHANGELOG.md` if it exists (installed alongside the skills), or fetch from GitHub:

```bash
_CHANGELOG=$(curl -fsSL --max-time 5 \
  "https://raw.githubusercontent.com/nmrtn/nanopm/main/CHANGELOG.md" 2>/dev/null || echo "")
echo "$_CHANGELOG"
```

Find the section for the new version in the changelog. Summarize as 4-6 bullets grouped by theme (new skills, improvements, fixes). Don't list every line — focus on user-facing changes.

Format:
```
nanopm v{new} — upgraded from v{old}!

What's new:
- [bullet 1]
- [bullet 2]
...
```

### Step 7: Continue

After showing what's new, continue with the originally invoked skill (if this was an inline upgrade triggered by UPGRADE_AVAILABLE). If invoked standalone as `/pm-upgrade`, done.

---

## Standalone usage

When invoked directly as `/pm-upgrade`:

1. Force a fresh update check:
```bash
source ~/.nanopm/lib/nanopm.sh
_CHECK=$(nanopm_update_check)
echo "CHECK: $_CHECK"
```

2. **If `UPGRADE_AVAILABLE {old} {new}` in output:** follow Steps 1-6 above.

3. **If no UPGRADE_AVAILABLE output:** tell the user "You're already on the latest version (v{current})."

**STATUS: DONE**
