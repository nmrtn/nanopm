# nanopm

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**You think. nanopm structures it.**

Solo founders and small teams don't have a PM. They have a backlog, some instincts, and a nagging feeling they're building the wrong thing. nanopm is an AI-powered product management CLI for Claude Code — it automates the full planning cycle (audit → strategy → roadmap → PRD) directly in your editor and remembers everything across sessions.

Inspired by [gstack](https://github.com/garrytan/gstack) by Garry Tan (YC CEO), which proved you can give Claude Code a full engineering team via the SKILL.md standard. nanopm is the PM layer on top of that idea.

---

## The problem

Product work with AI is fragmented:

- You prompt ChatGPT for a strategy. Context is gone next session.
- You track roadmap in Notion. It doesn't know your codebase.
- You write PRDs in Linear. They don't feed back into your next audit.
- You switch between tools constantly. Nothing compounds.

No existing tool runs the full planning cycle, persists memory, and lives where you code.

---

## What it does

One command runs the full pipeline:

```
/pm-run
```

```
audit → objectives → strategy → roadmap → PRD → tickets
```

Each skill writes a markdown artifact. The next skill reads it. Context compounds — the strategy knows the audit, the PRD knows the strategy, the tickets know the PRD. Re-run `/pm-audit` six months later and it knows what you tried before.

---

## Example

```
You:     /pm-audit

nanopm:  Q1: What are you building? (one sentence)
You:     A Claude Code skill pack for PM workflows.

nanopm:  Q2: Who is it actually for?
You:     Solo founders who context-switch too much.

...11 questions later...

nanopm:  AUDIT.md written.

         Biggest gap: no evidence of demand. You're solving
         your own problem without knowing if others have it.
         Question you're avoiding: would you pay for this?

         Recommended next: /pm-discovery
```

---

## Who it's for

- **Solo founders acting as their own PM** — structured product thinking without leaving the terminal
- **Engineers doing product work** — go from codebase to roadmap without context-switching
- **Small teams without a dedicated PM** — a repeatable process that compounds over time
- **AI-native builders using Claude Code** — product planning that lives next to your code, not in a separate tab

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash
```

Installs to `~/.claude/skills/nanopm/`. Skills appear as `/pm-*` commands in Claude Code.

**Requirements:** Claude Code. `python3` (standard on macOS/Linux).

---

## All skills

```
/pm-run              → full pipeline in one command
/pm-scan             → read an existing codebase to understand what it actually does before planning
/pm-discovery        → figure out WHAT to build before planning HOW (pre-product / greenfield)
/pm-audit            → brutal honest assessment of product, user, and biggest gap
/pm-objectives       → OKRs with anti-goals and measurable key results
/pm-user-feedback    → aggregate feedback from Dovetail, Productboard, etc; cluster themes, surface top signal
/pm-competitors-intel → monitor competitor pages, diff snapshots, surface strategic implications
/pm-strategy         → strategy + mandatory adversarial challenge (assumption, test, cost)
/pm-roadmap          → outcome-driven roadmap (Shape Up / Scrum / NOW-NEXT-LATER)
/pm-prd              → full PRD or Shape Up pitch, adapts to your methodology
/pm-breakdown        → break PRD into tasks, create tickets in Linear / GitHub Issues
/pm-retro            → compare roadmap vs commits, surface what drifted
```

The pipeline compounds. Every skill also works standalone.

---

## Pipeline

```mermaid
graph LR
    RUN(["/pm-run"]):::runner -.->|orchestrates| AUDIT

    SCAN["/pm-scan"]:::entry -->|existing codebase| AUDIT["/pm-audit"]
    DISC["/pm-discovery"]:::entry -->|greenfield| AUDIT
    AUDIT --> OBJ["/pm-objectives"]
    OBJ --> STRAT["/pm-strategy"]
    UF["/pm-user-feedback"] --> STRAT
    CI["/pm-competitors-intel"] --> STRAT
    STRAT --> ROAD["/pm-roadmap"]
    ROAD --> PRD["/pm-prd"]
    PRD --> BREAK["/pm-breakdown"]
    BREAK --> SHIP(["ship"])
    SHIP --> RETRO["/pm-retro"]
    RETRO -.->|next cycle| AUDIT

    classDef runner fill:#f5f5f5,stroke:#aaa,stroke-dasharray:5 5
    classDef entry fill:#e8f4e8,stroke:#5a9e5a
```

---

## Memory

Every skill run appends to `~/.nanopm/memory/{project}.jsonl`. Every new skill knows what was tried before. Re-run `/pm-audit` six months later — it knows the history. No other PM tool does this because no other PM tool lives in your editor.

---

## How it compares

| | nanopm | Notion / Linear | ChatGPT |
|---|---|---|---|
| Lives in your editor | ✅ | ❌ | ❌ |
| Persistent memory across sessions | ✅ | ⚠️ manual | ❌ |
| Full pipeline (audit → PRD) | ✅ | ❌ | ❌ |
| Reads your codebase | ✅ | ❌ | ❌ |
| Zero-config (no integrations required) | ✅ | ❌ | ✅ |
| Adapts to Shape Up / Scrum / Kanban | ✅ | ✅ | ❌ |

Notion and Linear are great for tracking decisions. They don't make them. ChatGPT is great for one-off prompts. It doesn't remember the last six months of your product thinking. nanopm fills the gap between "I have a codebase" and "I have a clear plan".

---

## How it gets data

nanopm tries each tier in order, uses the highest available:

| Tier | How | Setup |
|------|-----|-------|
| 1 — MCP | Direct tool calls | Add `mcp__linear__*` etc. to your Claude config |
| 2 — API | REST/GraphQL | Set `LINEAR_API_KEY`, `NOTION_API_KEY`, `GITHUB_TOKEN`, etc. |
| 3 — Browser | Headless scrape | Install browse binary, sign in once in your browser |
| 4 — Manual | You fill it in | Always works, zero setup |

No integrations required. Tier 4 always works.

Connectors: Linear, GitHub Issues, Notion, Dovetail.

---

## Methodology support

nanopm detects your methodology at audit time and adapts its artifacts:

- **Shape Up** → roadmap uses bets + appetite + cool-down; PRDs become pitches
- **Scrum/Agile** → roadmap uses sprint framing, epics, story points
- **Kanban / hybrid / none** → NOW/NEXT/LATER roadmap, standard PRDs

---

## Staleness detection

Every skill run warns if your AUDIT.md or STRATEGY.md is more than 20 commits old:

```
⚠  nanopm: AUDIT.md is 34 commits old — consider re-running /pm-audit
```

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
bash test/skill-syntax.sh          # static checks (no LLM needed)
bash test/context-threading.e2e.sh # context plumbing E2E
bash test/website-bootstrap.e2e.sh # browser tier scenarios
bash test/adversarial.e2e.sh       # adversarial subagent gate (needs claude CLI)
```

---

*Built on the SKILL.md standard from [gstack](https://github.com/garrytan/gstack) — thank you Garry for proving that AI can own an entire function end-to-end.*
