# Quality Diff Notes: nanopm
Test product: nanopm itself (the PM skill pack)
Before: pipeline run on 2026-03-28 (pre-fix artifacts)
After: to be run after prompt changes are installed

---

## What to compare

For each artifact, answer these three questions:

1. **Specificity:** Can any sentence be copy-pasted unchanged into a different product's artifact? (Goal: zero such sentences in "after")
2. **Actionability:** Does every section end with an imperative directive? (Goal: yes for all sections in "after")
3. **Behavior change:** After reading the "after" artifacts, does the next commit look different than it would have without running the pipeline?

---

## Expected "after" improvements (per issue)

### pm-audit → AUDIT.md
- Section 1: Should include one observation from code/commits that sharpens the pitch — not just "nanopm is a skill pack that..."
- Section 2: Should end with an **Action:** directive naming a decision
- Section 3: Should end with **Action:** naming a specific output + deadline
- Section 4: Should be a single interrogative sentence (not a paragraph), followed by **Action:**

### pm-objectives → OBJECTIVES.md
- Fewer or zero redundant questions asked (Q1/Q2 should be skipped if AUDIT.md Q5 is present)
- Anti-goals: each item should include "revisit when {trigger}"
- Anti-goals: should end with **Action:** re: how to use the list during the period

### pm-strategy → STRATEGY.md
- Phase 2 question may be skipped (bet derivable from OBJECTIVES.md + AUDIT.md)
- "How We Win": each advantage should include "Why this holds:" clause
- "What We're Saying No To": each item should include "revisit when {trigger}"
- "The Risk": should end with **Action:** running cheapest test
- Adversarial FALSIFICATION: must include specific number + user segment + behavior + timeframe

### pm-roadmap → ROADMAP.md
- Q1 (capacity) skipped for solo project — defaulted from CONTEXT.md
- LATER items: each should have "revisit when {trigger}"
- "Explicitly NOT on the roadmap": each item should add what would need to change

### pm-prd → PRD
- Q1 (problem) skipped — derived from ROADMAP.md outcome statement
- Q2 (success) skipped — derived from OBJECTIVES.md KRs
- Success Criteria: "What will be different in commits?" row present and filled
- User Stories: max 3, each adding new information beyond Problem Statement
- Design notes replaced by "The One UX Decision" section
- Open questions table: has "Blocks" column, ends with **Action:**

---

## Pending: external test products

Open question (due 2026-04-04): Choose 2 external products for testing.
Requirements:
- Different category from nanopm (avoid another dev tool or PM tool)
- Real products with real context (not fictional)
- Owner willing to answer the 11 CONTEXT.md questions

When chosen, create:
- `test/quality-examples/{product-slug}/before/` — run current pipeline
- `test/quality-examples/{product-slug}/after/` — run post-fix pipeline
- `test/quality-examples/{product-slug}/diff-notes.md` — comparison

---

*Status: before/ captured. after/ pending pipeline re-run after ./setup installs updated skills.*
