---
id: handoff-lands-in-builders-tool
type: opportunity
title: "Handed-off work doesn't land cleanly in the delivery tool the builder already uses"
theme: Build handoff
status: draft
priority: medium
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-18
---

## 1. Problem summary
Even with a good PRD, getting the work into the builder's actual delivery tool is friction. Solo builders already live in a specific delivery surface — Linear, GitHub Issues, OpenSpec, gstack, Symphony, or just markdown — and a handoff that requires manual re-entry, or that lands as a malformed/partial artifact, stalls the loop right at the point where planning is supposed to become building. The handoff has to meet the builder where they already work, not force them to a new tool.

## 2. Value to the user
### Job to be done
When I finish planning, I want the work to arrive ready-to-build in the exact tool I already use, so I can start coding without re-typing tasks or reconciling formats. The alternative today is copy-pasting the PRD into issues by hand, or adopting whatever single target a competitor supports — neither of which matches my existing workflow.
### Where we fall short
**Handoff is single-target or doesn't fit the builder's tool**
If the handoff only supports one destination, or produces an artifact the target tool can't ingest cleanly, the builder drops back to manual work and the autonomous loop breaks at the last step.

## 3. Value to the company
This is nanopm's stated differentiator: symmetric, first-class handoff to six peer delivery targets versus single-target or no-handoff competitors. Making each target land cleanly is what turns the differentiator from a feature list into a reason the loop actually closes. Related: [[handoff-traceability-lost]], [[loop-runs-itself-on-a-cycle]].
