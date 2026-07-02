---
id: ascii-trail-map-in-every-preamble
type: solution
title: "ASCII trail-map in every skill preamble"
opportunity: pipeline-sequence-opaque
status: proposed
lens: design
appetite: small-bet
impact: medium
provenance: assumed
linked_objectives: []
last_updated: 2026-07-01
---

## Pitch
A single-line ASCII progress indicator at the top of every skill run, riding on `nanopm_preamble`: `Define ●●●○○ · Discover ○○○ · Plan ○○○ · Build ○○`. Filled dots = done skills, hollow dots = pending, cursor sits on the next recommended one. Theo sees where he is in a journey he didn't know existed, and the next hollow dot tells him what to type. Free to add — no new skill, no viewer work, no interactive gate. Complements a per-skill entry banner but stands alone as the cheapest possible position signal.

## Riskiest assumption
A *visual* progress artifact — not a prompt — is enough to break menu paralysis; Theo will read the map and self-navigate to the next hollow dot without being told.

## Cheapest test
Mock the trail-map string, paste it into a `/pm-standup` output, show it to Nico and 2 cohort founders — do they correctly identify their next recommended skill in <5 seconds? No code change until yes.

## Dissent/tension note
Design: progress bars seduce a founder into completionism — running skills to fill dots rather than because the skill's output changes his decisions. That's the exact "thin inputs, silent degradation" failure mode the parent opportunity ([[pipeline-sequence-opaque]]) warns about.
