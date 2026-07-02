---
id: skills-yaml-manifest-as-single-source-of-truth
type: solution
title: "skills.yaml manifest as single source of truth"
opportunity: pipeline-sequence-opaque
status: proposed
lens: eng
appetite: big-bet
impact: medium
provenance: assumed
linked_objectives: []
last_updated: 2026-07-01
---

## Pitch
Add a machine-readable `skills.yaml` at the repo root declaring every skill's phase, order, prerequisites, and one-line value prop. `setup` distributes it to `~/.nanopm/`; `lib/nanopm.sh` reads it for both the entry banner AND the end-of-run "Recommended Next Skill" emission; README, CLAUDE.md, and `plugin.json` are all *generated* from it by a `make docs` target. Single source of truth for skill ordering across every surface today (4+ places) and every future surface (viewer, plugin marketplace, `/pm-run`). Solves the underlying drift problem, not just the symptom.

## Riskiest assumption
The maintenance win from de-duplicating ordering across 4+ places is worth the up-front cost of writing the manifest, the generator, and migrating existing docs — within the ~3.75-week zero-buffer capacity this cycle.

## Cheapest test
Write the manifest by hand for all 24 skills (1 day of work), keep everything else as-is, and check whether the manifest alone (as a standalone doc surface) reads clearer to a fresh user than the current README. If yes, then justify building the generators next cycle.

## Dissent/tension note
Eng: correct long-term architecture but wrong bet-size for zero-buffer capacity; a manifest without consumers is just another doc, and building the consumers is the actual work. Directly competes with Solution B ([[entry-banner-in-every-skill-preamble]]) and Solution D ([[readme-phase-first-reframe-plus-how-to-use-guide]]) — do those first; write this after we know the shape.
