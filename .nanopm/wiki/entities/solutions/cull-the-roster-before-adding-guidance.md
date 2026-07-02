---
id: cull-the-roster-before-adding-guidance
type: solution
title: "Cull the roster before adding guidance"
opportunity: pipeline-sequence-opaque
status: shortlisted
lens: eng, business
appetite: small-bet
impact: high
provenance: assumed
linked_objectives: []
last_updated: 2026-07-01
---

## Pitch
Kill 3–5 skills instead of layering more guidance on top. The founder himself flagged `/pm-user-feedback` as "pointless in its current way of working"; audit the 24-skill surface and retire any skill that can't name the KR it serves — likely `/pm-user-feedback`, possibly `/pm-add-feedback` if downstream loaders don't read it, `/pm-data` if under-used. Ship nanopm 0.x with 14–16 skills, not 21–24. Menu paralysis and per-skill opacity shrink mechanically when the menu shrinks — and this is the only option that honors both "subtract before you add" and the founder's own kill-list.

## Riskiest assumption
The killed skills aren't load-bearing for a silent minority of runs — no cohort user is quietly depending on `/pm-user-feedback` outputs feeding a downstream skill's context.

## Cheapest test
Grep the codebase and `.nanopm/` context loaders for downstream dependencies on the kill-list skills; grep active users' repos + own dogfood repo for artifacts written by each candidate. Any skill with zero artifacts in 60 days AND zero references outside its own dir is a safe kill; deprecate with a one-week notice in the CHANGELOG. Half a day.

## Dissent/tension note
Eng: deletion cheap to code, expensive to reverse — if we cut wrong we lose weeks rebuilding. Business: culling mid-proof-quarter muddies the cross-matrix read (control-arm ran the 21-skill version, prototype-arm the 15-skill one).
