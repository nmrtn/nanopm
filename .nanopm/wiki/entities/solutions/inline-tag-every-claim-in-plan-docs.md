---
id: inline-tag-every-claim-in-plan-docs
type: solution
title: "Inline-tag every claim in Plan docs"
opportunity: cant-tell-evidenced-from-assumed
status: proposed
provenance: assumed
lens: eng, design
appetite: small-bet
impact: high
linked_objectives: [run-proof-quarter-clean-read]
last_updated: 2026-06-29
---

## Pitch
Extend the wiki-canonical inline citation grammar (`"<verbatim quote or data point>" — <source>, <YYYY-MM-DD>`, with `⚠ low-confidence` or a `nano-hypothesis` marker where applicable) to the Plan-phase skills — strategy, roadmap, PRD — so every load-bearing claim ships with its provenance attached in the prose. Concretely: bring `docs/strategy.md` and `docs/roadmap.md` (plus the PRD template) up to the `## Provenance & assumptions` template `docs/product.md` already implements (NANOPM-WIKI.md §4.3), and update each Plan skill to emit citations at write time. Design layers visible chips/badges (`[E]`/`[U]`/`[N]`) over the same grammar in the viewer; the markdown stays portable to Vibe/Codex hosts. No new file types, no new sidecar — this is migration debt being paid, not new architecture.

## Riskiest assumption
LLM generation reliably emits well-formed citations inline at write time without a deterministic post-pass — and `nanopm-lint-agent`'s structural pre-filter can catch missing/malformed citations on Plan docs the same way it does on Define docs.

## Cheapest test
Add the §4.3 template to `/pm-strategy` only, regenerate one real `docs/strategy.md`, run `nanopm-lint-agent` against it, and count (a) load-bearing claims emitted with valid citation grammar on first pass, and (b) lint false-positive rate. Ship to roadmap + PRD if ≥80% of claims carry valid grammar on first pass.

## Dissent/tension note
Design: parenthetical citations bloat prose and Theo skims — visible-to-the-eye markers (chips, color) may serve calibrated confidence better than text, but they ride on top of this grammar, not instead of it.
