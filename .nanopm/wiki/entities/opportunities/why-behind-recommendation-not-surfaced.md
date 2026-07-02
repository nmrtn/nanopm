---
id: why-behind-recommendation-not-surfaced
title: "The 'why' behind a recommendation isn't surfaced where the user is working"
theme: Trust & evidence
status: draft
priority: medium
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-17
---

## 1. Problem summary
When nanopm recommends a bet, a NOW item, or a next skill, the rationale that justifies it — the sources, the reasoning, the assumption being made — lives somewhere other than where the user reads the recommendation. The Define skills write rationale to a reasoning sidecar that the viewer opens only in a separate window behind a "Reasoning" button (CLAUDE.md architecture), and in the terminal the reasoning scrolls away as the conversation moves on. The user is left with a conclusion stripped of its "why," so to trust or challenge it they have to go hunting — and most won't.

## 2. Value to the user
### Job to be done
Theo wants to interrogate a recommendation in the moment he reads it — to see *why* this is the bet before he commits, so he can disagree with the reasoning rather than just the conclusion. The alternative today is a confident recommendation he either accepts or argues with from scratch, with the supporting logic buried in a separate artifact or scrolled out of view.

### Where we fall short
**Rationale is separated from the recommendation it justifies**
The reasoning exists (sidecar files, adversarial-challenge sections in STRATEGY.md) but it is one click or one scroll away from the claim it supports, never co-located at the point of decision.
- Inferred from ETHOS principle 3 ("The Question You're Avoiding") and the architecture's deliberate clean-doc/sidecar separation; no user data exists, so nano-hypothesis.

## 3. Value to the company
Reinforces "the voice in the room that asks the uncomfortable question" by making the question visible at the moment of the call. Distinct from `cant-tell-evidenced-from-assumed`: that one labels *confidence* on a claim; this one surfaces the *rationale chain* (sources + assumption + reasoning) behind a recommendation, in-context.
