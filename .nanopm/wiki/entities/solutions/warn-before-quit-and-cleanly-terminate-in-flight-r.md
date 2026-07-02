---
id: warn-before-quit-and-cleanly-terminate-in-flight-r
type: solution
title: "Warn before quit and cleanly terminate in-flight runs"
opportunity: a-skill-run-launched-from-the-viewer-loses-its-wor
status: shortlisted
provenance: assumed
lens: eng, design, business
appetite: small-bet
impact: high
linked_objectives: []
last_updated: 2026-06-29
---

## Pitch
Add an `applicationShouldTerminate` / `NSApplicationDelegate` hook that, when `runs.filter(\.isActive)` is non-empty, shows a native confirm-quit sheet ("2 runs still working: /pm-product, /pm-roadmap — quit anyway and lose their progress?") and, on confirmed quit, SIGTERMs each child by reusing the existing `RunManager.cancel(_:)` path. The cheapest tier the grounding names: no persistence, no resume. Cleanly-terminated runs already land in `.failed`, so the "interrupted vs done" signal comes for free. All three lenses converged here — it's the smallest footprint that kills the *silent* loss, which is the brand-damaging facet ("loses a run with no explanation won't believe the GUI is safe").

## Riskiest assumption
That the painful losses arrive through an interceptable quit path (⌘Q) — but most lost-work cases are the process being *killed* (force-quit, crash, logout, OOM), which `applicationShouldTerminate` never sees. If so, the warning protects only the polite-quit minority and is theater for the real failure mode.

## Cheapest test
Recall/inspect how the observed losses actually happened (clean ⌘Q vs force-kill vs crash) — one afternoon of dogfooding notes, zero code. If the painful ones are kills, a quit dialog doesn't help.

## Dissent/tension note
Design: a modal that blocks quit fights the user at the worst moment and only covers polite quits. Business: spends team time before a recruited user named the gap (trips the anti-goal) — justified only if silent loss confounds the quarter's read.
