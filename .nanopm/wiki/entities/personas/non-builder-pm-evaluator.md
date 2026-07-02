---
id: non-builder-pm-evaluator
type: persona
title: "Anti-persona: Non-builder PM evaluator"
status: active
provenance: nano-hypothesis
sources: [PERSONAS.md]
relates_to: []
last_updated: 2026-06-23
---

## Summary
The anti-persona is the non-builder evaluating nanopm as PM software — PMs, product managers, and founder-curious operators who want a Notion/Linear/ProductBoard replacement and do not (and will not) run an AI coding agent. They are who nanopm is explicitly NOT building for, because nanopm only delivers value inside an agent runtime.

## What we know
**Job to be done**
They want a standalone PM tool — structured audits, strategies, and PRDs — without ever touching an AI coding agent ("can I use this without Claude Code?"). nanopm cannot serve this without becoming PM SaaS (hosted editor, own LLM calls, own auth, a Notion-shaped backlog), which would kill the cost structure, the agent-native value prop, and the architectural bet. The tempting failure mode is optimizing the macOS viewer so PMs can use it standalone — every such decision pushes one click closer to PM SaaS.
- "Non-builders evaluating nanopm as PM software — PMs, product managers, founder-curious operators who want a Notion/Linear/ProductBoard replacement and do not (and will not) run an AI coding agent." — PERSONAS.md
- "Why we say no: nanopm only delivers value inside an agent runtime. Every skill is a structured prompt the agent executes against the codebase, your nanopm state, and the connectors. Without the agent, you have markdown files and bash scripts — not a product." — PERSONAS.md
- "Revisit when: An agent-runtime-free version of the planning loop is shown to produce output that compounds ... Under the current architecture, this is structurally never." — PERSONAS.md
