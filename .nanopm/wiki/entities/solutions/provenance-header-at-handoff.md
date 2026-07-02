---
id: provenance-header-at-handoff
type: solution
title: "Auto-prepend a legible provenance header to the build handoff"
opportunity: handoff-traceability-lost
status: proposed
provenance: assumed
lens: design
appetite: small-bet
impact: high
linked_objectives: []
last_updated: 2026-06-27
---

## Pitch
At handoff, auto-prepend a five-line legible chain to the top of WORKFLOW.md (the file the builder reads first): Opportunity → Bet → Spec → Success metric → Falsification, each a one-clause plain-English claim with a clickable link back to its source wiki entity. Sam opens the handoff and sees the WHY before the WHAT — no re-derivation from memory at the exact moment they need to defend the build. Surfaces the pieces that already exist as one visible spine.

## Riskiest assumption
That Sam reads the top of WORKFLOW.md before diving into the task list — if they scroll straight to the tasks, a header above them is invisible and the legibility never lands.

## Cheapest test
Add the header to one real handoff, hand it to Sam cold a week later, and ask "why are we building this and what proves it worked?" — observe whether they answer from the doc or from memory.

## Dissent/tension note
Design: legibility only works if the chain is the first decision-relevant thing — a header risks becoming banner-blindness boilerplate Sam learns to skip. Depends on the threaded link existing (pairs with "thread the opportunity link").
