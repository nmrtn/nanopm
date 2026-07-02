---
type: overview
section: define
generated: 2026-06-29
sources: [vision-mission, business-model, org, product, personas]
---

# PM Context Brief
Generated 2026-06-29 · Project: nanopm · Sources: vision-mission, business-model, org, product, personas

## What we do
nanopm is a pack of 24 markdown "skills" plus a shared bash runtime, Python validators, and a SwiftUI macOS viewer prototype that turns an AI coding agent (Claude Code / Mistral Vibe / OpenAI Codex) into a PM. Each skill is a structured prompt the agent executes: it queries what's known in a **maintained LLM-wiki** at `.nanopm/wiki/` (Karpathy's pattern — ingest / query / lint), reasons, reads the codebase or site, and writes a human-readable artifact back. The next skill reads from there — planning compounds across sessions instead of bouncing across ChatGPT / Notion / Linear where nothing knows the code. Since v0.23.0–0.24.0 the wiki hosts a working **Teresa-Torres Opportunity Solution Tree** (Outcomes → Opportunities → Solutions → PRD): planning skills now query the ranked opportunities and `/pm-solutions` seeds `/pm-prd <chosen-solution-slug>`. Adversarial gates refuse to complete strategy / roadmap / PRD / solutions runs without a falsifiable bet (segment + behavior + metric + timeframe). Built engine + recipes: every skill is a thin recipe over shared query → reasoning → ingest primitives.
_More detail: `.nanopm/wiki/docs/product.md`_

## Who it's for
Primary: **Terminal-native Theo** — a solo founder / indie hacker shipping with an AI coding agent, no dedicated PM, lives in the terminal. His JTBD: catch wrong-direction work before weeks are spent, and make planning compound across sessions instead of evaporating across four tools that don't know the code. Secondary (unvalidated, assumed): **Designer-founder Dani**, who ships with an agent but does not live in the terminal — the explicit bet behind the macOS viewer; she earns "primary" only once Theo's cohort retains AND the viewer cohort retains higher. Anti-persona: non-builders evaluating nanopm as standalone PM SaaS (a Notion/Linear replacement) who will not run an AI coding agent — serving them means rebuilding as PM SaaS and killing the agent-native value prop.
_More detail: `.nanopm/wiki/docs/personas.md`_

## How we make money
We don't — **free MIT-licensed open-source skill pack, monetization deliberately deferred.** Zero revenue by design; distribution is a free `curl | bash` setup script plus GitHub clone. One pricing tier ($0, nothing gated); the CLI pack and macOS viewer ship as a single MIT bundle. No GTM motion exists — distribution is incidental (GitHub repo, README, word of mouth), there's no GTM or user-research owner, and cohorts are recruited by hand. Riskiest assumption: that deferral is a safe sequence rather than a way to keep building a free tool that never crosses into a business. Falsifiable trigger: if either Q3 2026 proof cohort reads PASS, name a revenue model within 30 days.
_More detail: `.nanopm/wiki/docs/business-model.md`_

## Why we exist
**Mission:** give solo founders and PMs building with AI coding agents an AI PM OS that automates discovery, signal surfacing, and continuous strategy revision — so deciding *what to build next* stops being the human bottleneck. **Vision (3–5 yr):** the product team is 90% automated (directional, assumed); the PM loop runs continuously alongside the coding agent — scanning sources, surfacing/validating signal, revising strategy — shortening build–measure–learn from quarters to days, with the human making only the calls that require taste, ethics, and no's. The viewer is instrumentation toward that loop, not a competing destination. **Stage: Pre-PMF** — two-person side project, 27 GitHub stars · 1 fork · 0 external issues · 0 retention measured, no named cohort recruited. Q3 2026 is an explicit *proof quarter* for one question: is form factor the adoption blocker, or is the value? Values: problem first · falsify before you commit · subtract before you add · ship to learn · adversarial honesty.
_More detail: `.nanopm/wiki/docs/vision-mission.md`_

## Who decides
A two-person side project: **Nicolas Martin** (`nmrtn`, co-founder, repo of record, 53 commits/12mo) and **Guillaume Simon** (`guillaumesimon`, co-founder, 34 commits/12mo, recent Define + viewer work). Both contribute code; **both decide everything together — no formal split, no designated tiebreaker, no decision log.** Decisions happen in DMs/calls and are not recorded; GitHub is the tool of record and `.nanopm/` artifacts capture PM thinking but not the "we agreed X" moments. No external stakeholders, investors, or paying customers; weekly hours are the binding constraint, not roles.
_More detail: `.nanopm/wiki/docs/org.md`_

## What's NOT known yet
- **Zero external validation.** No named cohort recruited, 0 pipeline runs measured on any external user, 0 retention data (instrumentation removed v0.4→v0.6, not re-enabled) — every claim about real users is a hypothesis. The biggest gap is an action gap, not a hiring gap.
- **The One Belief is unproven:** that a real founder/PM voluntarily returns to a full nanopm pipeline within 21 days. If false, no form factor saves the product.
- **OST end-to-end loop is wired but unused.** No founder has taken an opportunity → `/pm-solutions` → chosen solution → `/pm-prd` → shipped feature — not even internally. The chain compiles; usage is the next falsification.
- **The memory bet is validated by wiring, not use.** Whether the judgment lint catches real contradictions the structural pass misses has a 3-week falsification window and zero data yet — if it surfaces nothing real, removing the pre-write gate was premature.
- **One product or two?** CLI skill pack vs. macOS viewer diverge in audience (Theo vs. Dani); which surface is canonical is unanswered, and the viewer bet (form factor, not value, is the blocker) is unvalidated.
- **No revenue model, no GTM, no unit economics** — all premature until retention proves; no GTM or user-research owner exists in the org, and decisions aren't logged.
- **Positioning lag:** the README still sells nanopm defensively ("building the wrong thing fast"), one notch below the "AI PM OS" ambition the product already embodies, and under-tells the macOS surface and the OST chain.
