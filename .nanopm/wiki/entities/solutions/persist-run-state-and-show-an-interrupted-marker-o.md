---
id: persist-run-state-and-show-an-interrupted-marker-o
type: solution
title: "Persist run state and show an Interrupted marker on relaunch"
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
Write a thin `.nanopm/.runs/<id>.json` per run (skill, started-at, sessionID, last-event, status) on state transitions. On relaunch, RunManager rehydrates the Activity Monitor from these files and shows a third status — **Interrupted** — for any run that was `running` when the app last died, replaying the last few events so the user sees *where* it stopped. This kills the timestamp-archaeology workaround (the app reads back state instead of the user inspecting `.nanopm/` mtimes) and, in business framing, de-confounds Objective 1's cross-matrix read — an interrupted run becomes legible to the experimenter instead of looking like "the value was thin."

## Riskiest assumption
That an honest "Interrupted — here's roughly where it stopped" restores enough trust without actually resuming the work — i.e. that the user is fine re-running rather than continuing, and that interruptions are frequent enough in the N=10 prototype arm to be worth the legibility.

## Cheapest test
Mock the Activity Monitor with one hand-written interrupted-run JSON + the new status row, put it in front of a designer-founder and ask "what would you do next?". If the answer is "re-run, fine," the resume tier is lower priority than it looks.

## Dissent/tension note
Design: tells the truth but doesn't save the work — the honest-failure half of the JTBD only. Eng: a file write per state transition is more I/O churn than a throwaway prototype needs — debounce to sessionID-capture + terminate, not per-event.
