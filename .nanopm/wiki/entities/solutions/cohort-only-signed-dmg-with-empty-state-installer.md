---
id: cohort-only-signed-dmg-with-empty-state-installer
type: solution
title: "Cohort-only signed .dmg + empty-state installer (1:1 distribution)"
opportunity: users-can-t-easily-install-the-viewer-and-launch-i
status: proposed
lens: business, design, eng
appetite: small-bet
impact: high
provenance: assumed
linked_objectives: [obj1-kr2]
last_updated: 2026-06-29
---

## Pitch
Ship a signed `.dmg` of the viewer behind a hand-distributed link — no public download, no Homebrew cask — and make first launch a project-picker. When Dani opens the app and points it at a folder, an in-app onboarding card detects what's missing (no `.nanopm/`, no CLI on PATH, no host skill pack) and offers one button per gap, running the existing `setup` script under the hood with a live log drawer. The empty-state IS the installer; distribution stays 1:1 to the named KR2 cohort so we don't accidentally optimize for the anti-persona.

## Riskiest assumption
That install friction (not the deeper "I don't know what a Claude/Vibe/Codex host is" or "what's an API key" confusion that sits one layer down) is the binding constraint on KR2 — i.e. a clicked `.dmg` + in-app CLI install is enough to convert a named non-terminal founder into a completed-first-pipeline user.

## Cheapest test
Hand 3 named non-terminal founders a pre-built unsigned `.dmg` over a Zoom call this week and watch them try to reach "first pipeline run." If 2/3 complete with only verbal help, the signed-`.dmg` + empty-state path is worth building; if they stall on host-pack or API-key setup, install isn't the real blocker and we'd be polishing the wrong layer.

## Dissent/tension note
Cross-lens — Eng: structurally cheapest path, but the Gatekeeper "this app might be malware" screen is a real trust moment for a non-terminal persona (notarization may need to follow). Design: the empty-state must keep the project folder path prominently visible or we drift toward the SaaS anti-goal. Business: anti-goal says don't polish past prototype-arm needs — keep distribution 1:1 until at least 3 KR2 founders are using it.
