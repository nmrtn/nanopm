---
id: no-cross-project-view-each-repo-nanopm-state-is-si
title: "No cross-project view — each repo's nanopm state is siloed"
theme: Adoption & form factor
status: draft
priority: medium
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
related_to: []
last_updated: 2026-06-18
---

## 1. Problem summary
A founder running nanopm across several projects has a separate `.nanopm/` per repo, with no consolidated view across them. Portfolio-level priorities — and problems that recur across products — are invisible, because every project's state is read one repo at a time. There's no way to compare bets across projects, or to notice that the same user problem is surfacing in three of them.

## 2. Value to the user
### Job to be done
A multi-project founder or fractional PM wants to see "what's the most important thing across everything I'm building," and to spot patterns that only appear when projects are viewed together — not to re-open each repo's folder in turn.

### Where we fall short
**State is repo-scoped by construction**
nanopm's state lives in each project's local `.nanopm/`. That keeps a single project self-contained, but means there is no surface that aggregates opportunities, bets, or roadmaps across projects — so cross-project signal and portfolio prioritization have nowhere to live.

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. e.g. a multi-project index in the viewer; a cross-repo `nanopm portfolio` readout. -->
