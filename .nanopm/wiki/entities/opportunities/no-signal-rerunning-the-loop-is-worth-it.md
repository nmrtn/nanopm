---
id: no-signal-rerunning-the-loop-is-worth-it
title: "After the first run, a founder has no signal that returning to the loop is worth it"
theme: Continuity & retention
status: draft
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: [obj1-kr3]
last_updated: 2026-06-17
---

## 1. Problem summary
nanopm's single biggest open unknown is whether anyone voluntarily returns for a second full pipeline run. After the first run, the artifacts sit in a local `.nanopm/` folder and nothing tells the founder when re-running is worthwhile, what's changed since last time, or what re-running would give them that the existing docs don't. The cost of returning is fully visible (open the repo, find the folder, run a skill) while the payoff is invisible — so the rational default is not to come back. This is the make-or-break behavior: the second run within 21 days is the moment the switch completes.

## 2. Value to the user
### Job to be done
Theo is trying to decide, on any given day, whether opening nanopm again is worth the interruption to his build flow. He wants a cheap, honest answer to "has enough changed that my plan is now stale?" and "is there a reason to revisit?" The alternative today is no prompt at all — he either happens to remember nanopm exists or he doesn't, and a planning tool that depends on being remembered is one that quietly evaporates.

### Where we fall short
**The payoff of returning is invisible; only the cost is visible**
The product surfaces no "why come back now" signal — no view of time since last run, no flag that commits have drifted from the plan, no prompt that the bet's timeframe is expiring.
- CONTEXT-SUMMARY.md: "The One Belief to falsify: a real founder voluntarily returns to a full pipeline within 21 days" — 0 retention ever measured — nano-hypothesis.

**No lightweight readback of prior-run state**
There's no at-a-glance answer to "when did I last touch this, and what's pending?"
- PLAN-SUMMARY.md NOW item 2 ("Lightweight retention readback … prior-run timestamps") confirms the surface does not exist today — nano-hypothesis.

## 3. Value to the company
The opportunity most tightly bound to nanopm's survival: Objective 1 / KR3 is literally a cross-matrix read on voluntary 2nd runs within 21 days. If the product gives no reason to return, the proof quarter reads FAIL not because the planning value is absent but because the return trigger was never built.
