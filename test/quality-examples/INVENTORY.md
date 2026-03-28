# Artifact Quality Inventory
Generated: 2026-03-28
Purpose: Identify generic, non-actionable, and interchangeable sections across all 5 skill output templates. This drives the prompt changes in Issues #2–4.

---

## How to use this file

A section **fails** if any of these are true:
1. **Generic** — it could be copy-pasted unchanged into a different product's artifact
2. **Non-actionable** — the reader finishes the section and doesn't know what to do next
3. **Interchangeable** — the language could describe any startup in the same category

A section **passes** if:
- It names a specific number, user, behavior, or date that only applies to this product
- It ends with an imperative directive the reader can act on immediately

---

## pm-audit → AUDIT.md

### Section 1: What You're Actually Building
**Status: FAILS — Generic**
Guidance says "2-4 sentences" but no structure enforces specificity. Common output: "X is a tool that helps Y do Z by doing W." This sentence structure applies to any product. No forcing function for what makes this product's behavior distinct from its stated pitch.
**Weak phrase pattern:** "nanopm is a set of... skills that orchestrate a structured... workflow"
**Fix needed:** Require the section to include (a) one observation from code/commits/data that contradicts or sharpens the pitch, and (b) what the product does that users don't expect.
**Missing action:** No directive. Reader learns what was built but not what to do with that knowledge.

### Section 2: Who You're Actually Building It For
**Status: PASSES conditionally**
The template guidance includes a good example of naming the divergence ("You say enterprise CTOs, your users are indie devs"). But the divergence example is only shown as illustration, not required. If stated and actual audiences match, this section becomes a one-liner restatement of Q2.
**Missing action:** No directive. Should force a decision: "If stated and actual audiences diverge, pick one to optimize for and write it in CONTEXT.md Q2 before continuing."

### Section 3: The Biggest Strategic Gap Right Now
**Status: FAILS — Non-actionable**
Guidance says "concrete, specific, actionable" but that's aspirational. The actual template has no structure that produces an action. Common output: a 2-3 sentence description of a gap that ends with no directive.
**Weak phrase pattern:** "The gap: zero external validation data."
**Fix needed:** Require section to end with an **Action:** line naming a specific thing to do this week to close or measure the gap.

### Section 4: The Question You're Avoiding
**Status: PARTIALLY FAILS**
The adversarial subagent prompt says "one paragraph, no hedging" — this is decent but unconstrained. The output is a challenge paragraph, not a falsifiable question with a test. Compare to pm-strategy's adversarial prompt which requires ASSUMPTION + FALSIFICATION + CHEAPEST TEST. pm-audit's adversarial is weaker.
**Fix needed:** Require the output to end with the question stated as a single interrogative sentence, followed by: "**Action:** Answer this before setting objectives. Your answer goes in CONTEXT.md."

### Section 5: Recommended Next Skill
**Status: PASSES**
Always `**Run: /pm-{skill}**` + one sentence rationale. Directive. Fine.

---

## pm-objectives → OBJECTIVES.md

### Objective blocks (KR tables)
**Status: PASSES**
The KR table format (Target + Metric columns) enforces measurability. Solid.

### What's NOT an objective this period
**Status: FAILS — Generic**
Template says "List 2-3 things explicitly out of scope." Common output: a bullet list with no rationale per item, or rationale that could apply to any product ("Not X because it's premature").
**Fix needed:** Each anti-goal must include: (a) why this was tempting (what would make a reasonable person pursue it), and (b) the specific condition that would re-open it.
**Missing action:** No directive on how to use this list during the period. Should end with: "**Action:** Before accepting any new feature request this period, check it against this list. If it matches, the answer is no."

### Recommended Next Skill
**Status: PASSES**
Always `/pm-strategy` + one sentence. Fine.

### Context-aware question skipping gap
Q2 ("top goals") almost always overlaps with CONTEXT.md Q5 ("top 1-2 goals this quarter"). These are the same question asked twice.
Q3 ("constraints") almost always derivable from CONTEXT.md Q8 (team) + Q11 (methodology).
**Fix needed:** Explicit derivation rules before each question is asked.

---

## pm-strategy → STRATEGY.md

