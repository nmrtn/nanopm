---
id: there-s-no-way-to-schedule-jobs-or-sequences-of-jo
type: opportunity
title: "There's no way to schedule jobs or sequences of jobs to run automatically at a regular cadence"
theme: Loop autonomy & trust
status: draft
priority: medium
provenance: user-stated
evidence_sources: []
linked_objectives: []
related_to: [loop-runs-itself-on-a-cycle]
last_updated: 2026-07-03
---

## 1. Problem summary
Nothing in nanopm runs on a timer. There is no scheduling primitive to program a single job — or a sequence of jobs — to fire automatically at a regular cadence (daily, weekly, etc). Any automation today has to be manually triggered by the user, which blocks building the autonomous, self-driving loop the product is betting on, and any other feature (continuous discovery, periodic freshness checks, staged pipelines) that needs to run unattended on a schedule.

## 2. Value to the user
### Job to be done
Define a job (or an ordered sequence of jobs) once, set its cadence, and trust it fires on its own — without the builder acting as the human cron, remembering to kick things off. Today the only alternative is invoking each skill by hand whenever the builder happens to think of it.
### Where we fall short
**No scheduling/cron primitive exists**
There is no mechanism anywhere in nanopm to register a job or job sequence against a recurring timer. Every run is triggered by a human typing a command.
- "We might need to have a routine / cron engine to program jobs and sequence of jobs at a regular timing." — PM (user-stated), 2026-07-03

**Blocks every downstream autonomy bet**
Both the self-driving PM loop ([[loop-runs-itself-on-a-cycle]]) and continuous discovery ([[discovery-runs-only-when-i-remember]]) need this same underlying capability — a way to schedule and sequence jobs — but neither can be built until the scheduling engine itself exists.

## 3. Value to the company
This is infrastructure, not a standalone feature — it's the enabling mechanism the autonomy bet depends on. Building it once unlocks multiple higher-value opportunities rather than each reinventing its own timer. Related: [[loop-runs-itself-on-a-cycle]], [[discovery-runs-only-when-i-remember]].
