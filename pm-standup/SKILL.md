---
name: pm-standup
version: 0.3.0
description: "Daily standup briefing. Pulls commits from all your active GitHub repos, Linear, Google Calendar, and Granola. Works from a standalone Product OS folder — no need to be inside a codebase. Surfaces today's meetings, cross-repo activity, priorities, and drift."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, mcp__claude_ai_Google_Calendar__gcal_list_events, mcp__claude_ai_Google_Calendar__gcal_list_calendars, mcp__claude_ai_Granola__list_meetings, mcp__claude_ai_Granola__query_granola_meetings
---

## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
nanopm_telemetry_pending "pm-standup"
_STANDUP_FILE=".nanopm/STANDUP.md"
```

## When to run this

Run `/pm-standup` at the start of your workday to:
- Know what you shipped or moved yesterday
- See today's meetings at a glance
- Set your top 1-3 priorities for today
- Surface any blockers before they cost you time
- Stay aligned with the roadmap without opening 4 tools

This skill never asks questions. It reads context, generates the briefing, done.

## Phase 1: Gather yesterday's activity

**GitHub — multi-repo commits (last 24h):**

```bash
_TIER_GITHUB=$(nanopm_has_connector github)
echo "GITHUB_TIER: $_TIER_GITHUB"
```

If GITHUB tier is MCP or API:
- Fetch all commits by the authenticated user across all repos in the last 24h
- Use GitHub API: `GET /search/commits?q=author:{username}+committer-date:>{yesterday_iso}&sort=committer-date`
- For each commit extract: repo name, commit message, timestamp
- Group by repo — show repo name as prefix: `[repo-name] commit message`
- Limit to 15 commits total, most recent first

If GITHUB not available: fall back to local git:
```bash
git log --since="24 hours ago" --oneline --no-merges 2>/dev/null | head -10 || echo "NO_GIT"
```
Note in output: "(local repo only — connect GitHub for multi-repo view)"

**First-run repo list:**
On first run, store the list of active repos found via GitHub API:
```bash
nanopm_config_get "github_active_repos"
```
If empty: fetch repos with pushes in the last 30 days, store as comma-separated list:
```bash
nanopm_config_set "github_active_repos" "{repo1},{repo2},..."
```
This speeds up subsequent runs — only query known active repos instead of all repos.

**Linear (if available):**
```bash
_TIER_LINEAR=$(nanopm_has_connector linear)
echo "LINEAR_TIER: $_TIER_LINEAR"
```

If LINEAR tier is MCP or API:
- Fetch issues moved to Done in the last 24h
- Fetch issues currently In Progress
- Fetch any issues marked Blocked or flagged

If LINEAR not available: read `.nanopm/ROADMAP.md` and check for any manually updated status.

**Roadmap drift check:**
```bash
[ -f ".nanopm/ROADMAP.md" ] && echo "ROADMAP_EXISTS" || echo "ROADMAP_MISSING"
[ -f ".nanopm/AUDIT.md" ] && echo "AUDIT_EXISTS" || echo "AUDIT_MISSING"
```

If ROADMAP_EXISTS: scan for items marked as "this week" or current sprint. Cross-reference with GitHub commits — flag items with no recent commits across any repo.

**Granola — recent meetings (last 48h):**

Try `mcp__claude_ai_Granola__list_meetings` with limit: 5.

If available: extract meetings from the last 48h. For each:
- Title, date, participants
- Flag any meeting titled with "user", "customer", "interview", "discovery" → note as "📋 user signal available — run /pm-interview to extract"

If Granola not available: skip silently.

## Phase 2: Fetch today's meetings

Try `mcp__claude_ai_Google_Calendar__gcal_list_events` with:
- calendar_id: "primary"
- time_min: today 00:00:00
- time_max: today 23:59:59

If available, for each event extract:
- Start time, title, duration, attendees count
- Classify: internal sync | external call | user interview | solo block

**Prep flag logic:**
If an event title contains a feature name or product area AND there are no git commits touching that area in the last 48h → flag as "⚠ no recent progress on this topic"

If Google Calendar not available: skip the MEETINGS section silently.

## Phase 3: Generate the briefing

Output the standup briefing — concise, scannable, no fluff:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STANDUP — {Day, Date}  ·  {project slug}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

YESTERDAY
  ✓ [{repo}] {commit message}
  ✓ [{repo}] {commit message}
  ✓ {if nothing shipped: "No commits in the last 24h"}
  {if Granola had a user meeting: "📋 User call with {name} — run /pm-interview to extract signal"}

TODAY'S MEETINGS
  {HH:MM} → {event title} ({duration}) {⚠ no recent commits on this topic — if flagged}
  {if no calendar connected: omit this section entirely}

PRIORITIES
  → {priority 1 — inferred from roadmap + in-progress items}
  → {priority 2}
  → {priority 3 if relevant}

BLOCKERS
  ⚠ {any blocked Linear issues, or "None"}

DRIFT
  {if something was planned this week but has no commits: flag it here}
  {if nothing drifted: "On track"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Rules for PRIORITIES:**
- Infer from: in-progress Linear issues → roadmap current sprint items → AUDIT.md biggest gap
- Weight toward items with meetings today (if you have a review at 14:00, that's probably a priority)
- Never list more than 3
- If the roadmap is stale (>20 commits old), flag it: "⚠ ROADMAP.md is {N} commits old — consider /pm-roadmap"

**Rules for DRIFT:**
- A roadmap item drifted if: it was due this week, has no commits in 48h, and is not marked Done
- Don't flag items that are explicitly blocked — those appear under BLOCKERS

**Rules for TODAY'S MEETINGS:**
- Show time + title + duration only — no attendee list (too noisy)
- Flag prep gaps (no recent commits on the meeting topic) with ⚠
- If a meeting looks like a user interview (title keywords: user, customer, interview, call, discovery) → append "📋 run /pm-interview after"
- If no meetings today: show "No meetings today"

## Phase 4: Save and write

Write the briefing to `.nanopm/STANDUP.md` (overwrite — always the latest).

```bash
nanopm_context_append "{\"skill\":\"pm-standup\",\"outputs\":{\"date\":\"$(date +%Y-%m-%d)\",\"drift\":\"$(grep -c 'DRIFT' .nanopm/STANDUP.md 2>/dev/null || echo 0)\"}}"
```

Do NOT ask the user anything. Do NOT wait for input. Generate and display the briefing immediately.

## Telemetry

```bash
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.nanopm/analytics/.pending-"$_TEL_SESSION_ID" 2>/dev/null || true

_OUTCOME="success"

if [ -x ~/.nanopm/bin/nanopm-telemetry-log ]; then
  ~/.nanopm/bin/nanopm-telemetry-log \
    --skill "pm-standup" \
    --duration "$_TEL_DUR" \
    --outcome "$_OUTCOME" \
    --session-id "$_TEL_SESSION_ID" 2>/dev/null || true
fi
```

**STATUS: DONE**
