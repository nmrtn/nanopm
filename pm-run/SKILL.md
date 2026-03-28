---
name: pm-run
version: 0.2.0
description: "Run the full nanopm PM pipeline: feedback → audit → objectives → strategy → roadmap → PRD. One command for a complete planning cycle. Each skill reads the prior output — the pipeline compounds."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, WebFetch
---

## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
```

## Overview

`/pm-run` runs the full PM planning pipeline in sequence:

```
/pm-user-feedback → /pm-audit → /pm-objectives → /pm-strategy → /pm-roadmap → /pm-prd
```

Each skill compounds on the last. Feedback grounds the audit in real user signal. The audit informs objectives. The strategy shapes the roadmap. The PRD flows from the roadmap and quotes directly from user feedback.

This skill orchestrates the pipeline inline — you don't need to manually invoke each skill.

If you're not sure what to build yet, run `/pm-discovery` first. `/pm-run` assumes you know the product direction.

## Phase 0: Check existing artifacts

```bash
echo "=== Existing artifacts ==="
[ -f ".nanopm/FEEDBACK.md"   ] && echo "  FEEDBACK.md   ✓" || echo "  FEEDBACK.md   (will create)"
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
1. **Feedback** — pull from Dovetail, Productboard, Notion, Linear, GitHub (or manual paste)
2. **Audit** — 11 questions about your product (Q6 pre-filled from feedback)
3. **Objectives** — OKRs anchored to top feedback themes
4. **Strategy** — strategic position + adversarial challenge
5. **Roadmap** — NOW/NEXT/LATER with signal-backed priority markers
6. **PRD** — spec for the top NOW item, with real user quotes

Takes 15-25 minutes depending on how much context you already have.

A) Run the full pipeline (Recommended)
B) Skip feedback collection — run audit → PRD only
C) Feedback only (stops after FEEDBACK.md)
D) Skip to strategy (assumes feedback + audit + objectives exist)
E) Cancel"

If B: skip Phase 2 (feedback), run Phases 3–7.
If C: run only pm-user-feedback inline (Phase 2), then stop.
If D: skip to Phase 5 (strategy).
If E: exit.

## Phase 2: Run pm-user-feedback inline

Read and follow `~/.claude/skills/pm-user-feedback/SKILL.md` inline, skipping:
- Its own "Preamble (run first)" (already sourced above)

Complete all phases through **Phase 6: Save context**.

After pm-user-feedback completes: "✅ Feedback collected. Moving to audit..."

If user chose C: stop here. Output: "Pipeline stopped after feedback. Run /pm-audit to continue."

## Phase 3: Run pm-audit inline

Read and follow `~/.claude/skills/pm-audit/SKILL.md` inline, skipping:
- Its own "Preamble (run first)" (already sourced above)

Complete all phases of pm-audit through **Phase 7: Save context**.

After pm-audit completes: "✅ Audit complete. Moving to objectives..."

If user chose B: stop here. Output: "Pipeline stopped after audit. Run /pm-objectives to continue."

## Phase 4: Run pm-objectives inline

Read and follow `~/.claude/skills/pm-objectives/SKILL.md` inline, skipping:
- Its own "Preamble (run first)"

Complete all phases through save context.

After pm-objectives completes: "✅ Objectives set. Moving to strategy..."

## Phase 5: Run pm-strategy inline

Read and follow `~/.claude/skills/pm-strategy/SKILL.md` inline, skipping:
- Its own "Preamble (run first)"

Complete all phases through save context. This includes the adversarial challenge.

After pm-strategy completes: "✅ Strategy locked (adversarial review done). Moving to roadmap..."

## Phase 6: Run pm-roadmap inline

Read and follow `~/.claude/skills/pm-roadmap/SKILL.md` inline, skipping:
- Its own "Preamble (run first)"

Complete all phases through save context.

After pm-roadmap completes: "✅ Roadmap built. Moving to PRD for top NOW item..."

## Phase 7: Run pm-prd inline

Read the roadmap NOW section and identify the top priority item. Run pm-prd for that item.

Read and follow `~/.claude/skills/pm-prd/SKILL.md` inline, skipping:
- Its own "Preamble (run first)"

After pm-prd completes: "✅ PRD written."

## Phase 8: Pipeline summary

Output a summary table:

```
=== nanopm pipeline complete ===

  FEEDBACK.md   ✅  .nanopm/FEEDBACK.md
  AUDIT.md      ✅  .nanopm/AUDIT.md
  OBJECTIVES.md ✅  .nanopm/OBJECTIVES.md
  STRATEGY.md   ✅  .nanopm/STRATEGY.md
  ROADMAP.md    ✅  .nanopm/ROADMAP.md
  PRD           ✅  .nanopm/PRD-{feature}.md

Key outputs:
  Top user signal: {top unaddressed theme from FEEDBACK.md}
  Strategic bet:   {one-line from STRATEGY.md}
  Top NOW item:    {first item from ROADMAP.md NOW}
  North star:      {key result from OBJECTIVES.md}

Next: /pm-breakdown to create tickets from the PRD
      /pm-competitors-intel to monitor what competitors shipped this cycle
      /pm-retro after your next sprint to compare plan vs reality
================================
```

**STATUS: DONE**
