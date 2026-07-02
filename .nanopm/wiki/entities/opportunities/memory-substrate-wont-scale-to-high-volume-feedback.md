---
id: memory-substrate-wont-scale-to-high-volume-feedback
title: "The memory substrate won't scale to high-volume feedback — flat wiki, no vector/similarity retrieval"
theme: Memory & substrate
status: defining
priority: medium
provenance: evidence-backed
evidence_sources: [user-verbatim, external-prospect]
linked_objectives: []
related_to: [opportunities-not-grounded-in-raw-verbatims, memory-query-retrieval-is-a-black-box]
last_updated: 2026-06-30
---

## 1. Problem summary
nanopm's memory is a flat markdown wiki. That holds for a founder's hand-curated context, but the moment real signal arrives at volume — Intercom tickets, App Store reviews, many interviews — the wiki is the wrong shape: there's no structured store and no similarity/vector retrieval to dedup near-identical feedback or pull "everything about topic X." The founders' read is that beyond a certain volume the wiki "exposes everything" and can't be the substrate; the answer is a structured (likely vector/graph) store the agent ingests into and retrieves from via a similarity tool, not by stuffing pages into context.

## 2. Value to the user
### Job to be done
A founder ingesting feedback at volume wants nanopm to absorb it, dedup it, and let the agent retrieve exactly the relevant slice on demand — without re-reading raw sources and without the wiki bloating until the LLM can't navigate it. The alternative today (flat MD + read-into-context) doesn't survive thousands of feedback lines.

### Where we fall short
**No structured store / similarity retrieval for high-volume signal**
The wiki isn't adapted to that thickness of volume; retrieval is "read pages into context" rather than a similarity search.
- "Quand tu as cinquante mille lignes de feedback, comment tu les ingères... la réponse ça peut pas être autre chose qu'une base de données, même vectorielle pour des similarités contextuelles. Le Wiki n'est pas du tout adapté à cette épaisseur de volume." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)
- "Le but ça serait d'avoir une base structurée automatiquement, l'agent ingère ce qu'il faut, retrieve ce qu'il faut, via un tool de similarity qui lui permet d'aller chercher le bon contenu." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)

**Externally corroborated — a CPTO built exactly this at scale**
Lachlan Laycock (CPTO, Livestorm) independently built a ProductBoard replacement on the same source→fact→problem model, with embeddings + LLM "fact edges" for similarity matching — driven precisely by feedback volume (~50K insights). First external confirmation of the bet.
- "On a énormément d'insights (~50K)... j'importe tous les insights comme des sources, puis j'en extrais des facts. Quand j'extrais les facts, je crée des embeddings pour qu'ils puissent être rapprochés des problems. Ce processus de fact edges s'appuie sur des LLM pour évaluer la pertinence des correspondances." — Lachlan Laycock (CPTO, Livestorm), iMessage 2026-06-30 (raw/feedback/dae1853ac1c1.md)

## 3. Value to the company
This is the scaling ceiling of the whole ingestion bet: grounding opportunities in verbatims only compounds if the substrate can hold real feedback volume. Owned on the memory track. Now **externally validated** by a CPTO operating at 50K-insight scale — no longer founder-only conjecture. Still a sequencing question (don't build a vector DB before the manual loop proves value), but the demand is real.

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: a structured (vector/graph) store behind the wiki; a similarity-retrieval tool the agent calls instead of reading pages into context; dedup-by-embedding on ingest. -->

## Open / superseded
**Provenance upgraded user-stated → evidence-backed (2026-06-30).** First external signal: an independent CPTO (Livestorm) built the same vector/fact-edge architecture at ~50K-insight scale for the same reason. — Lachlan Laycock, iMessage 2026-06-30 (raw/feedback/dae1853ac1c1.md)
