---
id: pm-skills-2
type: competitor
title: "PM Skills 2.0 (productcompass)"
status: active
provenance: evidence-backed
sources: [COMPETITORS.md]
relates_to: []
last_updated: 2026-06-23
---

## Summary
PM Skills 2.0 (productcompass / phuryn) is the most direct head-to-head on the "PM skill pack for AI coding agents" wedge — same intent, ~3× the surface area (9 plugins / 68 skills / 42 commands), 7 hosts, and marketplace-native install. It has no explicit Define phase and no typed/schema-validated state; its `/red-team-prd` is a callable command rather than a refusal mechanism.

## What we know
**Latest change & strategic note**
The most direct head-to-head on the same wedge; the differentiators nanopm must defend are pipeline-compounding typed JSONL state, a hard refusal-based gate, and the Define-phase artifacts.
- "9 plugins / 68 skills / 42 commands across discovery → strategy → execution → shipping; supports Claude Code, Claude Cowork, Codex CLI, Cursor, Gemini CLI, OpenCode, Kiro (7 hosts); marketplace-native install (claude plugin install, GitHub marketplace); MIT; includes shipped-code quality skills (/security-audit-static, /performance-audit-static, /derive-tests)." — COMPETITORS.md

**Strengths**
- "Broader raw surface area (9 plugins, 68 skills, 42 commands — ~3× nanopm's 21); wider host coverage (7 ... vs nanopm's 3); marketplace-native install ...; shipped-code quality skills (/security-audit-static, /performance-audit-static, /derive-tests, /ship-check); a dedicated intended-vs-implemented skill closing the spec-vs-shipped loop; 'red-team' framing more legible to PMs than 'falsifiable bet'; MIT." — COMPETITORS.md

**Weaknesses**
- "No explicit Define phase artifacts in the snapshot ...; no typed-state / schema-validated JSONL — skills look like prompts, not a compounding state machine; no connector ecosystem advertised ...; no GUI / viewer; skills appear independent plugin-style rather than pipeline-compounding; /red-team-prd is a callable command, not a refusal mechanism; no user-research ingestion path; same pre-PMF profile (free MIT OSS, unknown traction)." — COMPETITORS.md

**Gaps vs nanopm**
- "They have marketplace-native install across 7 hosts, shipped-code quality and test-derivation skills, and ~3× the raw skill count — we don't. We have a Define phase, typed JSONL state with schema validators driving compounding, 16 connector specs with MCP → API → browser → manual fallback, a hard adversarial gate refusing strategy/roadmap/PRD without segment+behavior+metric+timeframe, a dedicated quantitative-data skill (/pm-data on PostHog/Amplitude), user-research ingestion (/pm-interview, /pm-user-feedback), a SwiftUI macOS viewer, and a daily-ops cadence (/pm-standup, /pm-weekly-update) outside the pipeline — they don't." — COMPETITORS.md
