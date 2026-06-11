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
| pm-audit | `/pm-audit` | Deep product audit |
| pm-objectives | `/pm-objectives` | Define OKRs and anti-goals |
| pm-strategy | `/pm-strategy` | Strategy with structured adversarial challenge |
| pm-roadmap | `/pm-roadmap` | Outcome-driven roadmap |
| pm-prd | `/pm-prd` | Full PRD (or Shape Up pitch) |
| pm-breakdown | `/pm-breakdown` | Break PRD into tasks, hand off to Linear / GitHub / OpenSpec / gstack / Human |
| pm-retro | `/pm-retro` | Compare roadmap vs commits, surface drift |
| pm-interview | `/pm-interview` | Prepare and debrief user interviews, update FEEDBACK.md |
| pm-standup | `/pm-standup` | Daily briefing — what shipped, today's priorities, blockers |
| pm-weekly-update | `/pm-weekly-update` | Draft stakeholder update email, adapted to audience |
| pm-data | `/pm-data` | Answer a product question with PostHog or Amplitude data |

## Architecture

Skills run across four phases: **Define** (vision-mission, business-model, org, product, personas, audit) → **Discover** (competitors-intel, user-feedback, interview, data) → **Plan** (objectives, strategy, roadmap, prd) → **Build** (breakdown, retro).

All skills source `lib/nanopm.sh` for shared runtime functions.
State: `~/.nanopm/` (global config + memory), `.nanopm/` (per-project outputs, gitignored).
Data ingestion: MCP → API → browser → CONTEXT.md manual fallback.

## Development

```bash
./setup                   # auto-detect installed agents, install to all
./setup --host=claude     # Claude Code only → ~/.claude/skills/
./setup --host=vibe       # Mistral Vibe only → ~/.vibe/skills/
./setup --host=codex      # OpenAI Codex only → ~/.codex/skills/
./setup --host=all        # all paths including ~/.agents/skills/
```

## Testing

```bash
bash test/skill-syntax.sh          # tier 1: static validation (free)
bash test/adversarial.e2e.sh       # tier 2: release gate 1
bash test/context-threading.e2e.sh # tier 2: release gate 2
```
