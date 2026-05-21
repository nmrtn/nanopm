---
name: pm-interview
version: 0.3.0
description: "User interview guide based on Teresa Torres (story-based), Rob Fitzpatrick (Mom Test), Bob Moesta (JTBD Switch), and Cindy Alvarez (Lean Customer Dev). Prepares a hypothesis-driven guide, runs live or imports from Granola, extracts signal into FEEDBACK.md."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, WebFetch, mcp__claude_ai_Granola__list_meetings, mcp__claude_ai_Granola__get_meeting_transcript, mcp__claude_ai_Granola__query_granola_meetings
---

## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
nanopm_telemetry_pending "pm-interview"
_FEEDBACK_FILE=".nanopm/FEEDBACK.md"
_INTERVIEW_FILE=".nanopm/INTERVIEW.md"
```

## When to run this

Run `/pm-interview` when:
- You have a specific assumption to validate (from /pm-discovery or /pm-audit)
- You want to understand why users behave a certain way
- You're about to write a PRD and need real user signal first
- You just finished a user call and want to extract the signal

**The goal is never to pitch.** The goal is to collect specific stories from the past that reveal real behavior.

## Frameworks used

This skill draws from four recognized approaches:

- **Rob Fitzpatrick (The Mom Test):** Only ask questions that are honest even if the interviewee wants to please you. Past behavior only, no hypotheticals.
- **Teresa Torres (Continuous Discovery Habits):** One specific story per interview. Anchor to a real past event, then excavate the timeline.
- **Bob Moesta (JTBD Switch Interview):** Map the full decision timeline — from first dissatisfaction to current use. Identify the four forces (push, pull, anxiety, inertia).
- **Cindy Alvarez (Lean Customer Development):** Falsify your critical hypotheses. Know your top 3 questions before the call. End with a forward action.

## Phase 0: Prior context

```bash
nanopm_context_read pm-interview
nanopm_context_all
```

If prior interview entries found: "Found {N} past sessions. This session builds on them — prior verdicts will inform the guide."

Read prior context to understand which assumptions have already been tested and what signal exists.

```bash
[ -f ".nanopm/DISCOVERY.md" ] && echo "DISCOVERY_EXISTS" || echo "DISCOVERY_MISSING"
[ -f ".nanopm/AUDIT.md" ] && echo "AUDIT_EXISTS" || echo "AUDIT_MISSING"
[ -f ".nanopm/FEEDBACK.md" ] && echo "FEEDBACK_EXISTS" || echo "FEEDBACK_MISSING"
```

## Phase 1: Set the focus

Ask via AskUserQuestion:

**"What are you trying to learn from this interview?**

Be specific — name the assumption or behavior you want to understand.

Good examples:
- 'I want to know why PMs at startups feel their standup process is broken'
- 'I want to understand why users drop off after onboarding step 3'
- 'I want to know what workaround people use when they can't do X'

Bad examples (too vague):
- 'What users think of the product'
- 'General feedback'

If you have DISCOVERY.md or AUDIT.md open, I'll suggest the highest-risk assumption as a default."

If DISCOVERY_EXISTS or AUDIT_EXISTS: extract the top-risk assumption and suggest it. Let the user confirm or override.

From the focus, extract or infer:
- The **specific behavior** to anchor the story on (e.g., "the last time they chose what to watch")
- The **critical hypotheses** to falsify (max 3)
- The **stage** (pre-product/discovery, feature validation, churn/retention investigation, positioning)

## Phase 2: Interviewee profile

Ask via AskUserQuestion:

**"Who is the person you're interviewing?**

- Job title and company size
- Their relationship to the problem: current user / churned user / prospect / never tried it
- How you found them

If you don't have someone yet, I can write a recruitment message."

**If no subject yet:** write a 3-sentence recruitment message (LinkedIn or Slack) targeting the ideal profile from DISCOVERY.md/AUDIT.md context. Include: who you're looking for, what you want to talk about (problem, not your solution), and a clear ask (30-min call).

**Interview type detection:** Based on the relationship to the problem, classify the session:
- **Current user** → use story-based (Torres) + JTBD ongoing use questions
- **Churned user / switched away** → use JTBD Switch full timeline (Moesta)
- **Prospect / never tried** → use Lean Customer Dev (Alvarez) + Mom Test
- **Buyer / decision-maker** → use positioning interview (Dunford framing)

## Phase 3: Build the interview guide

Generate a complete, ready-to-use interview guide. The guide is a **compass, not a script** (Constable) — questions are ordered by criticality, most important hypotheses first.

---

### Opening (3–5 min)

Set the frame:
> "Thanks for making time. I'm trying to understand your experience with [problem area] — I'm not here to pitch anything, just to learn. I'll ask you about specific situations you've been in, not hypothetical scenarios. Mind if I take notes?"

Warm-up:
> "Tell me a bit about your role and what [relevant activity] looks like in a typical week."

---

### Story anchor (Torres method)

Pick ONE behavior most likely to reveal the assumption. Anchor to a real past event:

> "I'd love to start with a specific situation. **Tell me about the last time you [specific behavior].**"

- If they generalize ("I usually...") → redirect: "Let's focus on one specific time — the most recent one you can remember. Walk me through what actually happened."
- Excavate the timeline with neutral prompts: "What happened first?" / "What happened next?" / "What made you decide to do that?"
- Never interpret while they're talking. Note, then follow up.

---

### Core questions (15–20 min)

Generate 5–7 questions based on the interview type and focus. Apply these rules for every question:

**Mom Test rules (Fitzpatrick):**
- ✓ Ask about specific past behavior: "Tell me about the last time..."
- ✓ Ask what they've tried: "What else have you tried to solve this?"
- ✓ Ask about implications: "What happens when [problem] occurs?"
- ✗ Never ask: "Would you use X?" / "Do you think X is a good idea?" / "How much would you pay?"
- ✗ Never ask hypothetical future questions

**Mandatory questions (always include):**
1. **Workaround question:** "How are you handling [the problem] right now? Walk me through exactly what you do."
   → *Reveals your real competition. If the answer is "nothing," probe harder — someone with a real problem always has a workaround.*

2. **Implication question:** "What happens if you don't solve this? What does it cost you — time, money, stress?"
   → *Separates a real problem from a minor irritant. No real cost = weak signal.*

3. **Alternative question:** "What else have you tried? What did you like or hate about it?"
   → *Reveals the competitive landscape and pricing anchor.*

**For JTBD Switch sessions (Moesta), follow the 6 stages:**
1. First Thought: "When did you first realize something needed to change? What triggered that?"
2. Passive Looking: "At what point did you start casually noticing alternatives?"
3. Active Looking: "When did you start seriously evaluating options?"
4. Deciding: "Walk me through the moment you made the decision."
5. Onboarding: "What was the first thing you did after you started?"
6. Ongoing Use: "How is your situation different now? What can you do that you couldn't before?"

Map the four forces during the session:
- **Push** (frustration with current situation): listen for "I was frustrated by...", "It wasn't working because..."
- **Pull** (attraction to new solution): listen for "I heard that...", "I wanted to be able to..."
- **Anxiety** (fear of switching): listen for "I was worried that...", "I wasn't sure if..."
- **Inertia** (attachment to old solution): listen for "I was used to...", "We had already..."

**Probing techniques (NNG funnel):**
- "Can you tell me more about that?"
- "What do you mean by [vague word]?" — never let abstract words (easy, fast, better) pass without unpacking
- "Why does that matter to you?"
- **Silence** — wait 3–5 seconds before following up. Interviewees fill silence with the most honest answers.
- "You mentioned X — can we go back to that?"
- "Faster than what?" / "Better than how?" (Moesta) — contrast reveals meaning

---

### Hypothesis check (Alvarez)

For each of the top 3 critical hypotheses, include one targeted question. Order these by criticality — most important first (Constable: if the call cuts short, you've still tested the most critical hypothesis).

Format:
```
Hypothesis: [belief]
Question: [specific behavior-based question to test it]
Confirmation signal: [what answer would confirm it]
Refutation signal: [what answer would refute it]
```

---

### Closing (3–5 min)

> "Is there anything about [problem area] you expected me to ask that I didn't?"
> "Who else do you think I should talk to? Could you introduce me?"
> "What would be most useful for me to send you as a follow-up?"

**Forward action** (Alvarez): always end with a specific next step — an intro, a follow-up session, or sharing a prototype later.

---

### Anti-patterns to avoid

| What to avoid | Why |
|---|---|
| "Would you use X?" | Produces false positives — people say yes to be polite |
| Pitching before the core questions | Biases every answer that follows |
| Interpreting aloud while they talk | Shuts down their train of thought |
| Asking compound questions | Interviewee answers only the easiest part |
| Accepting vague answers without probing | "It was frustrating" tells you nothing |
| Asking about hypothetical futures | Behavior prediction is unreliable |

---

## Phase 4: Live capture mode

Tell the user:

> "Guide ready. Recommended duration: 30–45 min. The questions are ordered by importance — if the call runs short, you've still covered the most critical hypothesis.
>
> When you're done, come back and say 'I just finished the interview' — I'll extract the signal. If you recorded in Granola, I'll pull the transcript automatically."

If the user says they've just finished: proceed to Phase 5.

## Phase 5: Signal extraction

**Check Granola first:**

Try `mcp__claude_ai_Granola__query_granola_meetings` with the interviewee name or topic from Phase 2.

If a matching meeting is found:
- Fetch full transcript with `mcp__claude_ai_Granola__get_meeting_transcript`
- Tell the user: "Found a Granola transcript — extracting signal automatically."
- Use the transcript as source. Skip the manual paste question.

If no Granola transcript: ask via AskUserQuestion:

**"Paste your raw notes — don't filter, don't clean up. Exact quotes are the most valuable thing."**

---

From the raw notes or transcript, extract:

**Key findings:**
- What confirmed existing assumptions?
- What surprised you or contradicted assumptions?
- What was implied but never said directly?

**Verbatim quotes** (mark the strongest one ⭐):
> "exact quote" — [context]
*Pick quotes that reveal emotion, workaround behavior, or a real cost. Paraphrases have no value here.*

**Four forces map (JTBD):**
| Force | Evidence from this session |
|-------|--------------------------|
| Push (why they wanted to change) | |
| Pull (what attracted them) | |
| Anxiety (what held them back) | |
| Inertia (what they were attached to) | |

**Jobs identified:**
| Functional job | Emotional job | Current workaround | Pain level (1–5) | Frequency |
|---------------|--------------|-------------------|-----------------|-----------|

**Hypothesis verdicts:**
For each hypothesis tested:
- Hypothesis: [restate it]
- Verdict: CONFIRMED / REFUTED / INCONCLUSIVE
- Evidence: [what they said or did]

**Signal reliability:**
- 1–2 interviews: directional only, don't act yet
- 3 interviews: minimum for a single assumption
- 5 interviews: standard threshold (Teresa Torres / Nielsen Norman)
- 8–12 interviews: sufficient for a full JTBD map (Moesta)

## Phase 6: Write findings

Append to `.nanopm/FEEDBACK.md` (create if missing):

```markdown
---

