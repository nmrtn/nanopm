---
id: typed-state-layer
type: feature
title: "Typed cross-session state layer"
status: active
provenance: evidence-backed
sources: [PRODUCT.md]
relates_to: []
last_updated: 2026-06-23
---

## Summary
Every skill writes an append-only, schema-validated JSONL record so the next session reads the prior decision instead of re-grepping markdown. This typed memory that compounds across sessions is positioned as the durable value of nanopm and remains the load-bearing infrastructure of the architecture.

## What we know
**How it works**
Append-only typed records with schema enforcement.
- "every artifact lands in **typed, schema-validated state** so the next session reads the prior decision instead of regrepping markdown" — PRODUCT.md
- "`bin/nanopm-state-log` (schema-enforcing append: enums, confidence 1–10, required fields), `bin/nanopm-state-read` (read)" — PRODUCT.md

**Why it matters**
The core durable-value bet.
- "Typed cross-session state is the durable value. The v0.6.x core thesis: memory that compounds is why you'd use nanopm over ad-hoc ChatGPT." — PRODUCT.md
- "the architecture still leans entirely on the JSONL state layer" — PRODUCT.md
