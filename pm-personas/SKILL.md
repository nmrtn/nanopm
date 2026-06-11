---
name: pm-personas
version: 0.1.0
description: "Define who you're building for. Reverse-engineers personas from the codebase and prior nanopm artifacts when they exist, or builds them from scratch by interviewing you when the repo is empty. Produces PERSONAS.md — JTBD proto-personas plus an explicit anti-persona."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent
---

<!-- portability-v2 -->
> **Multi-host portability rules.** When invoking `AskUserQuestion`:
> 1. The `header` field MUST be a short noun phrase (≤ 12 characters). Mistral Vibe
>    rejects longer headers with `string_too_long`. Pick from: `Start`, `Target`,
>    `Scope`, `Audience`, `Methodology`, `Feature`, `Question`.
> 2. The `options` list MUST have at least 2 items. Vibe rejects empty/single-option
>    calls. For free-text input, always provide ≥ 2 framing options (e.g. `Yes, here's the input` /
>    `Skip`) — never call `ask_user_question` with `options: []`.


## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
_PERSONAS_FILE=".nanopm/PERSONAS.md"
```

## What this skill does

`/pm-personas` answers one question: **who are you actually building for?** It produces
`PERSONAS.md` — 1-3 proto-personas framed around the job-to-be-done, plus one explicit
**anti-persona** (the tempting user you are deliberately NOT serving).

It runs in one of two modes, auto-detected:

- **Reverse-engineer mode** — the repo has code and/or prior nanopm artifacts. The skill
  reads them, drafts the personas the product *implies*, then asks you to confirm or correct.
- **From-scratch mode** — the repo is empty or pre-product. The skill interviews you and
  builds the personas from your answers.

Personas are an **input** to the pipeline. `PERSONAS.md` sharpens `/pm-audit` ("who for"),
`/pm-objectives`, `/pm-strategy`, and `/pm-prd`. Run it early.

## Phase 0: Prior context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_read pm-personas
nanopm_context_all
```

If a prior pm-personas entry exists: "Prior personas from {ts}. This run will refine them, not start over."

## Phase 1: Detect the mode

Detect what evidence is available, then pick a mode.

```bash
# Prior nanopm artifacts — each is a strong source of "who"
for f in SCAN DISCOVERY FEEDBACK AUDIT DATA INTERVIEW CONTEXT; do
  [ -f ".nanopm/$f.md" ] && echo "${f}_EXISTS" || echo "${f}_MISSING"
done

# Is this a real codebase, or an empty/greenfield repo?
_TRACKED=$(git ls-files 2>/dev/null | grep -vcE '^(\.nanopm/|\.git)' || echo 0)
echo "TRACKED_FILES=$_TRACKED"
[ -f README.md ] && echo "README_EXISTS" || echo "README_MISSING"
```

**Decision:**
- If any `.nanopm/*.md` artifact exists, OR `TRACKED_FILES` is more than ~10 → **Reverse-engineer mode**.
- Otherwise (empty repo, no artifacts) → **From-scratch mode**.

State the chosen mode to the user in one line and why ("Found AUDIT.md + a real codebase — I'll reverse-engineer who it's for, then check with you.").

---

## Phase 2A: Reverse-engineer mode

Gather the "who" signal from what already exists. Read the strongest sources first:

1. **Prior artifacts** (highest signal): read any of `SCAN.md`, `DISCOVERY.md`, `FEEDBACK.md`,
   `AUDIT.md`, `DATA.md` that exist. `DISCOVERY.md` and `AUDIT.md` often already name the user;
   `FEEDBACK.md` names real people in real situations; `DATA.md` shows who actually uses the product.
2. **The product's own positioning**: read `README.md`, landing-page copy, the homepage/marketing
   route, any `CONTEXT.md`. How does the product describe its user *today*?
3. **The shape of the code**: route names, auth/roles, pricing tiers, data models, onboarding flow,
   feature flags. The product encodes assumptions about its user — surface them.
   - For a large repo, dispatch one subagent via the **Agent tool**: *"Read this codebase and
     extract every signal about WHO it is built for — roles, permissions, pricing tiers, onboarding
     copy, route names, the language used in the UI. Return a bulleted list of inferred user types
     and the evidence for each. Do not propose features."* Use its findings as raw material.

From this, draft 1-3 personas the product *implies* (see Phase 3 for the shape). Mark each fact as
**Evidenced** (you saw it in code/data/feedback) or **Assumed** (you inferred it).

Then confirm with the user. Ask as SEPARATE sequential `AskUserQuestion` calls — one per question,
never batched. Skip any that the evidence already answers cleanly.

- **Q1 — Is the primary persona right?** Present your drafted primary persona in one line and ask:
  "This is who the product seems built for. Is this the real primary user, or are you actually
  building for someone else?" (header: `Audience`)
- **Q2 — Reality vs. aspiration.** "Is this who uses it *today*, or who you *want* to use it? If
  they differ, name both — the gap matters." (header: `Target`)
- **Q3 — Who do you keep saying yes to that you shouldn't?** This seeds the anti-persona. (header: `Scope`)

Do not ask more than three questions. Correct your drafts with the answers.

---

## Phase 2B: From-scratch mode

