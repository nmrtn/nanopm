# nanopm memory redesign — LLM-wiki proposal

Status: proposal for review
Author: Guillaume
Audience: Nico

A proposal to turn nanopm's memory from an append-only log into a compounding,
self-maintaining knowledge wiki, built on the pattern Karpathy describes in
[llm-wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).
No new infrastructure — just markdown, git, and subagents.

---

## 1. The problem

Every skill run loads, on top of our two summaries, the **entire raw event log**
(`nanopm_context_all`). That log is:

- **append-only and unbounded** — it grows forever, one line per skill run
- **never deduplicated** — re-running a skill stacks another near-identical line
  (vision-mission appears ~7 times today)
- **partially corrupted** — values containing newlines split a record across two
  lines, so we feed invalid JSON into every run
- **full of legacy noise** — retired skills (`pm-scan`, `pm-audit`) still load

Today that's ~50 lines / 13KB of duplicated, half-broken records injected into 16
skills on every invocation. It is not memory — it is a transcript we re-read in
full each time.

The ambition behind it is right: give Nano always-available context so downstream
work doesn't drift. The **mechanism** is naive — "keep everything + reload
everything" is not memory, it's a growing pile.

## 2. The insight: we're already half-way there

We don't need a rewrite. In Karpathy's terms, nanopm already has most of the
pieces — they're just scattered and unnamed:

| Karpathy concept | What we already have |
|---|---|
| `overview` synthesis pages | our two summaries (CONTEXT-SUMMARY, PLAN-SUMMARY), always loaded |
| a full wiki section | `opportunities/` (index + log + schema + one page per item) |
| raw → wiki layer | Define docs + reasoning sidecars (our Evidenced/Assumed calls are provenance) |
| adversarial write-gate | `pm-challenge-me` |

The fix is to **name the pattern, unify the scattered pieces under it, and add the
few primitives we're missing.** The gist says it plainly: *the real product is
the schema.*

## 3. The approach: one LLM-wiki, three layers

```
.nanopm/
  NANOPM-WIKI.md         # THE SCHEMA — librarian instructions. The file that makes it work.
  raw/                   # SOURCES, immutable. Never edited, never loaded whole.
    feedback/  intel/  data/  interviews/  git-activity/  events.jsonl
  wiki/                  # LLM-owned. Interlinked markdown.
    index.md             # catalog (1 line/page). ALWAYS loaded.
    log.md               # chronological, greppable (## [date] ingest | Title)
    overview/
      company.md         # = today's CONTEXT-SUMMARY (Define synthesis)
      current-work.md    # = today's PLAN-SUMMARY (Plan synthesis)
    entities/            # the primitive that unlocks scale (see §4)
      personas/  competitors/  opportunities/  objectives/  features/  people/
    docs/                # skill outputs = views filed back into the wiki
      vision-mission.md  strategy.md  roadmap.md  prds/ ...
```

**Three layers:**

1. **Raw sources** — immutable inputs (connector pulls, interviews, our typed
   event log). The LLM reads them, never rewrites them. Never loaded in full.
2. **Wiki** — the LLM-owned markdown layer: an index, a log, the two overview
   syntheses, entity pages, and skill docs filed back as views.
3. **Schema** (`NANOPM-WIKI.md`) — the instructions that make the agent a
   disciplined wiki maintainer instead of a generic chatbot. Conventions, page
   formats, and the ingest/query/lint workflows. We co-evolve it over time.

**Karpathy's three operations map onto nanopm's phases:**

| Operation | nanopm skills | What changes |
|---|---|---|
| **Ingest** (source → integrated across the wiki) | Discover (feedback, intel, data, interview) | today they *overwrite a doc*; instead they *integrate* across entity pages + index + log |
| **Query** (read wiki → synthesize → **file the answer back**) | Plan, Build, Daily Ops | the output (strategy, PRD, standup) becomes a wiki page instead of dying in chat |
| **Lint** (health: contradictions, stale, orphans, gaps) | staleness check + new | from a *warning to the human* to a *maintenance pass* |

## 4. The unlock: entity pages

Today nanopm produces **documents** — one per skill. The power of the wiki pattern
comes from **entity pages** that many sources update over time.

Our natural entities: **personas, competitors, opportunities, objectives,
features, and people** (including the founders).

Example: a user interview, a competitor intel pull, and an Amplitude metric all
touch the same `entities/personas/theo.md` — instead of living isolated in
FEEDBACK.md, COMPETITORS.md, and DATA.md. The entity page **compounds**; the skill
docs become point-in-time **views** synthesized from it. This is what turns "50
log lines" into knowledge that gets richer with every source.

