---
id: thread-opportunity-link
type: solution
title: "Thread the opportunity link through the existing PRD → breakdown → handoff chain"
opportunity: handoff-traceability-lost
status: shortlisted
provenance: assumed
lens: eng, business
appetite: small-bet
impact: high
linked_objectives: []
last_updated: 2026-06-28
---

## Pitch
Persist a single `opportunity_id` (a reference, not a copied string) through the carriers that already exist: add it to pm-prd's YAML frontmatter, propagate it into pm-breakdown's per-task `Ties to:` line and the `PRD:` header, and into the WORKFLOW.md handoff — alongside the typed-state decision.jsonl pm-prd/pm-breakdown already write. No new skill, no new surface, no migration: the spec stays tethered to the opportunity it serves, resolvable back to the live success metric. The cheapest structural fix, and the foundation every other option here builds on.

## Riskiest assumption
That a single threaded id is load-bearing — that the thread breaks from a missing field rather than from the solo maintainer (n=1) just not filling it or stubbing a junk id. Reference-by-id avoids the copied-metric-rots failure but trades it for dangling-reference risk if opportunities get renamed/merged.

## Cheapest test
On 2–3 existing PRDs, hand-add the `opportunity_id` line and re-run pm-breakdown; confirm the id survives into every task's `Ties to:` and into WORKFLOW.md with only field plumbing — and that at build time it answers "why am I building this" faster than grepping notes.

## Dissent/tension note
Eng/Business: cheapest structural fix, but a copied metric rots and the live bet is distribution-before-features — even a one-day plumbing change is a tax on the one July thing that matters.
