---
id: feed-learning-back-into-context-and-discovery
type: opportunity
title: "What the builder learns from a shipped build never feeds back into context, discovery, or the opportunity DB — so the next cycle repeats the same mistakes"
theme: Outcome learning
status: draft
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-18
---

## 1. Problem summary
After a build, whatever the builder learns — the metric moved or it didn't, a discovery assumption proved false, an opportunity turned out mis-ranked — stays trapped in the post-build moment. It is not written back into the context brief, the discovery assumptions, or the opportunity database that feed the next planning cycle. The loop stays open: each cycle starts from the same stale baseline instead of compounding on the last one.

## 2. Value to the user
### Job to be done
When a build teaches the builder something, they want that lesson to automatically update the inputs to the next cycle — so the next round of personas, discovery, opportunities, and objectives reflects reality, not the assumptions they started with. Today the alternative is the builder remembering to manually edit context docs (which they won't), so the learning evaporates.
### Where we fall short
**No write-back path from Phase 5 to Phases 1/2/3**
The pipeline flows forward (context → discovery → opportunities → plan → build) but has no return edge. A validated or invalidated assumption from a ship doesn't update the discovery doc or re-rank the opportunity DB; a behavioral surprise doesn't amend the context summary.

**Learnings don't compound across cycles**
Because nothing closes the loop, cycle N+1 reasons from the same baseline as cycle N. Mistakes aren't retired and confirmed bets aren't reinforced — the database of opportunities and the context brief drift away from what the builder now knows.

## 3. Value to the company
This is the literal thing nanopm exists to do — close the loop so Phase 5 feeds Phases 1/2/3. Without it the product is a sequence of one-shot PM documents, not a learning system; with it, every cycle makes the next one smarter, which is the whole differentiated bet. Related: [[measure-shipped-outcome-vs-prd-metrics]], [[cold-start-context]], [[loop-runs-itself-on-a-cycle]].
