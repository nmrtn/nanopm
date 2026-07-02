# PRD: Coherence lint between the two overview briefs
Hand-drafted 2026-06-24 (gates not executed)
Project: nanopm
Status: PROPOSED — NOW

## Problem
Two briefs are loaded into every skill run: `wiki/overview/company.md` (who we are) and `wiki/overview/current-work.md` (what we're building). Nothing checks they don't contradict each other. A realistic drift: company.md says "pre-PMF, primary persona = solo founder" while current-work.md's roadmap reads "Q3: enterprise contracts." The lint sleep pass (`nanopm_wiki_lint_check`, lib/nanopm.sh:784) checks the wiki for stale pages / orphans / broken edges — but not brief-vs-brief coherence. A silent contradiction means every downstream skill anchors on inconsistent context, which is exactly the drift the two briefs exist to prevent. These two pages carry ~95% of memory's value today, so their mutual consistency is the single highest-leverage integrity check.

## Scope
### In scope
- Add a check to `nanopm-lint-agent` (the deterministic sleep pass) that compares the two overview briefs on a small set of high-signal axes: company stage, primary persona / segment, and the named strategic bet vs the mission.
- Surface a **warning, not a block**, with the two conflicting lines quoted, in the once/day lint readout already wired into the preamble.
### Out of scope
- Auto-resolving the contradiction — the human (or the next regen) decides; lint only flags.
- Heavy semantic NLP — keep it a targeted heuristic plus, optionally, a single bounded LLM-judge pass consistent with how the lint agent already works.

## Success criteria
- On a seeded project whose two briefs disagree on stage or segment, the lint readout flags it with both offending lines within one run.
- Zero false positives on a coherent project across 5 runs.

## Ties to
- Parent: memory-wiki-redesign (the lint / "sleep" operation).
- Strategy/Objective: keeps the always-loaded baseline trustworthy. Highest value/effort ratio of the memory follow-ups — small deterministic check, protects the context every skill reads.
