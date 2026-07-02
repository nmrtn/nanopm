---
id: team-cant-collaborate-on-shared-nanopm-state
title: "Co-founders / teams can't collaborate on the same nanopm state — it's local per-machine"
theme: Adoption & form factor
status: defining
priority: medium
provenance: user-stated
evidence_sources: [user-verbatim]
linked_objectives: []
related_to: [plan-artifacts-buried-and-unshareable, no-cross-project-view-each-repo-nanopm-state-is-si]
last_updated: 2026-06-30
---

## 1. Problem summary
nanopm state (`.nanopm/` wiki + raw) lives locally in one person's repo checkout. Two people building the same product can't work on the same files — the co-founders hit exactly this on the strategy call ("ça me frustre qu'on ne bosse pas sur les mêmes fichiers"). The framing that lands: nanopm artifacts should be treated like code — a shared source of truth, with the wiki/MD living in the cloud and skills authenticating (API key) to read/write the same context across users. Without it, nanopm is a single-player tool, which blocks any team adoption and forces ad-hoc file passing.

## 2. Value to the user
### Job to be done
A founding team (or a PM + stakeholders) wants one shared, current nanopm state everyone reads and writes — not a copy each. The alternative today is manually sharing files or duplicating state, which diverges immediately.

### Where we fall short
**State is local; no shared/cloud-hosted wiki**
The generated files aren't shared across people; collaboration requires the wiki to live somewhere shared.
- "L'ensemble des fichiers générés par un nanopm doivent être partagés entre plusieurs personnes. Le Wiki, les MD doivent vivre dans le cloud, et les skills ont une API key pour récupérer le même contexte entre plusieurs utilisateurs. C'est comme du code." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)
- "Ça me frustre qu'on ne bosse pas sur les mêmes fichiers." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)

## 3. Value to the company
Team collaboration is the gate to nanopm being more than a solo-founder tool — and it interacts with the "expose my wiki?" privacy question and the substrate decision (a shared store likely needs the same DB as the high-volume bet). Guardrail: internal founder signal (N=1, two co-founders); also a big architectural bet (cloud + auth), not a v1 spine item.

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: cloud-hosted shared wiki; skills authenticate via API key to a shared backend; treat .nanopm as code (a shared repo / DB); per-workspace privacy controls. -->
