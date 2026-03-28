---
name: pm-discovery
version: 0.1.0
description: "Product discovery. Figures out WHAT to build before you plan HOW to build it. Maps the opportunity space, surfaces the riskiest assumptions, and designs the cheapest tests. Run this before pm-audit when you're pre-product, pivoting, or unsure if a feature is right."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, WebFetch
---

## Preamble (run first)

```bash
source ~/.claude/skills/nanopm/lib/nanopm.sh 2>/dev/null || \
  source .claude/skills/nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
_DISCOVERY_FILE=".nanopm/DISCOVERY.md"
```

## When to run this

Run `/pm-discovery` when:
- You're pre-product and unsure what to build
- You're considering a new feature and want to validate it first
- You're pivoting and need to re-examine the problem space
- pm-audit gave you a strategic gap you don't know how to close

Run `/pm-audit` when you already know what you're building and want to assess it.

## Phase 0: Prior context

```bash
nanopm_context_read pm-discovery
nanopm_context_all
```

If prior discovery entry found: "Prior discovery from {ts}. This run will build on it."

## Phase 1: Scope the discovery

Ask via AskUserQuestion — ONE question:

**"What are you trying to figure out? Be specific.**

Examples:
- 'Should we build X feature, and if so, for whom?'
- 'Why are users churning at step 3?'
- 'Is there a market for Y?'
- 'What should we build next?'
- 'Is our current direction right?'"

This answer scopes everything that follows. Don't proceed with a vague answer — push for a specific question the discovery should answer.

## Phase 2: The job to be done

Ask ONE AT A TIME via AskUserQuestion. Skip if clearly answered by context.

**Q1: Who is the user you're focused on?**
"Describe the specific person you're trying to help. Not a category — a person.
Job title, company size, situation they're in when they reach for your product.
e.g., 'a solo founder about to hire their first sales rep' or 'an ops manager at a 50-person logistics company who's still running dispatch in a spreadsheet.'"

Push if the answer is categorical ("SMBs", "developers"). Ask: "Can you name an actual person — or describe someone you've talked to who fits this?"

**Q2: What is the job they're hiring your product to do?**
"When they use your product, what are they really trying to accomplish?
Not the feature — the outcome. What does success look like for them?
e.g., 'stop worrying that something fell through the cracks' or 'look competent in front of their VP.'"

This is the functional + emotional job. Push past "use the feature" to what changes in their life.

**Q3: What are they doing instead right now?**
"If your product doesn't exist — or doesn't cover this need — what do they do?
The specific workaround. The spreadsheet. The Slack thread. The hiring of a person.
What does that workaround cost them in time, money, or pain — and how often does the pain occur?"

This is the most important question. If the answer is "nothing" — probe harder. Someone solving a real problem always has a workaround, even if it's denial.

**Q4: What would have to be true?**
"For your solution to win, what would have to be true about the user, the market, or the problem?
List 2-3 beliefs your plan depends on.
e.g., 'users are willing to pay $X/month for this', 'the workaround is painful enough to change behavior', 'the decision-maker and the user are the same person.'"

Stop after all four are answered. Don't ask more than four questions in this phase.

## Phase 3: Opportunity mapping

Synthesize the answers into an opportunity map. For each stated user job and workaround, identify:

**Underserved outcomes** — jobs the user is trying to do that existing solutions address poorly. Rate each: High / Medium / Low underservice.

**Anxiety** — what makes users hesitant to switch or adopt? (switching cost, trust, habits)

**Constraints** — what limits the solution space? (budget, tech, team size, time)

Do NOT propose solutions yet. Map the opportunity space only.

## Phase 4: Assumption inventory

List all the assumptions the discovery direction rests on. For each, rate:
- **Importance** (1-5): how much does the strategy collapse if this is wrong?
- **Confidence** (1-5): how much evidence do you have that it's true?
- **Risk score**: Importance × (5 - Confidence) — higher = test this first

Format:

| Assumption | Importance | Confidence | Risk | Source |
|------------|-----------|------------|------|--------|
| {belief} | {1-5} | {1-5} | {score} | {where it came from} |

Sort by risk score descending. The top 2-3 are what discovery must address.

## Phase 5: Test design

For each high-risk assumption (top 3 from Phase 4), design the cheapest possible test:

**Test design format:**

```
Assumption: {the belief}
Risk score: {N}

Cheapest test:
  What: {one specific action — not a project, an action}
  Who: {who you need to talk to or observe}
  Time/cost: {how long and what it costs}
  Signal: {what result confirms the assumption}
  Counter-signal: {what result would refute it}
  Verdict by: {date — no more than 2 weeks out}
```

Examples of cheap tests:
- 5 user interviews asking about the workaround (not demoing the solution)
- A fake door / landing page with a "sign up" button that measures intent
- Offer to do the job manually (concierge MVP) before building anything
- Check if competitors' reviews mention this pain in the top complaints
- Ask a current user: "If we removed this feature tomorrow, what would you do?"

Avoid: building anything, running surveys to hundreds of people, waiting for "enough data."

## Phase 6: Write DISCOVERY.md

Write `.nanopm/DISCOVERY.md`:

```markdown
# Product Discovery
Generated by /pm-discovery on {date}
Project: {slug}
Discovery question: {from Phase 1}

---

## The User

{Who they are, what job they're hiring a product to do, emotional + functional outcome.
Specific enough that you could email this person.}

---

## The Status Quo

{What they do today when the solution doesn't exist or doesn't fit.
The workaround, its cost in time/money/pain, and how often it occurs.}

---

## Opportunity Space

{2-3 underserved outcomes from Phase 3. Each rated High/Med/Low.
Not solutions — observations about where the pain is greatest and why existing approaches fall short.}

---

## Assumption Inventory

| Assumption | Importance | Confidence | Risk | Source |
|------------|-----------|------------|------|--------|
{rows from Phase 4, sorted by risk}

---

## Tests to Run

### Test 1 (highest risk assumption)
{test design from Phase 5}

### Test 2
{test design from Phase 5}

### Test 3 (if needed)
{test design from Phase 5}

---

## What NOT to build yet

{Explicitly: what directions this discovery ruled out, or put on hold until tests return results.
Building before the top assumptions are tested is how startups waste 6 months.}

---

## Recommended Next Skill

**Run tests first. Then: /pm-audit**

Once the top 2-3 assumption tests return results, run /pm-audit with the validated understanding
of who the user is and what they actually need. The audit will be significantly sharper.

{If tests already run / evidence already exists: "Evidence is sufficient — run /pm-audit now."}

---

*Sources: user answers, prior context, opportunity analysis*
```

## Phase 7: Save context

```bash
nanopm_context_append "{\"skill\":\"pm-discovery\",\"outputs\":{\"discovery_question\":\"$(head -5 .nanopm/DISCOVERY.md | grep 'Discovery question' | cut -d: -f2- | xargs | tr '\"' \"'\" | head -c 100)\",\"top_risk\":\"$(grep -A1 'Assumption Inventory' .nanopm/DISCOVERY.md | tail -1 | tr '\"' \"'\" | head -c 100)\",\"next\":\"pm-audit\"}}"
```

## Completion

Tell the user:
- DISCOVERY.md written to `.nanopm/DISCOVERY.md`
- The top assumption by risk score and the cheapest way to test it
- How long each test should take before results are actionable
- "Run tests before building. The goal of discovery is to fail fast on paper, not in code."
- Recommended next: run the tests, then `/pm-audit`

**STATUS: DONE**
