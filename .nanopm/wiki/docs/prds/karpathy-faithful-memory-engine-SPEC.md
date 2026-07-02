# Trimmed-core spec — Karpathy-faithful memory engine

Companion to PRD `karpathy-faithful-memory-engine.md`. Drafted 2026-06-25 for co-sign with Nico before any code changes.

**Purpose.** Define the minimal core we route skills onto: the 3-layer wiki + three agent operations (ingest / query / lint) + index/log + dedup. Everything heavier is cut. This is the "engine"; skills are recipes on top.

**Good news from the code.** `nanopm_wiki_schema` (the generated `NANOPM-WIKI.md`) *already* describes ingest/query/lint, `index.md`, and `log.md`. So this isn't a rewrite — it's three surgical removals plus wiring one prompt that's already written. Touch-points are named in §5 so the diff is reviewable against the repo.

---

## 1. The schema (the contract)

Keep exactly as-is — it's already faithful:

```
.nanopm/
├─ NANOPM-WIKI.md        # the contract (flat by design)
├─ raw/                  # immutable sources (connector pulls, event log, snapshots)
└─ wiki/                 # all LLM-owned content
   ├─ index.md           # catalog — ALWAYS loaded (bounded; ## Collections for series)
   ├─ log.md             # append-only heartbeat: <op> ∈ ingest | query | lint | migrate
   ├─ overview/          # company.md, current-work.md (the two always-loaded briefs)
   ├─ docs/              # filed-back views (skill outputs, prds/, tasks/, …)
   └─ entities/          # compounding pages (personas, competitors, opportunities, …)
```

**Two changes to the schema (`NANOPM-WIKI.md` §11):**
- **Remove the confidence gate + `wiki/_review/` review surface.** §11 currently says ambiguous writes route to `_review/` for human confirmation. Replace with: *writes apply directly (single-writer-per-file is kept); contradictions and reversals are surfaced after the fact by the lint pass — in `log.md`, and optionally at preamble (see The One UX Decision in the PRD). No pre-write approval queue.*
- **Skiplist housekeeping files.** `entities/opportunities/INDEX.md`, `LOG.md`, `SCHEMA.md` (and the equivalent for any future entity collection) are **not** entity pages: exclude them from lint (`entity_pages()`) and from the index (`collect_pages()`). Reuse the dedup agent's existing skiplist. *(This is PR-#121 review item #2.)*

**Kept unchanged:** single-writer-per-file (§11), the page templates (§4 overview/entity/doc), dedup-by-citation, supersede-don't-delete, the two briefs, and — outside the engine — the skills and the adversarial PM gates.

---

## 2. The three operation prompts

### a. Ingest — `nanopm_ingest_prompt` (exists; one step changes)

