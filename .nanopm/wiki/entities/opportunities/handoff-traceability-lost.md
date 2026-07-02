---
id: handoff-traceability-lost
type: opportunity
title: "By build time, nobody can trace why this is being built or what proves it worked"
theme: Build handoff
status: ready-for-solutions
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-27
---

## 1. Problem summary
When the solo builder reaches the build phase, the PRD and its success metrics have drifted away from the opportunity that justified them. The thread from "user problem → bet → spec → success metric" breaks somewhere between planning and delivery, so by the time work lands in the delivery tool, the builder can no longer say why this is being built or what behavior change would prove it worked. For a solo builder wearing both PM and engineer hats, this severs the loop precisely where it needs to close.

## 2. Value to the user
### Job to be done
When I hand work off to build, I want the spec and its success metric to stay tethered to the originating opportunity, so I can defend why I'm building this and know what outcome to measure once it ships. Today the alternative is re-deriving the rationale from memory, or shipping without a metric tied to anything — and then having no basis for the outcome-learning step later.
### Where we fall short
**The PRD and success metrics detach from the opportunity**
The handoff carries the spec but not the chain of reasoning behind it — which opportunity it serves and which behavior change validates it — so the build phase starts disconnected from discovery.

## 3. Value to the company
Direct support for nanopm's core bet: a closed, autonomous product loop. Traceability from opportunity to success metric is the spine that lets the loop later learn from outcomes; without it, the loop is open and the autonomy claim weakens. Related: [[prioritize-opportunities-by-strategic-impact]], [[measure-shipped-outcome-vs-prd-metrics]].

## Solutions
_Brainstormed via `/pm-solutions` on 2026-06-27 — full comparison in `.nanopm/wiki/entities/solutions/INDEX.md`._
- **[Thread the opportunity link through the chain](../solutions/thread-opportunity-link.md)** · eng, business · small-bet · high · **shortlisted**
- **[Auto-prepend a legible provenance header](../solutions/provenance-header-at-handoff.md)** · design · small-bet · high · proposed
- **[Detect and flag a broken thread](../solutions/flag-broken-thread.md)** · eng, design · small-bet · medium · proposed
- **[Defer to the loop-closing objective](../solutions/defer-until-loop-objective.md)** · business · small-bet · low · proposed
