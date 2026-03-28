# nanopm

**You answer questions. nanopm does the thinking.**

Solo founders and small teams don't have a PM. They have a backlog, some instincts, and a nagging feeling they're building the wrong thing. nanopm is the PM layer for Claude Code — it runs the full planning cycle inside your terminal and remembers everything across sessions.

Inspired by [gstack](https://github.com/garrytan/gstack) by Garry Tan (YC CEO), which proved you can give Claude Code a full engineering team via the SKILL.md standard. nanopm is the PM layer on top of that idea.

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
/pm-discovery        → figure out WHAT to build before planning HOW
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

    DISC["/pm-discovery"] -->|optional| AUDIT["/pm-audit"]
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
```

---

## Memory

Every skill run appends to `~/.nanopm/memory/{project}.jsonl`. Every new skill knows what was tried before. Re-run `/pm-audit` six months later — it knows the history. No other PM tool does this because no other PM tool lives in your editor.

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

MIT license.