Keep steps 1–5 and 7 verbatim (read schema+index → extract durable claims → pick entity page → **dedup by citation** → **supersede, don't delete** → reindex+log). **Replace step 6:**

> ~~6. Write each page THROUGH the confidence gate (`nanopm-confidence-gate apply …`)~~
> **6. Write the page directly (single-writer-per-file). If a claim reverses an established one, still write it, but tag the change in `log.md` (`--op ingest --reversal "<what flipped>"`) so the next lint pass can sanity-check it. No approval queue.**

### b. Query — `nanopm_query_prompt` (NET-NEW primitive)

The schema describes Query (§9) but there's no shared callable — skills each re-implement "read context, synthesize." Formalize it so skills call one primitive:

```
You are the nanopm query agent. Answer a question against the memory wiki,
conforming to .nanopm/NANOPM-WIKI.md (the contract).

Question: ${question}

Steps:
1. Read .nanopm/wiki/index.md; drill into the entity/overview/doc pages relevant
   to the question (don't read the whole wiki).
2. Synthesize an answer grounded in those pages, each load-bearing claim carrying
   its citation (verbatim — source, date), exactly as the pages store them.
3. If the answer is worth keeping (a reusable synthesis, not a one-off lookup),
   file it back as a docs/ page via the ingest path so explorations compound.
4. Append a query line: nanopm-ingest-agent log --op query --title "<question>".

Return the answer (with citations) as your output — it is the return value, not a
message to a human.
```

This is what a skill's "read upstream artifacts" phase *is* — a query. Skills become `query` (read what we know) → their own opinionated reasoning → `ingest` (file the answer back).

### c. Lint (judgment) — `nanopm_lint_prompt` (exists; wire it on + drop the gate)

The judgment prompt is already written (missing-but-expected contradictions, gaps, drift). Two changes:
- **Wire it.** Today only the deterministic `bin/nanopm-lint-agent` (structural: stale/orphans/edges/index-drift) runs. Make the lint agent dispatch the judgment prompt after the structural pass (the structural pass becomes a cheap pre-filter).
- **Replace step 3** (currently "route every write through `nanopm-confidence-gate`") with: *do not auto-fix; surface proposed fixes and any reversals/contradictions in `log.md` (and at preamble per the UX decision). Apply only unambiguous, high-signal fixes directly.*

**This is the load-bearing piece** — dropping the gate is only safe because this judgment lint catches contradictions after the fact. It must land **before** the gate is removed (sequence step 3 before 4), and it's exactly what the PRD's Falsification tests.

---

## 3. Migration-on-upgrade (the proper home for PR-#121 review item #1)

Instead of threading a flat-path fallback through ~10 per-doc reads, handle it once at upgrade:

- **Detect + auto-migrate on first post-upgrade run.** In the preamble, if legacy flat docs (`.nanopm/<X>.md`) exist and their `wiki/docs/<slug>.md` equivalents don't, run `nanopm-migrate-to-wiki` once in **copy mode**, print a one-line banner (`nanopm: migrated N docs into wiki/`), and continue. After this, every read resolves the wiki path — no skill ever sees "missing" and rebuilds over an existing doc.
- **`--finalize` matches before deleting (PR-#121 review item #3).** Only delete the legacy flat file when the wiki copy actually matches (content or mtime); otherwise keep it and log `kept — wiki copy differs`.
- **Net:** the per-doc reads stay wiki-only (simple), and the upgrade hole is closed at the migration boundary, not smeared across every read.

---

## 4. Cut / keep / build — the whole engine on one screen

| | |
|---|---|
| **Cut** | confidence gate (`bin/nanopm-confidence-gate`), the `wiki/_review/` queue + `nanopm_load_reviews` preamble surfacing, the mechanical-only lint as the *main* act, the gate calls in the ingest + lint prompts |
| **Keep** | 3-layer model, `index.md`/`log.md`, page templates, dedup-by-citation, supersede, single-writer-per-file, the two briefs; **and (outside the engine) the skills + the adversarial PM gates** |
| **Build / wire** | `nanopm_query_prompt` (new) + route **every reading skill** through it; **re-express all `pm-*` skills as recipes** (query → reasoning → ingest); wire `nanopm_lint_prompt` as the active judgment pass; the skiplist (#2); migration-on-upgrade (#1/#3) |

---

## 5. Diff from today — code touch-points (for review against the repo)

- `lib/nanopm.sh`:
  - `nanopm_ingest_prompt` — step 6 → direct write + reversal-tag-in-log.
  - `nanopm_lint_prompt` — step 3 → surface in log, no gate.
  - `nanopm_wiki_schema` — §11 rewrite (remove gate/`_review`; keep single-writer); add the housekeeping skiplist note.
  - **new** `nanopm_query_prompt`.
  - remove `nanopm_load_reviews` + its preamble call.
- `bin/`:
  - retire `nanopm-confidence-gate`.
  - `nanopm-lint-agent` — dispatch the judgment prompt after the structural pass.
  - `nanopm-ingest-agent` — `apply` writes directly (drop the gate hop); `entity_pages()` + `collect_pages()` skiplist INDEX/LOG/SCHEMA.
- skills — un-wire the ~5 signal skills (`pm-data`, `pm-personas`, `pm-user-feedback`, `pm-interview`, `pm-competitors-intel`) from the gate; then re-express **every** `pm-*` skill in recipe form (query → reasoning → ingest), routing all reading skills through `query`. Rolled out skill-by-skill within this PRD.
- preamble — add the migrate-on-upgrade detector + banner.

---

## 6. Open decisions to co-sign

1. **The One UX Decision** (from the PRD): contradictions surfaced *log-only* (faithful, quiet) vs *at preamble top* (visible, re-creates some "review surface" feel). Pick before wiring lint.
2. **Query reach:** internal primitive only for v1, or also a user-facing `/pm-ask`? (PRD: internal only for v1.)
3. **Ownership/sequence:** this spec assumes #121 merges first (with #2/#3 fixed), then steps 2→5 of the PRD sequence. Confirm Nico's happy to own/refine this spec or hand it back.

---

*Sources: `nanopm_wiki_schema` / `nanopm_ingest_prompt` / `nanopm_lint_prompt` in lib/nanopm.sh, the §9/§11 workflow sections of NANOPM-WIKI.md, Nico's PR-#121 review (comments 1 & 2), Karpathy's LLM-wiki gist.*
