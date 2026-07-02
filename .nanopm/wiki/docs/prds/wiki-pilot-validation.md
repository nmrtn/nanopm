# PRD: Validate the personas ingest pilot before fanning out
Hand-drafted 2026-06-24 (gates not executed)
Project: nanopm
Status: PROPOSED — NOW (learning gate, not a build)

## Problem
Memory-wiki Phase 2 (#111) wired exactly ONE entity into the ingest loop: personas. The load-bearing bet of the whole redesign — that an entity page *compounds* (gets richer, dedupes by citation, supersedes old claims cleanly) as multiple sources touch it — is unvalidated in real runs. The README itself concedes ingest quality "depends on real source volume." Wiring the remaining Define entity skills (pm-org→people, pm-product→features) and the other signal skills now multiplies a mechanism whose sign we haven't observed. The Phase 2 commit message says it plainly: "proves fuel enters the engine on one entity before fanning out." This PRD is that proof step — look at the fuel actually combusting before building more pipes.

## Scope
### In scope
- Run the personas ingest on a source-rich project: ≥3 sources touching the same persona (e.g. an interview via /pm-interview + a /pm-user-feedback pull + a /pm-data run).
- Read the generated `.nanopm/wiki/entities/personas/<slug>.md`. Assess whether the page *integrates* (richer across sources, citation-deduped, old claims superseded with provenance kept) or *degrades* (near-duplicate citations, unresolved contradictions, bloat).
- Write a one-page findings note + an explicit go / no-go decision on fanning out, naming any failure modes with file evidence so the next wiring round fixes the engine first.
### Out of scope
- Building any new ingest wiring (gated by this finding).
- Changing the ingest/gate engine — fixes are downstream of what this observes.

## Success criteria
- A written go/no-go decision, backed by reading ≥1 real persona page touched by ≥3 sources.
- If "no-go," the specific failure modes are named with `.nanopm/wiki/` file evidence, so they become the next round's fix-list rather than a vague "it didn't feel right."

## Ties to
- Parent: memory-wiki-redesign (this is the Phase 2 pilot's validation gate).
- Strategy/Objective: directly expresses the roadmap's own discipline — "don't build the 16th connector before the loop retains" — applied to the wiki. Cheapest possible way to learn whether the entity-page bet holds.