## Interview — {date} — {interviewee profile}

**Focus:** {assumption or question tested}
**Session type:** {story-based | JTBD switch | lean discovery | positioning}

**Key findings:**
{bullet list — specific and concrete}

**Best quote** ⭐:
> "{exact verbatim quote}" — {context}

**Other quotes:**
> "{quote}" — {context}

**Four forces:**
| Force | Evidence |
|-------|---------|
| Push | {what frustrated them about the status quo} |
| Pull | {what attracted them toward a solution} |
| Anxiety | {what made them hesitant} |
| Inertia | {what they were reluctant to leave behind} |

**Jobs identified:**
| Functional job | Emotional job | Workaround | Pain | Frequency |
|---|---|---|---|---|

**Hypothesis verdicts:**
- {hypothesis}: {CONFIRMED / REFUTED / INCONCLUSIVE} — {evidence}

**Recommended next:**
{/pm-discovery to reframe | /pm-audit | more interviews (N total so far, {5 - N} more recommended) | /pm-prd if signal is sufficient}

---
```

Write session summary to `.nanopm/INTERVIEW.md` (overwrite — latest session only).

## Phase 7: Save context

```bash
nanopm_context_append "{\"skill\":\"pm-interview\",\"outputs\":{\"focus\":\"$(head -20 .nanopm/INTERVIEW.md | grep 'Focus' | cut -d: -f2- | xargs | tr '\"' \"'\" | head -c 100)\",\"verdict\":\"$(grep 'Hypothesis verdicts' .nanopm/INTERVIEW.md | cut -d: -f2- | xargs | head -c 50)\",\"next\":\"pm-audit\"}}"
```

## Completion

Tell the user:
- FEEDBACK.md updated
- Hypothesis verdicts summary (CONFIRMED / REFUTED / INCONCLUSIVE per hypothesis)
- Current signal reliability level (N interviews done, how many more needed)
- If any hypothesis was REFUTED: "This is valuable — a refuted assumption before you built saves weeks. Run /pm-discovery to reframe."
- Recommended next skill

## Telemetry

```bash
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.nanopm/analytics/.pending-"$_TEL_SESSION_ID" 2>/dev/null || true

_OUTCOME="success"

if [ -x ~/.nanopm/bin/nanopm-telemetry-log ]; then
  ~/.nanopm/bin/nanopm-telemetry-log \
    --skill "pm-interview" \
    --duration "$_TEL_DUR" \
    --outcome "$_OUTCOME" \
    --session-id "$_TEL_SESSION_ID" 2>/dev/null || true
fi
```

**STATUS: DONE**
