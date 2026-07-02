---
id: viewer-as-host-plugin-slash-command
type: solution
title: "Viewer as a host-plugin /viewer command — no separate app"
opportunity: users-can-t-easily-install-the-viewer-and-launch-i
status: proposed
lens: design
appetite: small-bet
impact: high
provenance: assumed
linked_objectives: [obj1-kr2]
last_updated: 2026-06-29
---

## Pitch
Don't ship an app at all — ship a "Run NanoPM Viewer" surface inside the existing Claude Code / Vibe / Codex plugin. When the user installs the nanopm plugin in their agent host, the plugin offers a `/viewer` command that downloads, builds (once, cached), and launches the viewer pre-pointed at the current project. The empty-state problem evaporates because the viewer is launched FROM a project context that already has `.nanopm/` populated.

## Riskiest assumption
That the KR2 founder is already using a host agent (Claude Code / Vibe / Codex) with the plugin installed — i.e. the persona who rejects "the terminal" nonetheless accepts an agent-host CLI. If she's truly tool-averse, she's not in the host either, and this reaches zero new users.

## Cheapest test
Look at the 0-of-10 KR2 recruitment funnel: of the non-terminal founders already in conversation, how many already have Claude Code / Vibe / Codex installed? If <3, this path is dead. One afternoon of asking, no build.

## Dissent/tension note
Design: solves install by piggybacking on a terminal-adjacent surface; may quietly redefine "non-terminal founder" as "founder who uses an agent host with a CLI," which is a different persona than the grounding. Eng's sharper variant (a `nanopm viewer` shell subcommand) was an adversarial floor: if the cohort would accept *that*, the whole `.dmg` track is overbuilding — but it contradicts the persona's "no curl-pipe-bash" stance directly.
