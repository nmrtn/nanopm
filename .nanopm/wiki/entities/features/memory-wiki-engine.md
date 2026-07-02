---
id: memory-wiki-engine
type: feature
title: "Memory wiki engine"
status: active
provenance: evidence-backed
sources: [README.md, CHANGELOG.md, lib/nanopm.sh, bin/nanopm-ingest-agent, bin/nanopm-lint-agent, bin/nanopm-migrate-to-wiki, .nanopm/NANOPM-WIKI.md]
relates_to: [skill-pack, context-briefs, opportunity-solution-tree]
last_updated: 2026-06-29
---

## Summary
A maintained LLM-wiki (Karpathy pattern) that replaces the old append-only memory log with a small, always-current set of pages every skill reads at the start of a run. Three primitives — **query → reasoning → ingest** — let any skill read upstream context with citations, do its work, and write the result back as wiki pages; a **lint** pass keeps it honest after the fact. Everything nanopm produces (briefs, doc pages, entity pages) is wiki-canonical: a project's `.nanopm/` is `raw/` (immutable sources) + `wiki/` (all generated content) + `NANOPM-WIKI.md` (the contract).

## What it does
- Reads upstream context through a shared `nanopm_query_prompt` subagent that walks `wiki/index.md`, drills into only the pages that matter, and returns a cited synthesis — never raw doc dumps into the agent's context.
- Writes results back through `bin/nanopm-ingest-agent apply` — a locked, single-writer-per-file write that dedupes by citation before appending — then regenerates `wiki/index.md` and the heartbeat `wiki/log.md`.
- Health-checks itself via `bin/nanopm-lint-agent`: a cheap structural pass (orphans, broken links, stale pages, index drift) plus a once-a-day judgment pass that flags contradictions and reversals — surfaced in the next run's preamble (`LINT_JUDGMENT_DUE`).
- Migrates legacy flat docs into the wiki on first post-upgrade run via `bin/nanopm-migrate-to-wiki` (copy by default; `--finalize` removes the legacy original only when the wiki copy matches), and folds retired `reasoning/` sidecars into each page's inline `## Provenance & assumptions`.

## How it works
- The contract: `.nanopm/NANOPM-WIKI.md` (emitted by `nanopm_wiki_schema` in `lib/nanopm.sh`) names the three layers — `raw/` (immutable sources), `wiki/overview/` (the briefs), `wiki/entities/<type>/` (compounding pages), `wiki/docs/` (per-skill doc pages and dated collections).
- The three primitive prompts live in `lib/nanopm.sh`: `nanopm_query_prompt`, `nanopm_ingest_prompt`, `nanopm_lint_prompt` — every `pm-*` skill is recipe-form over them.
- The deterministic mechanics live in `bin/nanopm-ingest-agent` (citation dedup, `apply`, `reindex`, `log`) and `bin/nanopm-lint-agent` — host-agnostic Python so the same commands run on Claude / Vibe / Codex, with an inline fallback on hosts without an Agent tool.
- The single source of truth is `wiki/`: there is no pre-write approval queue and no `reasoning/` sidecar layer — write freely, lint surfaces, the user curates.

## Status
Shipped — 0.19.0 (engine + migration) through 0.22.0 (Karpathy-faithful three-primitive form, judgment lint wired). Regression-gated by `test/wiki-canonical.sh`, `test/memory-wiki.e2e.sh`, `test/migrate-wiki.e2e.sh`, and `test/ingest-path.sh`.

## Related
- [[skill-pack]] — every skill is a recipe over these primitives.
- [[context-briefs]] — the always-loaded `overview/company.md` + `overview/current-work.md` live in the wiki.
- [[opportunity-solution-tree]] — the OST entity pages are written through ingest and gated by lint.
- [[typed-state-layer]] — JSONL decisions still live alongside the wiki for typed, falsifiable records.
- [[wiki-export]] — `nanopm-export` renders a wiki section to one shareable file on demand.

*Sources: `.nanopm/NANOPM-WIKI.md`, `lib/nanopm.sh` (`nanopm_query_prompt`, `nanopm_ingest_prompt`, `nanopm_lint_prompt`, `nanopm_wiki_ensure`, `nanopm_migrate_on_upgrade`), `bin/nanopm-ingest-agent`, `bin/nanopm-lint-agent`, `bin/nanopm-migrate-to-wiki`, CHANGELOG 0.19.0/0.20.0/0.21.0/0.22.0.*
