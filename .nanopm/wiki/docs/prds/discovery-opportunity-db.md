# PRD: Discovery Opportunity DB + `/pm-opportunities` skill
Hand-drafted 2026-06-17 in pm-prd standard format (Phase 4b panel run; state not logged) · Status: DRAFT
Project: nanopm

> This is the definitive scope for the committed **NOW** roadmap item "Discovery Opportunity DB v0"
> (PLAN-SUMMARY 2026-06-16, Guillaume + Nicolas, 2 eng-week appetite). It **refines** the one-line
> roadmap scope in two founder-made ways, flagged for confirmation:
> 1. **Structure:** the roadmap implied a single `OPPORTUNITIES.md`; this PRD specifies an
>    `.nanopm/opportunities/` **folder** (an LLM-wiki: one file per opportunity + index + log + schema).
> 2. **Scoring removed from v1:** the roadmap line said "OBJECTIVES-KR impact score"; per Guillaume's
>    2026-06-17 call, numeric scoring is **out of v1** — ordering is a coarse qualitative `priority`.
>    ROADMAP.md / PLAN-SUMMARY.md should be updated to match.
>
> Pattern reference: Karpathy's "LLM Wiki" (persistent compounding artifact + schema config + ingest/lint
> + index/log), instantiated as a *typed* opportunity DB rather than a free-form wiki.

---

## Problem Statement

