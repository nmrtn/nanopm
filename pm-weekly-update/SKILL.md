---
name: pm-weekly-update
version: 0.1.0
description: "Weekly stakeholder update. Drafts a clear, honest status email for your manager, CEO, investors, or team. Reads what shipped, what slipped, and what changed strategically. Adapts tone to the audience."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Agent
---

## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
nanopm_telemetry_pending "pm-weekly-update"
_UPDATE_FILE=".nanopm/WEEKLY_UPDATE.md"
```

## When to run this

Run `/pm-weekly-update` at the end of your work week to:
- Draft a stakeholder update without starting from a blank page
- Stay honest about slippage without burying it
- Keep your audience aligned on direction, not just activity
- Build a record of weekly progress (appended to history)

## Phase 0: Prior context

```bash
nanopm_context_read pm-weekly-update
nanopm_context_all
```

Check for previous weekly updates to maintain continuity of tone and ongoing commitments:
```bash
ls .nanopm/weekly-updates/ 2>/dev/null | sort | tail -3 || echo "NO_PRIOR_UPDATES"
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
_TIER_LINEAR=$(nanopm_has_connector linear)
echo "LINEAR_TIER: $_TIER_LINEAR"
```

If LINEAR available:
- Issues completed this week
- Issues in progress
- Issues that slipped from this week's plan
- Any new issues added mid-week (scope creep signal)

**Roadmap and objectives:**
```bash
[ -f ".nanopm/ROADMAP.md" ] && cat .nanopm/ROADMAP.md || echo "NO_ROADMAP"
[ -f ".nanopm/OBJECTIVES.md" ] && cat .nanopm/OBJECTIVES.md || echo "NO_OBJECTIVES"
[ -f ".nanopm/AUDIT.md" ] && head -40 .nanopm/AUDIT.md || echo "NO_AUDIT"
```

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

## Phase 5: Save the update

Write to `.nanopm/WEEKLY_UPDATE.md` (latest draft — overwrite).

Also append to weekly history:
```bash
mkdir -p .nanopm/weekly-updates
cp .nanopm/WEEKLY_UPDATE.md ".nanopm/weekly-updates/$(date +%Y-%m-%d).md" 2>/dev/null || true
```

```bash
nanopm_context_append "{\"skill\":\"pm-weekly-update\",\"outputs\":{\"date\":\"$(date +%Y-%m-%d)\",\"audience\":\"stakeholders\",\"status\":\"drafted\"}}"
```

## Completion

Tell the user:
- Draft written to `.nanopm/WEEKLY_UPDATE.md`
- Remind them to check the "NEEDS YOUR INPUT" section before sending — that's the most actionable part
- If anything slipped: "The slippage is in the update. Don't soften it — your stakeholders will respect the honesty more than the spin."

## Telemetry

```bash
_TEL_END=$(date +%s)
_TEL_DUR=$(( _TEL_END - _TEL_START ))
rm -f ~/.nanopm/analytics/.pending-"$_TEL_SESSION_ID" 2>/dev/null || true

_OUTCOME="success"

if [ -x ~/.nanopm/bin/nanopm-telemetry-log ]; then
  ~/.nanopm/bin/nanopm-telemetry-log \
    --skill "pm-weekly-update" \
    --duration "$_TEL_DUR" \
    --outcome "$_OUTCOME" \
    --session-id "$_TEL_SESSION_ID" 2>/dev/null || true
fi
```

**STATUS: DONE**
