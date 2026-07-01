# Opportunity DB — Schema & Conventions

This file is the single source of truth for how `.nanopm/opportunities/` is
structured. `/pm-opportunities` reads it on every run and conforms to it. You may
edit it (e.g. rename themes, adjust the template) to tune the database — the skill
follows whatever this file says.

## Granularity — exactly two levels
- **L1 Theme** — a grouping (e.g. "Model representation", "Consistency").
- **L2 Opportunity** — the tracked unit: one user problem you could brainstorm
  solutions against.
- Never go deeper. "Where we fall short" bullets inside an opportunity are facets
  of that one opportunity, NOT a third level. Prefer appending to / merging with an
  existing opportunity over creating a near-duplicate.

## Themes (L1)
<!-- bootstrap proposes these from your context; edit freely. One per line. -->
- Context upkeep
- Continuous discovery
- Opportunity intelligence
- Build handoff
- Outcome learning
- Loop autonomy & trust

## Provenance — always explicit
Every opportunity (and every evidence item) carries one:
- `nano-hypothesis` — inferred by Nano from company/product context, no external
  evidence yet. Low confidence.
- `user-stated` — asserted by you (the PM). A real human belief, unvalidated.
  Medium confidence.
- `evidence-backed` — derived from connected insight sources (verbatims, data,
  tickets). Confidence scales with volume/quality.
Agent-linked evidence whose match is uncertain is tagged `⚠ low-confidence` until
a human confirms it.

## Priority (the ranking, no scoring at v1)
`high | medium | low` — a judgment, Nano-proposed and user-overridable. There is no
numeric score in v1.

## Status workflow
`draft → defining → review → ready-for-solutions`

## Evidence attribution format
`"<verbatim quote or data point>" — <source>, <date>` (append ` ⚠ low-confidence`
for uncertain agent-linked matches).

## Opportunity file template — `.nanopm/opportunities/<slug>.md`
```markdown
---
id: <kebab-slug>
title: "<the user problem, in plain language>"
theme: <one L1 theme>
status: draft                 # draft | defining | review | ready-for-solutions
priority: medium              # high | medium | low  (judgment)
provenance: nano-hypothesis   # nano-hypothesis | user-stated | evidence-backed
evidence_sources: []          # e.g. [user-verbatim, behavioral-data, market-signal]
linked_objectives: []         # optional KR ids from OBJECTIVES.md
last_updated: <YYYY-MM-DD>
---

## 1. Problem summary
<2–4 sentences: the user problem, why it exists, who it affects.>

## 2. Value to the user
### Job to be done
<what the user is trying to accomplish, and the alternative today.>
### Where we fall short
**<sub-problem>**
<description>
- "<verbatim>" — <source>, <date>

## 3. Value to the company        <!-- optional: qualitative strategic fit -->
## 4. Success criteria             <!-- optional -->
## 5. Solution hypotheses          <!-- pointer only — stay in problem space -->
```

## INDEX.md
Generated, never hand-edited. Grouped by theme; within a theme, ordered by
`priority` (high→low) then `last_updated` (newest first). One line per opportunity:
title (link) · priority · provenance · last_updated — one-line summary.

## LOG.md
Append-only heartbeat. One line per change: `<date> | <action> | <slug(s)> | <provenance>`.
