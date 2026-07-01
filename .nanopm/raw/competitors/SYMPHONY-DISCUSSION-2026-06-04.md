# Symphony GitHub Discussion — Tracking

**Posted:** 2026-06-04 07:07 UTC (00:07 PT)
**URL:** https://github.com/openai/symphony/discussions/86
**Title:** nanopm — generates Symphony WORKFLOW.md + Linear tickets from a PRD
**Category:** Show and tell
**Day-0 baseline:** 0 reactions, 0 comments, 0 OpenAI engagement

## Verdict target (from issue #13 / typed target `symmetric-launch-week-one`)

Success at day 14:
- **≥10 stars** on `nmrtn/nanopm`, AND
- **at least one of:** OpenAI-employee mention, OpenSpec-community mention, gstack-author mention, inbound issue from a Symphony/OpenSpec/gstack user

OR for this specific channel:
- **≥1 OpenAI-employee response** to discussion #86, OR
- **≥3 substantive comments** from anyone in the discussion

## Day-by-day

| Day | Date | 👍 | ❤️ | 🎉 | 👀 | 🚀 | Comments | Stars on nmrtn/nanopm | OpenAI engagement | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 2026-06-04 | 0 | 0 | 0 | 0 | 0 | 0 | **26 stars** (1 fork, 2 watchers) | none | Posted 07:07 UTC. Day-0 stars baseline captured. **First qualitative engagement same day**: friend (knee-physio app builder) asked which nanopm command to use for pricing work → see qualitative log below. |
| 1 | 2026-06-05 | 0 | 0 | 0 | 0 | 0 | 0 | **27 stars** (+1) | none | Public discussion still cold. **Second qualitative engagement**: another user reported ETHOS slow-validation bias in /pm-roadmap and /pm-strategy → see qualitative log. Also: 3 direct user testimonials in DMs ("j'aime trop nanopm", "incroyable") that will go into the LinkedIn post. |
| 2 | 2026-06-06 | | | | | | | | | |
| 3 | 2026-06-07 | | | | | | | | | |
| 5 | 2026-06-09 | | | | | | | | | |
| 7 | 2026-06-11 | | | | | | | | | (week 1 review) |
| 10 | 2026-06-14 | | | | | | | | | |
| 14 | 2026-06-18 | | | | | | | | | (**verdict day**) |

## Refresh command (run daily, takes 5 seconds)

```bash
gh api repos/openai/symphony/discussions/86 | python3 -c "
import json, sys
d = json.load(sys.stdin)
r = d['reactions']
print(f\"Comments: {d.get('comments',0)} | 👍{r.get('+1',0)} ❤️{r.get('heart',0)} 🎉{r.get('hooray',0)} 👀{r.get('eyes',0)} 🚀{r.get('rocket',0)}\")
"
gh api repos/nmrtn/nanopm | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f\"Stars: {d['stargazers_count']} | Forks: {d['forks_count']} | Watchers: {d['subscribers_count']}\")
"
```

Append a row to the day-by-day table.

## Qualitative engagement log

Captures non-public engagement (DMs, screenshots, conversations) that the public reaction counts won't show.

### 2026-06-04 — Friend asks about pricing skill

**Context:** Friend is building a knee-physiotherapy app (reminder + videos/gifs for exercises). Asked which nanopm command to use to work on the pricing model.

**The exchange (paraphrased from screenshot):**
- Friend: "J'aimerais travailler sur le modèle de pricing, tu me recommandes quelle commande?"
- Builder: "/pm-strategy je dirai, mais il faut plutôt réfléchir à une nouvelle skill. /pm-gtm"
- Friend: "Super idée. En s'appuyant sur competitors"

**Signal value:** First external user engagement since launch. Same day as discussion #86. Proves a non-stranger is using nanopm on a real product AND has opinions about its scope.

**Architectural insight (from friend):** /pm-gtm should compose with /pm-competitors-intel. Correct instinct — GTM/pricing decisions benefit from competitive pricing landscape, which the competitors-intel snapshots already provide.

**Action taken:**
- Typed `gap` decision written to state with key `missing-gtm-pricing-skill`, confidence 8, source=user-stated
- Recommendation back to friend: use `/pm-strategy` for the bet and positioning + run `/pm-competitors-intel` to pull competitor pricing pages + manually layer pricing on top. NOT building /pm-gtm yet.
- Rationale: scope-out `not-49-skill-catalog` (in state) requires ≥3 external users requesting a missing skill before building. This counts as **1 of 3**.
- If 2 more requests come in within the next 7-14 days, /pm-gtm becomes the next NOW item.

**Lessons for nanopm:**
- The first thing external users ask is "which command for X?" — strongly suggests nanopm needs a better discovery surface (maybe `/pm-help` that takes a goal and recommends a command)
- Pricing is a common gap that strategy-as-bet doesn't cover
- The /pm-competitors-intel → /pm-gtm composition is the obvious next pipeline addition

### 2026-06-05 — User reports ETHOS slow-validation bias