A core PM discipline (Teresa Torres' continuous discovery) is keeping a **ranked, always-current database
of user opportunities** — the problems/needs behind what you build, not the solutions. Today nanopm has
no such object: `FEEDBACK.md` is a periodic firehose of clustered themes + verbatims (and is currently
absent on this very repo), and `ROADMAP.md` jumps from raw signal straight to committed NEXT items. The
problem space — *what hasn't been solved yet, with what evidence, at what confidence* — evaporates between
runs instead of compounding. This is the exact failure nanopm exists to prevent, applied to discovery:
per CONTEXT-SUMMARY, "planning compounds across sessions instead of evaporating in ChatGPT threads" —
except the opportunity layer doesn't compound at all.

For **Terminal-native Theo** (primary persona, PERSONAS.md §1), whose job-to-be-done is "catch
wrong-direction work before he spends weeks shipping it" and "make planning compound across sessions,"
the missing piece is a problem-space backlog he can trust: one that records *who has the problem, with
what intensity, and how sure we are* — and that an agent keeps current so he doesn't have to. Without it,
prioritization runs on memory and vibes, which is "vibes wearing a PRD's clothing" (PERSONAS.md).

This is also strategic, not just hygienic: STRATEGY.md "How We Win #1" is **multi-source signal synthesis
into opportunity/gap mapping**, and PLAN-SUMMARY (2026-06-16) makes the Discovery Opportunity DB the
**lead killer-demo and recruitment hook** for the Q3 proof cohorts (OBJ1 KR2). The DB is both the
discipline Theo lacks and the artifact we lead recruitment with.

This is internal tooling, pre-PMF, two-person side project — one user on record (the founders),
`build_mode=solo-fast` (unset → default). Every user-behavior claim here is observed-personally
hypothesis, not instrumented.

---

## User Stories

- As **Theo**, when I start planning, I want a single ranked list of the user problems we've identified —
  each one clickable into a detail page with its evidence — so I prioritize against a standing problem
  space, not whatever I remember this week.
- As **Theo pre-evidence**, I want to dump my own hunches and let Nano pre-fill plausible opportunities
  from the company context, **clearly marked** as my assumption vs. Nano's hypothesis vs. evidence-backed,
  so a low-confidence guess never masquerades as a validated problem (ETHOS #4, Evidence Before Conviction).
- As **Theo**, when new signal arrives (an interview, a feedback batch), I want the agent to file it into
  the right existing opportunity or propose a new one — at a sane granularity, not 400 micro-problems — so
  the database stays current as a byproduct of discovery, not a separate chore.

---

## Success Criteria

| Criteria | How Measured | Target |
|----------|-------------|--------|
| `bootstrap` produces a usable problem space on a real repo | Run `/pm-opportunities bootstrap` on nanopm (FEEDBACK absent) | 5–12 opportunities at Theme→Opportunity altitude, each with a provenance tag; `INDEX.md` + ≥5 detail files written |
| Provenance is never ambiguous | `grep` frontmatter across `opportunities/*.md` | 100% carry a valid `provenance` value; every `evidence-backed` opp cites ≥1 attributed quote/data point; fail if any file is missing or invalid |
| Granularity guardrail holds | Review the generated set (two checks) | (a) 0 opportunities nest deeper than L2 — no opportunity file points to a child opportunity; (b) no two opportunities describe the same user problem (reviewer judgment) |
| The artifact renders in the viewer | Open the viewer after a run | `.nanopm/opportunities/` files appear under the **Discover** phase; `INDEX.md` opens and its links resolve |
| Killer-demo reaction (the roadmap bet) | Show generated DB to 5 cold-DM'd friend-PMs | ≥3 reply with unprompted positive reaction or a named concrete use case by 2026-07-14 |
| What will be different in commits after this ships? | Review git log 7 days post-ship | New `skills/pm-opportunities/SKILL.md`; `lib/nanopm.sh` gains an opportunity bootstrap/render helper set + a `SCHEMA.md` writer; `.nanopm/opportunities/{SCHEMA,INDEX,LOG}.md` + per-opportunity files generated on first run; viewer `PhaseMapper` (Models.swift) gains `"opportunities"` → Discover; `test/skill-syntax.sh` `_SKILLS` array gains `pm-opportunities`; `setup` registers the new skill |

**Anti-goals (v1):** Not building numeric scoring or a ranking formula (deferred — Open question). Not
building the continuous auto-ingest/matcher loop or the `lint` health pass (v2). Not wiring opportunity
updates as a side effect into `pm-user-feedback`/`pm-interview`/`pm-data` (v2). Not a dedicated ranked
viewer view or `[[wiki-link]]` rendering (v2 — respects the "viewer polish beyond what Discovery DB v0
needs" anti-goal, PLAN-SUMMARY). Not a work tracker — opportunities are problem-space objects the agent
maintains and hands off downstream, never a Linear/Notion replacement (PERSONAS.md anti-persona;
"rebuilding a tracker" anti-goal).

---

## Falsification

**The committed bet (PLAN-SUMMARY NOW item #1).** Within 21 days of shipping Discovery Opportunity DB v0
to `main` — by **2026-07-14** — of **5 cold-DM'd friend-PMs** (terminal-comfortable, shown the generated
`.nanopm/opportunities/` for a sample or their own repo), **fewer than 3** reply with an unprompted
positive reaction **or** a named concrete use case. If 3 of 5 don't bite by that date, the bet that an
agent-maintained opportunity DB is the killer demo / recruitment hook (OBJ1 KR2) is wrong, and the DB is a
PM-hygiene nicety, not an adoption lever.

*(NUMBER: 3 of 5 · SEGMENT: cold-DM'd terminal-comfortable friend-PMs · BEHAVIOR: unprompted positive
reaction or named concrete use case · TIMEFRAME: by 2026-07-14. Solo-fast: observed personally via DM
replies, no instrumentation.)*

---

## Scope

### In scope (v1 — the ~2 eng-week killer demo)

- **`.nanopm/opportunities/` folder** as the artifact: `SCHEMA.md` (conventions), `INDEX.md` (the ranked
  wiki home), `LOG.md` (append-only heartbeat), and one `<slug>.md` per opportunity. (See Appendix for shapes.)
- **`/pm-opportunities` skill, two modes:**
  - `bootstrap` — first run. Loads CONTEXT-SUMMARY + PLAN-SUMMARY (preamble), pulls `FEEDBACK.md`/`DATA.md`
    via a retrieval subagent **if present**, collects user assumptions, lets Nano propose hypotheses, then
    **fans out subagents** to draft the initial opportunity set at Theme→Opportunity altitude, writes the
    folder, generates `INDEX.md` + `LOG.md`.
  - `add` — capture one problem the user dictates, or let Nano pre-fill one, as a new/updated opportunity
    (low/medium confidence, provenance-marked).
- **Provenance taxonomy** on every opportunity and every evidence item: `nano-hypothesis` / `user-stated`
  / `evidence-backed`, plus a `⚠ low-confidence` flag on any agent-linked evidence pending review.
- **Granularity guardrail:** exactly two levels, Theme (L1) → Opportunity (L2); the drafting subagents are
  prompted to prefer merging into an existing opportunity and never nest deeper.
- **Human review gate:** `bootstrap`'s proposed set and any new opportunity are shown for confirmation
  before write; the user can drop/merge/rename before it lands.
- **`INDEX.md` ordering** by coarse `priority: high|medium|low` (Nano-proposed, user-overridable), grouped
  by theme — regenerated from frontmatter on every write.
- **Viewer:** `PhaseMapper` recognizes `.nanopm/opportunities/` → **Discover**; `INDEX.md` + detail files
  render via the existing markdown view. (Reuses current rendering — no new view.)
- **Registration:** `setup` installs the skill; `test/skill-syntax.sh` validates it.

### Out of scope (v1) — revisit as v2

- **Numeric scoring + ranking formula** (composite + sub-scores + momentum decay + scoring log) — deferred
  by founder decision 2026-06-17; revisit once there's enough real opportunity volume to calibrate weights.
- **`ingest` mode + the matcher subagent** (route a batch of insights → append/new/discard) — the
  continuous-update loop. v2.
- **`lint` mode** (audit: stale/thin/orphan/duplicate opportunities + coverage gaps) — v2; this is what
  restores "freshness" without scoring.
- **Side-effect wiring** — making `pm-user-feedback`/`pm-interview`/`pm-data` trigger an opportunity update
  on completion (the "no new skills, update as a byproduct" mechanism). v2.
- **`query` mode** (answer questions over the DB, file findings back) — v2; converges with `pm-brainstorm`.
- **Rich viewer** — dedicated ranked home view + `[[wiki-link]]` navigation. v2.

---

## Requirements

### Functional requirements

1. **Preamble & context.** The skill sources `lib/nanopm.sh`, runs `nanopm_preamble`, and works from the
   CONTEXT-SUMMARY + PLAN-SUMMARY briefs the preamble already loads (`nanopm_load_context`,
   `nanopm_load_plan`) — so every opportunity is judged against who we are and what we're betting on.
2. **Mode detection.** Mirror `nanopm_define_mode`: detect `bootstrap` (no `.nanopm/opportunities/` yet)
   vs. an existing DB; accept an explicit mode arg (`bootstrap`/`add`). Unknown/no arg → ask.
3. **Schema first.** On `bootstrap`, write `.nanopm/opportunities/SCHEMA.md` *before* drafting
   opportunities. SCHEMA.md is the single source of structural truth (template, theme vocabulary,
   granularity rule, provenance taxonomy, priority + status conventions, evidence-attribution format). Both
   modes **read SCHEMA.md** and conform to it. The user can edit SCHEMA.md to tune the DB without touching
   the skill.
4. **Bootstrap inputs, in priority order.** (a) `FEEDBACK.md` / `DATA.md` via a bounded retrieval subagent
   *if present* (do not read raw into main context — reuse the `nanopm_retrieval_prompt` contract);
   (b) user assumptions gathered interactively; (c) Nano hypotheses inferred from CONTEXT-SUMMARY. Each
   source stamps the resulting opportunity's `provenance` accordingly. Must work with **zero** FEEDBACK/DATA
   (the current state of this repo) — falling back to (b)+(c) at low/medium confidence.
5. **Subagent fan-out for drafting.** `bootstrap` dispatches drafting subagents (one per theme or per
   candidate cluster) concurrently; each returns structured opportunity drafts (frontmatter + body)
   conforming to SCHEMA.md. The main agent assembles, dedups against the emerging set, and gates on review.
   **Fallback (appetite guard):** if concurrent, dedup-aware fan-out overruns the 2-week appetite, degrade to
   serial drafting with one post-hoc dedup pass — the demo's value is the resulting DB, not the orchestration.
6. **Granularity enforcement.** Drafting/`add` prompts instruct: prefer appending to / merging with an
   existing opportunity; create a new one only for a distinct problem at solution-able altitude; never
   exceed Theme→Opportunity; propose a split if an opportunity is too broad, a merge if two overlap.
7. **Provenance & confidence, never silent.** Every opportunity frontmatter carries `provenance` and a
   human-readable confidence note; every evidence bullet carries its source + (for agent-linked, uncertain
   matches) a `⚠ low-confidence — review` marker. This operationalizes ETHOS #4 and the "not a validator —
   sharpen" voice: missing provenance is surfaced as a sharpening prompt, not hidden.
8. **Review gate.** Before writing new opportunities (bootstrap set or `add`), present the proposed
   titles/themes/provenance for confirmation; apply user edits (drop/merge/rename) before write. (Same
   gate spirit as the anti-persona STOP in other skills — agent proposes, human commits.) The gate is a
   simple confirm-list (drop/merge/rename by hand), not an automated merge engine.
9. **INDEX + LOG generation.** After any write, regenerate `INDEX.md` from all opportunity frontmatter
   (grouped by theme, ordered by `priority` then `last_updated`, with one-line summaries + relative links),
   and append a line to `LOG.md` (`<date> | <action> | <slug(s)> | provenance`).
10. **Viewer mapping.** In the viewer `PhaseMapper` (Models.swift:122) add a **folder-path** rule
    `lower.hasPrefix("opportunities/") → .discover`, alongside the existing `intel/`/`interviews/` rules
    at Models.swift:129 — **not** in the filename-prefix `discoverNames` list, because filenames like
    `INDEX.md`/`SCHEMA.md` would never match a name prefix. One line; the artifact is inert in the viewer
    until it lands.
11. **Registration & tests.** Add `pm-opportunities` to `setup`'s install path and to the `_SKILLS` array
    in `test/skill-syntax.sh`; the SKILL.md passes frontmatter + preamble validation.

### Non-functional requirements

- **Context discipline:** the main agent never reads `FEEDBACK.md`/`DATA.md` raw — only bounded
  retrieval-subagent digests. Net main-context cost stays ~1 page of briefs + digests.
- **Portability:** uses only `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `AskUserQuestion`, `Agent`
  (the Define-skill tool set). No Claude-Code-only workflow primitive — must run under `--host=vibe`/`codex`.
- **Idempotence:** re-running `bootstrap` on an existing DB does not clobber — it routes to the existing-DB
  path (in v1, that means `add`/no-op with a notice; full re-ingest is v2).
- **Typed-state respect:** if opportunities are logged to the state layer, use `nanopm_state_log` with a
  typed record (a new `opportunity` type or reuse `timeline`) — never an ad-hoc format (STRATEGY.md
  typed-state guardrail).

---

## The One UX Decision

**One `OPPORTUNITIES.md` file, or an `.nanopm/opportunities/` folder (the LLM-wiki)?**

- **Option A — single `OPPORTUNITIES.md`** (the roadmap one-liner's implied shape). One ranked table +
  inline blurbs. Less code, trivial viewer rendering, one file to diff. **But** it can't hold per-opportunity
  evidence/JTBD/detail without becoming unreadable, breaks the "click into a detail page" wiki UX Guillaume
  asked for, and has nowhere clean for the v2 ingest/lint loop to operate per-opportunity.
- **Option B — `opportunities/` folder + INDEX/LOG/SCHEMA (recommended).** Scales to rich per-opportunity
  detail and evidence, gives the matcher/lint a per-file unit to work on in v2, matches the Karpathy
  LLM-wiki pattern and Guillaume's stated vision, and mirrors existing nanopm precedents (`prds/`, `intel/`).
  Cost: more files, a `PhaseMapper` entry, and INDEX generation — all cheap.

Tradeoff: A is less to build this week but caps the feature at "a ranked list" and forces a rewrite for v2;
B costs a folder + index generation now but is the structure every later mode depends on. **Recommend B.**

**Decided 2026-06-17: Option B** (folder/LLM-wiki). This is the explicit refinement of the roadmap's
implied single-file scope — recorded here so the deviation is named, not silent.

---

## Open questions

| Question | Owner | Blocks | By when |
|----------|-------|--------|---------|
| With scoring removed from v1, how is `INDEX.md` ordered? **Reco:** coarse `priority: high\|medium\|low` (Nano-proposed, user-overridable), grouped by theme. Alternative: order by evidence-count + recency (objective, no judgment); or no ordering until scoring lands. Low-stakes, non-blocking — `priority` field can ship and be ignored if we change our mind. | Guillaume / Nicolas | INDEX ordering logic only (not the artifact or the skill) | Before `INDEX.md` generation is implemented |
| Confirm the two roadmap refinements (folder vs single file; scoring out of v1) and update ROADMAP.md / PLAN-SUMMARY line accordingly. | Guillaume / Nicolas | Roadmap/PLAN-SUMMARY accuracy (not implementation) | Before merge |

**Action:** Neither open question blocks building the template, SCHEMA, or `bootstrap`. The `priority`
default (coarse, Nano-proposed) is safe to implement now and revisit.

---

## Dependencies

- **`lib/nanopm.sh`** — `nanopm_preamble`, `nanopm_load_context`, `nanopm_load_plan`, `nanopm_define_mode`,
  `nanopm_retrieval_prompt`, `nanopm_reasoning_path` (path convention if a reasoning sidecar is added),
  `nanopm_state_log`. All shipped; this skill composes them.
- **CONTEXT-SUMMARY.md + PLAN-SUMMARY.md** — the standing baseline the preamble loads; every opportunity is
  graded against them. Present on this repo.
- **`FEEDBACK.md` / `DATA.md`** — richest evidence inputs when present; **currently absent** here, so
  `bootstrap` must degrade gracefully to user-stated + nano-hypothesis provenance.
- **Viewer `PhaseMapper`** (viewer/Sources/NanoPMViewer/Models.swift) — one-line addition; the artifact is
  inert in the viewer until then.
- **`setup` + `test/skill-syntax.sh`** — skill registration + tier-1 validation.

---

## Ties to

- **Strategy:** directly executes STRATEGY.md "How We Win #1" (multi-source signal synthesis into
  opportunity/gap mapping). Respects the typed-state and no-tracker guardrails; the wiki is a *typed*
  artifact the agent owns, handed off downstream — not a Linear/Notion clone.
- **Objective:** advances **OBJ1 KR2** (non-terminal-native prototype cohort recruited + first pipeline run
  via the viewer) — the DB is the recruitment-pitch mechanism (PLAN-SUMMARY: "lead with the Discovery
  Opportunity DB as the killer demo and recruitment hook").
- **Roadmap:** **NOW** (through 2026-08-15), item #1, 2 eng-week appetite, ~1.5 eng-week buffer held for
  scope expansion — this PRD spends part of that buffer on the folder/LLM-wiki structure. Sequences ahead of
  the cohort-recruitment NEXT items (which depend on this demo). Sibling NOW item: "Lightweight retention
  readback" (Nicolas).
- **Lineage:** extends the "compounding artifact" architecture (CONTEXT-SUMMARY / PLAN-SUMMARY
  regeneration, reasoning sidecars) into the Discover phase's problem space; instantiates Karpathy's LLM-wiki
  pattern as nanopm's first explicitly-wiki artifact.

---

## Reviewer notes

*Advisory — /pm-prd review panel, 2026-06-17 (solo-fast: advisory, non-blocking). Falsifiability gate: PASS (confidence 9).*

- **appetite-scope:** `bootstrap`'s concurrent, dedup-aware subagent fan-out + interactive review gate is the v1 complexity sink; if it overruns, the buffer is at risk. Mitigated in Req #5/#8 (serial-drafting fallback; confirm-list gate, not a merge engine) — keep orchestration as simple as the demo allows.
- **persona-fit:** v1 holds the line (agent-maintained; anti-goals explicit), but the artifact *shape* (folder + index + detail pages + status workflow) structurally tempts anti-persona drift, and the recruitment hook targets friend-PMs, not Theo. Post-ship watch-item: treat every "make the viewer nicer for PMs" request after the demo as the failure mode PERSONAS.md §3 names; re-check against the anti-goal first.
- **success-measurability:** tightened — the provenance and granularity rows now carry mechanical pass/fail tests.
- **dependency-feasibility:** fixed — Req #10 corrected to a folder-path rule (filename-prefix matching would never catch `INDEX.md`/`SCHEMA.md`).

---

## Appendix — concrete shapes (the format requested)

**Opportunity file** — `.nanopm/opportunities/<slug>.md` (scoring removed; provenance + coarse priority):

```markdown
---
id: model-variety-too-narrow
title: "Model variety is too narrow (ethnicity, body type, age)"
theme: Model representation          # L1 — from SCHEMA.md vocabulary
status: defining                     # draft | defining | review | ready-for-solutions
priority: high                       # high | medium | low  (judgment, Nano-proposed)
provenance: evidence-backed          # nano-hypothesis | user-stated | evidence-backed
evidence_sources: [user-verbatim, market-signal]
linked_objectives: [OBJ1-KR2]        # optional; ties to OBJECTIVES.md
last_updated: 2026-06-17
---

## 1. Problem summary            # core
## 2. Value to the user          # core
   ### Job to be done
   ### Where we fall short        (sub-problems + attributed evidence; ⚠ low-confidence flag where apt)
## 3. Value to the company       # optional — qualitative strategic fit
## 4. Success criteria           # optional
## 5. Solution hypotheses         # pointer only — stay in problem space
```

**`SCHEMA.md`** — the config layer (single source of structural truth; user-editable):

```markdown
# Opportunity DB — Schema & Conventions
- Granularity: exactly 2 levels — Theme (L1) → Opportunity (L2). Never deeper.
- Themes (L1): <project-specific list; bootstrap proposes, you edit>
- Opportunity template: <the file template above>
- Provenance: nano-hypothesis | user-stated | evidence-backed  (+ ⚠ low-confidence on agent-linked evidence)
- Priority: high | medium | low  (a judgment, not a calculation)
- Status workflow: draft → defining → review → ready-for-solutions
- Evidence format: "<quote>" — <source>, <date> [⚠ low-confidence]
- INDEX: grouped by theme, ordered by priority then last_updated, one-line summary + link per opportunity
- LOG: append-only, one line per change: <date> | <action> | <slug(s)> | <provenance>
- (v2) Matching rules: append-first; merge/split; dedup against INDEX before creating new
- (v2) Lint rules: flag stale / thin-evidence / orphan / duplicate opportunities + coverage gaps
```

**`INDEX.md`** — the wiki home:

```markdown
# Opportunities — ranked
Generated by /pm-opportunities · <date> · <N> opportunities

## Model representation
- **[Model variety is too narrow](model-variety-too-narrow.md)** · high · evidence-backed · 2026-06-17
  — Brands can't represent their target customers; 17-model library too narrow.
## Consistency
- **[Model face/identity drifts across generations](model-face-identity-drift.md)** · medium · user-stated · 2026-06-17
  — Same model's face changes between generations, breaking catalog coherence.
```

**`LOG.md`** — the heartbeat:

```markdown
# Opportunity DB — log
- 2026-06-17 | bootstrap: created 8 opportunities (3 evidence-backed, 5 nano-hypothesis) | /pm-opportunities
- 2026-06-17 | add: "users can't batch-export" (user-stated) | /pm-opportunities
```

---

*Sources: PLAN-SUMMARY.md (NOW item #1 scope + falsifiable bet + 2026-06-16 sequencing, read this session),
CONTEXT-SUMMARY.md (read this session), PERSONAS.md (Theo §1, anti-persona §3 — via retrieval subagent),
STRATEGY.md (How We Win #1, typed-state + no-tracker guardrails — via retrieval subagent), ETHOS.md
(principles #1/#3/#4/#6, "not a validator" voice — via retrieval subagent), PRODUCT.md (reuse map:
preamble, load_context/load_plan, retrieval prompt, reasoning sidecars, PhaseMapper, FEEDBACK downstream,
typed state — via retrieval subagent; PRODUCT_COMPLETENESS: complete), OBJECTIVES.md + ROADMAP.md (OBJ1
KR2, NOW placement — via retrieval subagent), the two example Photoroom opportunity PDFs + DB screenshot
(template reference), Karpathy "LLM Wiki" gist (pattern). No DATA.md / FEEDBACK.md on record — every
user-behavior claim is observed-personally hypothesis, not instrumented. `methodology` unset → standard PRD
format; `build_mode` unset → solo-fast.*
