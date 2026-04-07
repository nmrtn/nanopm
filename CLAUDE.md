# nanopm

Autonomous PM skill pack for Claude Code. Replaces the PM workflow end-to-end.

## Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| pm-run | `/pm-run` | Full pipeline in one command |
| pm-discovery | `/pm-discovery` | Figure out WHAT to build — pre-planning discovery |
| pm-audit | `/pm-audit` | Deep product audit |
| pm-objectives | `/pm-objectives` | Define OKRs and anti-goals |
| pm-strategy | `/pm-strategy` | Strategy with structured adversarial challenge |
| pm-roadmap | `/pm-roadmap` | Outcome-driven roadmap |
| pm-prd | `/pm-prd` | Full PRD (or Shape Up pitch) |
| pm-breakdown | `/pm-breakdown` | Break PRD into tasks, create tickets in Linear / GitHub Issues |
| pm-retro | `/pm-retro` | Compare roadmap vs commits, surface drift |
| pm-interview | `/pm-interview` | Prepare and debrief user interviews, update FEEDBACK.md |
| pm-standup | `/pm-standup` | Daily briefing — what shipped, today's priorities, blockers |
| pm-weekly-update | `/pm-weekly-update` | Draft stakeholder update email, adapted to audience |

## Architecture

All skills source `lib/nanopm.sh` for shared runtime functions.
State: `~/.nanopm/` (global config + memory), `.nanopm/` (per-project outputs, gitignored).
Data ingestion: MCP → API → browser → CONTEXT.md manual fallback.

## Development

```bash
./setup          # install skills to ~/.claude/skills/nanopm/
./setup --local  # install to .claude/skills/nanopm/ (project-local)
```

## Testing

```bash
bash test/skill-syntax.sh          # tier 1: static validation (free)
bash test/adversarial.e2e.sh       # tier 2: release gate 1
bash test/context-threading.e2e.sh # tier 2: release gate 2
```
