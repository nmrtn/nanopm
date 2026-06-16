---
name: pm-objectives
version: 0.1.0
description: "Define product objectives (OKRs). Reads challenge-session context, asks 2-3 clarifying questions, produces OBJECTIVES.md with measurable goals and key results."
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
_OBJECTIVES_FILE=".nanopm/OBJECTIVES.md"
```

## Phase 0: Prior context

Check if objectives have been set before:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_read pm-objectives
```

If a prior entry exists, show: "Prior objectives found from {ts}. Reviewing current context."

Read all prior context to inform this run:
```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_all
```

Key things to extract:
- Challenge session findings (gap, recommended next skill, what you're building)
- Prior objectives (if any) — flag which ones were hit or missed

## Phase 1: Context check

```bash
_CHALLENGES=".nanopm/CHALLENGES.md"; [ -f "$_CHALLENGES" ] || _CHALLENGES=".nanopm/AUDIT.md"  # legacy pre-rename name
[ -f "$_CHALLENGES" ] && echo "CHALLENGES_EXISTS" || echo "CHALLENGES_MISSING"
[ -f ".nanopm/PERSONAS.md"       ] && echo "PERSONAS_EXISTS"       || echo "PERSONAS_MISSING"
[ -f ".nanopm/FEEDBACK.md"       ] && echo "FEEDBACK_EXISTS"       || echo "FEEDBACK_MISSING"
[ -f ".nanopm/VISION-MISSION.md" ] && echo "VISION_MISSION_EXISTS" || echo "VISION_MISSION_MISSING"
[ -f ".nanopm/BUSINESS-MODEL.md" ] && echo "BUSINESS_MODEL_EXISTS" || echo "BUSINESS_MODEL_MISSING"
```

**If CHALLENGES.md exists (or legacy AUDIT.md):** Read it. Extract sections 1-3 (what you're building, who for, biggest gap).

**If VISION_MISSION_EXISTS:** read `.nanopm/VISION-MISSION.md`. Objectives must *ladder up to the mission* — every objective should be a measurable step toward the stated mission/vision. Flag any objective that doesn't connect to it.

**If BUSINESS_MODEL_EXISTS:** read `.nanopm/BUSINESS-MODEL.md`. Objectives should target *what moves the business* — bias the KRs toward the metrics the business model says matter (revenue, activation, the core GTM motion), not vanity goals. Both reads are advisory — if a doc is absent, proceed without it.

**If PERSONAS.md exists:** Read it. Objectives exist to move the **primary persona** toward their job-to-be-done — every objective should plausibly improve that persona's outcome. If an objective serves nobody in PERSONAS.md (or only the anti-persona), that's a signal it's a vanity goal — challenge it before writing it.

**If FEEDBACK.md exists:** Read it. Extract the top unaddressed themes. At least one objective should address the highest-severity unaddressed theme — surface this to the user: "FEEDBACK.md shows {theme} is the top unaddressed signal. Should a KR target it directly?"

**If CHALLENGES.md missing:** Tell the user: "No challenge session found. Running /pm-objectives without one gives weaker output. Consider running /pm-challenge-me first. Continuing with what I know."

## Phase 2: Clarifying questions

Ask these questions as SEPARATE sequential AskUserQuestion calls — one call per question, never batched. Wait for the answer before asking the next.

**Before asking any question**, check these sources in order:
1. Prior context from `nanopm_context_all` — look for a prior pm-objectives entry with a period
2. The /pm-challenge-me Q5 answer in CONTEXT.md — often names the quarter or goals directly
3. CHALLENGES.md Section 3 (biggest gap) — often implies the top goal

**Q1: Time horizon**
- Check: Does CONTEXT.md Q5 reference a specific quarter or timeframe? If yes, state it and skip Q1: "Period: {X} (from CONTEXT.md Q5)."
- If not derivable: ask "What time horizon are these objectives for? (e.g., Q2 2026, next 6 months)"

**Q2: Top goals**
- Check: Does CONTEXT.md Q5 name specific, measurable goals? If yes, use them as draft KRs and confirm: "Based on your Q5 answer, your goals are: {list}. Are these right for this period, or do you want to change them?"
- If vague or missing: ask "What are your top 1-3 goals for this period? Be specific — not 'grow the product' but 'reach 1,000 paying customers' or 'reduce churn below 5%.'"

**Q3: Constraints**
- Check: Is team size derivable from CONTEXT.md Q8? Is methodology from Q11? If both are present, synthesize: "Constraints: {team size} team, {methodology}, budget = {if stated}. Is anything missing?"
- If not derivable: ask "What constraints are you working under? (team size, budget, tech debt, regulatory, etc.)"

Stop when all three are answered or clearly answered from context.

## Phase 3: Write OBJECTIVES.md

Write `.nanopm/OBJECTIVES.md`:

```markdown
# Product Objectives
Generated by /pm-objectives on {date}
Project: {slug}
Period: {time horizon from Q1}

---

## Objective 1: {name — short, active verb phrase}

*{Why this matters — one sentence connecting to challenge findings or user goal}*

| Key Result | Target | Metric |
|-----------|--------|--------|
| KR1: {measurable outcome} | {number/threshold} | {how measured} |
| KR2: {measurable outcome} | {number/threshold} | {how measured} |
| KR3: {measurable outcome} | {number/threshold} | {how measured} |

---

## Objective 2: {name}

*{Why this matters}*

| Key Result | Target | Metric |
|-----------|--------|--------|
| KR1: {measurable outcome} | {number/threshold} | {how measured} |
| KR2: {measurable outcome} | {number/threshold} | {how measured} |

---

{Add Objective 3 only if clearly supported by evidence. Two tight objectives beat three vague ones.}

---

## What's NOT an objective this period

{For each item, include:
(a) why it was tempting — what would make a reasonable person pursue it this period,
(b) the specific condition that would re-open it ("Revisit when {trigger}").
A list without these two elements is just a to-do list for later, not a boundary.}

**Action:** Before accepting any new feature request or work item this period, check it against this list. If it matches an anti-goal, the answer is no without a re-prioritization conversation.

---

## Recommended Next Skill

**Run: /pm-strategy**

{One sentence: why strategy is the right next step given these objectives.}

---

*Sources: {CHALLENGES.md, prior context, user answers}*
```

**Rules for writing objectives:**
- Max 3 objectives. Two is fine. One is fine if it's the right one.
- Key results must be measurable (numbers, dates, binary outcomes).
- If the user gave vague goals, translate them to measurable KRs and note the translation.
- If the challenge session identified a strategic gap, at least one objective should address it.

## Phase 4: Save context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_append "{\"skill\":\"pm-objectives\",\"outputs\":{\"period\":\"$(head -5 .nanopm/OBJECTIVES.md | grep Period | cut -d: -f2- | xargs)\",\"objective_count\":\"$(grep -c '^## Objective' .nanopm/OBJECTIVES.md)\",\"next\":\"pm-strategy\"}}"
```

## Phase: Regenerate the plan brief

After OBJECTIVES.md is written, refresh the consolidated current-work brief so every
downstream skill run carries the latest plan. Print the canonical prompt and dispatch
it with the **Agent tool**:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_plan_brief_prompt
```

The subagent reads whichever of OBJECTIVES/STRATEGY/ROADMAP exist and writes
`.nanopm/PLAN-SUMMARY.md`, overwriting any previous version. This brief is loaded into
every skill's preamble (`nanopm_load_plan`), so keeping it current is what stops
downstream work from drifting from the live plan.

## Completion

Tell the user:
- OBJECTIVES.md written to `.nanopm/OBJECTIVES.md`
- How many objectives were set and for what period
- Any goals that couldn't be made measurable (ask user to sharpen them)
- Recommended next skill: `/pm-strategy`

**STATUS: DONE**
