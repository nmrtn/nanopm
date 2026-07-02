---
id: first-run-value-unprovable
title: "A new user can't tell whether nanopm is worth it before committing to the whole pipeline"
theme: Onboarding & guidance
status: ready-for-solutions
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-27
---

## 1. Problem summary
nanopm asks a new user to run a multi-skill pipeline (Define → Discover → Plan → Build) before the compounding payoff appears, but the value of any single first run is not obvious up front. The user has just installed yet another CLI tool and is carrying the open question "is this just ChatGPT-in-the-terminal with extra steps?" If the first session doesn't visibly beat their current ChatGPT-plus-Notion workaround, they abandon before the pipeline ever compounds. This hits the primary persona at the exact moment the switch is supposed to start.

## 2. Value to the user
### Job to be done
Theo wants fast, concrete proof that enforcing PM discipline inside his editor beats his current workaround, *before* he invests in learning a 21-skill, four-phase system. Today his alternative is a 4,000-word ChatGPT thread he can't find again — low friction to start, zero payoff that lasts. He needs a first run that returns something he couldn't have gotten from ChatGPT, ideally within the same session as install.

### Where we fall short
**The payoff is back-loaded behind the full pipeline**
The core value — planning that compounds and a system that says "no" — only becomes visible after multiple runs accumulate state. A single first run has no prior state to compound against, so the differentiated value is hardest to feel exactly when the user is deciding whether to stay.
- PERSONAS.md names the two install-time anxieties and marks the 2nd run within 21 days as where the switch *completes* — value is structurally deferred past first run.

**No measured signal that first-run value lands**
- CONTEXT-SUMMARY.md: zero pipeline runs measured on external users; retention instrumentation removed; Define-first phase has "no telemetry on completion vs. skip." Whether a first run converts is unobserved — nano-hypothesis from architecture + 27 stars / 0 known completions.

## 3. Value to the company
First-run conversion is the top of the entire proof-quarter funnel: if new users can't feel value fast, neither cohort arm ever reaches a 2nd run, and the form-factor-vs-value test never runs cleanly.

## Solutions
_Brainstormed via `/pm-solutions` on 2026-06-27 — full comparison in `.nanopm/wiki/entities/solutions/INDEX.md`._
- **[Hero first run — one code-grounded punch, no 21-skill menu](../solutions/hero-first-run-code-grounded-punch.md)** · design · big-bet · high · proposed
- **[The compounding receipt — show what the next run unlocks](../solutions/first-run-compounding-receipt.md)** · eng · small-bet · medium · proposed
- **[Live falsification moment — feel the gate refuse your vibes](../solutions/live-falsification-moment.md)** · design · small-bet · high · proposed
- **[Instrument the first run before building anything](../solutions/instrument-first-run-before-building.md)** · eng · small-bet · medium · proposed
- **[Concierge first run — change the promise, not the product](../solutions/concierge-first-pipeline.md)** · business · small-bet · high · proposed
