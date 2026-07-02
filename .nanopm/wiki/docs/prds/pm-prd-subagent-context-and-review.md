# PRD: Subagent-powered context & review for pm-prd
Hand-drafted 2026-06-15 in pm-prd standard format (gates not executed) · Status: DRAFT
Project: nanopm

> Covers the two portable, subagent-based improvements to `/pm-prd`:
> **Axe 1 — parallel context extraction** (Phase 2) and **Axe 2 — diverse-lens review panel** (Phase 4b).
> Workflow-based axes (3/4/5) are out of scope — they are Claude-Code-only and cannot live in the multi-host SKILL.md.

---

## Problem Statement

`/pm-prd` Phase 2 ("User research pull") gathers context by reading up to five docs —
PERSONAS, DATA, PRODUCT, BUSINESS-MODEL, FEEDBACK — **sequentially, in full, into the main
agent's context**, then extracting the slice relevant to `_FEATURE`. Each doc is large
(PERSONAS.md alone is ~65 lines of dense prose; PRODUCT/BUSINESS-MODEL larger) and ~80% of
each is irrelevant to any single feature. The main reasoning context — exactly where the spec
gets written — is flooded with cross-document noise before a word of the PRD is drafted. This
is the same context-pollution failure that the shipped `define-skill-context-discipline` PRD
(v0.10.0, PR #23) fixed for the five Define skills with a **retrieval subagent that returns a
bounded digest + file pointers** (`nanopm_retrieval_prompt`, lib/nanopm.sh:811). `pm-prd` is a
Plan-phase skill, so it never inherited that discipline — it still reads the world raw.

The review side has the mirror-image gap. Phase 4b runs a **single** adversarial reviewer
checking exactly **one** failure mode — falsifiability (the 4-element rubric). A PRD fails in
many other ways the gate is blind to: scope creep against the appetite, success criteria that
aren't measurable, a feature quietly aimed at the anti-persona, dependencies asserted but never
grounded. Today those slip through to engineering. The architecture that makes nanopm
defensible — per PERSONAS.md, "typed state, schema validators, **adversarial gates**" — is
applied to one dimension of the spec and no others.

The cost for **Theo** (terminal-native solo founder, the primary persona): the PRD he writes is
both noisier to produce and thinner-checked than it should be — the two things that turn a spec
from "a falsifiable bet" back into "vibes wearing a PRD's clothing," which is the precise
failure nanopm exists to prevent.

This is internal tooling: nanopm improving its own Plan phase. One user on record (the
founders), `build_mode=solo-fast` — so the bet is **observed personally, not instrumented**.

---

## User Stories

- As **Theo**, when I write a PRD for one feature, I want the skill to pull only the
  feature-relevant slice of each context doc — not dump five full docs into the reasoning that
  drafts my spec — so the PRD is written against signal, not noise.
- As **Theo**, when my draft has a vague success criterion or an unscoped dependency, I want the
  skill to catch it before handoff — not only check whether my falsification paragraph has four
  elements — so what I hand to engineering is actually shaped.
- As **Theo on `solo-fast`**, I want exactly one hard gate (falsifiability, as today) and every
  other check surfaced as advisory must-fix notes — not five blocking gates — so sharper review
  never costs me velocity on a clean spec.

---

## Success Criteria

| Criteria | How Measured | Target |
|----------|-------------|--------|
| Main context stays clean in Phase 2 | Transcript review of a PRD run with ≥2 context docs present: cross-doc context arrives only as retrieval-subagent digests, never as full raw `.nanopm/*.md` dumps in the main agent | 0 raw full-doc reads of PERSONAS/DATA/PRODUCT/BUSINESS-MODEL/FEEDBACK in the main agent |
| Context docs are pulled in parallel | Transcript shows the present docs dispatched as a single concurrent fan-out (multiple Agent calls in one turn), not one-doc-at-a-time | Single fan-out in every run where ≥2 docs exist |
| Control-flow gates survive the refactor | The anti-persona STOP still fires when `_FEATURE` serves the anti-persona; the draft-product warning still appears; only 🟢 DATA metrics are cited | All three behaviors preserved, now driven by subagent-returned flags |
| The review panel adds signal | Transcript review on a PRD deliberately seeded with a vague success criterion + an unscoped dependency: Phase 4b surfaces ≥1 substantive non-falsifiability objection | ≥1 real objection on the seeded-weakness run |
| Falsifiability stays the only hard gate (solo-fast) | A PRD with an advisory CONCERN but a valid Falsification still completes Phase 4b/5 state writes | Completes; CONCERN appended as a note, not a block |
| What will be different in commits after this ships? | Review git log 7 days post-ship | `pm-prd/SKILL.md` Phase 2 replaces the sequential per-doc `Read` blocks with a parallel retrieval-subagent fan-out + digest consumption; Phase 4b gains a panel dispatch + a `## Reviewer notes` append step (falsifiability gate + `nanopm_state_log` writes unchanged); `lib/nanopm.sh` gains a `pm-prd` retrieval-prompt helper and a review-lens prompt set; `test/skill-syntax.sh`, `test/adversarial.e2e.sh`, and the context-threading e2e all pass |

**Anti-goals:** Not adding hard gates beyond falsifiability in `solo-fast` (advisory lenses must
not block a clean run). Not adding analytics/event instrumentation. Not making `pm-prd` read
*more* docs than today — same inputs, cleaner ingestion. Not introducing any Claude-Code-only
workflow primitive — this must keep running under Vibe and Codex.

---

## Falsification

Across my next 5 `/pm-prd` runs — me, the solo founder, within 21 days of shipping this — the
bet is wrong if in **2 or more** of those runs I observe in the transcript either (a) the main
agent still reading a **full raw** context doc (PERSONAS / DATA / PRODUCT / BUSINESS-MODEL /
FEEDBACK) into its own context instead of consuming a retrieval subagent's digest, or (b) the
Phase 4b panel surfacing **no substantive objection beyond falsifiability** on a run where I
deliberately seed the draft with a vague success criterion and an unscoped dependency — i.e.,
the added lenses are ceremony, not signal.

---

## Scope

### In scope (v1)

- **Axe 1 — Phase 2 parallel retrieval.** Replace the sequential per-doc `Read`-and-extract
  blocks with a single concurrent fan-out: one retrieval subagent per *present* context doc,
  each keyed on `_FEATURE`, each carrying that doc's specific extraction intent, each returning
  a bounded digest with `.nanopm/{FILE}.md` pointers. The main agent works from the digests and
  never reads those docs raw.
- **Flags for control flow.** Each digest carries the structured signal the main agent's gates
  need (anti-persona, product-completeness, metric confidence) so the existing Phase 2 decisions
  stay in the main agent — subagents inform, never halt.
- **Axe 2 — Phase 4b review panel.** Keep the falsifiability reviewer exactly as-is (its 4-line
  contract feeds the `nanopm_state_log` structural gate) and run it alongside N advisory
  lens-reviewers dispatched concurrently: appetite/scope realism, success-criteria
  measurability, persona-fit, dependency/feasibility.
- **Advisory-by-default.** In `solo-fast`, a lens CONCERN is appended to the PRD under a new
  `## Reviewer notes` block (must-fix list, labelled by lens) and does **not** block the
  Phase 4b/5 state writes. Falsifiability remains the only hard gate.
- **Shared helpers in `lib/nanopm.sh`** for the retrieval prompt and the lens prompts, so the
  logic is testable and doesn't drift across edits.

### Out of scope (v1)

- **Workflow-based axes (3/4/5)** — multi-angle draft-and-jury, batch PRD generation across the
  roadmap, claim-grounding cross-check. They are Claude-Code-only dynamic workflows and cannot
  live in the multi-host SKILL.md. Revisit as a separate `/pm-prd-deep` companion under
  `.claude/workflows/`.
- **Changing Phase 2's inputs** — same five docs, FEEDBACK-first fallback to the Dovetail
  connector unchanged. Only *how* they're ingested changes.
- **Hard-blocking advisory lenses in `solo-fast`** — advisory-only there; in `team-traditional`
  they escalate to blocking (resolved 2026-06-15).
- **Touching the preamble / `nanopm_load_context`** — CONTEXT-SUMMARY stays the standing
  baseline; the retrieval subagents fetch feature-specific detail on top of it.

---

## Requirements

### Functional requirements

1. **Phase 2 fan-out.** For each context doc that exists (PERSONAS, DATA, PRODUCT,
   BUSINESS-MODEL, FEEDBACK), dispatch one retrieval subagent **in the same turn** (concurrent).
   The main agent must not `Read` any of those docs directly.
2. **Bounded, feature-keyed digests.** Each subagent returns ≤ ~200 words: only the
   `_FEATURE`-relevant slices, every bullet carrying a `.nanopm/{FILE}.md` pointer — reusing the
   trust-boundary + bounded-digest + pointer contract of `nanopm_retrieval_prompt` (lib:811),
   but keyed on `_FEATURE` and the doc's intent rather than on "doc-being-written / sections."
3. **Structured flags the main agent acts on.** PERSONAS → `FEATURE_SERVES:
   primary|secondary|anti|unclear`; DATA → only 🟢 metrics, each tagged with confidence; PRODUCT
   → `PRODUCT_COMPLETENESS: draft|...`; FEEDBACK → verbatim quotes only. The Phase 2 gates stay
   in the main agent: `FEATURE_SERVES: anti` → STOP and flag (unchanged behavior); `draft`
   product → one-line non-blocking warning; cite only 🟢 metrics as fact. **A subagent never
   halts the skill** — it returns the flag; the main agent decides.
4. **Phase 4b panel.** Dispatch the existing falsifiability reviewer (unchanged
   `VERDICT/MISSING/REWRITE/CONFIDENCE` contract) and the advisory lenses concurrently. Each
   lens returns exactly: `LENS: <name>` / `VERDICT: PASS|CONCERN` / `NOTE: <one-sentence
   sharpest objection>`. The lens prompts carry the same untrusted-input guard as the existing
   reviewer.
5. **Gating.** Falsifiability is the only hard gate in `solo-fast` (its FAIL path and the
   `nanopm_state_log --type decision/--type prd` writes are unchanged). Every lens CONCERN is
   appended under a new `## Reviewer notes` block in the PRD file, labelled by lens, as a
   must-fix list — without blocking the state writes. In `team-traditional`, a lens CONCERN
   **escalates to a hard block**: Phase 4b stops and the Phase 5 state writes do not run until the
   concern is resolved or explicitly waived — reusing the `build_mode` read already in 4b.2.
6. **Helpers.** A `pm-prd` retrieval-prompt helper (e.g. `nanopm_prd_retrieval_prompt <doc>
   <feature> <intent>`) and a lens-prompt set live in `lib/nanopm.sh`, mirroring how the Define
   retrieval prompt is centralized, so edits to one skill don't silently fork the contract.

### Non-functional requirements

- **Token cost neutral-to-cheaper on the main context:** full-doc reads are replaced by bounded
  digests; the extra spend is the N subagent calls, whose internal reads never touch the main
  context. Net main-context tokens should drop.
- **Latency:** the parallel fan-out makes Phase 2 wall-clock ≤ today's sequential reads.
- **Portability:** uses only the `Agent` tool (already in `pm-prd`'s `allowed-tools`). No
  workflow primitive. Must pass under `--host=vibe` and `--host=codex`.
- Existing tier-1 (`test/skill-syntax.sh`) and tier-2 (`adversarial.e2e.sh`,
  context-threading e2e) gates pass.

---

## The One UX Decision

**Does Phase 2 reuse the one generic Define retrieval subagent, or fan out one feature-keyed
subagent per doc?**

- **Option A — one generic retrieval subagent.** Call `nanopm_retrieval_prompt pm-prd "the PRD
  for {feature}" "Problem, User Stories, Success Criteria, Dependencies"` once; it judges
  relevance across all `.nanopm/*.md` and returns one digest. Maximum reuse, one hop. **But** the
  generic relevance-judger doesn't know pm-prd's per-doc intents — it would flatten the
  anti-persona check, the 🟢-only DATA rule, and the draft-product warning into "relevant facts,"
  losing the *judgments* those gates depend on.
- **Option B — feature-keyed panel, one subagent per doc (recommended).** Each subagent carries
  its doc's specific extraction intent and returns the control-flow flag the main agent needs.
  Preserves every existing Phase 2 gate, runs fully parallel, and still reuses the *contract*
  (bounded digest + file pointers + trust boundary) so it stays consistent with the Define
  pattern. Cost: a new `pm-prd`-specific prompt helper and N parallel agents instead of 1.

Tradeoff: A is less code and one call; B costs a helper and N calls but keeps the anti-persona
STOP and the confidence filter — which are **safety/quality gates, not nice-to-haves**, and must
not be flattened by a generic judge. Recommend **B**.

**Decided 2026-06-15: Option B.** The helper is `pm-prd`-specific (Open question 2), which only
makes sense under B — confirming the feature-keyed, per-doc fan-out as the implementation path.

---

## Open questions

| Question | Owner | Blocks | By when |
|----------|-------|--------|---------|
| ~~In `team-traditional`, should advisory lenses escalate to hard-blocking?~~ **Resolved 2026-06-15:** yes — advisory in `solo-fast`, escalate-to-blocking in `team-traditional`, reusing the `build_mode` read in 4b.2. | Guillaume | — | Resolved |
| ~~One shared Plan-phase retrieval helper, or a pm-prd-specific one now?~~ **Resolved 2026-06-15:** pm-prd-specific now (YAGNI); generalize when a second Plan skill needs it. | Guillaume | — | Resolved |

No open questions block implementation. The feature is fully specified.

---

## Dependencies

- **Agent tool** — already in `pm-prd`'s `allowed-tools`. No new dependency.
- **`nanopm_retrieval_prompt` / `nanopm_define_mode`** (lib:811 / lib:791) — the shipped contract
  this PRD mirrors for the Plan phase; the digest-with-pointers shape is the precedent.
- **`build_mode` config** (`solo-fast` / `team-traditional`) — already read in Phase 4b.2; drives
  advisory-vs-blocking for the panel.
- **CONTEXT-SUMMARY.md** — already loaded by the preamble; the retrieval subagents complement it
  (summary = standing baseline; subagents = feature-specific detail).

---

## Ties to

- **Strategy:** context discipline + adversarial gates are the load-bearing architecture per
  PERSONAS.md ("typed state, schema validators, adversarial gates") and ETHOS. This extends both
  to the Plan phase — the same lineage as the shipped `define-skill-context-discipline` fix,
  applied where the spec actually gets written.
- **Objective:** no OBJECTIVES.md on record — not tied to a tracked KR.
- **Roadmap:** no ROADMAP.md on record; sequenced as a Plan-phase quality fix after the
  Define-phase context-discipline work (PR #23).

---

*Sources: pm-prd/SKILL.md (Phase 2 + Phase 4b, read this session), lib/nanopm.sh
(`nanopm_retrieval_prompt` lib:811, `nanopm_define_mode` lib:791, read this session), prior PRD
define-skill-context-discipline.md (the shipped retrieval-subagent precedent), PERSONAS.md (Theo,
anti-persona, "adversarial gates" architecture line), config (`methodology=None — solo founder`,
`build_mode=solo-fast`), Claude Code docs on subagents and dynamic workflows (portability
boundary), user request (scope: Axe 1 + Axe 2 only). No DATA.md / FEEDBACK.md / ROADMAP.md /
OBJECTIVES.md on record — every user-behavior claim here is an observed-personally hypothesis,
not instrumented.*
