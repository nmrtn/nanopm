---
id: linear
type: competitor
title: "Linear"
status: active
provenance: evidence-backed
sources: [COMPETITORS.md]
relates_to: []
last_updated: 2026-06-23
---

## Summary
Linear is a project-management platform that now runs an end-to-end ticket → code → review workflow in-app via its Agent (Claude Code + Codex). It is a structural threat: the nanopm → Linear handoff (`/pm-breakdown`) is inverting, with Linear becoming the orchestration surface calling into Claude Code where nanopm runs.

## What we know
**Latest change & strategic note**
Coding Sessions shipped 2026-06-11; Linear is becoming the orchestration surface that calls into the coding agent, inverting the nanopm handoff.
- "Coding Sessions in Linear (2026-06-11) — Linear Agent writes code via Claude Code and Codex inside the platform, consuming AI credits. Combined with Diffs (code review in-app), Code Intelligence (codebase access for agents), Shared Skills, and MCP support, Linear now runs the end-to-end workflow from ticket → code → review without leaving the platform. Pricing unchanged ($10/$16 Business)." — COMPETITORS.md

**Strengths**
- "Native in-app coding agent shipped 2026-06-11 (Claude Code + Codex inside Linear); first-class Agent platform across all tiers including Free; structured Agent Sessions API ...; 11 named third-party agent integrations live; native code review (Linear Diffs); Slack-native agent surface; MCP support; Code Intelligence ...; auto-generated release notes; 'shared skills' as a tracker primitive; SAML/SCIM on Enterprise; mature brand and install base." — COMPETITORS.md

**Weaknesses**
- "Core PM upstream work (vision, personas, discovery, OKRs, strategy, roadmap, PRD) absent from the surface; agent scoped to ticket-shaped objects; coding sessions metered ('AI credits required across all tiers'); key features gated to Business+; free tier capped at 2 teams / 250 issues." — COMPETITORS.md

**Gaps vs nanopm**
- "They have a native in-app coding agent, native code review, Slack-native execution, a published Agent Sessions API, CI/CD release tracking, and Teams + Slack surfaces — we don't. We have 21 PM skills spanning Define → Discover → Plan → Build, adversarial falsifiability gates, compounding typed-JSONL state, and we hand off TO Linear via `/pm-breakdown` — Linear doesn't hand off upstream from any PM-planning tool, the upstream artifacts simply don't exist in its model." — COMPETITORS.md
