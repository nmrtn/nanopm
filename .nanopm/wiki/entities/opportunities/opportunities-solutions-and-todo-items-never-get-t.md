---
id: opportunities-solutions-and-todo-items-never-get-t
title: "Opportunities, solutions, and todo items never get their stage/status closed out"
theme: Trust & evidence
status: draft
priority: high
provenance: user-stated
evidence_sources: [user-verbatim]
linked_objectives: []
related_to: [opportunities-and-plans-go-stale-with-no-freshness]
last_updated: 2026-07-03
---

## 1. Problem summary
When a solution has been implemented (shipped) or is no longer pertinent (deprioritized or invalidated), nothing advances the `status`/stage of the originating opportunity, its solutions, or any derived todo items. They stay stuck at whatever stage they were drafted at — `draft`, `defining`, `review`, `ready-for-solutions` — so the DB silently drifts from what's actually done or dead instead of reflecting it.

## 2. Value to the user
### Job to be done
A builder wants the opportunity/solution/todo DB to reflect reality at a glance — which problems are solved, which solutions shipped, which todos are done or abandoned — so they can trust the ranked lists (INDEX.md, the roadmap, a future prioritized todo list) without manually auditing whether each item is still live. The alternative today is the builder having to remember, unprompted, to go back and hand-edit `status:` on every affected file whenever something ships or gets dropped — which they don't reliably do.

### Where we fall short
**No close-out step tied to shipping or dropping work**
There is no mechanism — in `/pm-breakdown`, `/pm-retro`, or elsewhere — that, on detecting a solution was implemented (e.g. via `/pm-retro`'s roadmap-vs-commits comparison) or explicitly abandoned, writes back to advance the opportunity's and solution's `status` field accordingly.
- "opportunities, solutions and todo list needs to be updated (their stage) when a solution have been implemented or if no more pertinent" — Nicolas Martin, 2026-07-03

**Stale status pollutes every downstream ranking**
`INDEX.md`, the roadmap, and any future cross-type prioritization list all read from these `status`/`priority` fields. A shipped or dead item with a stale `ready-for-solutions`/`review` status keeps competing for attention against genuinely open problems.

## 3. Value to the company
Closes the loop the Opportunity Solution Tree assumes but doesn't enforce: an item can move opportunity → solution → PRD → breakdown, but nothing moves it back to "done" once delivered, or to "no longer pertinent" once dropped. Directly protects the trustworthiness of the ranked lists that [[no-single-mechanism-prioritizes-across-all-work-ty]] and [[roadmap-doesnt-orchestrate-into-living-plan]] depend on — a prioritization mechanism built on stale statuses would rank dead work alongside live work. Adjacent to [[opportunities-and-plans-go-stale-with-no-freshness]] (which is about content going stale from disuse) but distinct: this is about a specific, detectable event — implementation or de-prioritization — failing to trigger a status write-back.

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: /pm-retro (which already diffs roadmap NOW items against commits) writing back a "shipped" status to the matching opportunity/solution; an explicit "mark not pertinent" action surfaced wherever an opportunity/solution/todo is reviewed; a status field on derived todo items that /pm-breakdown or the future prioritization mechanism can close. -->
