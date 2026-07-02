---
id: connector-library
type: feature
title: "Connector library"
status: active
provenance: evidence-backed
sources: [PRODUCT.md]
relates_to: []
last_updated: 2026-06-23
---

## Summary
A library of connector specs under connectors/ that let skills pull data from external PM and analytics tools. Each connector uses a four-tier fallback — MCP, then API, then browser, then manual — so data ingestion degrades gracefully when a richer integration is unavailable.

## What we know
**What it is**
Connector specs spanning the common PM/analytics tools.
- "Connector library — 16 connector specs under `connectors/` (Linear, GitHub, Notion, Dovetail, Productboard, PostHog, Amplitude, Mixpanel, Granola, Google Calendar/Drive, Intercom, HubSpot, Jira, Slack)" — PRODUCT.md

**How it works**
Graceful degradation across four tiers.
- "with 4-tier fallback (MCP → API → browser → manual)" — PRODUCT.md
- "Data ingestion: MCP → API → browser → CONTEXT.md manual fallback." — PRODUCT.md
