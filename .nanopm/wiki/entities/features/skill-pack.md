---
id: skill-pack
type: feature
title: "Skill pack"
status: active
provenance: evidence-backed
sources: [PRODUCT.md]
relates_to: []
last_updated: 2026-06-23
---

## Summary
A pack of markdown "skills" that turn an AI coding agent (Claude Code / Mistral Vibe / OpenAI Codex) into a PM. Each skill is a structured prompt the agent executes — it asks targeted questions, reads the codebase or site, and writes a human artifact plus a typed state record. Skills are grouped into four phases so PM work runs end-to-end inside the agent.

## What we know
**What it is**
The core product surface — structured prompts the agent runs.
- "nanopm is a pack of 21 markdown \"skills\" plus a shared bash runtime and two Python validators that turn an AI coding agent (Claude Code / Mistral Vibe / OpenAI Codex) into a PM." — PRODUCT.md
- "Each skill is a structured prompt the agent executes: it asks targeted questions, reads the codebase or site, and writes (a) a human markdown artifact to `.nanopm/` and (b) a typed, schema-validated JSONL record to `~/.nanopm/projects/{slug}/`." — PRODUCT.md

**How it is organized**
Four phases plus daily ops and orchestration.
- "Skill pack (21 skills, grouped by phase — v0.10.0 reorganization): Define ... Discover ... Plan ... Build / handoff ... Daily ops ... Orchestration / meta" — PRODUCT.md
- "The next skill reads from there — the pipeline compounds across sessions." — PRODUCT.md
