---
id: pipeline-scoped-for-epics-not-micro-tasks
title: "The opportunity→solution→PRD→breakdown pipeline only fits big EPIC-scale projects, not small tasks"
theme: Build handoff
status: draft
priority: medium
provenance: user-stated
evidence_sources: []
linked_objectives: []
related_to: []
last_updated: 2026-07-03
---

## 1. Problem summary
nanopm's Opportunity Solution Tree — opportunity → `/pm-solutions` → `/pm-prd` → `/pm-breakdown` — assumes every unit of work is a big project worth the full discovery-through-spec treatment. In practice, a builder's backlog also holds a lot of small, obviously-worth-doing work: minor improvements, bug fixes, one-line polish. That class of work has no natural entry point into the current pipeline, since none of it clears the bar of "an opportunity worth brainstorming solutions for."

## 2. Value to the user
### Job to be done
The builder wants nanopm to be where ALL planned work lives — not just EPIC-scale bets — so a bug fix or small improvement can still be captured, tracked, and handed off without either (a) forcing it through a PRD it doesn't need, or (b) falling outside nanopm entirely into an ad hoc note or a bare ticket.

### Where we fall short
**No lightweight lane for small work**
Today the only door into planning is the opportunity → solutions → PRD → breakdown chain, sized for projects that justify a full Opportunity Solution Tree. A one-line bug fix or a small tweak doesn't need a problem statement, three competing solutions, and a spec — but it still needs a place to be captured and hand off to `/pm-breakdown`'s targets (Linear, GitHub Issues, etc.) alongside the EPIC-scale work, or builders will just skip nanopm for that entire class of task.
- "for now we handle opportunities / solutions scope then PRD / breakdown. It's generally big projects, EPIC, but we'll need other kind of micro tasks (small improvements, bugs etc.)" — Nicolas Martin, 2026-07-03

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: a lightweight micro-task entry that skips solutions/PRD and goes straight to /pm-breakdown; a task "size" field on breakdown items (epic vs. task vs. bug) that routes each through the right amount of process. -->
