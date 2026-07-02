---
id: plan-artifacts-buried-and-unshareable
title: "The plan is buried in a local folder — users can't see it, navigate it, or share it"
theme: Adoption & form factor
status: draft
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-17
---

## 1. Problem summary
nanopm's output — the bet, the OKRs, the roadmap, the PRD — lands as markdown files in a local, gitignored `.nanopm/` folder. To know what was decided, a user has to remember the folder exists, open the right file in an editor, and reconstruct the picture by hand; there is no at-a-glance view of "what are we working on and why." And because the artifacts are local and unshareable, the planning can't travel to a co-founder, stakeholder, or the rest of a tiny team. This is the visibility half of the form-factor bet: even a user who *can* run nanopm gets value that's trapped and invisible.

## 2. Value to the user
### Job to be done
After running the pipeline, the user wants to (a) see the current state of their thinking at a glance and be guided on what to run next, and (b) put the plan in front of another human. Today the workaround is opening individual markdown files in an editor and, to share, manually copying content into Notion or a doc — which immediately re-forks the planning away from the agent that generated it and breaks the "planning compounds across sessions" promise.

### Where we fall short
**Artifacts are buried and offer no sense of "what's the state / what next"**
Output is files in a local `.nanopm/` folder; there's no overview of the current bet, no timeline of runs, no guidance on when/why to run the next skill.
- Inferred from STRATEGY.md ("artifacts buried in a local folder, no sense of what to do next") and CONTEXT-SUMMARY.md.

**The plan can't be shared without copying it out of nanopm**
`.nanopm/` is per-project and gitignored; there's no shareable surface, so the moment a user needs to show the plan to someone, they leave the tool.
- Inferred from CONTEXT-SUMMARY.md (artifacts "invisible/unshareable") and the "One product or two?" open question.

## 3. Value to the company
Visibility/orchestration above the agent is pillar 2 of "How We Win" and the core of what the prototype cohort tests. Reducing the "buried artifacts" friction is the mechanism the form-factor bet predicts will unlock retention. Guardrail: surface and share the work without becoming a tracker (no Linear/Notion replacement) and without hosting the user's code — make the plan *visible and portable*.

## 5. Solution hypotheses
Pointer only — stay in problem space. (Candidate directions: an overview/timeline surface for current state + next-skill guidance; a shareable/exportable view that keeps the agent in the loop.)
