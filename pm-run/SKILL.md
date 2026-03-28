---
name: pm-run
version: 0.1.0
description: "Run the full nanopm PM pipeline: audit → objectives → strategy → roadmap → PRD. One command for a complete planning cycle. Each skill reads the prior output — the pipeline compounds."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, WebFetch
---

## Preamble (run first)

```bash
source ~/.claude/skills/nanopm/lib/nanopm.sh 2>/dev/null || \
  source .claude/skills/nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
```

## Overview

`/pm-run` runs the full PM planning pipeline in sequence:

```
/pm-audit → /pm-objectives → /pm-strategy → /pm-roadmap → /pm-prd
```

Each skill compounds on the last. The audit informs objectives. The strategy shapes the roadmap. The PRD flows from the roadmap.

This skill orchestrates the pipeline inline — you don't need to manually invoke each skill.

If you're not sure what to build yet, run `/pm-discovery` first. `/pm-run` assumes you know the product direction.

## Phase 0: Check existing artifacts

```bash
echo "=== Existing artifacts ==="
[ -f ".nanopm/AUDIT.md"      ] && echo "  AUDIT.md      ✓" || echo "  AUDIT.md      (will create)"
[ -f ".nanopm/OBJECTIVES.md" ] && echo "  OBJECTIVES.md ✓" || echo "  OBJECTIVES.md (will create)"
[ -f ".nanopm/STRATEGY.md"   ] && echo "  STRATEGY.md   ✓" || echo "  STRATEGY.md   (will create)"
[ -f ".nanopm/ROADMAP.md"    ] && echo "  ROADMAP.md    ✓" || echo "  ROADMAP.md    (will create)"
echo "  PRD:          (will create for first roadmap item)"
echo "========================="
```

If any artifacts already exist, tell the user: "Existing artifacts found — this run will refresh them. Prior context is preserved in memory and will inform the new outputs."

## Phase 1: Confirm pipeline

Ask via AskUserQuestion:

**"Ready to run the full PM pipeline for: {slug}**

This will:
1. **Audit** — 11 questions about your product (skip what's already answered)
2. **Objectives** — OKRs and anti-goals for this period
3. **Strategy** — strategic position + adversarial challenge
4. **Roadmap** — NOW/NEXT/LATER priorities
5. **PRD** — spec for the top NOW item

Takes 10-20 minutes depending on how much context you already have.

A) Run the full pipeline
B) Run audit only (stops after AUDIT.md)
C) Skip to strategy (assumes audit + objectives exist)
D) Cancel"

If B: run only pm-audit inline (Phases 2 below), then stop.
If C: skip to Phase 4 (strategy).
If D: exit.

## Phase 2: Run pm-audit inline

Read and follow `~/.claude/skills/nanopm/pm-audit/SKILL.md` inline, skipping:
- Its own "Preamble (run first)" (already sourced above)

Complete all phases of pm-audit through **Phase 8: Save context**.

After pm-audit completes: "✅ Audit complete. Moving to objectives..."

If user chose B: stop here. Output: "Pipeline stopped after audit. Run /pm-objectives to continue."

## Phase 3: Run pm-objectives inline

Read and follow `~/.claude/skills/nanopm/pm-objectives/SKILL.md` inline, skipping:
- Its own "Preamble (run first)"

Complete all phases through save context.

After pm-objectives completes: "✅ Objectives set. Moving to strategy..."

## Phase 4: Run pm-strategy inline

Read and follow `~/.claude/skills/nanopm/pm-strategy/SKILL.md` inline, skipping:
- Its own "Preamble (run first)"

Complete all phases through save context. This includes the adversarial challenge.

After pm-strategy completes: "✅ Strategy locked (adversarial review done). Moving to roadmap..."

## Phase 5: Run pm-roadmap inline

Read and follow `~/.claude/skills/nanopm/pm-roadmap/SKILL.md` inline, skipping:
- Its own "Preamble (run first)"

Complete all phases through save context.

After pm-roadmap completes: "✅ Roadmap built. Moving to PRD for top NOW item..."

## Phase 6: Run pm-prd inline

Read the roadmap NOW section and identify the top priority item. Run pm-prd for that item.

Read and follow `~/.claude/skills/nanopm/pm-prd/SKILL.md` inline, skipping:
- Its own "Preamble (run first)"

After pm-prd completes: "✅ PRD written."

## Phase 7: Pipeline summary

Output a summary table:

```
=== nanopm pipeline complete ===

  AUDIT.md      ✅  .nanopm/AUDIT.md
  OBJECTIVES.md ✅  .nanopm/OBJECTIVES.md
  STRATEGY.md   ✅  .nanopm/STRATEGY.md
  ROADMAP.md    ✅  .nanopm/ROADMAP.md
  PRD           ✅  .nanopm/PRD-{feature}.md

Key outputs:
  Strategic bet:   {one-line from STRATEGY.md}
  Top NOW item:    {first item from ROADMAP.md NOW}
  North star:      {key result from OBJECTIVES.md}

Next: /pm-breakdown to create tickets from the PRD
      /pm-retro after your next sprint to compare plan vs reality
================================
```

**STATUS: DONE**
