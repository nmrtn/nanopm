---
id: trust-and-control-over-autonomous-decisions
type: opportunity
title: "The builder won't let the loop run unattended without seeing and gating its decisions"
theme: Loop autonomy & trust
status: draft
priority: medium
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-18
---

## 1. Problem summary
An autonomous loop only delivers value if the solo builder actually lets it run unsupervised — but handing a machine the authority to prioritize, decide, and ship is a leap of trust. The builder needs to see the reasoning and provenance behind each autonomous decision, and to control which decisions the loop may make alone versus which require their sign-off. Without that, they'll either babysit the loop (defeating its purpose) or switch it off.

## 2. Value to the user
### Job to be done
Delegate the loop's routine decisions with confidence while staying the final authority on the consequential ones — get leverage from autonomy without ceding judgment or accountability. Today the alternative is supervising every step manually, which is exactly the toil the loop is meant to remove.
### Where we fall short
**Reasoning isn't visible at the moment of an autonomous decision**
nanopm already stamps provenance and writes reasoning sidecars, but trust in *unattended* operation requires the builder to inspect why the loop auto-prioritized or auto-decided as it did — after the fact, on demand.

**No human checkpoint on consequential decisions**
A loop that just keeps shipping is dangerous without a gate; the builder needs to define which decisions the loop makes alone vs. which pause for sign-off.

## 3. Value to the company
Explainability is already a core design value (provenance stamps, reasoning sidecars). Extending that into autonomous operation is what makes "let it run" credible — trust is the gate that unlocks the whole autonomous-loop bet. Related: [[loop-runs-itself-on-a-cycle]].
