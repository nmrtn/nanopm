---
name: pm-breakdown
version: 0.1.0
description: "Break a PRD into engineering tasks and create tickets in Linear or GitHub Issues. Shows a draft first, asks for confirmation, then creates. Always outputs a markdown task list regardless of ticket creation."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent
---

## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
_TASKS_DIR=".nanopm/tasks"
mkdir -p "$_TASKS_DIR"
_METHODOLOGY=$(nanopm_config_get "methodology")
echo "METHODOLOGY: ${_METHODOLOGY:-not set}"
```

## Phase 0: Prior context

```bash
nanopm_context_read pm-breakdown
```

Read all prior context for team/repo config already stored:
```bash
nanopm_context_all
```

## Phase 1: Identify the PRD

List available PRDs:

```bash
ls .nanopm/prds/*.md 2>/dev/null || echo "NO_PRDS"
```

**If NO_PRDS:** "No PRDs found in `.nanopm/prds/`. Run `/pm-prd` first to create one."
Exit.

**If one PRD exists:** use it automatically, tell the user: "Using PRD: {filename}"

**If multiple PRDs exist:** ask via AskUserQuestion:
"Which PRD do you want to break down into tasks?
{list filenames with titles extracted from each file}"

Store the selected PRD path as `_PRD_FILE`.

## Phase 2: Read the PRD

Read `_PRD_FILE`. Extract:
- Feature name
- Problem statement
- Functional requirements (numbered list)
- Out of scope items
- Ties to (objective/KR)
- For Shape Up pitches: appetite, solution sketch, rabbit holes, no-gos

## Phase 3: Detect write targets

```bash
_TIER_LINEAR=$(nanopm_has_connector linear)
_TIER_GITHUB=$(nanopm_has_connector github)
echo "LINEAR: $_TIER_LINEAR | GITHUB: $_TIER_GITHUB"
```

Also check for stored project config:
```bash
_LINEAR_TEAM=$(nanopm_config_get "linear_team_id")
_LINEAR_TEAM_NAME=$(nanopm_config_get "linear_team_name")
_GITHUB_REPO=$(nanopm_config_get "github_repo")
echo "LINEAR_TEAM: ${_LINEAR_TEAM:-not set}"
echo "GITHUB_REPO: ${_GITHUB_REPO:-not set}"
```

Determine write capability:

- **Linear write available** if `_TIER_LINEAR` is 1 or 2
- **GitHub write available** if `_TIER_GITHUB` is 1 or 2
- **Markdown only** if both are tier 3/4

**If both write targets available:** ask via AskUserQuestion:
"Where should I create the tickets?
A) Linear
B) GitHub Issues
C) Both
D) Markdown only — I'll create tickets myself"

**If only one write target available:** use it, tell the user.

**If markdown only:** proceed, output markdown task list only.

Store choice as `_WRITE_TARGET` (linear / github / both / markdown).

## Phase 4: Project setup (first write, only if needed)

**Linear setup (skip if `_LINEAR_TEAM` already stored):**

If tier 1 (MCP): call `mcp__linear__list_teams` or `mcp__linear__get_viewer` to list available teams.
If tier 2 (API):
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ teams { nodes { id name } } }"}'
```

Present teams via AskUserQuestion: "Which Linear team should these tickets go to? {list team names}"

Store selection:
```bash
nanopm_config_set "linear_team_id"   "{selected_id}"
nanopm_config_set "linear_team_name" "{selected_name}"
```

**GitHub setup (skip if `_GITHUB_REPO` already stored):**

Derive from git remote:
```bash
_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
_GITHUB_REPO=$(echo "$_REMOTE" | sed 's/.*github\.com[:/]//' | sed 's/\.git$//')
echo "GITHUB_REPO: $_GITHUB_REPO"
```

If derivable, confirm with user. If not, ask: "What is the GitHub repo? (format: owner/repo)"

Store:
```bash
nanopm_config_set "github_repo" "$_GITHUB_REPO"
```

## Phase 5: Generate task breakdown draft

Decompose the PRD into engineering tasks. Use `_METHODOLOGY` to determine format and granularity.

**Decomposition rules (all methodologies):**
- Each task must be independently shippable (not "build the whole feature")
- Granularity: 1-3 days of engineering work per task
- Every functional requirement from the PRD should map to at least one task
- Out-of-scope items from the PRD must NOT appear as tasks
- Avoid tasks that are just "write tests for X" — testing should be part of the implementation task

**Shape Up** (`_METHODOLOGY` contains "shape"):
- Tasks are called "scope items" — named after the outcome, not the action
- Group related scope items if they're logically one unit of work
- Include the appetite as a constraint: "Total appetite: {X weeks}. Flag any scope items that individually risk more than 20% of appetite."
- Do NOT add story point estimates

**Scrum/Agile** (`_METHODOLOGY` contains "scrum", "agile", or "sprint"):
- Tasks are user stories where appropriate: "As a [user], I want [action] so that [outcome]"
- Add rough story point estimates: 1 / 2 / 3 / 5 / 8 (Fibonacci, no higher than 8 — split anything larger)
- Group under the feature as a parent epic

**All other methodologies (Kanban, hybrid, none, not set):**
- Tasks are plain engineering tasks with action verbs: "Implement X", "Add Y", "Refactor Z"
- Effort sizing: S (half-day), M (1 day), L (2-3 days)
- No story points

**Format each task as:**
```
Task N: {title}
  Description: {1-2 sentences — what to build and why, written for an engineer}
  Effort: {size or points}
  Acceptance: {one sentence — how to know it's done}
  Ties to: {PRD requirement number or section}
```

Hold the full task list in memory. Do NOT write to disk yet.

## Phase 6: Show draft and confirm

Present the full task breakdown to the user via AskUserQuestion:

"Here's the breakdown for **{feature name}** ({N} tasks, total effort: {sum}):

{formatted task list}

---
A) Create tickets as shown
B) Edit the list first — paste your modified version
C) Skip ticket creation — save markdown only"

**If B:** Accept the user's modified list. Re-parse it as the task list. Show the final version: "Updated. Creating {N} tasks." then proceed to Phase 7.

**If C:** Skip to Phase 8 (markdown output only).

## Phase 7: Create tickets

Create tasks one by one. For each task:

Show progress: "Creating: {task title}..."

### Linear (tier 1 — MCP)

```
mcp__linear__create_issue(
  title: "{task title}",
  description: "{description}\n\nAcceptance: {acceptance}\nTies to: {requirement}",
  teamId: "{_LINEAR_TEAM}",
  estimate: {story_points_if_scrum_else_omit}
)
```

### Linear (tier 2 — API)

```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"mutation { issueCreate(input: { title: \\\"${_TASK_TITLE}\\\", description: \\\"${_TASK_DESC}\\\", teamId: \\\"${_LINEAR_TEAM}\\\" }) { issue { id identifier url } } }\"
  }"
```

Extract and record the created issue URL for the output summary.

### GitHub Issues (tier 1 — MCP)

```
mcp__github__create_issue(
  owner: "{owner from _GITHUB_REPO}",
  repo: "{repo from _GITHUB_REPO}",
  title: "{task title}",
  body: "{description}\n\n**Acceptance:** {acceptance}\n**Ties to:** {requirement}\n\n*Created by nanopm /pm-breakdown*"
)
```

### GitHub Issues (tier 2 — API)

```bash
_OWNER=$(echo "$_GITHUB_REPO" | cut -d/ -f1)
_REPO=$(echo  "$_GITHUB_REPO" | cut -d/ -f2)
curl -s -X POST "https://api.github.com/repos/${_OWNER}/${_REPO}/issues" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"title\": \"${_TASK_TITLE}\", \"body\": \"${_TASK_BODY}\"}"
```

**Error handling:** If any individual ticket creation fails (auth error, API limit, network):
- Record the failure with the error message
- Continue creating remaining tickets (don't abort the whole batch)
- Report failures in the completion summary
- Always fall through to Phase 8 to write the markdown file

## Phase 8: Write task markdown

Always write `.nanopm/tasks/{slug-feature}.md` regardless of whether tickets were created:

```markdown
# Tasks: {feature name}
Generated by /pm-breakdown on {date}
Project: {slug}
PRD: {_PRD_FILE}
Methodology: {_METHODOLOGY or "default"}
Tickets: {linear/github/markdown-only}

---

{for each task:}
## Task N: {title}

**Effort:** {size/points}
**Ties to:** {requirement}
{if ticket created: **Ticket:** [{identifier}]({url})}
{if creation failed: **Ticket:** creation failed — {error}}

{description}

**Acceptance:** {acceptance}

---

## Summary

- Total tasks: {N}
- Total effort: {sum}
- Tickets created: {count} / {N}
{if any failures: - Failed: {list}}

---

*Source: {_PRD_FILE}*
```

## Phase 9: Save context

```bash
nanopm_context_append "{\"skill\":\"pm-breakdown\",\"outputs\":{\"feature\":\"$(basename $_PRD_FILE .md)\",\"task_count\":\"${_TASK_COUNT}\",\"write_target\":\"${_WRITE_TARGET}\",\"tasks_file\":\"${_TASKS_FILE}\"}}"
```

## Completion

Tell the user:
- Tasks file written to `.nanopm/tasks/{feature}.md`
- How many tickets were created and where
- Any failures (with actionable next steps — e.g., "check that your LINEAR_API_KEY has write scope")
- The created ticket URLs (list them)

Next: Start building, or `/pm-retro` after shipping to compare plan vs reality

## Telemetry

```bash
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.nanopm/analytics/.pending-"$_TEL_SESSION_ID" 2>/dev/null || true

_OUTCOME="success"

if [ -x ~/.nanopm/bin/nanopm-telemetry-log ]; then
  ~/.nanopm/bin/nanopm-telemetry-log \
    --skill "pm-breakdown" \
    --duration "$_TEL_DUR" \
    --outcome "$_OUTCOME" \
    --session-id "$_TEL_SESSION_ID" 2>/dev/null || true
fi
```

**STATUS: DONE**
