---
name: pm-opportunities
version: 0.2.0
description: "Build and maintain a ranked database of user opportunities (Teresa Torres-style — the user problems behind what you build, not the solutions). Stored as an LLM-wiki under .nanopm/wiki/entities/opportunities/: one file per opportunity + a ranked INDEX, a LOG, and an editable SCHEMA. bootstrap drafts the initial set from feedback + your assumptions + Nano's hypotheses, each marked by provenance; add captures one problem at a time. Two levels only (Theme → Opportunity); no scoring at v1 — a coarse priority instead."
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
_OPP_DIR=".nanopm/wiki/entities/opportunities"
mkdir -p "$_OPP_DIR"
```

## What this skill does

`/pm-opportunities` maintains your **opportunity database** — the persistent, ranked set of user
problems and unmet needs that sits between raw discovery (`FEEDBACK.md`, interviews, data) and
planning (`OBJECTIVES`, `ROADMAP`, `PRD`). It is an *LLM-wiki*: a folder of markdown the agent owns
and keeps current, not a thing you hand-maintain.

It runs in one of three modes:
- **`bootstrap`** — no DB yet: writes the `SCHEMA.md` conventions, gathers signal (feedback if
  present + your own assumptions + Nano's hypotheses), and fans out subagents to draft the initial
  ranked set, marking each opportunity's **provenance** before you confirm it.
- **`add`** — DB exists: capture one new problem (yours or a Nano pre-fill) as a new/updated
  opportunity, deduped against what's already there.
- **`generate`** — DB exists: draft up to N new candidate problems (global or for one theme), run them
  through the dedup agent, and write the survivors as `nano-hypothesis`. Additive — never overwrites.

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
_OPP_DIR=".nanopm/wiki/entities/opportunities"
[ -f "$_OPP_DIR/SCHEMA.md" ] && echo "DB: exists" || echo "DB: none"
ls "$_OPP_DIR"/*.md 2>/dev/null | grep -vE '/(INDEX|LOG|SCHEMA)\.md$' | wc -l | xargs echo "OPP_COUNT:"
```

**Decision.** First scan your launch context / arguments for a **structured hint** — the viewer's
Opportunities Run menu sends one, and a CLI user may type one. The hint takes priority over
auto-detection:

- **`add: <text>`** (a line or argument starting with `add:`) → route to **`add`** (Phase A) and use
  everything after the first `add:` as the user problem verbatim (colons inside the text are fine) —
  skip Phase A's "what's the problem?" question. If `<text>` is empty, fall through to Phase A's
  question instead.
- **`generate:`** — optionally `generate: <N>` or `generate: <N> for theme <theme>` → route to the
  additive **`generate`** mode (Phase G). `<N>` is the count (default 3 if absent, cap at 5);
  `<theme>` scopes drafting to that one L1 theme (else global).
- **Empty DB overrides the hint.** If `.nanopm/wiki/entities/opportunities/SCHEMA.md` does not exist, run
  **`bootstrap`** (Phase 2) regardless of any hint — you can't add to or generate into a DB that
  isn't there. If the hint carried `add:` text (only a CLI user can — the viewer's empty-DB menu
  offers Bootstrap alone, no text field), fold it into the bootstrap's user-assumptions input
  (Phase 2.2 source (b)).