### Strategic Position
**Status: PASSES conditionally**
When written well, this is specific. But the template allows vague segment names ("solo founders") without forcing a use-case + price-point qualifier.
**Fix needed:** Require explicit "not targeting" clause in the same section (currently it's in "What We're Saying No To").

### The Bet
**Status: PASSES**
Guidance says "one sentence, stated clearly as a falsifiable claim." When followed, this is good.

### How We Win
**Status: FAILS — Platitudes**
This is the most frequently generic section in practice. Common output: "context persistence," "zero-overhead entry," "opinionated structure" — these are feature descriptions, not competitive advantages. No format enforces why these advantages can't be copied tomorrow.
**Weak phrase pattern:** "Context persistence — X persists; Y loses context every time."
**Fix needed:** Each advantage must end with: "**Why this can't be copied in 30 days:** {specific reason}."

### The Risk
**Status: PASSES conditionally**
Guidance says "specific, named risk with a specific trigger condition." This is good. But the template has no forcing function — if the risk is written vaguely, nothing catches it.
**Fix needed:** Require the risk section to end with: "**Action:** Run this test before committing: {cheapest test from adversarial review}."

### Challenged by adversarial review → FALSIFICATION
**Status: FAILS — Too vague in practice**
The adversarial prompt says "Be concrete — not 'users don't adopt it' but 'fewer than 10% of users in segment X...'" but the example is just an example, not a structural requirement. The subagent can still output category-level falsifications.
**Fix needed:** Add explicit constraint: the FALSIFICATION answer must include (a) a specific number, (b) a named user segment, (c) a specific observable behavior, and (d) a timeframe. If any are missing, the answer is invalid.

### Context-aware question skipping gap
Phase 2 question ("what is your primary strategic bet") is often derivable by cross-referencing OBJECTIVES.md Objective 1 + AUDIT.md Section 3. The skill asks it anyway.
**Fix needed:** Explicit derivation logic before Phase 2.

---

## pm-roadmap → ROADMAP.md

### NOW table
**Status: PASSES**
The outcome statement format ("Ship X so {user} can {do Y}, measured by {metric}") is strong. Enforced by the rules section.

### NEXT section
**Status: PASSES conditionally**
Bullet format with rationale is fine. Risk of becoming too long / undifferentiated.

### LATER section
**Status: FAILS — Junk drawer risk**
Template says "only items with clear future value" but that's aspirational. Without a forcing function, LATER becomes a backlog dumping ground. Items without a re-open condition are forgotten noise.
**Fix needed:** Each LATER item must include a re-open condition: "Revisit when {specific trigger}." Items without a trigger should be deleted.

### Explicitly NOT on the roadmap
**Status: FAILS — Copy-paste from STRATEGY.md**
Usually just restates the "What We're Saying No To" from STRATEGY.md without adding roadmap-specific reasoning.
**Fix needed:** Each item should add what would need to be true to change this decision.

### Context-aware question skipping gap
Q1 (capacity): For solo projects, this is always ~1 eng-week/month. Should default and skip.
Q2 (top NOW item): If STRATEGY.md cheapest test is a concrete action, it's a strong NOW candidate. Should surface this automatically.

---

## pm-prd → PRD (standard format)

### Problem Statement
**Status: PASSES**
Good structure: who, how often, workaround, cost. Hard to be generic when these 4 are filled.

### User Stories
**Status: FAILS — Often redundant**
User stories often restate the problem statement in "As a... I want... so that..." format without adding new information. 5 user stories for one focused feature is often too many.
**Fix needed:** Max 3 user stories. Each must add something not in the Problem Statement.

### Success Criteria table
**Status: FAILS — Missing commits-delta field**
No field for "What will be different in commits after this ships?" — the behavioral proxy that proves the artifact changed what was built.
**Fix needed:** Add required row: "What will be different in commits after this ships?"

### Design notes
**Status: FAILS — Generic**
"High-level UX notes. Flag the hardest UX decision." Almost always produces either (a) obvious observations that don't need to be written down, or (b) notes that apply to any feature ("consider user onboarding flow").
**Fix needed:** Replace with "The one UX decision that, if wrong, invalidates the feature" — a single named decision, not a list of notes.

### Open questions table
**Status: FAILS — Vague ownership**
Owner column often says "solo" or "{name/team}" without a real person. "By when" is often a distant date with no consequence for missing it.
**Fix needed:** Every open question must have a named person (not a team) and a "blocks what" column — what work is blocked until this is answered.

### Completion text
**Status: FAILS — References non-existent skill**
Suggests running `/pm-watch` which doesn't exist. Should say `/pm-retro`.

### Context-aware question skipping gap
Q1 (problem): Derivable from ROADMAP.md NOW outcome statement.
Q2 (success): Derivable from OBJECTIVES.md KRs tied to this feature.

---

## Cross-cutting patterns

### Weak phrases to eliminate
The following phrases appear in outputs and signal generic content. Flag these in prompts:
- "users may face challenges" → requires specificity: which users, which challenge, with what frequency
- "consider running" → replace with imperative: "Run"
- "it's worth noting that" → delete; say the thing directly
- "this could be" → replace with assertion or delete
- "in the future" → requires a specific trigger condition

### Missing actions (all skills)
No artifact section outside of "Recommended Next Skill" blocks currently ends with an imperative directive. Sections end with observations. The reader finishes the artifact knowing more than before but not knowing what to do next.
**Fix needed across all skills:** Every section except the intro header block must end with an **Action:** or **Next:** line.

---

*This inventory drives changes in Issues #2 (context skipping), #3 (imperative actions), and #4 (adversarial prompt + PRD Success Criteria).*
