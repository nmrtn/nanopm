---
name: pm-opportunities
version: 0.1.0
description: "Build and maintain a ranked database of user opportunities (Teresa Torres-style — the user problems behind what you build, not the solutions). Stored as an LLM-wiki under .nanopm/opportunities/: one file per opportunity + a ranked INDEX, a LOG, and an editable SCHEMA. bootstrap drafts the initial set from feedback + your assumptions + Nano's hypotheses, each marked by provenance; add captures one problem at a time. Two levels only (Theme → Opportunity); no scoring at v1 — a coarse priority instead."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent
---

<!-- portability-v2 -->
> **Multi-host portability rules.** When invoking `AskUserQuestion`:
> 1. The `header` field MUST be a short noun phrase (≤ 12 characters). Mistral Vibe
>    rejects longer headers with `string_too_long`. Pick from: `Start`, `Target`,
>    `Scope`, `Audience`, `Methodology`, `Feature`, `Question`, `Confirm`.
> 2. The `options` list MUST have at least 2 items. Vibe rejects empty/single-option
>    calls. For free-text input, always provide ≥ 2 framing options (e.g. `Yes, here's the input` /
>    `Skip`) — never call `ask_user_question` with `options: []`.


## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
_OPP_DIR=".nanopm/opportunities"
mkdir -p "$_OPP_DIR"
```

## What this skill does

`/pm-opportunities` maintains your **opportunity database** — the persistent, ranked set of user
problems and unmet needs that sits between raw discovery (`FEEDBACK.md`, interviews, data) and
planning (`OBJECTIVES`, `ROADMAP`, `PRD`). It is an *LLM-wiki*: a folder of markdown the agent owns
and keeps current, not a thing you hand-maintain.

It runs in one of two modes:
- **`bootstrap`** — no DB yet: writes the `SCHEMA.md` conventions, gathers signal (feedback if
  present + your own assumptions + Nano's hypotheses), and fans out subagents to draft the initial
  ranked set, marking each opportunity's **provenance** before you confirm it.
- **`add`** — DB exists: capture one new problem (yours or a Nano pre-fill) as a new/updated
  opportunity.

Two rules hold everywhere: **two levels only** (Theme → Opportunity, never deeper) and **provenance
is never silent** (every opportunity is tagged `nano-hypothesis` / `user-stated` / `evidence-backed`).
There is no numeric scoring at v1 — ordering is a coarse `priority`. The conventions live in
`SCHEMA.md`, which you can edit to tune the DB without touching this skill.

## Phase 0: Prior context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_read pm-opportunities
```

If a prior entry exists: "Opportunity DB last touched {ts}. This run updates it, not starts over."

## Phase 1: Detect the mode

