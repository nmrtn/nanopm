---
id: memory-query-retrieval-is-a-black-box
title: "Memory query/retrieval is a black box — you can't see or trust whether it fetched the right pages"
theme: Memory & substrate
status: defining
priority: low
provenance: user-stated
evidence_sources: [user-verbatim]
linked_objectives: []
related_to: [memory-substrate-wont-scale-to-high-volume-feedback, why-behind-recommendation-not-surfaced]
last_updated: 2026-06-30
---

## 1. Problem summary
Every skill queries the memory wiki before running — it reads the index and decides which pages to pull deeper. But that retrieval step is opaque: the founder can't see whether the agent queried the right pages intelligently for the task at hand, and it "has become a bit of a black box." When retrieval quietly fetches the wrong context, downstream output degrades with no visible cause, and there's no signal to debug or trust the engine. The founder flags the engine and its prompts as needing optimization.

## 2. Value to the user
### Job to be done
The founder wants confidence that, when he works on (say) planning, the memory engine fetched the right pages — and ideally some visibility into what it retrieved and why. The alternative today is trusting an opaque step and only noticing via degraded output.

### Where we fall short
**Retrieval is opaque and unverifiable**
No view into which pages the query pulled or whether the routing was right; the engine/prompts need tuning.
- "Est-ce qu'il va bien faire sa query aux bonnes pages de manière intelligente... c'est devenu un peu une black box. Il y a de l'optimisation à faire sur ce moteur-là, sur les prompts." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)

## 3. Value to the company
Retrieval quality is the hidden lever under every skill's output; an opaque, untuned router caps the whole product's reliability. Lower priority than the structural substrate gaps, but related. Guardrail: internal founder signal (N=1, two co-founders).

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: surface what the query retrieved (pages + why) at run time; eval/tune the retrieval prompts; a retrieval-quality check. -->
