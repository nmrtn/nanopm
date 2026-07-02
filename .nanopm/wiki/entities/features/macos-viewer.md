---
id: macos-viewer
type: feature
title: "macOS viewer"
status: active
provenance: evidence-backed
sources: [PRODUCT.md]
relates_to: []
last_updated: 2026-06-23
---

## Summary
A SwiftUI macOS app that reads the same .nanopm artifacts and exposes them as a nav-and-detail GUI with in-app skill runs. It is the second product surface, built to test whether a GUI above the CLI unlocks adoption for a non-terminal-native audience. By its own framing it is an intentional throwaway prototype.

## What we know
**What it is**
A read-only GUI over the artifacts, with in-app runs.
- "a SwiftUI macOS viewer at `viewer/`, reads those same artifacts and exposes them as a nav-and-detail GUI with in-app skill runs" — PRODUCT.md
- "Read-only artifact rendering with designed views ... Headless run buttons for every skill ... Interactive runs: in-app questions, model transcript, session resume. Live activity monitor streaming parallel agent conversations" — PRODUCT.md

**Maturity and intent**
Prototype-grade, testing the GUI-adoption bet.
- "A GUI above the CLI unlocks adoption (v0.7+ pivot). The macOS viewer is the test: if form factor — not value — is the adoption blocker, a designed read-only surface should retain users the CLI doesn't." — PRODUCT.md
- "By the viewer's own framing (PRD + memory note: \"throwaway prototype\"), it is intentionally not production-grade." — PRODUCT.md
