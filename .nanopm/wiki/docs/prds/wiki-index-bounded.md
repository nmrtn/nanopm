# PRD: Bound the wiki index by construction
Hand-drafted 2026-06-24 (gates not executed)
Project: nanopm
Status: PROPOSED — LATER (promote just before ingest fan-out fills the catalog)

## Problem
The wiki catalog (`wiki/index.md`) is loaded into every run truncated at 6000 chars (`nanopm_load_index`, lib/nanopm.sh:750). Truncating a *brief* is harmless — you lose detail. Truncating the *catalog* silently hides pages past the cutoff: the agent cannot read-on-demand a page it can't see listed, so the "load the index, drill on demand" contract quietly breaks. Today the wiki is nearly empty so it never truncates. Once ingest fans out across personas / competitors / opportunities / objectives / features / people, the index crosses 6 KB and pages start disappearing from the agent's view — a scaling cliff that bites exactly when the wiki starts being valuable.

## Scope (when promoted to NOW)
### In scope
- Keep the index bounded **by construction** so it never needs char-truncation: either one terse line per page (cap per-line length in the reindex step), OR a two-level catalog (section overviews always loaded; per-section entity lists loaded on demand). Pick the simpler option that holds to ~150 pages.
- Remove the lossy `head -c 6000` on the catalog load — a brief may truncate, the catalog must not silently drop entries.
### Out of scope
- A search engine over the wiki — that is the separately-deferred `wiki-search-engine` PRD. This is the cheap pre-step that keeps `index.md` sufficient for longer.

## Revisit trigger (what promotes this from LATER to NOW)
Promote when ANY holds: the wiki crosses ~60 pages, OR `wiki/index.md` approaches 5 KB (just under the 6 KB load cap), OR the `wiki-pilot-validation` finding returns "go" on fanning out (fan-out is what grows the index). Until then, the current index comfortably fits the cap.

## Success criteria
- With a synthetic 150-page wiki, every page remains listed in the loaded catalog (zero silent drops) and the loaded index stays within budget.
- Deleting and rebuilding the index from `wiki/*.md` reproduces it identically (index stays a derived, disposable artifact).

## Ties to
- Parent: memory-wiki-redesign (index + loading rule §7).
- Sibling: wiki-search-engine (this defers the need for that by keeping `index.md` viable longer).
- Strategy/Objective: keeps the compounding wiki actually retrievable as it grows — the catalog must never hide what exists.
