---
id: planning-influence-on-shipped-work-invisible
title: "A founder can't see whether prior planning actually influenced what shipped"
theme: Continuity & retention
status: draft
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-17
---

## 1. Problem summary
A founder runs the planning loop (objectives → strategy → roadmap → PRD), then goes off and ships with their coding agent. When they come back, nothing connects the commits that landed to the bet that was supposed to drive them. The planning artifact and the actual work drift apart silently — the "retro gap" — and there's no surface that shows whether the plan changed what got built or was just a document filed and forgotten. This affects Terminal-native Theo, whose whole reason for adopting nanopm is to "catch wrong-direction work before weeks compound."

## 2. Value to the user
### Job to be done
Theo is trying to confirm that the planning he did was load-bearing — that his roadmap's NOW items map to real commits, and that work which drifted from the bet gets flagged before more weeks pile on. Today the alternative is doing this comparison by hand (eyeballing git log against a roadmap doc he has to re-find) or, more often, not doing it at all — the "4,000-word ChatGPT thread he can't find again" failure mode nanopm exists to replace.

### Where we fall short
**No visible link between the plan and the commits it was meant to drive**
The product writes a roadmap with NOW items but offers no continuous readback of plan-vs-reality; the comparison only happens if the founder manually invokes a retro.
- CONTEXT-SUMMARY.md "What's NOT known yet" (work drifting from the stated bet with no surfaced signal) — nano-hypothesis.

**Closing the loop requires the founder to remember to close it**
pm-retro exists but is opt-in and point-in-time; nothing nudges the founder when drift is accumulating.
- Inferred from PLAN-SUMMARY.md (retro framed as a discrete action, not a continuous signal) — nano-hypothesis.

## 3. Value to the company
nanopm's mission ("make planning compound across sessions") and its core promise both depend on the loop visibly closing. If a founder can't see that planning influenced shipping, the value proposition is unprovable to them — the most likely reason the One Belief (a founder voluntarily returns within 21 days) fails. Sits directly on the riskiest assumption in STRATEGY.md ("Empty house").
