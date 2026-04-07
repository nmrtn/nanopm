---
name: pm-interview
version: 0.2.0
description: "User interview guide. Prepares a structured interview guide for a specific assumption or discovery question, conducts the session live or imports from Granola, extracts signal, and appends findings to FEEDBACK.md for use by /pm-audit and /pm-user-feedback."
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
- You're about to write a PRD and need user signal first
- You want to update FEEDBACK.md with fresh qualitative data

Do NOT use this to pitch your solution. Use it to understand the problem.

## Phase 0: Prior context

```bash
nanopm_context_read pm-interview
nanopm_context_all
```

If prior interview entries found: "Found {N} past interview sessions. This session builds on them."

Also check if DISCOVERY.md exists — if so, read the top assumptions to pre-populate the focus.

```bash
[ -f ".nanopm/DISCOVERY.md" ] && echo "DISCOVERY_EXISTS" || echo "DISCOVERY_MISSING"
[ -f ".nanopm/AUDIT.md" ] && echo "AUDIT_EXISTS" || echo "AUDIT_MISSING"
```

## Phase 1: Set the focus

Ask via AskUserQuestion — ONE question:

**"What specific assumption or question should this interview answer?**

Examples:
- 'Do PMs at startups feel their current standup process is broken?'
- 'Why are users dropping off after the onboarding flow?'
- 'Would someone pay for this before it's built?'
- 'What's the biggest frustration with [competitor]?'

If you have DISCOVERY.md open, I'll suggest the top-risk assumption."

If DISCOVERY_EXISTS, extract the top assumption from the assumption inventory and suggest it as the default. Let the user confirm or override.

This focus question drives everything — the interview guide, the signal extraction, and how findings map to the roadmap.

## Phase 2: Interviewee profile

Ask via AskUserQuestion:

**"Who is the person you're interviewing?**

- Job title and company size
- Their relationship to the problem (power user, churned user, prospect, never tried it)
- How did you find them?

If you don't have someone scheduled yet, I can help you think through who to target."

If the answer is "I don't have anyone yet": output a recruitment script (2-3 sentences for LinkedIn / Slack / cold email) targeting the ideal profile from DISCOVERY.md or AUDIT.md context. Then stop — don't continue the interview guide until they have a subject.

## Phase 3: Build the interview guide

Based on the focus question and interviewee profile, generate a structured interview guide.

**Opening (2 min)**
- Set context: "I'm trying to understand your experience with [problem area], not sell anything."
- Ask for permission to take notes.
- Warm-up: "Tell me a bit about your role and what [relevant activity] looks like in your day."

**Core questions (15-20 min)**

Generate 5-7 open-ended questions following these rules:
- Start with behavior ("Tell me about the last time you..."), not opinion ("Do you think...")
- Go from past to present — never hypothetical future ("Would you use...")
- One question per topic — no compound questions
- Include at least one "worst experience" and one "workaround" question

Format:
```
Q1: [question]
   → If they give a vague answer: [follow-up probe]
   → Signal to listen for: [what confirms or refutes the assumption]

Q2: ...
```

**Closing (3 min)**
- "Is there anything about [problem area] I didn't ask that you think is important?"
- "Who else do you think I should talk to?"
- Thank them.

**Anti-patterns to avoid:**
- Never ask "Would you use X?" — it produces false positives
- Never describe your solution before the core questions
- Never interpret while they're talking — note, then follow up

## Phase 4: Live capture mode

Tell the user:

> "Interview guide ready. When you're done with the session, come back and I'll help you extract the signal.
>
> Run `/pm-interview` again and say 'I just finished the interview' to start extraction."

If the user says they've just finished an interview, proceed to Phase 5.

## Phase 5: Signal extraction

**Check Granola first:**

Try `mcp__claude_ai_Granola__query_granola_meetings` with the interviewee name or topic from Phase 2.

If a matching meeting is found:
- Fetch the full transcript with `mcp__claude_ai_Granola__get_meeting_transcript`
- Tell the user: "Found a Granola transcript for this session — extracting signal automatically."
- Use the transcript as the source for Phase 5 extraction. Skip the manual paste question.

If no Granola transcript found: ask via AskUserQuestion:

**"Give me your raw notes from the interview — paste them here, or describe what happened. Don't filter. Include exact quotes if you have them."**

From the raw notes, extract:

**Key findings:**
- What did they say that surprised you?
- What confirmed existing assumptions?
- What refuted them?

**Verbatim quotes** (mark the most powerful one with ⭐):
> "exact quote" — [context]

**Jobs and pains identified:**
| Job they're trying to do | Current workaround | Pain level (1-5) | Frequency |
|--------------------------|-------------------|------------------|-----------|

**Assumption verdict:**
- Focus assumption: [restate it]
- Verdict: CONFIRMED / REFUTED / INCONCLUSIVE
- Evidence: [what they said]

**What to do next:**
- If CONFIRMED: note it, run more interviews to increase confidence, or proceed to /pm-audit
- If REFUTED: revisit /pm-discovery — the assumption needs reframing
- If INCONCLUSIVE: flag which follow-up question would have clarified it

## Phase 6: Write findings

Append to `.nanopm/FEEDBACK.md` (create if missing):

```markdown
---

## Interview — {date} — {interviewee profile}

**Focus:** {assumption or question being tested}

**Key findings:**
{bullet list}

**Quotes:**
{verbatim quotes, best one marked ⭐}

**Jobs & pains:**
| Job | Workaround | Pain | Frequency |
|-----|-----------|------|-----------|
{rows}

**Assumption verdict:** {CONFIRMED / REFUTED / INCONCLUSIVE}
> {one sentence summary}

**Recommended next:** {/pm-discovery to reframe | /pm-audit | more interviews (N total recommended)}

---
```

If FEEDBACK.md already exists, append below the existing content — do NOT overwrite.

Also write a session summary to `.nanopm/INTERVIEW.md` (overwrite — this is the latest session only).

## Phase 7: Save context

```bash
nanopm_context_append "{\"skill\":\"pm-interview\",\"outputs\":{\"focus\":\"$(head -20 .nanopm/INTERVIEW.md | grep 'Focus' | cut -d: -f2- | xargs | tr '\"' \"'\" | head -c 100)\",\"verdict\":\"$(grep 'Assumption verdict' .nanopm/INTERVIEW.md | cut -d: -f2- | xargs | head -c 50)\",\"next\":\"pm-audit\"}}"
```

## Completion

Tell the user:
- FEEDBACK.md updated with interview findings
- The assumption verdict (CONFIRMED / REFUTED / INCONCLUSIVE) and what it means for the roadmap
- How many interviews are typically needed before signal is reliable (5 is the standard; 3 minimum for a single assumption)
- Recommended next: `/pm-audit` if signal is sufficient, or schedule another interview if INCONCLUSIVE

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
