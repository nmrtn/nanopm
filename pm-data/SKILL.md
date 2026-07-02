---
name: pm-data
version: 0.1.0
description: "Quantitative data analysis for PMs. Answers a specific product question using PostHog or Amplitude — trends, funnels, retention, paths. Writes findings to the wiki data page at .nanopm/wiki/docs/data.md, consumed by /pm-challenge-me and /pm-prd."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent, mcp__claude_ai_PostHog__query-trends, mcp__claude_ai_PostHog__query-funnel, mcp__claude_ai_PostHog__query-retention, mcp__claude_ai_PostHog__query-paths, mcp__claude_ai_PostHog__query-stickiness, mcp__claude_ai_PostHog__insight-query, mcp__claude_ai_PostHog__projects-get, mcp__claude_ai_PostHog__event-definitions-list, mcp__claude_ai_PostHog__persons-list
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
```

## When to run this

Run `/pm-data` when:
- You have a specific question about user behavior ("why do users drop at step 3?")
- You're about to run /pm-challenge-me and want quanti to back the qualitatif signal
- You're writing a PRD and need to quantify the problem size
- You want to check the impact of a shipped feature

**One question per run.** A vague question ("how is the product doing?") produces useless output. A specific question ("what is the Day 7 retention for users who completed onboarding vs those who didn't?") produces an insight.

## Phase 0: Prior context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_read pm-data
nanopm_context_read pm-data
```

Check for a prior wiki data page — if it exists, show a one-line summary of the last analysis and its date. Don't repeat the same analysis unless explicitly requested.

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
[ -f "$(nanopm_wiki_doc_path data)" ] && echo "DATA_EXISTS" || echo "DATA_MISSING"
```

Pull the upstream grounding through the **query primitive** — one read-side call that
synthesizes the relevant wiki pages, instead of bespoke per-doc reads (the recipe
pattern: query → reasoning → ingest). The raw docs stay out of this run; you reason
over the cited synthesis the query returns. Print the prompt and **dispatch it with the
Agent tool** (one subagent); on a host with no Agent tool, follow its steps inline.

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_query_prompt "For a quantitative data analysis, synthesize from the wiki: the product map — its surfaces, core workflow, and which user events/features the metrics would refer to (and whether the product page is marked Completeness: draft); and the biggest gap or 'question you're avoiding' from the latest challenge session, plus the top-risk assumption from any discovery page. Cite each claim. Name anything missing rather than inventing." none
```

Reason over the returned synthesis:
- **Ground which events and features the metrics refer to** — map the question's funnel steps and key events onto the product's real surfaces and core workflow before querying, so the analysis measures the right behavior. If the synthesis reports the product page header shows `Completeness: draft`, surface a one-line non-blocking warning: "Note: analyzing against a draft product concept." If no product context exists, proceed without it.
- **If a challenge session is present:** use its biggest gap or "question you're avoiding" to suggest turning those into data questions if the user hasn't specified one.

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

## Phase 1.5: Surface related opportunities

Now that the question is defined, search for opportunities related to the behavior or
metric being measured — so the interpretation in Phase 4 connects each data point to the
user problem it's meant to illuminate, not just a free-floating number:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_wiki_search "<key terms from the question — e.g. 'activation onboarding' or 'retention churn'>" opportunity 5
```

For each result, **Read the full page** (path column). In Phase 4, anchor each finding to
the relevant opportunity: "this drop-off maps to opportunity X (priority: high)" is a
stronger insight than the number alone.

## Phase 2: Detect available analytics tier

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
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

## Phase 5: Write the wiki Data page

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_DATA_PATH="$(nanopm_wiki_doc_path data)"
nanopm_wiki_doc_frontmatter pm-data evidence-backed "$(date +%Y-%m-%d)" "{sources}"
echo "WRITE_TO: $_DATA_PATH"
```

Write the file at `$(nanopm_wiki_doc_path data)` as: (a) the frontmatter block emitted by `nanopm_wiki_doc_frontmatter` above (substitute `{sources}` with the real comma-separated sources, e.g. `posthog`, `amplitude`), then (b) the body below. Append a new analysis section if the file already exists — preserve prior analyses, keep the confidence markers (🟢🟡🔴) inline in the body:

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
Usually answered by qualitative research — flag it for /pm-discovery if relevant.}

### Recommended next

{/pm-challenge-me to fold this into the product assessment |
/pm-discovery to investigate the biggest unknown qualitatively |
/pm-prd if the problem is validated and sized}

---
```

## Phase: Ingest into the memory wiki

Feed this analysis into the **memory wiki** (the compounding-knowledge layer; schema in
`.nanopm/NANOPM-WIKI.md`) so behavioral evidence refines the persona pages and metrics refine the
objective pages over time instead of being re-derived each run. **Advisory and non-blocking** —
if anything fails or the host can't dispatch a subagent, note it and finish normally; the wiki data
page is already written.

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_wiki_ensure && echo "WIKI_READY" || echo "WIKI_SCAFFOLD_FAILED (skip ingest, finish normally)"
```

If `WIKI_READY`, print the canonical ingest prompt and **dispatch it with the Agent tool** (one subagent):

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_ingest_prompt "$(nanopm_wiki_doc_path data)" "entities/personas (behavioral evidence) and entities/objectives (metrics)"
```

The subagent dedups each citation (`nanopm-ingest-agent citation-check`), writes each page
directly (single-writer-per-file) with `nanopm-ingest-agent apply`, then runs
`nanopm-ingest-agent reindex` + `log`. On a host without an Agent tool it follows the same steps
inline. Surface which entity pages changed; the once-daily judgment lint flags any contradiction
after the fact — there is no pre-write review queue.

## Phase 6: Save context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_DATA_PATH="$(nanopm_wiki_doc_path data)"
nanopm_context_append "{\"skill\":\"pm-data\",\"outputs\":{\"question\":\"$(head -20 "$_DATA_PATH" | grep 'Question' | cut -d: -f2- | xargs | tr '\"' \"'\" | head -c 100)\",\"source\":\"posthog\",\"next\":\"pm-challenge-me\"}}"
nanopm_wiki_doc_log pm-data "wrote docs/$(basename "$_DATA_PATH")"   # global heartbeat: this page write -> wiki/log.md
```

## Completion

Tell the user:
- The wiki data page (`.nanopm/wiki/docs/data.md`) updated
- The single most important finding in one sentence
- The confidence level and what would increase it
- Whether this data suggests running more interviews (/pm-discovery) or moving to planning (/pm-challenge-me)

If the data reveals a clear problem with quantified size: "This is now ready to feed into /pm-challenge-me — the quantitative problem size strengthens the challenge session's strategic recommendations."

**STATUS: DONE**
