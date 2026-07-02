---
id: memory-wiki-health-is-invisible-without-running-th
title: "Memory wiki health is invisible without running the lint agent by hand"
theme: Trust & evidence
status: draft
priority: medium
provenance: user-stated
evidence_sources: []
linked_objectives: []
related_to: [opportunities-and-plans-go-stale-with-no-freshness]
last_updated: 2026-06-23
---

## 1. Problem summary

A founder using nanopm's memory wiki has no at-a-glance signal of whether the wiki is healthy. Stale pages, orphans (unreachable nodes), and broken links accumulate silently and only surface if the founder remembers to run the lint agent by hand in the terminal. The viewer renders the wiki but does not report its structural state, so wiki rot stays invisible to anyone who isn't already running the CLI ritual.

## 2. Value to the user

### Job to be done
The founder wants to trust that the memory wiki accurately reflects the current state of their work — that pages are fresh, every node is reachable from the index, and no link points into the void. Today the alternative is either (a) ignore wiki health entirely and accept silent rot, or (b) drop into the terminal periodically to run the lint agent and read its output.

### Where we fall short

**No health surface in the viewer**
The GUI now reads the wiki/ layout (PR #109), but it doesn't render lint signals — orphans, stale pages, broken links — anywhere a founder would naturally see them. A non-terminal user has no way to learn the wiki has rotted short of asking.

**Lint is a manual ritual, not a passive signal**
The lint agent exists (PR #107) but only runs on demand from the CLI. There is no scheduled check, no badge, no notification — staleness has to be actively hunted for, which means it usually isn't.

**Orphan / broken-link semantics are tooling concerns, not UI concerns**
The recent fix (PR #108) clarified that an orphan is an unreachable node, not just an edge-less one — meaningful for the lint pass, but invisible in the viewer. The user can't tell, from the wiki itself, which pages are floating.

## 3. Value to the company

The memory wiki is a recent, foundational nanopm surface (wave 3) — its credibility depends on it staying coherent over time. A wiki that silently rots erodes the "honest, falsifiable bet" ethos nanopm sells. Surfacing health in the viewer turns a hidden CLI capability into a visible trust signal, reinforcing the same evidenced-vs-assumed transparency the rest of the product promises.

## 4. Success criteria

- A founder opening the viewer can see, without typing a command, whether the wiki has stale pages, orphans, or broken links — and which ones.
- The lint agent's output is reachable from the wiki view itself, not gated behind terminal recall.

## 5. Solution hypotheses

<!-- pointer only — stay in problem space; explore in /pm-prd or /pm-brainstorm -->
- Viewer health badge + per-page staleness indicator, driven by the existing lint agent.
- Scheduled lint pass on viewer open (or on a cadence) with results cached into the wiki layout.
