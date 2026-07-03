---
id: established-pm-pat
type: persona
title: "Established-PM Pat (anti-persona)"
status: active
provenance: evidence-backed
sources: [docs/personas.md, docs/strategy.md]
relates_to:
  - page: entities/personas/solo-builder-sam.md
    rel: contradicts
  - page: entities/personas/small-team-mia.md
    rel: contradicts
last_updated: 2026-06-26
---

## Summary

Established-PM Pat is a product manager at a company with a dedicated PM role, an existing product process, and a team of engineers. nanopm explicitly excludes this persona: the product replaces the PM function, so for Pat it creates duplication, not value. Pat's feature requests would pull nanopm away from its CLI/terminal ethos.

## What we know

**Why Pat is the anti-persona**
nanopm replaces the PM function; for Pat it duplicates it. Explicitly named in strategy.md as out-of-scope.
- "NOT for established product teams with a PM seat" — strategy.md via docs/personas.md, 2026-06-26
- "nanopm replaces the PM function; for Pat, it duplicates it. Their feedback would pull nanopm toward Jira integrations, stakeholder management features, team-level permissions, and approval workflows." — docs/personas.md, 2026-06-26

**Why Pat is tempting (but wrong)**
Pat speaks fluent PM — would use every skill, give detailed feedback, feel impressed by the pipeline. Looks like a power user.
- "Pat speaks fluent PM — they'd use every skill, give detailed feedback, and feel impressed by the pipeline. They look like a power user and would probably tell their network about it." — docs/personas.md, 2026-06-26

**The product impact of building for Pat**
Feature requests from Pat would pull nanopm toward Jira integrations, stakeholder management, team-level permissions, approval workflows — all of which violate the CLI/terminal ethos and the "no multi-user features" commitment.
- "The product would stop being sharp for the person with no PM and start being weak for the person who already has one." — docs/personas.md, 2026-06-26

**When to revisit**
Small-team validation (Mia) is complete AND there is explicit, repeated inbound from PM-seat users asking for a terminal-native PM layer — not the other way around.
- "Revisit when: Small-team validation (Mia) is complete AND there is explicit, repeated inbound from PM-seat users asking for a terminal-native PM layer — not the other way around." — docs/personas.md, 2026-06-26

**Decision rule**
When a feature request optimizes for Pat — richer stakeholder reporting, multi-user state, enterprise integrations — the answer is no without a re-prioritization conversation.
- "When a feature request optimizes for Pat — richer stakeholder reporting, multi-user state, enterprise integrations — the answer is no without a re-prioritization conversation." — docs/personas.md, 2026-06-26

**Confidence**
Evidenced — explicitly named in strategy.md and confirmed by maintainer.
- "Explicitly named in strategy.md ('NOT for established product teams with a PM seat') and confirmed by the maintainer." — docs/personas.md, 2026-06-26

## Open / superseded
_Nothing superseded yet._