**Context:** Different user (the "Pas faux" replier in screenshot). Ran `/pm-roadmap`. nanopm strongly suggested instrumenting / setting up measurement before building anything else. User liked the rigor ("trop cool") but flagged that nanopm assumes you ship with developers and that takes time.

**The exchange (paraphrased from screenshot, translated):**
- Builder (Nico): "How did it force your hand?"
- User: "/pm-roadmap. It strongly SUGGESTED instrumenting before building anything else. I found it really cool. But it assumes you ship with developers and that takes time. So it pushes back on directly building feature mockups."
- Builder: "Oh yeah, we could have a `/pm-setup` to define the mode: solo builder / squad / etc."
- User: "That's what I was going to tell you. The reasoning isn't the same on the roadmap."
- Builder: "What would the different modes change?"
- User: "It suggests a lot of 'Wizard of Oz' in strategy where you fake features to validate. For me that doesn't make sense in solo founder / ship-fast mode."
- Builder: "That should be the only Mode actually. I don't really see the point of not shipping fast."
- User: "Fair point."

**The architectural issue:** ETHOS principle 4 ("Evidence Before Conviction") implicitly assumes builds are expensive — so "Wizard of Oz / fake-it-first" is the cheapest test. For solo founders shipping with AI agents, cost-to-build approximates cost-to-fake, and **shipping IS the experiment.** The bias propagates through:
- `/pm-strategy` adversarial gate: "CHEAPEST TEST" framing biases toward fake-it
- `/pm-roadmap` gate: requires named segment + number + observable behavior + timeframe → implies upfront instrumentation
- `/pm-prd` Falsification: same 4-element rubric demands pre-build measurement plan
- `/pm-audit` Q9: "What metric matters most?" — assumes you want metrics

**Action taken:**
- Typed `gap` decision written to state with key `ethos-slow-validation-bias`, confidence 8, source=user-stated
- Two paths captured in the gap: (A) per-mode config, or (B) rewrite ETHOS principle 4 default to ship-and-observe
- Builder's instinct in the chat leaned toward path B ("ca devrait être le seul Mode en fait")
- **Not fixing today** — architectural decision; needs sleeping on

**Signal value:** This is qualitatively different from the /pm-gtm request. /pm-gtm was "you're missing a skill" — additive. This is "your default reasoning is wrong for your target audience" — corrective. Stronger signal because it's about framework bias, not feature gaps.

**Lessons for nanopm:**
- ETHOS was probably written from generic-PM context (think Marty Cagan / Teresa Torres talking to big teams). Target audience is actually solo + AI-native — different cost calculus.
- "Ship-and-observe" needs to be a first-class evidence path in the adversarial gates, not "Wizard of Oz" as the implied right answer.
- The user inadvertently named the right Q9 alternative: "Magicien d'OZ ça n'a pas lieu d'être en solo founder / ship fast" — the very acknowledgement of the methodology is the gap.

---

## Notes for the next observations

- **Posted at 00:07 PT (07:07 UTC)** — middle of European morning, dead time in the US. Engagement window starts when US wakes up ~6am PT. Don't read into low day-0 numbers.
- **Stars baseline needs capture.** Run the refresh command and fill in day-0 stars.
- **OpenAI engagement = any comment from an account whose GitHub profile lists OpenAI affiliation** (the Symphony authors Alex Kotliarskyi @AlexK_io, Victor Zhu @vzhu, Zach Brock @zbrock — check those specifically).

## What "win" looks like beyond the metric

- Substantive reply from Symphony maintainer (any of the 3 authors) — strong signal
- Reply from a Symphony user saying "tried this, here's what worked/didn't" — strongest possible signal (real usage)
- 5+ stars driven by the discussion (check stars time-series before/after posting)
- Any inbound nanopm GitHub issue/PR within 14 days referencing Symphony

## What to do if no engagement by day 7

- Don't bump the post. Looks needy.
- Move to step 2 of the launch plan: record the demo (issue #15) + post the Twitter thread (Draft 2 in `LAUNCH-DRAFTS-2026-06-03.md`). New channel, fresh attention.
- Reddit r/ClaudeAI is the third channel if Twitter is also quiet.

## Day-0 baseline capture

Run this NOW (or at next session) to capture day-0 numbers:

```bash
# Discussion baseline
gh api repos/openai/symphony/discussions/86 | python3 -c "
import json, sys
d = json.load(sys.stdin); r = d['reactions']
print(f'discussion: {d.get(\"comments\",0)} comments, reactions: 👍{r.get(\"+1\",0)} ❤️{r.get(\"heart\",0)} 🎉{r.get(\"hooray\",0)} 👀{r.get(\"eyes\",0)}')"

# Repo baseline
gh api repos/nmrtn/nanopm | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'repo: {d[\"stargazers_count\"]} stars, {d[\"forks_count\"]} forks, {d[\"subscribers_count\"]} watchers')"
```

Fill the day-0 row with the output.
