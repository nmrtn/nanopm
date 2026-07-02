---
id: challenge-mode-just-the-bets-view
type: solution
title: "Challenge mode / just-the-bets view"
opportunity: cant-tell-evidenced-from-assumed
status: proposed
provenance: assumed
lens: design
appetite: big-bet
impact: high
linked_objectives: [run-proof-quarter-clean-read]
last_updated: 2026-06-29
---

## Pitch
A "Challenge mode" toggle in the viewer (and a `nanopm challenge <doc>` CLI mirror) that strips all `evidence-backed` and `user-stated` sentences and renders ONLY the `nano-hypothesis` claims as a standalone "What I'm guessing" view. The inversion: instead of marking the assumed claims inside the plan, extract them into their own readable artifact. Theo gets a 30-second scan of just-the-bets — the document the adversarial-honesty value actually promises — and can choose to live there before returning to the full plan. Each bet links to its cheapest test from the matching opportunity / solution entity.

## Riskiest assumption
Assumed claims are coherent when read in isolation — that "What I'm guessing" reads as a real document rather than disconnected fragments that lose meaning without their evidenced scaffolding.

## Cheapest test
Manually extract the `nano-hypothesis` sentences from one real `docs/strategy.md` into a plain markdown file. Show to a Theo-proxy and ask "does this read as a coherent set of bets, or as gibberish?" Single 20-minute test, before any build.

## Dissent/tension note
Challenge mode is the design-most-fun answer but the heaviest build — it competes directly with the anti-goal of "viewer polish beyond what the prototype arm needs", and may be the exact avoidance behaviour Obj1 flagged twice. Eng adds: a viewer-first affordance breaks multi-host portability — Vibe/Codex users get a CLI shadow at best.
