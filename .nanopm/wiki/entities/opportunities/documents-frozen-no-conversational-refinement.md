---
id: documents-frozen-no-conversational-refinement
title: "Documents are frozen — I can't have a back-and-forth to refine one, so I re-run from scratch or escape to Claude Code"
theme: Continuity & retention
status: defining
priority: high
provenance: user-stated
evidence_sources: [user-verbatim]
linked_objectives: []
related_to: []
last_updated: 2026-06-29
---

## 1. Problem summary
nanopm skill runs are one-shot: the skill asks one question and stops. Once a document (a PRD, a solution, any generated artifact) is written, there's no way to open it and refine it through dialogue — the user must re-run the whole skill from scratch or leave nanopm and go back to Claude Code to keep working. The frozen-document model pushes the founder out of the product at exactly the moment he wants to stay in it and iterate.

## 2. Value to the user
### Job to be done
The founder wants an ongoing, ping-pong dialogue scoped to a specific document or solution — open it, discuss it, adjust it in place — in both the viewer and the CLI, rather than restarting a full run for every tweak. His alternative today is escaping to Claude Code (which he finds bizarre, since the work belongs in nanopm) or re-running from zero.

### Where we fall short
**Runs are one-shot — one question, then stop**
The skill poses a single question and halts; there's no way to continue the conversation within the frame of that solution/document.
- "Je lance la feature, il me pose une question et s'arrête... j'ai envie de continuer la discussion et de pouvoir faire un ping-pong avec NanoPM dans le cadre de cette solution." — self-interview, 2026-06-29 (Granola dc61e5c2)

**The frozen model pushes the user back to Claude Code**
Because he can't iterate inside nanopm, he leaves it to run things elsewhere — which feels wrong, since the work belongs in nanopm.
- "Ce qui m'oblige aujourd'hui parfois à retourner dans Claude Code pour lancer certains runs, ce qui est bizarre." — self-interview, 2026-06-29 (Granola dc61e5c2)

**No refine-in-place — every change means starting over**
He can't revisit a document and adjust it conversationally; it feels like starting from zero each time.
- "J'aimerais bien revenir sur un document et avoir une discussion sur ce document et l'ajuster... plutôt que de relancer un run entier from scratch. Là j'ai l'impression que je dois recommencer à zéro à chaque fois." — self-interview, 2026-06-29 (Granola dc61e5c2)

## 3. Value to the company
Conversational refinement is the third of the three H-severity gaps that, together, turn nanopm from a *generator you invoke* into a *partner you work with*. Every escape to Claude Code is a retention leak — the user leaving the product to do work the product was supposed to own. Possible evolution of the existing brainstorm surface scoped to a single artifact.

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: a document-scoped conversational mode (open a PRD/solution and iterate) in viewer + CLI; an evolution of /pm-brainstorm bound to one artifact; edit-in-place via dialogue rather than full re-run. -->
