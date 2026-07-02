---
id: one-tap-resume-of-an-interrupted-run-via-the-captu
type: solution
title: "One-tap resume of an interrupted run via the captured session id"
opportunity: a-skill-run-launched-from-the-viewer-loses-its-wor
status: proposed
provenance: assumed
lens: eng, design
appetite: big-bet
impact: high
linked_objectives: []
last_updated: 2026-06-29
---

## Pitch
Persist the `sessionID` the app already captures at runtime (today it's thrown away on quit), and on relaunch show a "Welcome back" banner atop the project view: "/pm-product was interrupted — resume where it left off?" One button fires `claude --resume <sessionID>` through the same `startTurn(resumeSession:)` machinery the app already uses to resume a waiting run. This is the closest thing to the "normal background-task durability" the JTBD names — the app offers to *finish the job*, not just confess it failed. The grounding flags this as the "bigger bet to weigh, not assume."

## Riskiest assumption
That `claude --resume` on a session whose child was SIGKILLed mid-tool-call continues cleanly to a coherent artifact set — rather than resuming into a corrupted, half-written `.nanopm/` and producing a worse mess than a clean re-run.

## Cheapest test
Manually kill a /pm-product run mid-write, then run `claude --resume <captured-sessionID> -p "continue"` by hand in the same project dir and inspect whether the artifact set ends up coherent. One terminal session, zero UI.

## Dissent/tension note
Eng: couples the viewer to the CLI's resume semantics (and could lean on the CLI's own session store rather than a nanopm-owned schema — but don't reach for SQLite; that's the over-build the prototype must refuse). Design: most delightful but least certainly safe — must never ship alone; pair it with the honest "interrupted" state so a silent half-finish can't betray trust worse than a clean re-run.
