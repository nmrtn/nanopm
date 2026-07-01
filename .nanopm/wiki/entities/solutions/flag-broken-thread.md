---
id: flag-broken-thread
type: solution
title: "Detect and flag a broken thread at handoff (warn-first, optional gate)"
opportunity: handoff-traceability-lost
status: proposed
provenance: assumed
lens: eng, design
appetite: small-bet
impact: medium
linked_objectives: []
last_updated: 2026-06-27
---

## Pitch
Make the link an invariant, not a convention: when pm-breakdown runs, walk the chain (opportunity → PRD → success metric → falsification) and flag any missing or unresolvable link inline in WORKFLOW.md — "⚠ this spec's success metric isn't tied to any opportunity behavior-change" — reusing the existing tier-1 static-validation harness. Warn-first so it never blocks exploratory specs; promotable to a hard gate if "no opportunity" proves rare. Surfaces absence — the failure mode the JTBD actually names — the moment it happens, not post-launch.

## Riskiest assumption
That "tethered vs drifted" is mechanically detectable (does the `Ties to:` link resolve? does a success metric exist?) rather than a semantic judgment only Sam can make — and that a solo builder won't stub a fake id to silence a hard gate.

## Cheapest test
Hand-audit 5 past PRDs for whether their metric traces to an opportunity, then check whether a dumb structural rule would have flagged the same ones; run it warn-only for a week and count legitimate "no opportunity yet" vs simply-omitted id.

## Dissent/tension note
Eng/Design: a hard gate fights the distribution-before-features bet and gets routed around; a noisy warning gets suppressed — a silenced guardrail is worse than none.
