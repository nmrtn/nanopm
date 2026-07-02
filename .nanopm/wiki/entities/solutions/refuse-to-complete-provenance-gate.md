---
id: refuse-to-complete-provenance-gate
type: solution
title: "Refuse-to-complete provenance gate (contractual, not display)"
opportunity: cant-tell-evidenced-from-assumed
status: proposed
provenance: assumed
lens: business
appetite: big-bet
impact: high
linked_objectives: [run-proof-quarter-clean-read]
last_updated: 2026-06-29
---

## Pitch
Make provenance a contractual gate, not a display feature. Extend the existing adversarial subagent gates that already fire on strategy / roadmap / PRD so they will NOT complete generation unless every load-bearing claim carries one of the fixed provenance tags (`nano-hypothesis` | `user-stated` | `evidence-backed`) AND the doc's evidenced-ratio clears a per-artifact floor (e.g. strategy ≥40% `evidence-backed` or `user-stated`). The product literally refuses to hand Theo a vibes-doc — the falsifiability-enforcing typed PM state layer the strategy doc names as structurally uncopyable, made visible at the point of generation rather than after.

## Riskiest assumption
Theo prefers a doc that refuses to ship over a doc that ships with caveats. A hard gate could feel like the tool is broken / nagging, and he just disables it or switches back to ChatGPT where the doc always completes.

## Cheapest test
Add the gate as opt-in behind a `--strict` flag on `/pm-strategy` for the prototype-arm cohort only. Measure: of users who try it once, what % keep using it on the next Plan skill in the pipeline. Kill if <30% retention to the next skill.

## Dissent/tension note
Eng: scope creep on gate machinery during a no-buffer quarter (~3.75 eng-weeks vs ~4 effective). Design: a worse first-run UX — the user wanted a plan, the tool returned an error. Business counter: it's the only solution structurally impossible to copy with a Notion template + GPT-4, which is the whole point.