The mode is driven by one fact — does the DB already exist (is there a `SCHEMA.md`)? — plus any
explicit `bootstrap` / `add` argument the user passed.

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/opportunities"
[ -f "$_OPP_DIR/SCHEMA.md" ] && echo "DB: exists" || echo "DB: none"
ls "$_OPP_DIR"/*.md 2>/dev/null | grep -vE '/(INDEX|LOG|SCHEMA)\.md$' | wc -l | xargs echo "OPP_COUNT:"
```

**Decision:**
- **DB none** → **`bootstrap`** (Phase 2). State: "No opportunity DB yet — I'll bootstrap one."
- **DB exists**:
  - argument contains "add", or the user named a specific problem → **`add`** (Phase A).
  - argument contains "bootstrap" → the DB already exists; do **not** clobber it. Tell the user
    "An opportunity DB already exists ({OPP_COUNT} opportunities). v1 doesn't re-bootstrap in place —
    I'll add to it instead. (Continuous re-ingest is a later mode.)" and route to **`add`**.
  - otherwise → ask once via `AskUserQuestion` (header `Scope`): "Add a new opportunity, or just open
    the current DB?" options `["Add an opportunity", "Just show the index"]`. "Just show" → print
    `INDEX.md` and stop.

---

## Phase 2: bootstrap

### 2.1 Write the schema first

`SCHEMA.md` is the source of structural truth every other step reads. Write it before drafting:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/opportunities"; mkdir -p "$_OPP_DIR"
nanopm_opportunities_schema > "$_OPP_DIR/SCHEMA.md"
echo "WROTE $_OPP_DIR/SCHEMA.md"
```

### 2.2 Gather the raw material (three provenance sources)

You build the first set from up to three sources. **Stamp each resulting opportunity's provenance by
where its signal came from** — never inflate (when a signal is your inference, it is `nano-hypothesis`,
not `evidence-backed`).

**(a) Connected evidence — feedback / data, IF present.** Detect, then pull via a bounded retrieval
subagent (do NOT read these raw into your own context):

```bash
for d in FEEDBACK DATA; do [ -f ".nanopm/$d.md" ] && echo "PRESENT: $d" || echo "ABSENT: $d"; done
```

For each PRESENT doc, dispatch ONE retrieval subagent via the **Agent tool**, printing the prompt with:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_retrieval_prompt pm-opportunities ".nanopm/opportunities/INDEX.md" \
  "distinct user problems / pain points / unmet needs, each with its strongest attributed verbatim quote or data point and the user segment it affects"
```

Opportunities derived from these digests are **`evidence-backed`**. **Zero-feedback fallback:** if both
are ABSENT (common on a fresh repo), skip this — you build from (b) + (c) only, at lower confidence.

**(b) Your assumptions.** Ask via `AskUserQuestion` (header `Question`): "What user problems or unmet
needs are you already convinced matter? List them — I'll tag them as your assumptions (`user-stated`,
medium confidence), kept separate from anything evidence-backed." options: `["Here they are", "Skip — let Nano propose"]`.
Anything the user gives is **`user-stated`**.

**(c) Nano's hypotheses.** From the CONTEXT-SUMMARY + PLAN-SUMMARY already in your preamble (who the
product is for, the bet, the OKRs), infer candidate user problems the product context implies. These
are **`nano-hypothesis`** — be explicit that they're your inference, not observed. Generate these even
when (a)/(b) are rich; they surface gaps the others miss.

### 2.3 Propose themes (L1), then fan out drafters

From the gathered material + context, propose a short list of **themes** (L1 groupings — aim for
3–7, not a long tail). State them in one line and let the user trim/rename via `AskUserQuestion`
(header `Scope`, options `["Looks right", "Let me adjust"]`). Then record them under `## Themes (L1)`
in `SCHEMA.md` (Edit the file).

For **each** confirmed theme, draft its opportunities with a subagent. Print the canonical prompt,
passing the gathered raw material that falls under that theme — each item annotated with its
provenance (`evidence-backed` / `user-stated` / `nano-hypothesis`):

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_opportunities_draft_prompt "THEME NAME HERE" "INPUTS FOR THIS THEME (provenance-annotated) HERE"
```

Dispatch them **all concurrently in one turn** via the **Agent tool** (one Agent call per theme, same
message). Each subagent returns one or more `===OPPORTUNITY===` blocks (frontmatter + body conforming
to `SCHEMA.md`).

> **Appetite guard / serial fallback.** If you can't fan out concurrently, or the fan-out is
> overrunning, draft the themes **one at a time in a single pass** instead — the resulting DB is what
> matters, not the orchestration.

**Assemble + dedup.** Collect every returned block. Across all of them, **merge any two opportunities
that describe the same user problem** into one (keep the richer evidence; take the higher-confidence
provenance). Enforce the guardrail: nothing nested deeper than Theme → Opportunity; if an opportunity
is really two problems, split it; if it's broader than its theme, tighten it. Hold the deduped set for
the review gate — **do not write files yet.**

---

## Phase 3: Review gate (confirm before writing)

Never write the bootstrap set unchecked. Present the proposed opportunities as a compact confirm-list —
one line each: **title** · theme · `priority` · `provenance` (+ a ⚠ on any low-confidence evidence
match). Group by theme. Surface the `nano-hypothesis` ones explicitly as *your* inference to scrutinize
(ETHOS: the job is to sharpen, not to validate).

Then ask via `AskUserQuestion` (header `Confirm`):
"Here's the proposed opportunity set ({N} across {T} themes). Write it?"
options: `["Write them", "Let me edit first", "Cancel"]`.

- **Write them** → Phase 4.
- **Let me edit first** → accept the user's drop / merge / rename instructions, apply them to the set
  (this is a hand confirm-list, not an automated merge engine), then Phase 4.
- **Cancel** → stop without writing.

---

## Phase 4: Write opportunities + regenerate INDEX + append LOG

For **each** confirmed opportunity:
1. Derive a slug from the title: lowercase, hyphens, strip punctuation, max ~50 chars.
2. Stamp `last_updated:` with today's date (`date +%Y-%m-%d`).
3. Write the block to `.nanopm/opportunities/<slug>.md` (frontmatter + body, per `SCHEMA.md`).

Then regenerate the index and log the run:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/opportunities"
nanopm_opportunities_reindex
_N=$(ls "$_OPP_DIR"/*.md 2>/dev/null | grep -vE '/(INDEX|LOG|SCHEMA)\.md$' | wc -l | tr -d ' ')
_PROV=$(grep -hm1 '^provenance:' "$_OPP_DIR"/*.md 2>/dev/null | sort | uniq -c | tr '\n' ' ')
printf '%s | bootstrap: created %s opportunities (%s) | /pm-opportunities\n' "$(date +%Y-%m-%d)" "$_N" "$_PROV" >> "$_OPP_DIR/LOG.md"
echo "WROTE $_N opportunities + INDEX.md + LOG.md"
```

Go to Phase 5.

---

## Phase A: add (DB exists — capture one opportunity)

Capture a single problem and slot it into the existing DB.

1. **Get the problem.** Either the user named it (use that), or ask via `AskUserQuestion`
   (header `Question`): "What's the user problem? One or two sentences — the pain, not the solution."
   options `["Here it is", "Let Nano draft one from context"]`. If "Let Nano draft", infer a candidate
   from CONTEXT-SUMMARY (provenance `nano-hypothesis`).
2. **Read SCHEMA + INDEX** to see the existing themes and avoid duplicating an opportunity. Read
   `.nanopm/opportunities/SCHEMA.md` and `.nanopm/opportunities/INDEX.md`.
3. **Match or create.** If the problem matches an existing opportunity, propose **updating** that file
   (append evidence / sharpen) rather than creating a near-duplicate. Otherwise draft a new opportunity
   conforming to the template: pick an existing theme (or propose a new one), set `provenance`
   (`user-stated` if the user asserted it; `nano-hypothesis` if you inferred it; `evidence-backed` only
   with an attributed quote/data point), set a coarse `priority`.
4. **Confirm** (Phase 3 gate, scaled to one): show title · theme · priority · provenance and ask
   `AskUserQuestion` (header `Confirm`, options `["Write it", "Edit", "Cancel"]`).
5. **Write + reindex + log** (same as Phase 4, for the one file):

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/opportunities"
nanopm_opportunities_reindex
printf '%s | add: %s (%s) | /pm-opportunities\n' "$(date +%Y-%m-%d)" "<slug>" "<provenance>" >> "$_OPP_DIR/LOG.md"
```

---

## Phase 5: Save context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/opportunities"
_N=$(ls "$_OPP_DIR"/*.md 2>/dev/null | grep -vE '/(INDEX|LOG|SCHEMA)\.md$' | wc -l | tr -d ' ')
nanopm_context_append "{\"skill\":\"pm-opportunities\",\"outputs\":{\"opportunity_count\":\"$_N\",\"index\":\"$_OPP_DIR/INDEX.md\",\"next\":\"pm-roadmap\"}}"
```

## Completion

Tell the user:
- Where the DB is: `.nanopm/opportunities/INDEX.md` (ranked home) + one file per opportunity.
- How many opportunities, **broken down by provenance** — and surface the `nano-hypothesis` and any
  `⚠ low-confidence` ones explicitly (one line each), so a CLI user leaves knowing which problems are
  inference, not evidence. This is the honesty the DB exists to keep.
- The top themes and the highest-`priority` opportunities.
- That `SCHEMA.md` is theirs to edit (themes, fields) — the skill follows it.
- Next step: feed the top opportunities into `/pm-roadmap` or `/pm-prd`, or run `/pm-opportunities add`
  whenever a new problem surfaces. (Continuous auto-ingest from discovery skills is a later mode.)

**STATUS: DONE**
