---
id: instrument-first-run-before-building
type: solution
title: "Instrument the first run before building anything"
opportunity: first-run-value-unprovable
status: proposed
provenance: assumed
lens: eng
appetite: small-bet
impact: medium
linked_objectives: []
last_updated: 2026-06-27
---

## Pitch
Resist building value-side features and instead instrument the existing first run: add minimal append-only event lines to the existing JSONL memory log (skill started / artifact written / which skill they stopped at / session length) so the proof quarter gets the measured first-run signal it currently lacks (0 runs measured, instrumentation removed). It reuses a primitive that already exists and tells you WHICH of the other solutions is even worth building.

## Riskiest assumption
That abandonment is observable in local CLI events at all — users may churn by simply never running a second command, and a local append-only log on machines you don't control may never reach you (no telemetry egress); or the drop is pre-install, upstream of anything instrumented.

## Cheapest test
Add 3 event lines to the existing JSONL writer and dogfood for a week; confirm the events are actually retrievable from cohort users (even via a manual "paste your log" ask) before investing in any value-side feature.

## Dissent/tension note
Eng + Business: smallest structural footprint and unblocks every other decision — but it's measurement, not value; on its own it moves no conversion this quarter, so it can't lift the funnel it measures.
