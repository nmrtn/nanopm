---
name: pm-data
version: 0.1.0
description: "Quantitative data analysis for PMs. Answers a specific product question using PostHog or Amplitude — trends, funnels, retention, paths. Writes findings to DATA.md, consumed by /pm-audit and /pm-prd."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, mcp__claude_ai_PostHog__query-trends, mcp__claude_ai_PostHog__query-funnel, mcp__claude_ai_PostHog__query-retention, mcp__claude_ai_PostHog__query-paths, mcp__claude_ai_PostHog__query-stickiness, mcp__claude_ai_PostHog__insight-query, mcp__claude_ai_PostHog__projects-get, mcp__claude_ai_PostHog__event-definitions-list, mcp__claude_ai_PostHog__persons-list
---

## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
nanopm_telemetry_pending "pm-data"
_DATA_FILE=".nanopm/DATA.md"
```

## When to run this

Run `/pm-data` when:
- You have a specific question about user behavior ("why do users drop at step 3?")
- You're about to run /pm-audit and want quanti to back the qualitatif signal
- You're writing a PRD and need to quantify the problem size
- You want to check the impact of a shipped feature

**One question per run.** A vague question ("how is the product doing?") produces useless output. A specific question ("what is the Day 7 retention for users who completed onboarding vs those who didn't?") produces an insight.

## Phase 0: Prior context

```bash
nanopm_context_read pm-data
nanopm_context_all
```

Check for prior DATA.md — if it exists, show a one-line summary of the last analysis and its date. Don't repeat the same analysis unless explicitly requested.

```bash
[ -f ".nanopm/DATA.md" ] && echo "DATA_EXISTS" || echo "DATA_MISSING"
[ -f ".nanopm/AUDIT.md" ] && echo "AUDIT_EXISTS" || echo "AUDIT_MISSING"
[ -f ".nanopm/DISCOVERY.md" ] && echo "DISCOVERY_EXISTS" || echo "DISCOVERY_MISSING"
```

If AUDIT_EXISTS: scan for "biggest gap" or "question you're avoiding" — suggest turning those into data questions if the user hasn't specified one.

## Phase 1: Define the question

Ask via AskUserQuestion:

**"What specific product question do you want to answer with data?**

Good examples:
- 'What is our funnel conversion from signup to first core action?'
- 'Why do users drop off after onboarding step 2?'
- 'What is Day 7 and Day 30 retention?'
- 'Which features do power users use that casual users don't?'
- 'Did the new onboarding we shipped 3 weeks ago improve activation?'

Bad examples (too vague):
- 'How is the product doing?'
- 'What are our metrics?'"

From the question, identify:
- **Analysis type:** trend / funnel / retention / path / cohort comparison / feature impact
- **Time range:** default last 30 days unless question implies otherwise
- **Key events needed:** list the event names to fetch

## Phase 2: Detect available analytics tier

```bash
_TIER_POSTHOG=$(nanopm_has_connector posthog)
_TIER_AMPLITUDE=$(nanopm_has_connector amplitude)
echo "POSTHOG: $_TIER_POSTHOG | AMPLITUDE: $_TIER_AMPLITUDE"
```

**Priority:** PostHog MCP first (most capable) → PostHog API → Amplitude API → manual.

If PostHog MCP available: fetch available event definitions first to use correct event names:
```
mcp__claude_ai_PostHog__event-definitions-list()
mcp__claude_ai_PostHog__projects-get()
```

If neither PostHog nor Amplitude available: go to Tier 4 (manual paste).

## Phase 3: Fetch the data

Run the appropriate queries based on the analysis type. Show progress ("Fetching funnel data...") but do not show raw API responses to the user — only the interpreted output.

**For funnel questions:**
- Define the 3-5 most logical steps for the funnel
- If event names are unclear, infer from event definitions or ask one targeted question
- Fetch conversion rate per step + absolute numbers
- Identify the single biggest drop-off step

**For retention questions:**
- Fetch Day 1, Day 7, Day 30 retention by default
- If a specific event is mentioned, use it as the returning event
- Compare against industry benchmarks: D1 > 25% good, D7 > 10% good, D30 > 5% good (SaaS baseline)

**For trend questions:**
- Fetch last 30 days by default, with prior 30-day comparison
- Calculate % change: positive/negative, significant (>10%) or noise (<5%)

**For path questions:**
- Fetch paths after a key event (e.g., after "signed_up")
- Identify the top 3 most common paths and the most common exit points

**For cohort comparison:**
- Split users by a defining behavior (e.g., completed onboarding vs didn't)
- Compare retention, activation rate, or feature usage between cohorts

**For feature impact:**
- Define "before" period (30 days pre-ship) and "after" period (30 days post-ship)
- Compare the target metric between the two periods
- Flag confounders if visible (e.g., big traffic spike from a campaign)

## Phase 4: Interpret the data

Do not just dump numbers. Interpret every metric:

**For each data point:**
- What does this number mean in plain English?
- Is it good, bad, or unclear? (use benchmarks where available)
- What does it suggest about user behavior?
- What follow-up question does it raise?

**The so-what rule:** Every number must be followed by "which means..." or "which suggests...". A number without interpretation is noise.

**Confidence level for each finding:**
- 🟢 High confidence — large sample (>500 users), clear pattern, consistent over time
- 🟡 Medium confidence — moderate sample (100–500), some variance
- 🔴 Low confidence — small sample (<100), noisy, or only 1-2 weeks of data

**Triangulation:** If FEEDBACK.md exists, check for qualitative signal that confirms or contradicts the quantitative findings. A quantitative drop-off confirmed by user interview quotes is a strong signal. A number with no qualitative backing is a hypothesis, not a finding.

## Phase 5: Write DATA.md

Write to `.nanopm/DATA.md` (append if file exists — preserve prior analyses):

```markdown
---

