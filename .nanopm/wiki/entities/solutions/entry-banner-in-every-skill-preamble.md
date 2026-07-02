---
id: entry-banner-in-every-skill-preamble
type: solution
title: "Entry-banner in every skill preamble — 'why this skill, why now, what you'll get'"
opportunity: pipeline-sequence-opaque
status: shortlisted
lens: eng, design, business
appetite: small-bet
impact: high
provenance: assumed
linked_objectives: []
last_updated: 2026-07-01
---

## Pitch
Every skill's preamble renders a 3-line banner sourced from a single `MAP.md`: **What you'll get** (one artifact), **Why now** (the prior skill it builds on), **Skip if** (one honest disqualifier). Central bash function in `lib/nanopm.sh` — portable across Claude / Vibe / Codex — read by `nanopm_preamble`, zero per-skill edits. `MAP.md` doubles as the "how to use nanopm to maximize impact" guidelines document the founder asked for. Kills per-skill value opacity at the moment of choice; the receipt at the end mirrors the preview.

## Riskiest assumption
The opacity Nico and the challenge-me signal point to is a *framing* problem (Theo doesn't know what he'll get) — not an *artifact-quality* problem. A prose banner is enough to defeat the "je n'ai pas trouvé la valeur dans cette skill" reaction.

## Cheapest test
Add the 3-line preamble to *only* `/pm-challenge-me` (the skill Theo explicitly called opaque) for one week; ask both co-founders whether it now feels worth running. If yes, roll out to the rest. If the framing alone doesn't move the needle for the one skill it was diagnosed on, we know it's an artifact-quality problem and don't ship it wider.

## Dissent/tension note
Eng: `MAP.md` becomes a third source of truth alongside README and CLAUDE.md — will drift without a lint gate. Business: papers over kill-candidates — if the skill doesn't deliver KR-linked output, prose won't save it. Design: adds friction on every run for the terminal-native who already knew what he was doing.
