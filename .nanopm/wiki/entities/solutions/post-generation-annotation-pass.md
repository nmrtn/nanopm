---
id: post-generation-annotation-pass
type: solution
title: "Post-generation annotation pass (`nanopm-annotate-agent` primitive)"
opportunity: cant-tell-evidenced-from-assumed
status: proposed
provenance: assumed
lens: eng
appetite: big-bet
impact: high
linked_objectives: [run-proof-quarter-clean-read]
last_updated: 2026-06-29
---

## Pitch
Add a deterministic post-generation annotation pass as a new shared primitive (`bin/nanopm-annotate-agent`). After a Plan skill writes its doc, a gated subagent re-reads the doc + the loaded `company.md` / `current-work.md` briefs + the wiki entity pages, and emits an annotated copy where each sentence-level claim gets a trailing `[E]` / `[U]` / `[N]` tag matching the fixed provenance vocabulary. The clean doc and the tagged doc both ship; the viewer toggles between them. This isolates calibration logic in one reusable primitive instead of asking every Plan skill template to remember inline citation grammar — a recipe over a new primitive, in keeping with the engine + recipes model.

## Riskiest assumption
A retrieval-grounded second LLM pass has materially lower fabrication than first-pass generation — i.e. that re-reading the wiki with the *specific* job of attribution produces more accurate tags than asking the original generator to do attribution alongside generation.

## Cheapest test
Hand-label 30 claims across one existing `docs/strategy.md` as E/U/N. Run a prototype annotation prompt with retrieval over `.nanopm/wiki/`. Score agreement with human labels. Need ≥85% agreement to justify the new primitive; below that, fall back to the inline-grammar approach instead.

## Dissent/tension note
A two-doc model violates the single-writer-per-file cleanliness invariant and doubles the surface the viewer must reconcile — risks blowing back open the bound-the-index target (2026-07-29). And adding a new shared primitive is exactly the "premature infrastructure" mistake the v0.4.0→v0.6.0 retro flagged.
