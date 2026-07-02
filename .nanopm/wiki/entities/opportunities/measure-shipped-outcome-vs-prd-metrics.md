---
id: measure-shipped-outcome-vs-prd-metrics
type: opportunity
title: "After shipping, the builder can't tell whether the feature actually moved the metric the PRD promised"
theme: Outcome learning
status: draft
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-18
---

## 1. Problem summary
A solo builder ships a feature with a PRD that named a success metric, then moves on to the next build without ever checking whether the metric moved. Nothing in the loop confronts the shipped result against the promise that justified it. The builder accumulates output (features shipped) with no evidence of outcome (user behavior changed) — the classic feature-factory trap.

## 2. Value to the user
### Job to be done
When a build lands, the builder wants to know "did this work?" — measured against the specific success criteria they set before building — so they can decide whether to double down, fix, or kill it. Today the alternative is gut feel, a one-off manual dashboard check that never happens, or simply assuming "shipped = done."
### Where we fall short
**No post-build confrontation against the PRD's stated metric**
Phase 5 is meant to analyze what happened after the build, but there is no mechanism that pulls the PRD's success metric forward, compares it to post-ship reality, and forces a verdict. The success criterion set in planning dies on the page.

**Output is tracked, outcome is not**
Retro compares roadmap intent vs commits (what shipped), which measures activity, not impact. The builder can see they shipped the thing without ever learning whether shipping the thing mattered to a user.

## 3. Value to the company
nanopm's core promise is a CLOSED autonomous loop, not a faster feature factory. If Phase 5 can't tell the builder whether a ship changed behavior, the product is just automating output — defeating its own positioning against ordinary task-runners. Related: [[handoff-traceability-lost]], [[feed-learning-back-into-context-and-discovery]].
