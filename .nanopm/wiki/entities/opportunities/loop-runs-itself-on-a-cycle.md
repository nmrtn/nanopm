---
id: loop-runs-itself-on-a-cycle
type: opportunity
title: "The PM has to remember to invoke each step; the loop doesn't run itself"
theme: Loop autonomy & trust
status: draft
priority: high
provenance: user-stated
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-18
---

## 1. Problem summary
The solo builder wants product management to run as a closed, self-driving loop — autoresearch then autobuild, cycling Phase 1→5→1 — but today every step is a manual `/pm-*` invocation. The work only advances when the PM remembers to trigger the next skill, so the loop stalls whenever attention drifts back to code. The cost falls on solo builders who have no PM to keep the cadence going.

## 2. Value to the user
### Job to be done
Keep the product loop turning — discovery feeding planning feeding build feeding learning — without having to personally drive each handoff. Today the alternative is the builder acting as the scheduler: manually firing each skill in sequence and re-orienting on where the loop left off.
### Where we fall short
**No autonomous cadence**
The pipeline is a set of commands the human chains by hand; nothing advances Phase 1→5→1 on its own cycle.
- "The whole loop should run AUTONOMOUSLY — autoresearch and autobuild — cycling on its own rather than the PM remembering to invoke each step manually." — PM (user-stated), 2026-06-18

**Re-orientation tax between steps**
Each manual invocation forces the builder to recall what ran last and what comes next, instead of the loop carrying that state forward itself.

## 3. Value to the company
The closed autonomous loop is the overarching product bet ("autoresearch, autobuild"). This opportunity is the core of that bet — without it nanopm is a toolbox of commands, not a self-running PM. Related: [[trust-and-control-over-autonomous-decisions]], [[feed-learning-back-into-context-and-discovery]].
