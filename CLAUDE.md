# nanopm

Autonomous PM skill pack for AI coding agents. Replaces the PM workflow end-to-end.

## Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| pm-run | `/pm-run` | Full pipeline in one command |
| pm-vision-mission | `/pm-vision-mission` | Define mission/vision/values/stage → VISION-MISSION.md |
| pm-business-model | `/pm-business-model` | Define business model, pricing, GTM → BUSINESS-MODEL.md |
| pm-org | `/pm-org` | Map the org, roles, decision-makers → ORG.md |
| pm-product | `/pm-product` | Deep product map — from code + site, or interview if greenfield → PRODUCT.md |
| pm-personas | `/pm-personas` | Define WHO you're building for — JTBD personas + anti-persona |
| pm-discovery | `/pm-discovery` | Figure out WHAT to build — pre-planning discovery |
| pm-opportunities | `/pm-opportunities` | Build & maintain a ranked user-opportunity database (Teresa Torres) → .nanopm/opportunities/ |
| pm-challenge-me | `/pm-challenge-me` | Challenge Me — adversarial challenges based on product context |
| pm-objectives | `/pm-objectives` | Define OKRs and anti-goals |
| pm-strategy | `/pm-strategy` | Strategy with structured adversarial challenge |
| pm-roadmap | `/pm-roadmap` | Outcome-driven roadmap |
| pm-prd | `/pm-prd` | Full PRD (or Shape Up pitch) |
| pm-breakdown | `/pm-breakdown` | Break PRD into tasks, hand off to Linear / GitHub / OpenSpec / gstack / Human |
| pm-retro | `/pm-retro` | Compare roadmap vs commits, surface drift |
| pm-interview | `/pm-interview` | Prepare and debrief user interviews, update FEEDBACK.md |
| pm-standup | `/pm-standup` | Daily briefing — what shipped, today's priorities, blockers |
| pm-brainstorm | `/pm-brainstorm` | Jam with Nano, the expert CPO — informal, context-loaded, resumable sessions |
| pm-weekly-update | `/pm-weekly-update` | Draft stakeholder update email, adapted to audience |
| pm-data | `/pm-data` | Answer a product question with PostHog or Amplitude data |

## Architecture

Skills run across four phases: **Define** (vision-mission, business-model, org, product, personas) → **Discover** (competitors-intel, user-feedback, interview, data) → **Plan** (objectives, strategy, roadmap, prd) → **Build** (breakdown, retro), plus **Daily Ops** (challenge-me, standup, brainstorm, weekly-update) running on any day, outside the pipeline.

All skills source `lib/nanopm.sh` for shared runtime functions.
Each Define skill writes TWO files: the clean, share-ready doc (claims only) and a reasoning sidecar at `.nanopm/reasoning/<same filename>` carrying the Evidenced/Assumed calls, sources, and rationale. The path convention lives in `nanopm_reasoning_path` (lib) and `ReasoningFiles` (viewer/Models.swift) — change one, change both. The viewer opens the sidecar in a separate window from a "Reasoning" button on the clean doc's detail view, never as its own sidebar row.
After each Define skill, a subagent regenerates `.nanopm/CONTEXT-SUMMARY.md` — a one-page consolidated company + product brief. `nanopm_preamble` loads it (`nanopm_load_context`) into every skill run, so all downstream work shares one baseline and doesn't drift.
Symmetrically, after each Plan skill (objectives, strategy, roadmap) a subagent regenerates `.nanopm/PLAN-SUMMARY.md` — the current-work brief (the bet, the OKRs, the NOW items) — from the shared prompt in `nanopm_plan_brief_prompt`. `nanopm_preamble` loads it (`nanopm_load_plan`) right after the context brief, and the viewer renders it atop the Plan overview. The `PLAN-SUMMARY.md` → `.plan` mapping lives in `PhaseMapper` (viewer/Models.swift) — change the path convention in one, change both. Net effect: every skill run carries both briefs — who we are, and what we're working on right now.
The viewer can update the installed skill pack in place: it detects a newer version via the CLI's `nanopm_update_check` (so GUI and terminal never disagree) and re-runs `setup`. `setup` writes a provenance marker to `~/.nanopm/install-source` (the repo path for a local clone, `remote` for a curl install, `plugin` when bootstrapped by the Claude Code plugin) which the viewer reads (`UpdateChecker` in viewer/Sources/NanoPMViewer) to refuse the in-app update on a dev clone — change the marker contract in one, change both.
Claude Code can also install nanopm as a native plugin (`.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`), separate from and additive to the `curl | bash` installer — Vibe/Codex ignore these files and keep using `setup`. The plugin ships the skills directly (namespaced `/nanopm:<skill>`) and its `hooks/hooks.json` `SessionStart` hook runs `setup --deps-only` once per version to bootstrap the shared runtime into `~/.nanopm/` without re-installing skills into `~/.claude/skills/` (which would double-load every command). The skill roster and version therefore live in TWO places — `_SKILL_LIST` in `setup` and the `skills`/`version` fields in `plugin.json` — kept in lockstep by `test/plugin-manifest.sh`; change one, change both (and bump `plugin.json` version alongside `VERSION` on release).
State: `~/.nanopm/` (global config + memory), `.nanopm/` (per-project outputs, gitignored).
Data ingestion: MCP → API → browser → CONTEXT.md manual fallback.

## Development

```bash
./setup                   # auto-detect installed agents, install to all
./setup --host=claude     # Claude Code only → ~/.claude/skills/
./setup --host=vibe       # Mistral Vibe only → ~/.vibe/skills/
./setup --host=codex      # OpenAI Codex only → ~/.codex/skills/
./setup --host=all        # all paths including ~/.agents/skills/
./setup --deps-only       # plugin bootstrap: runtime only, no host skills (used by the SessionStart hook)
```

## Testing

```bash
bash test/skill-syntax.sh          # tier 1: static validation (free)
bash test/plugin-manifest.sh       # tier 1: plugin ⇄ setup parity (skills, version)
bash test/adversarial.e2e.sh       # tier 2: release gate 1
bash test/context-threading.e2e.sh # tier 2: release gate 2
```