With **no hint**, fall back to auto-detect:
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
_OPP_DIR=".nanopm/wiki/entities/opportunities"; mkdir -p "$_OPP_DIR"
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
for d in FEEDBACK DATA; do { [ -f ".nanopm/wiki/docs/$(echo "$d" | tr 'A-Z' 'a-z' | tr '_' '-').md" ] || [ -f ".nanopm/$d.md" ]; } && echo "PRESENT: $d" || echo "ABSENT: $d"; done
```

For each PRESENT doc, dispatch ONE retrieval subagent via the **Agent tool**, printing the prompt with:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_retrieval_prompt pm-opportunities ".nanopm/wiki/entities/opportunities/INDEX.md" \
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
1. Derive a collision-safe slug with the helper — never hand-roll it:
   `_SLUG=$(nanopm_opportunity_slug "<title>")`. It transliterates accents, rejects the
   reserved INDEX/LOG/SCHEMA names (which would clobber those files on a case-insensitive
   disk), and appends `-2`/`-3` if `<slug>.md` already exists.
2. Stamp `last_updated:` with today's date (`date +%Y-%m-%d`).
3. Write the block to `.nanopm/wiki/entities/opportunities/$_SLUG.md` (frontmatter + body, per `SCHEMA.md`).

Then regenerate the index and log the run:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/wiki/entities/opportunities"
_N=$(ls "$_OPP_DIR"/*.md 2>/dev/null | grep -vE '/(INDEX|LOG|SCHEMA)\.md$' | wc -l | tr -d ' ')
if nanopm_opportunities_reindex; then
  printf '%s | bootstrap: created %s opportunities | /pm-opportunities\n' "$(date +%Y-%m-%d)" "$_N" >> "$_OPP_DIR/LOG.md"
  echo "WROTE $_N opportunities + INDEX.md + LOG.md"
else
  echo "ERROR: INDEX.md regeneration failed (see stderr) — likely a python3 issue. The opportunity files were written; fix and re-run /pm-opportunities to rebuild the index."
fi
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
   `.nanopm/wiki/entities/opportunities/SCHEMA.md` and `.nanopm/wiki/entities/opportunities/INDEX.md`.
3. **Dedup gate (the reusable agent).** Before writing, run the candidate through the dedup agent so
   you don't create a near-duplicate of something already in the DB. Print its prompt with the one
   candidate and dispatch it via the **Agent tool**:

   ```bash
   source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
   nanopm_opportunity_dedup_prompt "===CANDIDATE===
   title: <the problem, as a short title>
   problem: <the 1–2 sentence problem>"
   ```

   Read the single `===VERDICT===`. **Validate `target` first** (`[ -f ".nanopm/wiki/entities/opportunities/$target.md" ]`);
   an unresolved target is treated as `new`. Then apply the **interactive** policy — this is Mode A, the
   user is present, so ASK rather than auto-deciding (nanopm's high-confidence bar is **confidence ≥ 8**):
   - `duplicate-of` / `merge-into` at confidence **≥ 8** (target resolves) → ask via `AskUserQuestion`
     (header `Confirm`): "This looks like the existing **{target title}**. Merge into it, keep as a new
     opportunity, or cancel?" options `["Merge into it", "Keep as new", "Cancel"]`.
       - **Merge into it** → append the new phrasing / quote / evidence to
         `.nanopm/wiki/entities/opportunities/<target>.md` (under "## 2. Value to the user → Where we fall short"),
         bump its `last_updated`, and set `_SLUG=<target>`, `_ACTION=merge`, `_PROV=<target's existing
         provenance>` for the step-5 log. Go straight to step 5 (no step-4 confirm — the merge was just
         confirmed).
       - **Keep as new** → create (below), adding `related_to: [<target>]` to its frontmatter.
       - **Cancel** → stop without writing.
   - `new`, or any match **below 8** → **create**: draft a new opportunity conforming to the template —
     pick an existing theme (or propose a new one), set `provenance` (`user-stated` if the user
     asserted it; `nano-hypothesis` if you inferred it; `evidence-backed` only with an attributed
     quote/data point), set a coarse `priority`; add `related_to: [<target>]` for a sub-threshold match.
     Derive the slug with `_SLUG=$(nanopm_opportunity_slug "<title>")` and write
     `.nanopm/wiki/entities/opportunities/$_SLUG.md`.
4. **Confirm the create** (skip if the user already chose **Merge** in step 3 — that's confirmed). For a
   new opportunity, show title · theme · priority · provenance and ask `AskUserQuestion`
   (header `Confirm`, options `["Write it", "Edit", "Cancel"]`).
5. **Write + reindex + log** (same as Phase 4, for the one file):

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/wiki/entities/opportunities"
# Set _SLUG and _PROV to the opportunity you wrote/updated; _ACTION to "add" (new) or "merge" (merged in).
if nanopm_opportunities_reindex; then
  printf '%s | %s: %s (%s) | /pm-opportunities\n' "$(date +%Y-%m-%d)" "${_ACTION:-add}" "${_SLUG:-?}" "${_PROV:-?}" >> "$_OPP_DIR/LOG.md"
  echo "WROTE/UPDATED ${_SLUG:-opportunity} + INDEX.md + LOG.md"
else
  echo "ERROR: INDEX.md regeneration failed (see stderr). The opportunity file was written; fix python3 and re-run to rebuild the index."
fi
```

