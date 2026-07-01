# Product
Mode: reverse-engineered from codebase + maintainer confirmation · 2026-06-25

## What it is
nanopm is a **skill pack** — ~20 `/pm-*` commands installed into an AI coding agent
(Claude Code, Mistral Vibe, OpenAI Codex). It turns the agent into an autonomous PM that
runs the whole product loop from the terminal, where the builder already writes code.

## Surface area
Skills are organized in four phases, plus daily ops that run any day:

- **Define** — `pm-vision-mission`, `pm-business-model`, `pm-org`, `pm-product`, `pm-personas`
- **Discover** — `pm-user-feedback`, `pm-competitors-intel`, `pm-interview`, `pm-data`
- **Plan** — `pm-objectives`, `pm-strategy`, `pm-roadmap`, `pm-prd`
- **Build** — `pm-breakdown` (hands off to Linear / GitHub / OpenSpec / gstack), `pm-retro`
- **Daily ops** — `pm-challenge-me`, `pm-standup`, `pm-brainstorm`, `pm-weekly-update`, `pm-discovery`, `pm-opportunities`

`pm-run` orchestrates the full pipeline in one command; `pm-upgrade` keeps the install current.

## The memory layer (the differentiator)
A **LLM-wiki** the agent owns and maintains, following Karpathy's pattern. Three layers:
- `raw/` — immutable source material (feedback, competitor snapshots, interviews, an events log). Never edited, never shown whole.
- `wiki/` — the LLM-authored markdown the agent reads and refines (docs + entity pages for personas, competitors, opportunities, objectives, features).
- `NANOPM-WIKI.md` — the schema/contract.
Two always-loaded briefs — a company brief (who we are) and a plan brief (what we're
working on now) — are injected into **every** skill run, so work compounds instead of
starting cold. Three ops: ingest, query, lint.

## The viewer
A read-only **macOS SwiftUI app** that renders the `.nanopm/` wiki grouped by phase
(Define / Discover / Plan / Build / Daily / Others). It's the "something to look at" hook
on top of the CLI; it can also update the installed skill pack in place.

## Architecture
- **Runtime:** `lib/nanopm.sh` — shared bash functions every skill sources.
- **Skills:** plain markdown (`SKILL.md`) — portable across hosts.
- **Wiki engine:** Python bins in `~/.nanopm/bin/` (`nanopm-ingest-agent`,
  `nanopm-lint-agent`, `nanopm-migrate-to-wiki`, `nanopm-export`) — deterministic
  structure work; the LLM does the judgment.
- **Data ingestion ladder:** MCP → API → browser → manual `CONTEXT.md` fallback.
- **State:** `~/.nanopm/` (global config + bins), `.nanopm/` (per-project wiki, gitignored).
- **Install:** `curl | bash` (all hosts) or native Claude Code plugin.

## Maturity & honest gaps
Mechanically complete — every phase runs end-to-end, the wiki compounds, the viewer
renders it. **But:** unproven in real use (zero external users), the memory layer is new
and heavier than a low-signal project needs, and the whole thing is validated against a
single user (the maintainer). The product works; whether it's wanted is the open question.

---

## Provenance & assumptions
- **Skill surface / phases / pm-run** — *Evidenced.* From `CLAUDE.md`, the `pm-*/` skill
  dirs, and `setup`'s `_SKILL_LIST`.
- **Memory wiki (3 layers, 2 briefs, ingest/query/lint)** — *Evidenced.* From
  `NANOPM-WIKI.md`, `lib/nanopm.sh`, and the `bin/` engine; built/reviewed this session.
- **Viewer** — *Evidenced.* From `viewer/` (SwiftUI); rendered live this session.
- **Architecture / install ladder** — *Evidenced.* From `lib/`, `bin/`, `.claude-plugin/`, `setup`.
- **Maturity gaps (unproven, n=1, memory-heavy)** — *Assumed (honest interpretation).*
  Consistent across the project's AUDIT and this session; flagged so planning treats
  "mechanically done" and "validated" as different things.
