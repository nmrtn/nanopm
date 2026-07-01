# Solutions DB — Schema & Conventions

This file is the single source of truth for how `.nanopm/wiki/entities/solutions/` is
structured. `/pm-solutions` reads it on every run and conforms to it. You may
edit it (e.g. adjust the template, tune the lenses) — the skill follows whatever
this file says.

## The tree — exactly one parent
A solution is the **Solutions** node of the Opportunity Solution Tree
(Outcome → Opportunity → **Solution** → Assumption). It belongs to **exactly one**
parent opportunity (the `opportunity` frontmatter field — a single opportunity slug).
That one-parent rule is what makes the set a navigable tree, not a graph. A solution
serving "multiple opportunities" is out of scope at v1 — split it or pick the primary
parent. The deliverable of a run is the *comparison* of ≥3 sibling solutions under one
opportunity, never a single idea.

## Lens (the originating expert voice) — keep the room visible
Every solution records which lens proposed it:
- `eng` — structural/durable cost (code complexity, migrations, external-API cost,
  maintainability, scalability) — NOT dev time. A build can ship fast under an agent.
- `design` — experience, flow, delight; anchored on the personas' job-to-be-done.
- `business` — domain expertise and field/market knowledge; anchored on objectives +
  strategy.
The lens is preserved on the converged comparison so the cross-functional tension that
justifies the panel stays visible — never collapsed into an anonymous verdict.

## Appetite (Shape Up — a constraint, NOT an estimate)
`small-bet | big-bet` — how much the solution is *worth* spending against, in the
Shape Up sense. It is a budget the work fits into, not a prediction of how long it
takes. No numeric estimate is stored.

## Impact (qualitative — like opportunity priority)
`high | medium | low` — a coarse read of expected value, Nano-proposed and
user-overridable. There is **no numeric score** in v1; no impact number is ever
presented as fact.

## Provenance — always `assumed` at birth
Every solution is born `assumed`: it is a hypothesis the panel generated, not an
evidence-backed claim. No impact number is presented as fact. Validate via the cheapest
test, not via the brief.

## Status workflow
`proposed → shortlisted → chosen → speccing`
The agent never auto-selects `chosen` — the founder shortlists, then chooses, by hand.
`speccing` is set when `/pm-prd` consumes the chosen solution.

## Solution file template — `.nanopm/wiki/entities/solutions/<slug>.md`
```markdown
---
id: <kebab-slug>
type: solution
title: "<the proposed solution, in plain language>"
opportunity: <one parent opportunity slug>   # EXACTLY one — this is the tree edge
status: proposed              # proposed | shortlisted | chosen | speccing
lens: eng                     # eng | design | business  (the voice that proposed it)
appetite: small-bet           # small-bet | big-bet  (Shape Up constraint, not an estimate)
impact: medium                # high | medium | low  (qualitative; no numeric score)
provenance: assumed           # always assumed at birth — a panel hypothesis
linked_objectives: []         # optional KR ids the solution serves
last_updated: <YYYY-MM-DD>
---

## Pitch
<2–4 sentences: what the solution is and how it addresses the parent opportunity.>

## Riskiest assumption
<the single assumption most likely to be wrong and most damaging if it is —
choose what to spec by what's least proven, not by what sounds most impressive.>

## Cheapest test
<the cheapest experiment that would confirm or kill the riskiest assumption.>

## Dissent/tension note
<one line — keeps the originating lens's disagreement visible, e.g.
"Eng: cheap but caps scale at ~1k users".>
```

## INDEX.md
Generated, never hand-edited. Grouped by parent `opportunity`; within a group ordered
by `status` (chosen → shortlisted → speccing → proposed) then `last_updated` (newest
first). One line per solution: title (link) · lens · appetite · impact · status ·
last_updated.

## LOG.md
Append-only heartbeat. One line per change: `<date> | <action> | <slug(s)> | <provenance>`.
