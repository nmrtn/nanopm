---
id: no-single-mechanism-prioritizes-across-all-work-ty
type: opportunity
title: "No single mechanism prioritizes across ALL work types into one next-best-action list"
theme: Continuity & retention
status: draft
priority: high
provenance: user-stated
evidence_sources: [user-verbatim]
linked_objectives: []
related_to: [roadmap-doesnt-orchestrate-into-living-plan, prioritize-opportunities-by-strategic-impact, loop-runs-itself-on-a-cycle]
last_updated: 2026-07-03
---

## 1. Problem summary
A solo builder's work is scattered across different kinds of items — ranked opportunities, shortlisted solutions, known bugs, small improvements, and raw feedback — each tracked (if at all) in its own place. Nothing looks across all of them together to decide the single next best action. The builder wants a prioritization mechanism that ingests this full mixed context and produces one prioritized todo list they can just work down — and, eventually, that an autonomous general agent could execute from directly without a human in the loop.

## 2. Value to the user
### Job to be done
When the builder sits down to work (or when an autonomous agent needs to pick up the next task), they want one ranked, actionable list spanning every kind of pending work — not just user-problem opportunities, but also bugs, small polish items, and unprocessed feedback — so "what should I do next" has one answer instead of requiring them to mentally merge several separate lists. The alternative today is manually triaging across the opportunity DB, solutions, an issue tracker, and memory of open feedback, with no single view and no consistent ranking logic tying them together.

### Where we fall short
**No cross-type prioritization mechanism**
Ranking exists only within a single artifact type (e.g. opportunities have a coarse `priority`), never across opportunities, solutions, bugs, small improvements, and feedback as one pool competing for the same next slot.
- "we may need to have a prioritization skill that considers all context (opportunities, solutions, bugs, small improvements, feedbacks etc) that prioritizes the next best action to do" — Nicolas Martin, 2026-07-03

**No actionable output — a todo list, not just a ranking**
Even a good ranking is inert unless it resolves into a concrete, workable list. The builder wants the output to be a literal prioritized todo list, not another document to interpret before deciding what to do.
- "Maybe even create a prioritized todo list for the human user, and thus later for the autonomous general agent." — Nicolas Martin, 2026-07-03

**Two audiences, one list**
The same mechanism needs to serve a human today and, later, feed an autonomous general agent directly — so the list can't be shaped only for human judgment calls; it needs to be structured enough for an agent to consume unattended.

## 3. Value to the company
This is the connective layer the loop's other open gaps depend on: [[roadmap-doesnt-orchestrate-into-living-plan]] wants opportunities+solutions+objectives turned into a living roadmap; [[prioritize-opportunities-by-strategic-impact]] wants an explicit ranking framework; [[loop-runs-itself-on-a-cycle]] wants a general agent driving the process end-to-end. None of the three, alone, covers ranking across bug/feedback/small-improvement inputs into one executable list — which is what an autonomous agent would need to actually pick up work without a human curating its queue first.

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: a triage skill that reads the opportunity DB, solutions, an issue tracker, and raw feedback, and emits one ranked, typed todo list; a shared scoring rubric usable by both a human and an agent; a "next action" primitive the autonomous loop (see [[loop-runs-itself-on-a-cycle]]) could call directly. -->
