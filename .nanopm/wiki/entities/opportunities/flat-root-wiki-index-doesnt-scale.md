---
id: flat-root-wiki-index-doesnt-scale
title: "The flat root wiki index doesn't scale — it lists every entity and truncates, so the LLM can't navigate it"
theme: Memory & substrate
status: defining
priority: medium
provenance: user-stated
evidence_sources: [user-verbatim]
linked_objectives: []
related_to: [memory-substrate-wont-scale-to-high-volume-feedback]
last_updated: 2026-06-30
---

## 1. Problem summary
The wiki's root `index.md` is flat: it lists every competitor, persona, feature, opportunity, and solution on one page. As the wiki grows it becomes a large file the LLM can't navigate well, and entries are already being truncated — so the routing layer that's supposed to help the agent find the right page instead degrades decisions. The founder's read is that a single top-level index is the wrong altitude: each folder should carry its own index, and the level above should list only the sub-indexes — a recursive structure the agent can drill into at any depth.

## 2. Value to the user
### Job to be done
The founder wants the wiki to behave like a real wiki / a company Notion: a stable, navigable hierarchy where the home index points to section indexes, not a flat dump of everything. The alternative today is a bloated, truncated root index that makes the agent's retrieval unreliable.

### Where we fall short
**Flat root index lists everything and truncates**
The general index holds all opportunities (and all other entities), and they're truncated — the same bloat problem nanopm exists to solve, reproduced one level up.
- "Dans l'index général de ton wiki tu as la liste de toutes tes solutions et toutes tes opportunités... j'ai peur que le truc devienne impossible à naviguer pour un LLM. À la racine, j'ai encore toutes les opportunités dedans et en plus elles sont tronquées." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)

**No recursive sub-index structure**
Each folder should have its own index; the level above should list only the sub-indexes, so the agent drills down on demand.
- "Il nous manque un second level de contenu, des sous-index... tu rajoutes un niveau index et au niveau du dessus tu ne listes que les index sous-jacents. Une architecture récursive, peu importe la profondeur, il arrive à se débrouiller." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)

## 3. Value to the company
The index IS the routing layer the whole memory-wiki bet depends on; if it's the wrong altitude, every skill's retrieval inherits bad navigation. Note: overlaps the existing `wiki-index-bounded` PRD / NOW work — this opportunity is the problem statement behind it. Guardrail: internal founder signal (N=1, two co-founders).

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: per-folder index.md; a root index that lists only sub-indexes; recursive drill-down; bound each index by construction (ties to wiki-index-bounded). -->