---

## Phase G: generate (additive)

Reached when the launch hint was **`generate:`** and a DB already exists. You DRAFT up to N new
candidate opportunities, run them through the **dedup agent**, and write only the survivors — never
overwriting what's there. Generated opportunities are Nano's inference: their provenance is always
**`nano-hypothesis`** (never inflate to evidence-backed — there is no new evidence, only inference).

### G.1 Resolve N and scope, read the existing DB

- **N** = the hinted count, default **3**, **cap at 5**.
- **Scope** = the hinted theme if one was given (draft within that single L1 theme), else **global**
  (spread across the themes already in `INDEX.md`).

Read what already exists so you draft genuinely NEW problems and give the dedup agent its bearings:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/wiki/entities/opportunities"
grep -hE '^(title|theme):' "$_OPP_DIR"/*.md 2>/dev/null   # existing titles + themes (avoid repeats)
```

### G.2 Draft candidates (reuse the bootstrap drafter)

Build a provenance-annotated input blob = the existing titles (labelled "already covered — do NOT
repeat") + the CONTEXT-SUMMARY / PLAN-SUMMARY already in your preamble (Nano-hypothesis source
material). Draft with the canonical per-theme drafter:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_opportunities_draft_prompt "ONE L1 THEME" "INPUTS (existing titles to avoid + context), ask for up to N NEW problems"
```

- **Theme-scoped** (`generate: N for theme X`): one drafter for theme X, asked for up to N NEW candidates.
- **Global** (`generate: N`): dispatch one drafter **per existing theme** concurrently (one Agent call
  each, same turn — the Phase 2.3 bootstrap pattern), each asked for **0–1** NEW candidate (0–2 only
  when N exceeds the number of themes) so you don't draft far more than N just to discard them; collect
  the union. Serial fallback if you can't fan out.

Hold the drafted `===OPPORTUNITY===` candidate blocks; **do not write yet.**

### G.3 Dedup gate (the reusable agent, strict batch policy)

Format every drafted candidate into the dedup agent's input and run ONE dedup pass:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_opportunity_dedup_prompt "===CANDIDATE===
title: <candidate 1 title>
problem: <candidate 1 problem summary>
===CANDIDATE===
title: <candidate 2 title>
problem: <candidate 2 problem summary>"
```

Dispatch it via the **Agent tool**. Apply the **strict batch policy** to each returned `===VERDICT===`
block — nanopm's high-confidence bar is **confidence ≥ 8** (the project default is strict; only
near-identical problems auto-merge).

**First, validate `target`.** For any `duplicate-of` / `merge-into` verdict, confirm the target is a
real file on disk before trusting it (`[ -f ".nanopm/wiki/entities/opportunities/$target.md" ]`). If it does NOT
resolve (the agent mis-stemmed the slug), treat that verdict as **`new`** — never skip or merge
against a target you can't find, or the candidate is silently lost.

- `duplicate-of` at confidence **≥ 8** (target resolves) → **skip** (already covered; don't write).
- `merge-into` at confidence **≥ 8** (target resolves) → **append** the candidate's new phrasing /
  quote / evidence to `.nanopm/wiki/entities/opportunities/<target>.md` (under "## 2. Value to the user → Where we
  fall short", or the problem summary) and bump its `last_updated`. Do NOT create a new file.
- everything else — `new`, an **unresolved target**, or any match **below 8** — → **write as new**
  (`nano-hypothesis`). If there was a sub-threshold match (including a low-confidence `duplicate-of`),
  add `related_to: [<target-slug>]` to the new file's frontmatter so the loose link stays visible
  without forcing a merge. (Sub-8 never merges — that's the strict default, deliberate.)

If the surviving NEW set exceeds **N**, trim to N: rank `high > medium > low`, break ties by drafting
order (theme order for global), keep the first N — and report how many you trimmed in the G.4 summary,
so the cull is never silent.

### G.4 Write + reindex + log

For each NEW survivor: `_SLUG=$(nanopm_opportunity_slug "<title>")`, stamp `provenance: nano-hypothesis`
and `last_updated` (`date +%Y-%m-%d`), write `.nanopm/wiki/entities/opportunities/$_SLUG.md` per `SCHEMA.md`. Each
MERGE was edited in place. Then regenerate the index and log one line per write AND per merge:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/wiki/entities/opportunities"
if nanopm_opportunities_reindex; then
  # append to LOG.md — one line per new write and per merge:
  #   <date> | generate: new <slug> (nano-hypothesis) | /pm-opportunities
  #   <date> | generate: merged candidate into <slug> | /pm-opportunities
  echo "INDEX regenerated — append the LOG lines above for each write/merge"
else
  echo "ERROR: INDEX.md regeneration failed (see stderr). The opportunity files were written; fix python3 and re-run /pm-opportunities to rebuild the index."
fi
```

Print a one-line summary so a headless/viewer run reports what happened:
`generate: wrote {W} new, merged {M}, skipped {S} duplicate(s), trimmed {T} over cap — N={N}, scope={theme name|global}`.

Then go to Phase 5.

---

## Phase 5: Save context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/wiki/entities/opportunities"
_N=$(ls "$_OPP_DIR"/*.md 2>/dev/null | grep -vE '/(INDEX|LOG|SCHEMA)\.md$' | wc -l | tr -d ' ')
nanopm_context_append "{\"skill\":\"pm-opportunities\",\"outputs\":{\"opportunity_count\":\"$_N\",\"index\":\"$_OPP_DIR/INDEX.md\",\"next\":\"pm-roadmap\"}}"
```

## Phase: Regenerate the plan brief

A fresh opportunity DB is the "what we're hearing" signal the always-loaded plan brief should
carry — so the next planning run starts from the current top opportunities, not a stale list.
Print the canonical prompt and dispatch it with the **Agent tool** (one subagent); on a host
with no Agent tool, follow its steps inline:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_plan_brief_prompt
```

Keep the security-preamble lines at the top of that prompt intact. The subagent reads the wiki
Plan docs + the opportunity INDEX and rewrites `.nanopm/wiki/overview/current-work.md` (its
"Top open opportunities" section now reflects this run). Skip silently if `.nanopm/wiki/`
doesn't exist.

## Completion

Tell the user:
- Where the DB is: `.nanopm/wiki/entities/opportunities/INDEX.md` (ranked home) + one file per opportunity.
- How many opportunities, **broken down by provenance** — and surface the `nano-hypothesis` and any
  `⚠ low-confidence` ones explicitly (one line each), so a CLI user leaves knowing which problems are
  inference, not evidence. This is the honesty the DB exists to keep.
- The top themes and the highest-`priority` opportunities.
- That `SCHEMA.md` is theirs to edit (themes, fields) — the skill follows it.
- Next step: feed the top opportunities into `/pm-roadmap` or `/pm-prd`, or run `/pm-opportunities add`
  whenever a new problem surfaces. (Continuous auto-ingest from discovery skills is a later mode.)

### Solutioning nudge (if any opportunity is ready)

After the completion summary, check whether any opportunity has reached the end of the status
workflow — `status: ready-for-solutions` in its frontmatter:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_OPP_DIR=".nanopm/wiki/entities/opportunities"
grep -lE '^status:[[:space:]]*ready-for-solutions' "$_OPP_DIR"/*.md 2>/dev/null \
  | grep -vE '/(INDEX|LOG|SCHEMA)\.md$' \
  | sed -E 's#.*/##; s#\.md$##'   # one ready-for-solutions slug per line
```

- **None ready** → surface nothing; the run is done.
- **One or more ready** → offer to move it into solution space. Ask via `AskUserQuestion`
  (header `Confirm`): "{N} opportunit(y/ies) are ready for solutions ({slug list}). Brainstorm
  solutions on one now?" options `["Yes, launch it", "Not now"]`. On **Yes**, launch
  `/pm-solutions <slug>` on the chosen (or single) ready slug. On a host with no `AskUserQuestion`,
  print a clear suggestion line instead — e.g.
  `{N} opportunity(ies) ready for solutions: {slug list}. Run /pm-solutions <slug> to brainstorm solutions.`

**STATUS: DONE**
