# Contributing to nanopm

Thanks for wanting to make nanopm better. Whether you're fixing a typo in a skill prompt, adding a connector, or building an entirely new workflow, this guide will get you up and running fast.

---

## Quick start

nanopm skills are Markdown files (`SKILL.md`) that Claude Code discovers from `~/.claude/skills/nanopm/`. When developing, you want Claude Code to use skills from your working tree so edits take effect instantly without reinstalling.

```bash
git clone https://github.com/nmrtn/nanopm && cd nanopm

# Symlink your checkout into the current project so Claude Code reads from it live
ln -sfn "$(pwd)" ~/.claude/skills/nanopm
```

Now edit any `pm-*/SKILL.md`, invoke it in Claude Code (e.g. `/pm-audit`), and your changes are live immediately. No reinstall needed.

To go back to a clean install from the registry:

```bash
rm ~/.claude/skills/nanopm   # remove the symlink
curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash
```

---

## How it works

### Skills

Each skill lives in its own directory:

```
pm-audit/
└── SKILL.md        ← the entire skill: prompt + instructions for Claude

pm-strategy/
└── SKILL.md

lib/
└── nanopm.sh       ← shared bash helpers (memory read/write, staleness check, etc.)
```

`SKILL.md` is the source of truth — edit it directly. There are no templates or build steps.

The preamble at the top of each `SKILL.md` follows a consistent pattern:

```markdown
---
description: What this skill does
---

## Preamble

Read `lib/nanopm.sh` for shared helpers.
Load memory from `~/.nanopm/memory/{project}.jsonl` if it exists.

## Instructions

[skill-specific instructions for Claude]
```

The `lib/nanopm.sh` preamble line tells Claude to load shared helpers automatically — keep it in every skill.

### Memory

Every skill appends structured entries to `~/.nanopm/memory/{project}.jsonl` after each run. The next skill in the pipeline reads this file to understand what was tried before. This is what makes context compound across sessions.

### Connectors

Connectors tell skills how to pull data from external tools (Linear, Notion, GitHub, Dovetail). Each connector is a single markdown file in `connectors/` describing the integration tiers (MCP → API → browser → manual).

---

## Adding a skill

1. Copy an existing skill as a starting point:
   ```bash
   cp -r pm-audit pm-myskill
   ```
2. Edit `pm-myskill/SKILL.md` — update the description, instructions, and output artifact name.
3. Keep the `lib/nanopm.sh` preamble and the memory read/write pattern from the original.
4. Add your new skill to the pipeline table in `README.md`.
5. Test it: invoke `/pm-myskill` in Claude Code on a real project.

---

## Adding a connector

A connector is a single markdown file:

```bash
connectors/myservice.md
```

Follow the tier pattern from `connectors/README.md`:

| Tier | How | Notes |
|------|-----|-------|
| 1 — MCP | Direct tool calls | `mcp__myservice__*` |
| 2 — API | REST/GraphQL | `MYSERVICE_API_KEY` env var |
| 3 — Browser | Headless scrape | Sign in once in browser |
| 4 — Manual | User fills it in | Always works |

Skills try each tier in order and use the highest available — no setup required from users who only want tier 4.

---

## Testing

```bash
bash test/skill-syntax.sh           # static checks — validates SKILL.md structure (free, <5s)
bash test/context-threading.e2e.sh  # context plumbing between skills (needs claude CLI)
bash test/website-bootstrap.e2e.sh  # browser tier connector scenarios
bash test/adversarial.e2e.sh        # adversarial subagent gate (needs claude CLI, ~$0.10/run)
```

Always run `skill-syntax.sh` before opening a PR — it's free and catches structural issues fast.

---

## The contributor workflow

1. **Symlink your checkout** into the project where you felt the pain (see Quick start)
2. **Fix the issue** — changes are live immediately in Claude Code
3. **Test by actually using the skill** — do the thing that annoyed you, verify it's fixed
4. **Run `bash test/skill-syntax.sh`** to catch any structural issues
5. **Open a PR from your fork**

This is the recommended way to contribute: fix nanopm while doing your real work, in the project where you actually felt the pain.

---

## Things to know

- **SKILL.md files are edited directly.** No build step, no templates. What you see is what Claude reads.
- **`lib/nanopm.sh` is shared.** If you add a helper there, all skills get it. Document it with a comment.
- **Memory is append-only.** Don't design skills that overwrite `~/.nanopm/memory/` entries — append new ones with a timestamp so history is preserved.
- **Staleness warnings are automatic.** `lib/nanopm.sh` emits a warning when `AUDIT.md` or `STRATEGY.md` is more than 20 commits old. Don't suppress this in new skills.
- **Tier 4 (manual) must always work.** Every connector skill must degrade gracefully to "ask the user to paste it in". Never hard-require an API key or MCP setup.

---

## Shipping your changes

When you're happy with your edits:

```bash
/ship
```

This reviews the diff, bumps the version, updates CHANGELOG.md, and opens a PR.