No code, no artifacts. Build the personas by interviewing the user. Ask as SEPARATE sequential
`AskUserQuestion` calls — one per question, never batched. Wait for each answer.

- **Q1 — Who is the one person you're building for?** "Describe a specific person, not a category.
  Job title, company size/stage, the situation they're in when they reach for your product. Name an
  actual person if you can." Push back on "SMBs" / "developers" — demand a person. (header: `Audience`)
- **Q2 — What job are they hiring the product to do?** "Not the feature — the outcome. The
  functional *and* emotional job. What changes in their day when it works?" (header: `Target`)
- **Q3 — What do they do today instead?** "The workaround — the spreadsheet, the Slack thread, the
  intern, the denial. What does it cost them, and how often does the pain hit?" If the answer is
  "nothing," probe harder. (header: `Scope`)
- **Q4 — Who is this explicitly NOT for?** "Name the tempting adjacent user you will *not* serve, and
  why serving them would pull the product off course." This seeds the anti-persona. (header: `Scope`)

Stop after four questions. Build the personas from the answers.

---

## Phase 3: Build the personas

Write 1-3 proto-personas. **Two sharp personas beat three vague ones. One is fine if it's the right one.**
Each persona is a real, switchable human — not a demographic bucket.

For each persona, fill:

- **Handle** — a memorable, human name + role tag (e.g. "Solo-founder Sofia", "Ops-lead Marcus").
- **Who they are** — role, company size/stage, the one line that makes them concrete.
- **The moment** — the specific situation when they reach for the product.
- **Job to be done** — functional + emotional outcome. What does success feel like for them?
- **Today's workaround** — what they do without you, and what it costs (time / money / pain / frequency).
- **The switch** — the trigger that makes them adopt, and the anxiety they must overcome to do it.
- **How we'll recognize them** — an observable signal (in product analytics, in sales calls, in support tickets).
- **Confidence** — Evidenced (saw it) or Assumed (inferred), with the source.

Then the **anti-persona** — who you're deliberately NOT building for:
- Who they are, **why they're tempting** (what makes a reasonable person want to serve them),
  **why serving them would break the product**, and **"Revisit when {trigger}"**.
- An anti-persona without those elements is just a footnote, not a boundary.

## Phase 4: Write PERSONAS.md

Write `.nanopm/PERSONAS.md`:

```markdown
# Who You're Building For
Generated by /pm-personas on {date}
Project: {slug}
Mode: {Reverse-engineered from code/artifacts | Built from scratch}

---

## Primary Persona — {handle}

*{one-line identity}*

- **The moment:** {when they reach for the product}
- **Job to be done:** {functional + emotional outcome}
- **Today's workaround:** {what they do without you, and its cost}
- **The switch:** {trigger to adopt + anxiety to overcome}
- **Recognize them by:** {observable signal}
- **Confidence:** {Evidenced — source | Assumed — basis}

---

## Secondary Persona — {handle}

{Only if it earns its place. Same shape. If there's no clear second user, say so:
"No secondary persona yet — the product lives or dies on the primary."}

---

## Anti-Persona — who we are NOT building for

**{who}**

- **Why they're tempting:** {what makes serving them look reasonable}
- **Why we say no:** {how serving them would pull the product off course}
- **Revisit when:** {the specific condition that would re-open this}

**Action:** When a request optimizes for the anti-persona, the answer is no without a
re-prioritization conversation.

---

## The one bet

{One sentence. If we're wrong about WHO, this is the belief that collapses — and the whole
plan with it. This is the assumption to test first.}

{Reality-vs-aspiration note: if who-uses-it-today ≠ who-you-want, state the gap explicitly here.}

---

## Recommended Next Skill

**Run: /pm-audit**

{One sentence: the audit will now have a real user to assess "who for" against, instead of guessing.
If AUDIT.md already exists and is stale relative to these personas, say so.}

---

*Sources: {list — artifacts read, code signals, user answers}*
```

**Rules:**
- Max 3 personas. The anti-persona is mandatory.
- Never write a demographic-only persona ("35-year-old male, urban"). Job + situation + workaround or it doesn't ship.
- Every claim is tagged Evidenced or Assumed. Be honest about how much is inference.
- In reverse-engineer mode, if the product's implied user and the user's stated user diverge, surface the gap — that divergence is often the most valuable finding.

## Phase 5: Save context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_append "{\"skill\":\"pm-personas\",\"outputs\":{\"primary\":\"$(grep -m1 '^## Primary Persona' .nanopm/PERSONAS.md | sed 's/^## Primary Persona — //' | tr '\"' \"'\" | head -c 80)\",\"persona_count\":\"$(grep -cE '^## (Primary|Secondary) Persona' .nanopm/PERSONAS.md)\",\"mode\":\"$(grep -m1 '^Mode:' .nanopm/PERSONAS.md | cut -d: -f2- | xargs | head -c 60)\",\"next\":\"pm-audit\"}}"
```

## Completion

Tell the user:
- PERSONAS.md written to `.nanopm/PERSONAS.md`
- Which mode ran, and how many personas (plus the anti-persona)
- The one bet — the riskiest belief about who the user is
- Any reality-vs-aspiration gap you found
- Recommended next skill: `/pm-audit`

**STATUS: DONE**
