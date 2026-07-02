# PRD: Debounce + de-block the overview brief regeneration
Hand-drafted 2026-06-24 (gates not executed)
Project: nanopm
Status: PROPOSED — NOW

## Problem
`company.md` is regenerated after EVERY Define skill; `current-work.md` after EVERY Plan skill (`nanopm_plan_brief_prompt`, lib/nanopm.sh:826) — each via a **blocking Agent subagent on the critical path**. Run the Define phase (5 skills) and the company brief regenerates 5×; run the Plan pipeline and the plan brief regenerates 3×. Each regen re-reads the same source docs to produce a ~1-page brief. It's idempotent, so it's safe — but it's wasteful subagent spend and latency, and `/pm-run` (the most-run path) pays it in full, sequentially, while the user waits.

## Scope
### In scope
- **Debounce:** in a multi-skill pipeline (`pm-run`), regenerate each brief **once at the end**, not after every constituent skill.
- **De-block:** dispatch the regen so it doesn't sit on the user-visible critical path where avoidable — e.g. coalesce, or mark the brief stale and regenerate via the queued/sleep path.
- Single-skill runs keep regenerating once at the end, as today (no behavior change for the common case).
### Out of scope
- Changing the regen prompt or the brief's output shape (`nanopm_plan_brief_prompt` + the inline Define regen stay identical).
- Changing what counts as "stale" / what triggers a regen.

## Success criteria
- Running `/pm-run` end-to-end regenerates each brief **exactly once** (not once per constituent skill), verified in the transcript.
- The brief is never older than the last Define/Plan write that feeds it (no stale-brief regression introduced by the debounce).

## Ties to
- Parent: memory-wiki-redesign / plan-summary.
- Strategy/Objective: pure efficiency on the most-run path — cuts redundant subagent calls and wait time with zero change to output.
