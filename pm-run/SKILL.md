---
name: pm-run
version: 0.2.0
description: "Run the full nanopm PM pipeline: feedback → personas → audit → objectives → strategy → roadmap → PRD. One command for a complete planning cycle. Each skill reads the prior output — the pipeline compounds."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, WebFetch
---

<!-- portability-v2 -->
> **Multi-host portability rules.** When invoking `AskUserQuestion`:
> 1. The `header` field MUST be a short noun phrase (≤ 12 characters). Mistral Vibe
>    rejects longer headers with `string_too_long`. Pick from: `Start`, `Target`,
>    `Scope`, `Audience`, `Methodology`, `Feature`, `Question`.
> 2. The `options` list MUST have at least 2 items. Vibe rejects empty/single-option
>    calls. For free-text input, always provide ≥ 2 framing options (e.g. `Yes, here's the input` /
>    `Skip`) — never call `ask_user_question` with `options: []`.


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
/pm-user-feedback → /pm-personas → /pm-audit → /pm-objectives → /pm-strategy → /pm-roadmap → /pm-prd
```

Each skill compounds on the last. Feedback grounds the audit in real user signal. Personas crystallize who you're building for, sharpening the audit's "who for" and every downstream prioritization. The audit informs objectives. The strategy shapes the roadmap. The PRD flows from the roadmap, targets the primary persona, and quotes directly from user feedback.

This skill orchestrates the pipeline inline — you don't need to manually invoke each skill.

If you're not sure what to build yet, run `/pm-discovery` first. `/pm-run` assumes you know the product direction.

## Phase 0: Check existing artifacts

```bash
echo "=== Existing artifacts ==="
[ -f ".nanopm/SCAN.md"       ] && echo "  SCAN.md       ✓" || echo "  SCAN.md       (none)"
[ -f ".nanopm/FEEDBACK.md"   ] && echo "  FEEDBACK.md   ✓" || echo "  FEEDBACK.md   (will create)"
[ -f ".nanopm/PERSONAS.md"   ] && echo "  PERSONAS.md   ✓" || echo "  PERSONAS.md   (will create)"
[ -f ".nanopm/AUDIT.md"      ] && echo "  AUDIT.md      ✓" || echo "  AUDIT.md      (will create)"
[ -f ".nanopm/OBJECTIVES.md" ] && echo "  OBJECTIVES.md ✓" || echo "  OBJECTIVES.md (will create)"
[ -f ".nanopm/STRATEGY.md"   ] && echo "  STRATEGY.md   ✓" || echo "  STRATEGY.md   (will create)"
[ -f ".nanopm/ROADMAP.md"    ] && echo "  ROADMAP.md    ✓" || echo "  ROADMAP.md    (will create)"
echo "  PRD:          (will create for first roadmap item)"
echo "========================="
```

If any artifacts already exist, tell the user: "Existing artifacts found — this run will refresh them. Prior context is preserved in memory and will inform the new outputs."

## Phase 0b: Starting point

**Skip this phase if** SCAN.md, AUDIT.md, or DISCOVERY.md already exist — context is established, proceed to Phase 1.

**If none exist**, ask via AskUserQuestion before anything else.

- **question:** "How are you starting?"
- **header:** `Start` (must be ≤12 chars — Mistral Vibe constraint)
- **multiSelect:** false
- **options:**
  - A) "Existing project" — code already exists. Run pm-scan first.
  - B) "Greenfield" — nothing built. Run pm-discovery first.
  - C) "Skip to audit" — I know what I'm building.

If A: run pm-scan inline (read and follow `$(nanopm_skill_path pm-scan)`, skipping its preamble) before Phase 2. After scan completes: "✅ Codebase scanned. Moving to feedback..."
If B: run pm-discovery inline (read and follow `$(nanopm_skill_path pm-discovery)`, skipping its preamble) before Phase 2. After discovery completes: "✅ Discovery done. Moving to feedback..."
If C: proceed directly to Phase 1.

## Phase 1: Confirm pipeline

Ask via AskUserQuestion.

- **question:** "Ready to run the full PM pipeline for {slug}? It will run feedback → personas → audit → objectives → strategy → roadmap → PRD. Takes 15-25 min."
- **header:** `Pipeline` (must be ≤12 chars — Mistral Vibe constraint)
- **multiSelect:** false
- **options:**
  - A) "Run full pipeline" (Recommended)
  - B) "Skip feedback" — audit → PRD only
  - C) "Feedback only" — stops after FEEDBACK.md
  - D) "Skip to strategy" — assumes feedback + audit + objectives exist
  - E) "Cancel"

If B: skip Phase 2 (feedback), but still run Phase 2b (personas) and Phases 3–7.
If C: run only pm-user-feedback inline (Phase 2), then stop.
If D: skip to Phase 5 (strategy).
If E: exit.

## Phase 2: Run pm-user-feedback inline

Read and follow `$(nanopm_skill_path pm-user-feedback)` inline, skipping:
- Its own "Preamble (run first)" (already sourced above)

Complete all phases through **Phase 6: Save context**.

After pm-user-feedback completes: "✅ Feedback collected. Moving to audit..."

If user chose C: stop here. Output: "Pipeline stopped after feedback. Run /pm-personas or /pm-audit to continue."

## Phase 2b: Run pm-personas inline

Read and follow `$(nanopm_skill_path pm-personas)` inline, skipping:
- Its own "Preamble (run first)" (already sourced above)

pm-personas auto-detects its mode: it reverse-engineers the personas from the codebase plus any artifacts already produced this run (FEEDBACK.md, and SCAN.md / DISCOVERY.md if present), then confirms them with you. Complete all phases through **save context**.

After pm-personas completes: "✅ Personas defined. Moving to audit..."

## Phase 3: Run pm-audit inline

Read and follow `$(nanopm_skill_path pm-audit)` inline, skipping:
- Its own "Preamble (run first)" (already sourced above)

Complete all phases of pm-audit through **Phase 7: Save context**.

After pm-audit completes: "✅ Audit complete. Moving to objectives..."

If user chose B: stop here. Output: "Pipeline stopped after audit. Run /pm-objectives to continue."

## Phase 4: Run pm-objectives inline

Read and follow `$(nanopm_skill_path pm-objectives)` inline, skipping:
- Its own "Preamble (run first)"

Complete all phases through save context.

After pm-objectives completes: "✅ Objectives set. Moving to strategy..."

## Phase 5: Run pm-strategy inline

Read and follow `$(nanopm_skill_path pm-strategy)` inline, skipping:
- Its own "Preamble (run first)"

Complete all phases through save context. This includes the adversarial challenge.

After pm-strategy completes: "✅ Strategy locked (adversarial review done). Moving to roadmap..."

## Phase 6: Run pm-roadmap inline

Read and follow `$(nanopm_skill_path pm-roadmap)` inline, skipping:
- Its own "Preamble (run first)"

Complete all phases through save context.

After pm-roadmap completes: "✅ Roadmap built. Moving to PRD for top NOW item..."

## Phase 7: Run pm-prd inline

Read the roadmap NOW section and identify the top priority item. Run pm-prd for that item.

Read and follow `$(nanopm_skill_path pm-prd)` inline, skipping:
- Its own "Preamble (run first)"

After pm-prd completes: "✅ PRD written."

## Phase 8: Pipeline summary

Output a summary table:

```
=== nanopm pipeline complete ===

  FEEDBACK.md   ✅  .nanopm/FEEDBACK.md
  PERSONAS.md   ✅  .nanopm/PERSONAS.md
  AUDIT.md      ✅  .nanopm/AUDIT.md
  OBJECTIVES.md ✅  .nanopm/OBJECTIVES.md
  STRATEGY.md   ✅  .nanopm/STRATEGY.md
  ROADMAP.md    ✅  .nanopm/ROADMAP.md
  PRD           ✅  .nanopm/prds/{feature}.md

Key outputs:
  Top user signal: {top unaddressed theme from FEEDBACK.md}
  Primary persona: {primary persona handle from PERSONAS.md}
  Strategic bet:   {one-line from STRATEGY.md}
  Top NOW item:    {first item from ROADMAP.md NOW}
  North star:      {key result from OBJECTIVES.md}

Next: /pm-breakdown to create tickets from the PRD
      /pm-competitors-intel to monitor what competitors shipped this cycle
      /pm-retro after your next sprint to compare plan vs reality
================================
```

**STATUS: DONE**
