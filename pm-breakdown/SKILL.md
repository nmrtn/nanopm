---
name: pm-breakdown
version: 0.3.0
description: "Break a PRD into engineering tasks and hand off to one of six peer targets: Linear, GitHub Issues, OpenSpec, gstack, Symphony (OpenAI's orchestrator), or Human-readable markdown. No preferred default — you pick the target."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent
---

<!-- portability-v2 -->
> **Multi-host portability rules.** When invoking `AskUserQuestion`:
> 1. The `header` field MUST be a short noun phrase (≤ 12 characters). Mistral Vibe
>    rejects longer headers with `string_too_long`. Pick from: `Start`, `Target`,
>    `Scope`, `Audience`, `Methodology`, `Feature`, `Question`.
> 2. The `options` list MUST have at least 2 items. Vibe rejects empty/single-option
>    calls. For free-text input, always provide ≥ 2 framing options (e.g. `Yes, here's the input` /
>    `Skip`) — never call `ask_user_question` with `options: []`.


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
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_read pm-breakdown
nanopm_context_all
```

## Phase 1: Identify the PRD

```bash
ls .nanopm/prds/*.md 2>/dev/null || echo "NO_PRDS"
```

**If NO_PRDS:** "No PRDs found in `.nanopm/prds/`. Run `/pm-prd` first to create one." Exit.

**If one PRD exists:** use it automatically, tell the user: "Using PRD: {filename}"

**If multiple PRDs exist:** ask via AskUserQuestion which one. Store path as `_PRD_FILE`.

## Phase 2: Read the PRD

Read `_PRD_FILE`. Extract:
- Feature name
- Problem statement
- Functional requirements (numbered list)
- Out of scope items
- Ties to (objective/KR)
- For Shape Up pitches: appetite, solution sketch, rabbit holes, no-gos

Derive the feature slug from the PRD filename: lowercase, hyphens, max 40 chars. Store as `_FEATURE_SLUG`.

## Phase 3: Pick the handoff target

nanopm produces the breakdown; the handoff target is where the work actually goes. The six targets are peers — pick whichever fits how this team or project ships work.

Always ask via AskUserQuestion (no preferred default). If the host's tool caps options at 4, ask in two rounds: first "Tracker / Spec / Direct?" then drill into the specific target.

**"Where should this breakdown become work?**

A) **Linear** — issues created in a Linear team, with priority and labels
B) **GitHub Issues** — issues in the repo, with linked body and acceptance
C) **OpenSpec** — write `openspec/changes/{feature}/` (proposal + design + tasks + specs); pick up with `/opsx:apply`
D) **gstack** — write `~/.gstack/projects/{slug}/ceo-plans/{date}-{feature}.md`; pick up with `/plan-ceo-review` or `/autoplan`
E) **Symphony** — write `WORKFLOW.md` to the repo root + create Linear issues. OpenAI's Symphony orchestrator picks up the tickets and spawns one Codex workspace per issue. See https://github.com/openai/symphony
F) **Human** — single markdown file with PRD body + copy-paste-ready ticket list, no external system touched"

Store choice as `_TARGET` (linear / github / openspec / gstack / symphony / human).

If the user picks a target that requires availability (Linear, GitHub, or Symphony — which needs Linear under the hood) and we don't have it, fall back gracefully (Phase 4 handles that).

## Phase 4: Target-specific setup

### If `_TARGET=linear`:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_TIER_LINEAR=$(nanopm_has_connector linear)
echo "LINEAR_TIER: $_TIER_LINEAR"
```

- If tier 1 (MCP) or 2 (API): proceed. If team not stored, look up via `mcp__linear__list_teams` (MCP) or GraphQL (API):
  ```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
  curl -s -X POST https://api.linear.app/graphql \
    -H "Authorization: $LINEAR_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"query": "{ teams { nodes { id name } } }"}'
  ```
  Ask user to pick a team, then store:
  ```bash
  nanopm_config_set "linear_team_id"   "{id}"
  nanopm_config_set "linear_team_name" "{name}"
  ```
- If tier 3 or 4: tell the user "Linear write isn't available without `LINEAR_API_KEY` or the Linear MCP. Want me to fall back to Human-readable markdown instead?" — if yes, set `_TARGET=human` and continue. Otherwise exit.

### If `_TARGET=github`:

Derive from git remote:
```bash
_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
_GITHUB_REPO=$(echo "$_REMOTE" | sed 's/.*github\.com[:/]//' | sed 's/\.git$//')
echo "GITHUB_REPO: $_GITHUB_REPO"
```

If derivable, confirm with user. Otherwise ask for `owner/repo`. Store:
```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_config_set "github_repo" "$_GITHUB_REPO"
```

If neither MCP nor `GITHUB_TOKEN` is available: same fallback offer as Linear.

### If `_TARGET=openspec`:

```bash
_CHANGE_DIR="openspec/changes/${_FEATURE_SLUG}"
mkdir -p "${_CHANGE_DIR}/specs/${_FEATURE_SLUG}"
echo "OPENSPEC_DIR: $_CHANGE_DIR"
```

No external dependency — OpenSpec writes are pure filesystem.

### If `_TARGET=gstack`:

```bash
_GSTACK_PROJ="$HOME/.gstack/projects/$_SLUG/ceo-plans"
mkdir -p "$_GSTACK_PROJ"
_GSTACK_DATE=$(date +%Y-%m-%d)
_GSTACK_FILE="$_GSTACK_PROJ/${_GSTACK_DATE}-${_FEATURE_SLUG}.md"
echo "GSTACK_FILE: $_GSTACK_FILE"
```

No external dependency — gstack writes are a markdown file at the path `/plan-ceo-review` reads from.

### If `_TARGET=symphony`:

Symphony's reference implementation (per SPEC.md v1) is Linear-only. The Symphony handoff is conceptually `WORKFLOW.md + Linear issues` — it reuses the Linear setup, then writes a `WORKFLOW.md` to the repo root.

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_TIER_LINEAR=$(nanopm_has_connector linear)
echo "LINEAR_TIER: $_TIER_LINEAR"
```

- **If tier 1 (MCP) or 2 (API):** proceed. Same flow as `_TARGET=linear` for team setup if `_LINEAR_TEAM_ID` isn't already stored. Additionally, Symphony's `WORKFLOW.md` needs the Linear **project slug** (URL-friendly identifier, distinct from team ID). Look up via `mcp__linear__list_projects` (MCP) or GraphQL:
  ```bash
  source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
  curl -s -X POST https://api.linear.app/graphql \
    -H "Authorization: $LINEAR_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"query": "{ projects { nodes { id name slugId } } }"}'
  ```
  Ask the user to pick the project Symphony should watch, store:
  ```bash
  source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
  nanopm_config_set "linear_project_slug" "{slugId}"
  ```
- **If tier 3 or 4:** tell the user "Symphony requires Linear access (LINEAR_API_KEY or the Linear MCP). Want me to fall back to Human markdown?" — if yes, set `_TARGET=human` and continue. Otherwise exit.

Set the WORKFLOW.md target path:
```bash
_WORKFLOW_FILE="WORKFLOW.md"
echo "WORKFLOW_FILE: $_WORKFLOW_FILE (Symphony reads this from the repo root)"
```

### If `_TARGET=human`:

```bash
_HUMAN_FILE=".nanopm/handoffs/${_FEATURE_SLUG}.md"
mkdir -p ".nanopm/handoffs"
echo "HUMAN_FILE: $_HUMAN_FILE"
```

Always available.

## Phase 5: Generate task breakdown draft

Decompose the PRD into engineering tasks. Use `_METHODOLOGY` to pick the format.

**Decomposition rules (all methodologies):**
- Each task independently shippable (not "build the whole feature")
- Granularity: 1-3 days per task
- Every functional requirement maps to at least one task
- Out-of-scope items from the PRD must NOT appear as tasks
- Testing is part of the implementation task, not a separate task

**Shape Up** (`_METHODOLOGY` contains "shape"):
- "Scope items" named after the outcome
- Include the appetite as a constraint: "Total appetite: {X weeks}. Flag any scope items risking >20% of appetite."
- No story points

**Scrum/Agile** (`_METHODOLOGY` contains "scrum", "agile", or "sprint"):
- User stories where appropriate: "As [user], I want [action] so that [outcome]"
- Fibonacci story points: 1 / 2 / 3 / 5 / 8 (split anything larger)
- Group under feature as parent epic

**Kanban / hybrid / none / not set:**
- Plain engineering tasks with action verbs: "Implement X", "Add Y", "Refactor Z"
- Effort: S (half-day), M (1 day), L (2-3 days)

**Format each task as:**
```
Task N: {title}
  Description: {1-2 sentences — what to build and why, written for an engineer}
  Effort: {size or points}
  Acceptance: {one sentence — how to know it's done}
  Ties to: {PRD requirement number or section}
```

Hold the full task list in memory.

## Phase 6: Show draft and confirm

Present the full task breakdown via AskUserQuestion:

"Here's the breakdown for **{feature name}** ({N} tasks, total effort: {sum}) — handoff target: **{_TARGET}**:

{formatted task list}

---
A) Looks right — proceed with handoff
B) Edit the list first — I'll paste my modified version
C) Save markdown only — skip the target write"

**If B:** Accept the user's modified list. Re-parse. Show: "Updated. Proceeding."
**If C:** Skip Phase 7's external write, still do Phase 8 (markdown) and log a handoff with `target=human`.

## Phase 7: Write to the chosen target

### Phase 7a — Linear

For each task (tier 1 — MCP):
```
mcp__linear__create_issue(
  title: "{task title}",
  description: "{description}\n\nAcceptance: {acceptance}\nTies to: {requirement}",
  teamId: "{_LINEAR_TEAM_ID}",
  estimate: {story_points_if_scrum_else_omit}
)
```

For tier 2 (API):
```bash
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"query\": \"mutation { issueCreate(input: { title: \\\"${_TASK_TITLE}\\\", description: \\\"${_TASK_DESC}\\\", teamId: \\\"${_LINEAR_TEAM_ID}\\\" }) { issue { id identifier url } } }\"
  }"
```

Record created URLs.

### Phase 7b — GitHub Issues

Tier 1 (MCP):
```
mcp__github__create_issue(
  owner: "{owner}",
  repo: "{repo}",
  title: "{task title}",
  body: "{description}\n\n**Acceptance:** {acceptance}\n**Ties to:** {requirement}\n\n*Created by nanopm /pm-breakdown*"
)
```

Tier 2 (API):
```bash
_OWNER=$(echo "$_GITHUB_REPO" | cut -d/ -f1)
_REPO=$(echo  "$_GITHUB_REPO" | cut -d/ -f2)
curl -s -X POST "https://api.github.com/repos/${_OWNER}/${_REPO}/issues" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"title\": \"${_TASK_TITLE}\", \"body\": \"${_TASK_BODY}\"}"
```

Record created URLs.

### Phase 7c — OpenSpec

Write `${_CHANGE_DIR}/proposal.md`:
```markdown
# {feature name}

## Why we're doing this

{problem statement from PRD — 2-3 sentences}

## What's changing

{summary of functional requirements as a bulleted list}

## What's not changing

{out of scope items}

## Ties to

{objective/KR from PRD}

---
*Generated by nanopm /pm-breakdown on {date}*
*Source: {_PRD_FILE}*
```

Write `${_CHANGE_DIR}/design.md`:
```markdown
# Technical Design: {feature name}

## Approach

{technical approach from PRD if present, otherwise: "To be determined during implementation."}

## Key decisions

{any constraints or technical notes from PRD}

## Open questions

{rabbit holes / risks from PRD if Shape Up, otherwise list any unknowns}

---
*Generated by nanopm /pm-breakdown on {date}*
```

Write `${_CHANGE_DIR}/tasks.md` — same content as the Phase 8 markdown file (full task list).

Write `${_CHANGE_DIR}/specs/${_FEATURE_SLUG}/spec.md` — convert each functional requirement to OpenSpec SHALL format:
```markdown
# {feature name} Specification

## Purpose
{one sentence from PRD problem statement}

## Requirements

{for each functional requirement:}
### Requirement: {requirement name — short noun phrase}
The system SHALL {requirement rewritten as normative}.

#### Scenario: {primary scenario name}
- GIVEN {precondition}
- WHEN {action}
- THEN {expected outcome}
```

If `openspec` CLI is on PATH, offer to run `openspec update`.

### Phase 7d — gstack

Write `$_GSTACK_FILE` with this format (matches what `/plan-ceo-review` reads from `~/.gstack/projects/{slug}/ceo-plans/`):

```markdown
---
status: ACTIVE
source: nanopm
created: {iso timestamp}
---
# CEO Plan: {feature name}
Generated by nanopm /pm-breakdown on {date}
Repo: {_SLUG}
Source PRD: {_PRD_FILE}

## Vision

{problem statement from PRD — 2-3 sentences. Frame as the strategic outcome, not the feature.}

## Why now

{ties to (objective/KR) + the gap or signal driving this feature, if available from prior nanopm context}

## Scope

{functional requirements from PRD as a numbered list — what's in}

## NOT in scope

{out of scope items from PRD}

## Tasks

{the full task list from Phase 5, same format as the markdown}

## Acceptance

{1-3 bullets describing how we know the feature is shipped successfully — from PRD success criteria}

## Open questions

{any unresolved items — rabbit holes / risks / unknowns}

---
*Source: nanopm v{version} → gstack. Drop into a gstack session and run `/plan-ceo-review` to lock the plan, or `/autoplan` for the full review pipeline.*
```

After writing, tell the user:
```
gstack ceo-plan written: {_GSTACK_FILE}

  Pick this up in a gstack session with:
    /plan-ceo-review     (sectional review)
    /autoplan            (full review pipeline)
```

### Phase 7f — Symphony

Two writes: a `WORKFLOW.md` to the repo root + Linear issues (same as Phase 7a, but each issue body references the WORKFLOW.md and the typed bet).

#### Step 1: Write `WORKFLOW.md` to the repo root

The `WORKFLOW.md` format follows OpenAI's Symphony SPEC.md (Section 5). YAML frontmatter configures the Symphony orchestrator + Codex agent; the Markdown body is the per-issue prompt template (Liquid-compatible, must use the `issue` and `attempt` variables).

```markdown
---
tracker:
  kind: linear
  api_key: $LINEAR_API_KEY
  project_slug: {linear_project_slug from config}
  active_states: [Todo, In Progress]
  terminal_states: [Done, Cancelled, Canceled]

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

# Workflow: {feature name}

You are a Codex agent working on a ticket from a nanopm-generated PRD. nanopm produced this WORKFLOW.md to give you the full PM context.

## Context for this ticket

- **Issue:** `{{ issue.identifier }}: {{ issue.title }}`
- **Attempt:** `{{ attempt | default: "1 (first run)" }}`
- **Source PRD:** `.nanopm/prds/{_FEATURE_SLUG}.md` (read this first — it's the source of truth)
- **Project state directory:** `~/.nanopm/projects/{slug}/` (typed decisions live here)

## The bet behind this work

{Insert the latest typed `bet` decision from `~/.nanopm/projects/{slug}/decision.jsonl` where `skill=pm-strategy` — the single sentence from the bet's `insight` field.}

## Falsification — how we'd know this PRD was wrong

{Insert the PRD's `## Falsification` paragraph verbatim.}

## What to do

1. Read `.nanopm/prds/{_FEATURE_SLUG}.md` carefully. The PRD is the source of truth. If anything here conflicts with the PRD, the PRD wins.
2. (Optional) Read `~/.nanopm/projects/{slug}/decision.jsonl` for additional context on prior PM decisions (typed `bet`, `scope-out`, `target`).
3. Implement only this ticket's scope. Each ticket is independently shippable.
4. Open a PR. PR body must reference: (a) the PRD path, (b) this ticket's `{{ issue.identifier }}`, (c) the success criterion from below.
5. Move the issue state to `Review` (or the equivalent handoff state in this Linear workflow) when done.

## What to NOT do

{Insert the PRD's `### Out of scope (v1)` items as a bulleted list. If any of these appear in the implementation, the PR will be rejected.}

## Acceptance — how to know this ticket is done

{Insert the relevant rows from the PRD's `## Success Criteria` table, plus the "What will be different in commits?" row verbatim — that row is the most concrete acceptance signal.}

## Multi-host note

This workflow runs under Symphony (Codex App Server). The source PRD and typed-state files were produced by nanopm running on Claude Code, Mistral Vibe, or OpenAI Codex — the artifacts are host-agnostic. If you spot something in the PRD that uses a Claude-specific construct (e.g., `AskUserQuestion`), translate it to your environment's equivalent (Codex handles questions conversationally).

---

*This WORKFLOW.md was generated by nanopm /pm-breakdown --target=symphony on {date}. The PRD at `.nanopm/prds/{_FEATURE_SLUG}.md` is the canonical specification. Symphony spec compatibility: v1 (Linear tracker, repo-owned WORKFLOW.md).*
```

#### Step 2: Create Linear issues (same as Phase 7a)

Use the existing Linear issue creation flow from Phase 7a — Tier 1 (MCP) or Tier 2 (API) per `_TIER_LINEAR`. For each task, add to the issue body:

- A back-link to the PRD: `Source PRD: .nanopm/prds/{_FEATURE_SLUG}.md`
- A reference to the WORKFLOW.md: `Symphony WORKFLOW.md: {_WORKFLOW_FILE} (read this first)`
- The task's acceptance criterion verbatim
- The task's ties (PRD requirement number, parent typed `target` decision key)

Symphony's tracker poll will pick up the issues automatically once the WORKFLOW.md is committed to the repo and Symphony is running.

#### Step 3: User-facing summary

After both writes succeed, tell the user:

```
Symphony handoff complete.

  Repo file:     {_WORKFLOW_FILE} (Symphony reads this)
  Linear issues: {N} issues created in team {_LINEAR_TEAM_NAME}
  Project slug:  {linear_project_slug}

  To start Symphony working these:
    1. Commit WORKFLOW.md to your repo
    2. Run Symphony (https://github.com/openai/symphony) with this project configured
    3. Symphony will spawn one Codex workspace per ticket and start working

  Symphony spec compatibility: v1 (Linear tracker)
```

### Phase 7e — Human

Write `$_HUMAN_FILE` — a single self-contained markdown that travels anywhere:

```markdown
# {feature name}
Generated by nanopm /pm-breakdown on {date}
Source PRD: {_PRD_FILE}

## Why we're doing this

{problem statement}

## Functional scope

{functional requirements as bullets}

## NOT in scope

{out of scope items}

---

## Tickets

Copy-paste each block into your tracker of choice. Each ticket is independently shippable.

### Ticket 1: {title}
**Effort:** {size/points}
**Ties to:** {requirement}

{description}

**Acceptance:** {acceptance}

---

### Ticket 2: {title}
{...}

---

{repeat for all tasks}

---

*Source: nanopm v{version} — markdown handoff. Paste into Linear, Jira, Notion, or any tracker.*
```

## Phase 8: Always write task markdown

Regardless of target, write `.nanopm/tasks/{_FEATURE_SLUG}.md`:

```markdown
# Tasks: {feature name}
Generated by /pm-breakdown on {date}
Project: {_SLUG}
PRD: {_PRD_FILE}
Methodology: {_METHODOLOGY or "default"}
Handoff target: {_TARGET}

---

{for each task:}
## Task N: {title}

**Effort:** {size/points}
**Ties to:** {requirement}
{if Linear/GitHub ticket created: **Ticket:** [{identifier}]({url})}
{if creation failed: **Ticket:** creation failed — {error}}

{description}

**Acceptance:** {acceptance}

---

## Summary

- Total tasks: {N}
- Total effort: {sum}
- Handoff target: {_TARGET}
- Handoff path: {_HANDOFF_PATH}
{if Linear/GitHub: - Tickets created: {count} / {N}}
{if any failures: - Failed: {list}}

---

*Source: {_PRD_FILE}*
```

## Phase 9: Log the handoff

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
# Determine handoff path written for this target
case "$_TARGET" in
  linear)   _HANDOFF_PATH="linear://team/${_LINEAR_TEAM_NAME}" ;;
  github)   _HANDOFF_PATH="github://${_GITHUB_REPO}" ;;
  openspec) _HANDOFF_PATH="${_CHANGE_DIR}" ;;
  gstack)   _HANDOFF_PATH="${_GSTACK_FILE}" ;;
  symphony) _HANDOFF_PATH="symphony://${_WORKFLOW_FILE}+linear://${_LINEAR_TEAM_NAME}" ;;
  human)    _HANDOFF_PATH="${_HUMAN_FILE}" ;;
esac

# Validated state write
nanopm_state_log --type handoff \
  "{\"feature\":\"${_FEATURE_SLUG}\",\"target\":\"${_TARGET}\",\"path\":\"${_HANDOFF_PATH}\"}"

# Update PRD status to handed-off
nanopm_state_log --type prd \
  "{\"feature\":\"${_FEATURE_SLUG}\",\"status\":\"handed-off\",\"target\":\"${_TARGET}\",\"path\":\"${_HANDOFF_PATH}\",\"skill\":\"pm-breakdown\"}"
```

## Phase 10: Save legacy context (back-compat)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_append "{\"skill\":\"pm-breakdown\",\"outputs\":{\"feature\":\"${_FEATURE_SLUG}\",\"task_count\":\"${_TASK_COUNT}\",\"target\":\"${_TARGET}\",\"handoff_path\":\"${_HANDOFF_PATH}\"}}"
```

## Completion

Tell the user:
- Tasks file: `.nanopm/tasks/{_FEATURE_SLUG}.md`
- Handoff target + path
- For Linear/GitHub: created tickets count + URLs; any failures with actionable fix
- For OpenSpec: change folder location + next command (`/opsx:apply`)
- For gstack: ceo-plan path + next command (`/plan-ceo-review` or `/autoplan`)
- For Human: single markdown file path — paste blocks into any tracker

Next: start building, or `/pm-retro` after shipping to compare plan vs reality.

**STATUS: DONE**
