---
name: pm-weekly-update
version: 0.1.0
description: "Weekly stakeholder update. Drafts a clear, honest status email for your manager, CEO, investors, or team. Reads what shipped, what slipped, and what changed strategically. Adapts tone to the audience."
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
```

## When to run this

Run `/pm-weekly-update` at the end of your work week to:
- Draft a stakeholder update without starting from a blank page
- Stay honest about slippage without burying it
- Keep your audience aligned on direction, not just activity
- Build a record of weekly progress (appended to history)

## Phase 0: Prior context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_read pm-weekly-update
nanopm_context_read pm-weekly-update
```

Check for previous weekly updates to maintain continuity of tone and ongoing commitments:
```bash
ls .nanopm/wiki/docs/weekly-updates/*.md 2>/dev/null | sort | tail -3 || echo "NO_PRIOR_UPDATES"
```

## Phase 1: Identify the audience

Ask via AskUserQuestion — ONE question:

**"Who is this update for?**

A) My manager / skip-level
B) CEO or executive team
C) Investors / board
D) My dev team
E) Cross-functional stakeholders (design, marketing, ops)

You can also just describe them in one line."

Each audience gets a different tone and level of detail:
- **Manager**: tactical, blockers front and center, decisions needed flagged
- **CEO/exec**: strategic signal only, no implementation detail, status in one word
- **Investors**: momentum, metrics, risks, no jargon
- **Dev team**: what shipped, what's next, decisions that affect them
- **Cross-functional**: what you're building and why it matters to them specifically

## Phase 2: Gather the week's data

**Git activity (last 7 days):**
```bash
git log --since="7 days ago" --oneline --no-merges 2>/dev/null | head -20 || echo "NO_GIT"
```

**Linear (if available):**
```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_TIER_LINEAR=$(nanopm_has_connector linear)
echo "LINEAR_TIER: $_TIER_LINEAR"
```

If LINEAR available:
- Issues completed this week
- Issues in progress
- Issues that slipped from this week's plan
- Any new issues added mid-week (scope creep signal)

**Wiki context (query the wiki):**

Pull the upstream context through the **query primitive** — one read-side call that
synthesizes the relevant wiki pages, instead of bespoke per-doc reads (the recipe pattern).
You reason over the cited synthesis the query returns. Print the prompt and **dispatch it
with the Agent tool** (one subagent); on a host with no Agent tool, follow its steps inline.

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_query_prompt "For a weekly stakeholder update, synthesize from the wiki: the org map and named decision-makers (to tailor the update to the stakeholders and route decisions to whoever owns them); the business model and the core GTM metrics that matter (to frame shipped work and traction commercially); the roadmap's current items and the current objectives/OKRs (to judge what shipped vs. what was planned); and the single biggest gap from the latest challenge session. Cite each claim, and name what's missing rather than inventing it." none
```

Reason over the returned synthesis — both framing moves below are advisory; if a fact is absent, proceed without it:
- **Org map + decision-makers** — *tailor the update to the stakeholders*: match tone and detail to who the audience (from Phase 1) actually is, and flag decisions to the named decision-maker who owns them.
- **Business model + core GTM metrics** — *frame metrics commercially*: translate shipped work and traction into the language of the business model (revenue, the core GTM motion, the metrics that matter), especially for the investor/exec audiences.
- **Roadmap + objectives + the biggest gap** — the planned work to assess shipped-vs-slipped against, and the strategic signal worth flagging.

**Prior week's commitments:**
If a previous update exists, extract any "next week I will..." commitments and check which were honored.

## Phase 3: Assess the week honestly

Before drafting, make an honest assessment:

**Status:** 🟢 On track | 🟡 At risk | 🔴 Blocked / behind

**What shipped:** (list, not spin)

**What slipped and why:** (be direct — one sentence per item)
- "X slipped because Y" not "X is still in progress"

**Strategic signal:** Did anything change this week that affects direction?
- New user feedback that challenges assumptions
- A competitor move worth noting
- A technical constraint that changes scope

**Commitments honored/missed from last week:** (if prior update exists)

## Phase 4: Draft the update

Write the update adapted to the audience from Phase 1.

**Template — Manager / exec:**
```
Subject: PM Update — Week of {date}

Status: {🟢 On track | 🟡 At risk | 🔴 Behind}

SHIPPED
- {item} — {one-line impact}
- {item}

SLIPPED
- {item} — {reason, one sentence}

NEXT WEEK
- {commitment 1}
- {commitment 2}

NEEDS YOUR INPUT
- {decision or unblock needed, if any — otherwise omit this section}

STRATEGIC NOTE
{One paragraph max. Only if something changed worth flagging — new signal, risk, pivot consideration. Omit if nothing material changed.}
```

**Template — Investors / board:**
```
Subject: Weekly Signal — {project} — {date}

ONE LINE: {what moved this week in one sentence}

MOMENTUM
- {shipped item with measurable impact if available}
- {traction signal: usage, signups, conversations, revenue}

RISKS
- {honest risk, one line}

NEXT MILESTONE
{what you're working toward and when}
```

**Template — Dev team:**
```
## Week of {date}

**Shipped:** {list}
**In progress:** {list}
**Blocked:** {list — include who can unblock}
**Next week's focus:** {top priority}
**Decisions made:** {any product decisions that affect implementation}
```

**Rules for all audiences:**
- Lead with status, not activity
- Slippage goes in the update — never omit it or bury it
- One strategic note max — this is an update, not a strategy doc
- If "needs your input" is empty, omit the section entirely
- Never use "we're making great progress" without a concrete data point

## Phase 5: Write the dated wiki Weekly Update page

Write the update to a DATED wiki doc page — one per week, history preserved (same
pattern as standup/retro). Each week is its own page in the `weekly-updates/` series
folder (the prds/-style layout):
`$(nanopm_wiki_series_path weekly-updates "$(date +%F)")` (i.e.
`.nanopm/wiki/docs/weekly-updates/YYYY-MM-DD.md`). The file MUST start with frontmatter,
then the update body:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_wiki_series_path weekly-updates "$(date +%F)"                                # the dated page to write
nanopm_wiki_doc_frontmatter pm-weekly-update user-stated "$(date +%Y-%m-%d)" "{sources}"
```

(Replace `{sources}` with the actual sources used — e.g. `git,linear,roadmap` — as a comma-separated list.) The body below the frontmatter is the update drafted in Phase 4. There is no separate "latest" file — each week is its own dated page in `weekly-updates/`.

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_append "{\"skill\":\"pm-weekly-update\",\"outputs\":{\"date\":\"$(date +%Y-%m-%d)\",\"audience\":\"stakeholders\",\"status\":\"drafted\"}}"
```

## Completion

Tell the user:
- Draft written to `.nanopm/wiki/docs/weekly-updates/$(date +%F).md` (this week's dated page)
- Remind them to check the "NEEDS YOUR INPUT" section before sending — that's the most actionable part
- If anything slipped: "The slippage is in the update. Don't soften it — your stakeholders will respect the honesty more than the spin."

**STATUS: DONE**