## 5. Where subagents fit

Subagents do the bookkeeping in their own context, so the raw layer never bloats
the main run.

| Subagent role | When | Why a subagent |
|---|---|---|
| **Ingest / bookkeeper** (per source/section) | after each Discover run, or when a source is dropped | reads raw in *its own* context, integrates across 10-15 pages, updates index + log. Raw never touches the main run. Generalizes our existing summary-regen subagent + the opportunities dedup agent. |
| **Lint / sleep** (background) | when staleness fires, or on a schedule | contradictions, stale claims, orphan pages, gaps. The "sleep phase." Ideal background job. |
| **Query / librarian** (optional, at scale) | a question spanning many pages | searches + synthesizes, returns a filed-back page. Not needed while the index suffices (~hundreds of pages). |
| **Challenge** (already exists) | write-gate for high-stakes knowledge | `pm-challenge-me` is the adversarial filter before a claim is promoted. |

**Not subagents:** loading (bash, deterministic, cheap — index + the two
overviews) and single-file recall (the main agent just reads the file). Never put
an agent on the critical path of startup.

Across hosts (Claude / Vibe / Codex), subagent dispatch stays **gated** and
**degrades gracefully**: no Agent tool available → the main agent does a
lightweight inline update, or marks the summary stale for the next run. Control
always stays with the main agent.

## 6. Scalability rules

These keep the wiki correct as it grows (drawn from the pattern and its
practitioners):

1. **Provenance on every claim** (source citation in frontmatter) → ingest becomes
   **idempotent and commutative**: grep the citation *before* writing = dedup at
   write time. Direct fix for today's duplicate and broken records. Dedup keys on
   a **stable identity** (the source), not text proximity.
2. **Supersede, don't delete** — knowledge is replaced, never erased. We keep what
   was believed, when, and what replaced it. Our reasoning sidecars already lean
   this way.
3. **One writer per file** (partition by section/entity) — parallel ingest agents
   don't collide, git auto-merges. Lets us run ingest in **waves**, like
   pm-breakdown already does.
4. **Confidence-gated writes** — high-confidence updates auto-apply; ambiguous ones
   (e.g. a strategy reversal) go to a review queue surfaced to the human. No LLM
   silently overwriting correct knowledge. Matches our adversarial DNA and our
   Evidenced/Assumed calls.
5. **Markdown + git is the only source of truth** — any search index (BM25/vector)
   is disposable and rebuildable, added later only if the index file stops
   scaling. Not load-bearing.

## 7. The loading rule

- **Always loaded**: `wiki/index.md` + `overview/company.md` +
  `overview/current-work.md`. Bounded and clean.
- **On demand**: the index points to the relevant entity/doc page → the agent
  reads that page.
- **Raw (`raw/`, the typed event log)**: never auto-loaded. Episodic source,
  queried only by skills that need it (pm-retro, lint).

`nanopm_context_all` **disappears** from the preamble. What it provided, the
ingest agent has already digested into the pages and overviews.

## 8. What we keep, change, drop

- **Keep**: both summaries, the opportunities wiki, reasoning sidecars, the
  challenge gate, the typed event log.
- **Change**: stop loading the raw log every run (load index + overviews only);
  generalize the regen subagent into a parameterized ingest agent; add entity
  pages.
- **Drop**: `nanopm_context_all` from the preamble.

## 9. Migration path (build on what ships)

1. **Write `NANOPM-WIKI.md`** (the schema/librarian). Highest leverage — the rest
   follows. Generalize the opportunities SCHEMA to the whole wiki.
2. **Re-file existing pieces** into the three layers (zero loss:
   CONTEXT-SUMMARY → overview/company, opportunities already there, docs → docs/).
3. **Generalize the regen subagent into a generic ingest agent**, parameterized by
   section, with provenance-dedup + supersede + confidence gating + host fallback.
4. **Cut `nanopm_context_all`** from the preamble; load index + overviews.
5. **Add entity pages** incrementally (personas and opportunities first — we
   already have them).
6. **Promote the staleness check into a lint agent** later.

## 10. Net effect

Bounded, self-cleaning, compounding memory. No new infrastructure — just markdown,
git, and subagents doing the bookkeeping nobody wants to do. We build on what
already ships rather than rebuilding.

**Next step:** draft `NANOPM-WIKI.md` (the schema) and co-evolve it from there.
