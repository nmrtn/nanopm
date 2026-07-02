---
id: opportunities-not-grounded-in-raw-verbatims
title: "Opportunities aren't grounded in raw verbatims — you can't pull up the actual feedback behind a problem"
theme: Trust & evidence
status: defining
priority: high
provenance: evidence-backed
evidence_sources: [user-verbatim, external-prospect]
linked_objectives: []
related_to: [why-behind-recommendation-not-surfaced, cant-tell-evidenced-from-assumed]
last_updated: 2026-06-30
---

## 1. Problem summary
An opportunity in the database is a claimed user problem, but today it carries no link back to the raw signal that justifies it — no archived feedback, no resolvable verbatim. A founder (or a stakeholder) looking at an opportunity can't answer "show me the actual user feedback that says this," so the DB reads as assertions rather than evidence, and re-analysis or trust-checking means going hunting in the original source — if it still exists. This is the foundational gap behind the feedback-ingestion bet: the `.nanopm/raw/` evidence layer was documented but empty, and citations like `— Granola <id>` pointed at nothing local. Until problems are anchored in archived verbatims, the opportunity DB can't be the trustworthy, traceable substrate the rest of the loop (solutions, roadmap, learning report) is supposed to build on.

## 2. Value to the user
### Job to be done
The founder wants every opportunity to be backed by the real, re-openable feedback behind it — to click a problem and see the verbatims that support it, and conversely to take a piece of raw feedback and see which opportunities it fed. The alternative today is taking the agent's word for it or re-reading the source by hand, which is exactly the trust-and-traceability problem nanopm exists to remove.

### Where we fall short
**Opportunities have no verbatim grounding and no path back to the source**
There is no link from an opportunity to the raw feedback that justifies it, and no way to ask "show me all the raw user feedback on this topic."
- "Actuellement les opportunités ne sont jamais associées avec un verbatim, et ça peut être important de se dire : montre-moi tous les users feedback bruts qui parlent de ce sujet." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)

**The pattern is known and wanted — it existed in the founder's prior tooling**
The founder already ran exactly this loop in Dust (analyze sources → match to the opportunity DB → attach quotes or propose new opportunities), and wants nanopm to do it natively.
- "Dans mes agents Dust, un passait, analysait tous les Dovetail, regardait ma base d'opportunités, allait chercher des quotes intéressantes ; si oui il les mettait dans l'opportunité avec les quotes associées ; sinon, s'il y avait des nouvelles opportunités liées à mes objectifs, il m'en proposait des nouvelles." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)

**Externally corroborated — the source→fact→problem grounding model**
A CPTO building a ProductBoard replacement made this grounding chain first-class: sources → extracted facts (categorized, importance-scored) → problems, each fact citing and resolving to its source — exactly the verbatim grounding nanopm lacks.
- "J'importe tous les insights comme des sources, puis j'en extrais des facts. Ces facts sont associés à des problems... [avec] un chatbot qui permet d'interroger la DB." — Lachlan Laycock (CPTO, Livestorm), iMessage 2026-06-30 (raw/feedback/dae1853ac1c1.md)

## 3. Value to the company
This is the trust mechanic the product is named after, applied to the opportunity DB: grounded, re-openable evidence is the thing a generic "ChatGPT-in-the-terminal" structurally can't fake. It is the foundational outcome of the feedback-ingestion-and-learning-loop bet (the `/pm-add-feedback` PRD) — without verbatim grounding, the downstream solutions/roadmap inherit ungrounded inputs. Now **externally validated**: a CPTO independently built his whole insight system around this exact grounding chain — no longer founder-only conjecture.

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions (already specced in the /pm-add-feedback PRD): archive every raw source under .nanopm/raw/; append exact verbatims to the matching opportunity with a citation that resolves to the archived file; a bidirectional manifest so a raw source lists the opportunities it fed; a viewer view to browse raw feedback and jump source⇄opportunity. -->

## Open / superseded
**Provenance upgraded user-stated → evidence-backed (2026-06-30).** First external signal: an independent CPTO (Livestorm) built his entire customer-insight system on the source→fact→problem grounding chain, confirming the gap and the wanted shape. — Lachlan Laycock, iMessage 2026-06-30 (raw/feedback/dae1853ac1c1.md)
