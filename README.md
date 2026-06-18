# nanopm

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.15.0-blue.svg)](CHANGELOG.md)

A PM skill pack for AI coding agents. Runs the PM workflow end-to-end — company + product context, the three external signals, the planning cycle (challenge, strategy, roadmap, PRD), and the day-to-day ops (an adversarial challenge, a jam with Nano, the standup, the weekly update) — inside the agent you already use. Keeps typed state across sessions. Won't write a PRD until you name what would prove your bet wrong.

Works with Claude Code, Mistral Vibe, and OpenAI Codex. One install command picks up whichever you have. An optional macOS viewer browses the artifacts and re-runs skills on the Claude Code backend, for the moments you'd rather not be in a terminal.

Built on the SKILL.md standard from [gstack](https://github.com/garrytan/gstack). nanopm is the PM layer.

---

## Why this exists

Building the wrong thing fast is the failure mode AI coding agents make easy. They'll ship whatever you describe — they don't ask if it's the right thing.

The PM work that catches that (challenge, strategy, falsification, roadmap, retro) usually lives in tools that don't know your code, lose context between sessions, and don't talk to each other. ChatGPT for the strategy. Notion for the PRD. Linear for the tickets. Nothing compounds.

nanopm runs the whole cycle where you already work, with two structural properties:

1. **Every artifact lands in typed, schema-validated state.** Each skill writes to `~/.nanopm/projects/{slug}/{type}.jsonl`. The next skill reads from there. No grep on markdown, no silent corruption, no `tail -1 | cut -d'|'` parsing.
2. **Adversarial gates on the claims that matter.** Every strategy needs a falsifiable bet. Every NOW roadmap item needs a measurable outcome with a timeframe. Every PRD needs a paragraph stating what would prove it wrong. Each gate is a subagent against a rubric plus a state validator. A skill cannot complete unless a well-formed record actually lands.

One command runs the full pipeline: `/pm-run`. Or invoke any skill standalone.

---

## Example

```
You:     /pm-challenge-me

nanopm:  Q1: What are you building? (one sentence)
You:     An AI agent harness for financial advisors — automates
         client reporting, portfolio commentary, and compliance checks.

nanopm:  Q2: Who is it actually for?
You:     Independent RIAs managing $50M–$500M books, no ops team.

...11 questions later...

nanopm:  CHALLENGES.md written.

         Biggest gap: you're solving the reporting problem, but the
         job your users are actually hired to do is winning and
         keeping clients. Faster reports don't help if advisors
         can't explain the AI's output to a nervous client.
         Question you're avoiding: would a compliance officer
         sign off on AI-generated commentary going out unsupervised?

         Recommended next: /pm-discovery
```

---

## Who it's for

- **Solo founder running PM yourself.** Audit your own product before you keep building.
- **Engineer without a PM partner.** Strategy, roadmap and PRDs in your editor, not in a separate tab.
- **Small team without a dedicated PM seat.** A repeatable cycle that doesn't depend on a hire.

If you already have a polished product process and a PM you trust, you don't need this.

---

## Install

```bash
# Auto-detect installed agents (Claude Code, Mistral Vibe, OpenAI Codex)
curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash

# Target a specific host
curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash -s -- --host=claude
curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash -s -- --host=vibe
curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash -s -- --host=codex

# Install to all hosts at once
curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash -s -- --host=all
```

| Host | Skills install to | Invocation |
|------|-------------------|------------|
| Claude Code | `~/.claude/skills/` | `/pm-*` commands |
| Mistral Vibe | `~/.vibe/skills/` | `/pm-*` commands |
| OpenAI Codex | `~/.codex/skills/` | `/pm-*` commands |

**Requirements:** One of: Claude Code, Mistral Vibe, or OpenAI Codex. `python3` (standard on macOS/Linux).

### Claude Code plugin (optional, Claude Code only)

Claude Code users can install nanopm as a native [plugin](https://code.claude.com/docs/en/plugins.md) instead of the `curl | bash` script:

```
/plugin marketplace add nmrtn/nanopm
/plugin install nanopm
```

The plugin bundles all skills and bootstraps its shared runtime (`~/.nanopm/`)
automatically on first session via a `SessionStart` hook. Plugin-installed
commands are namespaced as `/nanopm:pm-run`, and updates flow through Claude
Code's own `/plugin` manager. **This path is Claude-Code-specific** — Mistral
Vibe and OpenAI Codex don't read the plugin manifest, so for those agents use
the `curl | bash` installer above (it remains the cross-agent path and is
unaffected by the plugin).

---

## All skills

**Planning pipeline:**
```
/pm-run              → full pipeline in one command
/pm-vision-mission   → define mission, vision, values, and company stage
/pm-business-model   → define business model, pricing, packaging, and GTM motion
/pm-org              → map the org, key roles, and decision-makers
/pm-product          → deep product map — reads code + the public site, or interviews you when greenfield
/pm-personas         → define who you're building for — JTBD personas + an explicit anti-persona
/pm-discovery        → figure out WHAT to build before planning HOW (pre-product / greenfield)
/pm-objectives       → OKRs with anti-goals and measurable key results
/pm-user-feedback    → aggregate feedback from Dovetail, Productboard, etc; cluster themes, surface top signal
/pm-competitors-intel → discover competitors, monitor + diff their pages, run SWOT + positioning analysis
/pm-opportunities    → build + maintain a ranked DB of user problems (Teresa Torres), tagged by provenance
/pm-strategy         → strategy + mandatory adversarial challenge (assumption, test, cost)
/pm-roadmap          → outcome-driven roadmap (Shape Up / Scrum / NOW-NEXT-LATER)
/pm-prd              → full PRD or Shape Up pitch, adapts to your methodology
/pm-breakdown        → break PRD into tasks, hand off to Linear / GitHub / OpenSpec / gstack / Human
/pm-retro            → compare roadmap vs commits, surface what drifted
```

**Daily ops:**
```
/pm-challenge-me     → three adversarial challenges: strategy, users, focus — starting with the question you're avoiding
/pm-brainstorm       → jam with Nano, your expert CPO — informal, context-loaded, resumable
/pm-standup          → morning briefing — what shipped, today's meetings, top 1-3 priorities
/pm-interview        → prepare a user interview guide, or debrief a transcript from Granola
/pm-weekly-update    → draft stakeholder update email (CEO, investor, or team), adapted to audience
/pm-data             → answer a product question using PostHog or Amplitude — trends, funnels, retention
```

The pipeline compounds. Every skill also works standalone.

---

## Pipeline

nanopm runs in four zones. Context first. Signal in. Planning cycle. Delivery out.

| Zone | Skills | Purpose |
|---|---|---|
| **1. Define** | `/pm-vision-mission` · `/pm-business-model` · `/pm-org` · `/pm-product` · `/pm-personas` | Establish company + product context: the business, the org, who it's for, the product map |
| **2. Discover** | `/pm-user-feedback` · `/pm-interview` · `/pm-data` · `/pm-competitors-intel` · `/pm-opportunities` | Pull the three external signals (user research, analytics, market), then distill them into a ranked DB of user problems |
| **3. Pipeline** | `/pm-objectives` → `/pm-strategy` → `/pm-roadmap` → `/pm-prd` → `/pm-breakdown` | Skills run in sequence; each reads typed state from the prior |
| **4. Handoffs** | Linear · GitHub · OpenSpec · gstack · Human markdown | `/pm-breakdown` writes to whichever target fits — no preferred default |
| **Daily Ops** | `/pm-challenge-me` · `/pm-brainstorm` · `/pm-standup` · `/pm-weekly-update` | Recurring day-to-day PM ops: an adversarial challenge, a jam with Nano, the daily briefing, the weekly stakeholder update |

---

### 1. Define — establish company + product context

Each Define skill produces a reusable context artifact downstream skills read. Dual-mode: reverse-engineer from code + the public site when material exists, interview from scratch when greenfield. Run the ones you have material for.

- **`/pm-vision-mission`** — mission, vision, values, company stage → `VISION-MISSION.md`.
- **`/pm-business-model`** — business model, pricing, packaging, GTM motion → `BUSINESS-MODEL.md`.
- **`/pm-org`** — org map, key roles, decision-makers → `ORG.md`.
- **`/pm-product`** — deep product map → `PRODUCT.md`. Dual-mode: for an existing product it reads the codebase (routes, models, tests, git history) plus the public site and positioning; for greenfield it interviews you to define the product concept from scratch. Reads `openspec/specs/` when present.
- **`/pm-personas`** — defines who you're building for → `PERSONAS.md`. Reverse-engineers personas from `PRODUCT.md` and prior artifacts when they exist, or interviews you from scratch when the repo is empty. JTBD proto-personas + an explicit anti-persona.

After any Define skill finishes, a subagent regenerates `.nanopm/CONTEXT-SUMMARY.md` — a one-page brief (what you do, who for, business model, org, why) synthesized from whatever Define docs exist. Every downstream skill loads it at startup (via the shared preamble), so the agent always works from the same company + product baseline and context doesn't drift between skills.

### 2. Discover — the three external signals

Each signal skill produces an artifact the pipeline reads. They're independent. Run only the ones you have data for.

- **`/pm-user-feedback`** — aggregates Dovetail, Productboard, Notion, Linear, GitHub → `FEEDBACK.md`. Clusters themes, surfaces top unaddressed signal.
- **`/pm-interview`** — interview guide (Torres / Mom Test / JTBD) or transcript debrief from Granola → appends to `FEEDBACK.md`.
- **`/pm-data`** — answers a product question via PostHog or Amplitude → `DATA.md` with confidence-tagged metrics. Consumed by the challenge session and the PRD.
- **`/pm-competitors-intel`** — discovers competitors from your product description, snapshots their pages and diffs against prior runs → `INTEL-{date}.md` and persistent `COMPETITORS.md`. An opt-in `analyze` mode runs per-competitor SWOT (vs `PRODUCT.md`) plus a scored positioning matrix, with a reasoning sidecar.
- **`/pm-opportunities`** — builds and maintains a ranked database of user problems (Teresa Torres sense — the unmet needs behind what you build, not the solutions) → `.nanopm/opportunities/`, an LLM-wiki the agent keeps current: one `<slug>.md` per opportunity plus a ranked `INDEX.md`, an append-only `LOG.md`, and an editable `SCHEMA.md`. Two levels only (Theme → Opportunity) and every opportunity carries explicit provenance (`evidence-backed` / `user-stated` / `nano-hypothesis`). `bootstrap` drafts the initial set from feedback + your assumptions + Nano's hypotheses; `add` captures one problem at a time. Sits between the raw `FEEDBACK.md` firehose and the roadmap — the bridge from Discover into Plan.

### 3. Pipeline — the planning cycle

Each skill writes a markdown artifact for humans and a typed JSONL record for the next skill. Run `/pm-run` for the whole sequence, or invoke any single skill standalone. (The adversarial challenge session, `/pm-challenge-me`, lives in Daily Ops — run it on any day, outside the pipeline.)

1. **`/pm-objectives`** → `.nanopm/OBJECTIVES.md` — OKRs with anti-goals and measurable KRs anchored to top signal.
2. **`/pm-strategy`** → `.nanopm/STRATEGY.md` — the bet, the risk, what you're saying no to. Adversarial review forces a falsifiable claim. Writes typed `bet` and `scope-out` decisions.
3. **`/pm-roadmap`** → `.nanopm/ROADMAP.md` — NOW/NEXT/LATER, Shape Up bets, or Scrum sprints. The gate writes one typed `target` per committed item (each must contain segment, behavior, metric, timeframe).
4. **`/pm-prd`** → `.nanopm/prds/{feature}.md` — full PRD or Shape Up pitch. Required Falsification section, gated on 4 elements. Writes a typed `bet` decision + a `prd` status record.
5. **`/pm-breakdown`** — tasks + handoff. See zone 4.

After any Plan skill (`/pm-objectives`, `/pm-strategy`, `/pm-roadmap`) finishes, a subagent regenerates `.nanopm/PLAN-SUMMARY.md` — a one-page brief (what you're betting on, what you're aiming for, what you're building now, what you're saying no to) synthesized from whatever OBJECTIVES/STRATEGY/ROADMAP docs exist. It's the Plan-phase counterpart to the Context Brief: every downstream skill loads it at startup too, right after the context brief, so the agent always carries both who the company is and what it's working on right now.

State lives in `~/.nanopm/projects/{slug}/{type}.jsonl` (typed, schema-validated). The next skill reads from there.

### 4. Handoffs — where work lands

`/pm-breakdown` writes the tasks to one of six peer targets. No preferred default. See the [Handoffs](#handoffs) section below for the full per-target output spec.

| Target | What gets written |
|---|---|
| **Linear** | Issues in a Linear team, with acceptance + PRD link |
| **GitHub Issues** | Repo issues, with body linking the PRD |
| **OpenSpec** | `openspec/changes/{feature}/` — pick up with `/opsx:apply` |
| **gstack** | `~/.gstack/projects/{slug}/ceo-plans/{date}-{feature}.md` — pick up with `/plan-ceo-review` |
| **Symphony** | `WORKFLOW.md` (repo root) + Linear issues — pick up with [OpenAI's Symphony](https://github.com/openai/symphony) |
| **Human** | `.nanopm/handoffs/{feature}.md` — paste into any tracker |

Every handoff is logged to `~/.nanopm/projects/{slug}/handoff.jsonl`.

### Daily ops (parallel to the pipeline)

These skills run on a day-to-day cadence without going through the planning sequence:

- **`/pm-challenge-me`** — brutal honest read → `CHALLENGES.md`. Reads `PRODUCT.md` + the company docs, surfaces the biggest gap, then delivers three direct challenges — strategy, users, focus — starting with the question you're avoiding. The adversarial gate writes a typed `question` decision.
- **`/pm-brainstorm`** — an informal jam with **Nano**, the expert CPO at your service. A context-loaded thinking partner for product ideas, user problems, and what to build next — no gate, no PRD, no artifact. Sessions are named and **resumable** via your host's native session resume, so the thinking compounds; the viewer adds a graphical chat with the same conversations.
- **`/pm-standup`** — morning briefing: commits, calendar, meeting notes.
- **`/pm-weekly-update`** — stakeholder update email adapted to audience.
- **`/pm-retro`** — compares roadmap commitments to actual commits, surfaces drift.

---

## Memory

State lives in `~/.nanopm/projects/{slug}/` as append-only, schema-validated JSONL — one file per record type:

| File | What it holds |
|---|---|
| `decision.jsonl` | Typed PM decisions: `bet`, `antigoal`, `target`, `methodology`, `gap`, `question`, `scope-in`, `scope-out`. Each carries confidence 1–10 and provenance (`observed`, `user-stated`, `inferred`, `derived`, `adversarial`). |
| `prd.jsonl` | Per-feature metadata: status (`draft`, `ready`, `handed-off`, `shipped`, `abandoned`), target, path. |
| `handoff.jsonl` | Which target each PRD went to, when, where. |
| `timeline.jsonl` | Skill run events: started, completed, outcome, duration. |

Every write goes through `bin/nanopm-state-log`, which enforces the schema before append — required fields, enum allowlists, key format, confidence range, length caps. Bad records fail loud with a non-zero exit. There are no silent appends.

Re-run `/pm-challenge-me` six months later and it reads the prior decisions before asking anything new.

---

## How it compares

| | nanopm | DIY prompts in your agent | Notion / Linear | ChatGPT |
|---|---|---|---|---|
| Lives in your editor | ✅ | ✅ | ❌ | ❌ |
| Typed memory across sessions | ✅ schema-validated JSONL | ❌ | ⚠️ manual writes | ❌ |
| Full PM pipeline (challenge → PRD) | ✅ | ⚠️ if you reprompt every time | ❌ | ❌ |
| Reads your codebase | ✅ | ✅ | ❌ | ❌ |
| Adversarial gates on bets & outcomes | ✅ subagent + state validator | ❌ | ❌ | ❌ |
| Peer handoff targets | ✅ Linear / GitHub / OpenSpec / gstack / human | ⚠️ ad-hoc | ⚠️ Linear only | ❌ |
| Multi-host (Claude / Vibe / Codex) | ✅ | n/a | n/a | n/a |
| Adapts to Shape Up / Scrum / Kanban | ✅ | ⚠️ if you prompt it | ✅ | ❌ |
| Zero-config — works without integrations | ✅ tier 4 manual | ✅ | ❌ | ✅ |

The point isn't to replace your tracker. The point is to make the decisions *before* the tracker — and make sure those decisions are typed, falsifiable, and still here next session.

---

## How it gets data

nanopm tries each tier in order, uses the highest available:

| Tier | How | Setup |
|------|-----|-------|
| 1 — MCP | Direct tool calls | Add `mcp__linear__*` etc. to your agent's config |
| 2 — API | REST/GraphQL | Set `LINEAR_API_KEY`, `NOTION_API_KEY`, `GITHUB_TOKEN`, etc. |
| 3 — Browser | Headless scrape | Install browse binary, sign in once in your browser |
| 4 — Manual | You fill it in | Always works, zero setup |

No integrations required. Tier 4 always works.

**Connectors:**

| Connector | Primary use | Tier 1 (MCP) | Tier 2 (API key) |
|-----------|------------|-------------|-----------------|
| Linear | Sprint, issues, roadmap | ✅ | `LINEAR_API_KEY` |
| GitHub Issues | PRs, releases, issues | ✅ | `GITHUB_TOKEN` |
| Notion | Pages, databases | ✅ | `NOTION_API_KEY` |
| Dovetail | Insights, themes | — | `DOVETAIL_API_KEY` |
| Productboard | Features, user notes | — | `PRODUCTBOARD_API_KEY` |
| PostHog | Trends, funnels, retention | ✅ | `POSTHOG_API_KEY` |
| Amplitude | Trends, funnels, retention | — | `AMPLITUDE_API_KEY` |
| Mixpanel | Event trends, funnels | — | `MIXPANEL_SERVICE_ACCOUNT` |
| Google Calendar | Today's meetings | ✅ | — |
| Granola | Meeting transcripts | ✅ | — |
| Intercom | Support tickets, themes | — | `INTERCOM_API_TOKEN` |
| HubSpot | Pipeline, ICP signal | — | `HUBSPOT_API_KEY` |
| Jira | Sprint, blockers | (preview) | `JIRA_API_TOKEN` |
| Google Drive | PRDs, research docs | ✅ | — |
| Slack | Channel decisions | ✅ | `SLACK_API_TOKEN` |

See [`connectors/README.md`](connectors/README.md) for full setup details per connector.

---

## Methodology support

nanopm detects your methodology at challenge time (CONTEXT.md intake) and adapts its artifacts:

- **Shape Up** → roadmap uses bets + appetite + cool-down; PRDs become pitches
- **Scrum/Agile** → roadmap uses sprint framing, epics, story points
- **Kanban / hybrid / none** → NOW/NEXT/LATER roadmap, standard PRDs

---

## Staleness detection

Every skill run warns if your CHALLENGES.md or STRATEGY.md is more than 20 commits old:

```
⚠  nanopm: CHALLENGES.md is 34 commits old — consider re-running /pm-challenge-me
```

---

## Handoffs

nanopm runs the PM half. Delivery lives elsewhere. `/pm-breakdown` writes the breakdown to one of six peer targets — no preferred default, you pick the one that fits how the project actually ships.

**Linear** — issues created in a Linear team via MCP or `LINEAR_API_KEY`. Each ticket carries the acceptance criteria and ties back to the PRD requirement.

**GitHub Issues** — issues in the repo via MCP or `GITHUB_TOKEN`. Body links the PRD and embeds acceptance.

**OpenSpec** — writes `openspec/changes/{feature}/` with `proposal.md`, `design.md`, `tasks.md`, and `specs/{feature}/spec.md` (requirements as SHALL statements). Pick this up with `/opsx:apply` to implement. If your repo already uses OpenSpec, `/pm-product` will read `openspec/specs/` automatically — specs describe intent more accurately than READMEs.

**gstack** — writes `~/.gstack/projects/{slug}/ceo-plans/{date}-{feature}.md` with a `status: ACTIVE` frontmatter. Pick this up in a [gstack](https://github.com/garrytan/gstack) session with `/plan-ceo-review` or `/autoplan` — the file is read directly from gstack's plan glob.

**Symphony** — writes `WORKFLOW.md` to the repo root and creates Linear issues. The `WORKFLOW.md` frontmatter configures [OpenAI's Symphony](https://github.com/openai/symphony) orchestrator; the body is a per-issue prompt template that embeds the PRD path, the typed bet from `decision.jsonl`, the PRD's Falsification criterion, and the out-of-scope items. Symphony's daemon polls Linear, spawns one Codex workspace per ticket, and runs them to PR. Requires `LINEAR_API_KEY` or the Linear MCP — Symphony is Linear-only in its v1 spec.

**Human** — single self-contained markdown at `.nanopm/handoffs/{feature}.md`. PRD body plus copy-paste-ready ticket blocks. Paste into Notion, Jira, a Slack thread, an email, anything. No external system touched.

Every handoff is recorded in `~/.nanopm/projects/{slug}/handoff.jsonl` — typed, schema-validated, queryable later.

---

## Uninstall

```bash
bash uninstall          # removes skills, keeps ~/.nanopm/ memory
bash uninstall --purge  # removes everything including memory and config
```

---

## Contributing

Add a connector: one markdown file in `connectors/`. See `connectors/README.md`.
Add a skill: copy any `pm-*/SKILL.md`, follow the preamble pattern in `lib/nanopm.sh`.

## Tests

```bash
bash test/run-all.sh               # run the full local suite (no LLM, no network)
bash test/run-all.sh --with-llm    # also run the adversarial e2e (needs claude CLI)
```

Individual suites:

```bash
bash test/skill-syntax.sh           # static checks: frontmatter, gates, state binaries, telemetry purge
bash test/state-layer.sh            # nanopm-state-log/read validators
bash test/multi-host.sh             # NANOPM_HOST detection + nanopm_skill_path resolution
bash test/gates.sh                  # ETHOS gates wired in pm-challenge-me / pm-roadmap / pm-prd
bash test/update-check.sh           # semver comparison, stale-cache regression, snooze
bash test/context-threading.e2e.sh  # legacy context append plumbing
bash test/website-bootstrap.e2e.sh  # browse + connector tier detection
bash test/adversarial.e2e.sh        # adversarial subagent gate (needs claude CLI)
```

---

## Authors

Created and maintained by **Nicolas Martin** ([@nmrtn](https://github.com/nmrtn)) and **Guillaume Simon**, co-authors.

---

*Built on the SKILL.md standard from [gstack](https://github.com/garrytan/gstack).*