## Data Analysis — {date}

**Question:** {the specific question answered}
**Source:** {PostHog | Amplitude | manual}
**Time range:** {date range}

### Findings

**{Finding 1 title}**
{Number}: {what it means} — {so what / implication}
Confidence: {🟢 High | 🟡 Medium | 🔴 Low} — {reason}

**{Finding 2 title}**
...

### Key insight

{One paragraph. The most important thing the data reveals. Not a list — a narrative.
What is the data actually saying about user behavior? What does it suggest you should do?}

### Biggest unknown

{The most important question the data raises but cannot answer alone.
Usually answered by qualitative research — flag it for /pm-interview if relevant.}

### Recommended next

{/pm-audit to fold this into the product assessment |
/pm-interview to investigate the biggest unknown qualitatively |
/pm-prd if the problem is validated and sized}

---
```

## Phase 6: Save context

```bash
nanopm_context_append "{\"skill\":\"pm-data\",\"outputs\":{\"question\":\"$(head -10 .nanopm/DATA.md | grep 'Question' | cut -d: -f2- | xargs | tr '\"' \"'\" | head -c 100)\",\"source\":\"posthog\",\"next\":\"pm-audit\"}}"
```

## Completion

Tell the user:
- DATA.md updated
- The single most important finding in one sentence
- The confidence level and what would increase it
- Whether this data suggests running more interviews (/pm-interview) or moving to planning (/pm-audit)

If the data reveals a clear problem with quantified size: "This is now ready to feed into /pm-audit — the quantitative problem size strengthens the audit's strategic recommendations."

## Telemetry

```bash
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.nanopm/analytics/.pending-"$_TEL_SESSION_ID" 2>/dev/null || true

_OUTCOME="success"

if [ -x ~/.nanopm/bin/nanopm-telemetry-log ]; then
  ~/.nanopm/bin/nanopm-telemetry-log \
    --skill "pm-data" \
    --duration "$_TEL_DUR" \
    --outcome "$_OUTCOME" \
    --session-id "$_TEL_SESSION_ID" 2>/dev/null || true
fi
```

**STATUS: DONE**
