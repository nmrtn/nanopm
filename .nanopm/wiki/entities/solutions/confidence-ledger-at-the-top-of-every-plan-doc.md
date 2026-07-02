---
id: confidence-ledger-at-the-top-of-every-plan-doc
type: solution
title: "Confidence ledger at the top of every Plan doc"
opportunity: cant-tell-evidenced-from-assumed
status: proposed
provenance: assumed
lens: design, business
appetite: small-bet
impact: medium
linked_objectives: [run-proof-quarter-clean-read]
last_updated: 2026-06-29
---

## Pitch
Promote the `## Provenance & assumptions` section from the doc footer to the doc header, reformatted as a "Confidence ledger": a 3-row table (`evidence-backed N` / `user-stated N` / `nano-hypothesis N`) with the top-3 riskiest assumed claims quoted verbatim and a "Falsify this first" link to the cheapest test. The doc opens with its own self-critique before the prose. Business angle: the aggregate counts become a headline differentiator — a screenshot-able "confidence credit score" the README and prototype-cohort onboarding can point at. Zero inline noise, fully portable markdown — works identically in viewer and terminal `cat`, no host-specific affordance.

## Riskiest assumption
Theo reads top-down and actually internalises the ledger before the prose — rather than skipping past it the way everyone skips past README badges and TL;DRs.

## Cheapest test
A/B two `docs/roadmap.md` variants (ledger-on-top vs. footer-only) on Nico + 2 friendlies. 24h later ask "what was the riskiest claim in the roadmap?" Compare recall accuracy.

## Dissent/tension note
A header ledger front-loads doubt — it may undermine the "this is a real plan worth committing to" affordance and push users back to ChatGPT precisely because the doc itself looks unsure of itself. Business view: a score without inline tags risks being theatre — a number Theo distrusts more than the prose.
