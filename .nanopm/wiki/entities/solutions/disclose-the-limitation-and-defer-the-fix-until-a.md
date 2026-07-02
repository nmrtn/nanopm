---
id: disclose-the-limitation-and-defer-the-fix-until-a
type: solution
title: "Disclose the limitation and defer the fix until a cohort user names it"
opportunity: a-skill-run-launched-from-the-viewer-loses-its-wor
status: proposed
provenance: assumed
lens: business
appetite: small-bet
impact: medium
linked_objectives: []
last_updated: 2026-06-29
---

## Pitch
Touch no run code. Instead, disclose "a run can be interrupted and you may lose work" as an explicit known limitation of the prototype, and write the deferral down in the objectives anti-goal list with a falsifiable revisit trigger ("when a recruited prototype-arm user names lost-run recovery as why they didn't return, OR both arms read PASS"). Treat any interruption as a recruited-cohort observation. This keeps the quarter's only scarce resource — two people's time — pointed at recruitment (0/10 in both arms), not at a founder-only bug no external user has reported, and stops the team re-litigating the fix every time it bites in dogfooding.

## Riskiest assumption
That a mid-run quit is rare enough in real cohort use that disclosing it costs less retention than the engineering time to fix it would cost in recruitment delay — and that the team can actually hold the line on a bug they personally hit every week.

## Cheapest test
Ship to the first 2-3 recruited prototype users with the one-line disclosure; count how many hit an interrupted run in their first pipeline. Zero hits in 3 users = the fix was never on the critical path.

## Dissent/tension note
Business (self-dissent): a deferral note does nothing for the actual prototype-arm user who loses a run next week — it optimizes founder focus at the possible cost of a real cohort member's first impression.
