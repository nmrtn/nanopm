---
id: cant-tell-evidenced-from-assumed
title: "The user can't tell which plan claims are evidenced versus assumed"
theme: Trust & evidence
status: ready-for-solutions
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-29
---

## 1. Problem summary
nanopm's whole promise is planning that is "an honest falsifiable bet, not vibes wearing a PRD's clothing" — but a generated strategy, roadmap, or PRD reads as uniformly authoritative prose, with no visible marker separating a claim grounded in real signal from one the agent inferred. The user (Terminal-native Theo) cannot quickly answer "which parts of this plan are I-checked-this versus I-made-this-up?" When every line carries the same confident tone, the user either over-trusts inferences or has to re-litigate the whole document — and the easiest path is to over-trust. This affects every founder acting on a nanopm artifact.

## 2. Value to the user
### Job to be done
Theo wants to act on the plan with calibrated confidence — to spend his scrutiny on the assumed claims and move fast on the evidenced ones, so the roadmap he commits weeks to is honest rather than confident-sounding. Today the alternative is a ChatGPT thread of uniformly fluent prose he has to either trust wholesale or re-verify line by line; nothing flags its own confidence.

### Where we fall short
**Generated artifacts present evidenced and assumed claims in identical authoritative prose**
The Define skills already split claims into a clean doc plus an Evidenced/Assumed reasoning sidecar (CLAUDE.md architecture; PERSONAS.md tags lines "Evidenced"/"Assumed"), but the Plan-phase outputs the user acts on — strategy, roadmap, PRD — surface no inline confidence marker on the page where decisions get made.
- Inferred from ETHOS principle 4 ("Evidence Before Conviction") and VISION-MISSION's value "falsify before you commit"; zero user feedback on record, so nano-hypothesis.

## 3. Value to the company
Directly serves the core differentiator versus "ChatGPT-in-the-terminal" (PERSONAS anti-anxiety: "Is this just ChatGPT with extra steps?"). Visible confidence calibration is the thing a generic LLM wrapper structurally can't fake and the clearest embodiment of the "adversarial honesty" value — the trust mechanic the product is named after.

## 5. Solution hypotheses
Pointer only: inline evidenced/assumed tagging on Plan artifacts; a confidence legend; surfacing the existing reasoning-sidecar signal into the clean doc.

## Solutions
_Brainstormed via `/pm-solutions` on 2026-06-29 — full comparison in `.nanopm/wiki/entities/solutions/INDEX.md`._
- **[Inline-tag every claim in Plan docs](../solutions/inline-tag-every-claim-in-plan-docs.md)** · eng, design · small-bet · high · proposed
- **[Confidence ledger at the top of every Plan doc](../solutions/confidence-ledger-at-the-top-of-every-plan-doc.md)** · design, business · small-bet · medium · proposed
- **[Refuse-to-complete provenance gate (contractual, not display)](../solutions/refuse-to-complete-provenance-gate.md)** · business · big-bet · high · proposed
- **[Post-generation annotation pass (`nanopm-annotate-agent` primitive)](../solutions/post-generation-annotation-pass.md)** · eng · big-bet · high · proposed
- **[Challenge mode / just-the-bets view](../solutions/challenge-mode-just-the-bets-view.md)** · design · big-bet · high · proposed
