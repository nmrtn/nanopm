---
name: pm-run
version: 0.2.0
description: "Run the full nanopm PM pipeline: feedback → personas → challenges → objectives → strategy → roadmap → PRD. One command for a complete planning cycle. Each skill reads the prior output — the pipeline compounds."
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
[Define]   /pm-vision-mission → /pm-business-model → /pm-org → /pm-product
[Discover] /pm-user-feedback
[Define]   /pm-personas → /pm-challenge-me
[Plan]     /pm-objectives → /pm-strategy → /pm-roadmap
[Build]    /pm-prd
```

Each skill compounds on the last. **Define** establishes the ground truth first — the company (vision, business model, org) and the product map. Feedback grounds everything in real user signal. Personas crystallize who you're building for; the challenge session forms the first judgment against the now-stated context. Objectives, strategy, and roadmap plan on top; the PRD flows from the roadmap, targets the primary persona, and quotes user feedback.

This skill orchestrates the pipeline inline — you don't need to manually invoke each skill.

Establishing Define context first is the **strong default, not a gate** — you can skip it (Phase 0b) and the pipeline still runs, with downstream skills warning when context is thin. Each Define skill auto-detects its mode (map an existing codebase/site vs. define from scratch), so the same flow works whether you have a product or are starting greenfield. For deeper opportunity exploration before planning, `/pm-discovery` remains available separately.

## Phase 0: Check existing artifacts

```bash
echo "=== Existing artifacts ==="
[ -f ".nanopm/PRODUCT.md"    ] && echo "  PRODUCT.md    ✓" || echo "  PRODUCT.md    (will create)"
[ -f ".nanopm/FEEDBACK.md"   ] && echo "  FEEDBACK.md   ✓" || echo "  FEEDBACK.md   (will create)"
[ -f ".nanopm/PERSONAS.md"   ] && echo "  PERSONAS.md   ✓" || echo "  PERSONAS.md   (will create)"
_CHALLENGES=".nanopm/CHALLENGES.md"; [ -f "$_CHALLENGES" ] || _CHALLENGES=".nanopm/AUDIT.md"  # legacy pre-rename name
[ -f "$_CHALLENGES" ] && echo "  CHALLENGES.md ✓" || echo "  CHALLENGES.md (will create)"
[ -f ".nanopm/OBJECTIVES.md" ] && echo "  OBJECTIVES.md ✓" || echo "  OBJECTIVES.md (will create)"
[ -f ".nanopm/STRATEGY.md"   ] && echo "  STRATEGY.md   ✓" || echo "  STRATEGY.md   (will create)"
[ -f ".nanopm/ROADMAP.md"    ] && echo "  ROADMAP.md    ✓" || echo "  ROADMAP.md    (will create)"
echo "  PRD:          (will create for first roadmap item)"
echo "========================="
```

If any artifacts already exist, tell the user: "Existing artifacts found — this run will refresh them. Prior context is preserved in memory and will inform the new outputs."

## Phase 0b: Establish Define context (advisory)

The **Define** phase establishes the ground truth the rest of the pipeline reads — the company
(vision/mission, business model, org) and the product map. This is the strong default but **not a
gate**: the user can skip it. Each Define skill auto-detects its mode, so this works for an existing
product or a greenfield idea.

**Skip this phase if** PRODUCT.md already exists — Define context is established, proceed to Phase 1.

**If PRODUCT.md is missing**, ask via AskUserQuestion before anything else.

- **question:** "Start by establishing your company & product context? (Recommended — the rest of the pipeline plans on top of it.)"
- **header:** `Start` (must be ≤12 chars — Mistral Vibe constraint)
- **multiSelect:** false
- **options:**
  - A) "Yes, establish context" (Recommended) — run the Define skills first.
  - B) "Just the product map" — run only `/pm-product`, skip the company docs.
  - C) "Skip — I'll plan directly" — jump to the pipeline; downstream skills warn if context is thin.

If A: run inline, in order, skipping each one's "Preamble (run first)": `$(nanopm_skill_path pm-vision-mission)`, `$(nanopm_skill_path pm-business-model)`, `$(nanopm_skill_path pm-org)`, then `$(nanopm_skill_path pm-product)`. After each: "✅ {DOC}.md written." Then: "✅ Define context established. Moving to feedback..."
If B: run only `$(nanopm_skill_path pm-product)` inline (skip its preamble). After it completes: "✅ Product mapped. Moving to feedback..."
If C: proceed directly to Phase 1. (Personas + challenge session in Phases 2b/3 still run; they degrade gracefully without the company docs.)

## Phase 1: Confirm pipeline

Ask via AskUserQuestion.

- **question:** "Ready to run the full PM pipeline for {slug}? It will run feedback → personas → challenges → objectives → strategy → roadmap → PRD. Takes 15-25 min."
- **header:** `Pipeline` (must be ≤12 chars — Mistral Vibe constraint)
- **multiSelect:** false
- **options:**
  - A) "Run full pipeline" (Recommended)
  - B) "Skip feedback" — challenges → PRD only
  - C) "Feedback only" — stops after FEEDBACK.md
  - D) "Skip to strategy" — assumes feedback + challenges + objectives exist
  - E) "Cancel"

If B: skip Phase 2 (feedback), but still run Phase 2b (personas) and Phases 3–7.
If C: run only pm-user-feedback inline (Phase 2), then stop.
If D: skip to Phase 5 (strategy).
If E: exit.

## Phase 2: Run pm-user-feedback inline

Read and follow `$(nanopm_skill_path pm-user-feedback)` inline, skipping:
- Its own "Preamble (run first)" (already sourced above)

Complete all phases through **Phase 6: Save context**.

After pm-user-feedback completes: "✅ Feedback collected. Moving to the challenge session..."

If user chose C: stop here. Output: "Pipeline stopped after feedback. Run /pm-personas or /pm-challenge-me to continue."

## Phase 2b: Run pm-personas inline

Read and follow `$(nanopm_skill_path pm-personas)` inline, skipping:
- Its own "Preamble (run first)" (already sourced above)

pm-personas auto-detects its mode: it reverse-engineers the personas from the codebase plus any artifacts already produced this run (PRODUCT.md and FEEDBACK.md, and DISCOVERY.md if present), then confirms them with you. Complete all phases through **save context**.

After pm-personas completes: "✅ Personas defined. Moving to the challenge session..."

## Phase 3: Run pm-challenge-me inline

Read and follow `$(nanopm_skill_path pm-challenge-me)` inline, skipping:
- Its own "Preamble (run first)" (already sourced above)

Complete all phases of pm-challenge-me through **Phase 7: Save context**.

After pm-challenge-me completes: "✅ Challenge session complete. Moving to objectives..."

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
  CHALLENGES.md ✅  .nanopm/CHALLENGES.md
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
