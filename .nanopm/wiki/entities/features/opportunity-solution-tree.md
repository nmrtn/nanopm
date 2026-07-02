---
id: opportunity-solution-tree
type: feature
title: "Opportunity Solution Tree"
status: active
provenance: evidence-backed
sources: [README.md, CHANGELOG.md, pm-opportunities/SKILL.md, pm-solutions/SKILL.md, lib/nanopm.sh]
relates_to: [memory-wiki-engine, adversarial-gates, skill-pack]
last_updated: 2026-06-29
---

## Summary
The Teresa-Torres-style Opportunity Solution Tree, materialized as two compounding wiki entity types and the two skills that build them. `/pm-opportunities` maintains a ranked database of user problems (Theme → Opportunity, two levels, no numeric score); `/pm-solutions` takes one opportunity and brainstorms a *compared set* of candidate solutions through a three-lens panel (Eng / Design / Business), so a founder weighs alternatives instead of jumping from the first idea straight to a PRD. Together they fill the Outcome → Opportunity → Solution → Assumption chain that planning used to skip.

## What it does
- **Opportunities DB.** `bootstrap` drafts an initial set from feedback + the founder's own assumptions + Nano hypotheses, each tagged by provenance (`evidence-backed` / `user-stated` / `nano-hypothesis`); `add` captures one problem at a time. Every write goes through a reusable dedup subagent (`nanopm_opportunity_dedup_prompt`) — confidence ≥ 8 is a high-confidence match — and the index is deterministically regenerated from frontmatter.
- **Solutions panel.** Three fixed expert lenses — Eng (structural cost, not dev-time) · Design (experience anchored on the persona's JTBD) · Business (market anchored on objectives) — dispatched concurrently to diverge, then a convergence pass dedups into ≥ 3 framed solutions. Each carries a pitch, appetite (Shape-Up small/big bet), qualitative impact, riskiest assumption, cheapest test, originating lens, and a one-line dissent note. The founder shortlists and chooses; the agent never auto-chooses.
- **A navigable tree, not buried notes.** Each opportunity links to its solutions; each solution has exactly one parent opportunity (the tree edge), bidirectionally navigable from either end in the viewer.
- **The loop closes end-to-end.** Downstream Plan skills (objectives, strategy, roadmap, discovery) query for the top-ranked open opportunities; `/pm-prd <chosen-solution>` seeds the spec's problem, riskiest assumption, and falsification from the chosen solution and its parent.

## How it works
- Storage: `.nanopm/wiki/entities/opportunities/<slug>.md` and `.nanopm/wiki/entities/solutions/<slug>.md`, each with their schema (`nanopm_opportunities_schema` / `nanopm_solutions_schema`) and a deterministic reindexer (`nanopm_opportunities_reindex` / `nanopm_solutions_reindex`) that emits a ranked `INDEX.md` from page frontmatter.
- Read-side: `nanopm_plan_brief_prompt` carries a "Top open opportunities" section into `wiki/overview/current-work.md`, so every skill run sees the freshest signal.
- Write-side: `opportunity` and `solution` are registered types across the ingest / migrate / state-log layers, with three lint rules for solutions (orphan, missing assumption/test, `chosen` without PRD).
- Surface: the viewer's Discover phase renders a single ranked Opportunities table and a filterable Solutions table with bidirectional opportunity↔solution navigation.

## Status
Shipped — `/pm-opportunities` (0.15.0) + viewer Opportunities table (0.16.0) + viewer Add menu and dedup agent (0.18.0); `/pm-solutions` (0.24.0); discover→plan loop closed (0.23.0). Regression-gated by `test/opportunity-loop.sh` and the `pm-solutions` checks in `test/skill-syntax.sh`.

## Related
- [[memory-wiki-engine]] — opportunities and solutions are wiki entity types, written through the ingest primitive.
- [[adversarial-gates]] — a chosen solution feeds the falsifiable bet that `/pm-prd` is gated on.
- [[skill-pack]] — `/pm-opportunities` and `/pm-solutions` are the two skills that build the tree.

*Sources: `pm-opportunities/SKILL.md`, `pm-solutions/SKILL.md`, `lib/nanopm.sh` (opportunity/solution helpers), CHANGELOG 0.15.0 / 0.16.0 / 0.18.0 / 0.23.0 / 0.24.0.*
