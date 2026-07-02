---
id: cant-run-without-terminal
title: "Non-terminal founders can't get into nanopm at all — the door is a CLI install"
theme: Adoption & form factor
status: draft
priority: high
provenance: nano-hypothesis
evidence_sources: []
linked_objectives: []
last_updated: 2026-06-17
---

## 1. Problem summary
A solo founder or product person who ships with an AI coding agent but doesn't live in a terminal currently has no way in: onboarding starts with a `curl … | bash` install and proceeds by typing slash commands inside a repo. The very first step assumes shell comfort, a cloned repo, and an agent CLI already wired up — so the people who feel the PM-discipline gap most acutely (the non-terminal-native segment) bounce before they ever run a single skill. This is the access half of the form-factor bet: the form factor, not the value, is what gates the funnel at step zero.

## 2. Value to the user
### Job to be done
The user wants nanopm's planning discipline — falsifiable bets, compounding strategy, a system that says "no" — without first having to become a terminal person. Today their only alternative is to either push through a CLI install they're not comfortable with, or give up and stay on the ChatGPT → Notion → Linear stack that doesn't know their code and doesn't carry decisions across sessions. There is no on-ramp that meets a GUI-first builder where they are.

### Where we fall short
**Install is CLI-gated from the first keystroke**
The entry point is `curl … | bash`; `setup` auto-detects agent CLIs only; the first action is typing `/pm-run` in a repo. A non-terminal-native user has no graphical path to a first run.
- Inferred from STRATEGY.md (the Q3 bet that "the wall is the *form factor*, not the *value*") and PERSONAS.md (Designer-founder Dani; the macOS viewer "isn't public").

**The viewer — the intended GUI on-ramp — is not yet a public door**
The macOS viewer is the architectural answer but ships as a throwaway prototype that isn't publicly available, so the non-terminal segment has nothing to download.
- Inferred from PERSONAS.md and PLAN-SUMMARY.md (prototype-cohort recruitment via the viewer is NEXT, not yet shipped).

## 3. Value to the company
This is the load-bearing test of the Q3 proof quarter. If a graphical on-ramp doesn't unlock the non-terminal segment, the "PM layer goes beyond power users" thesis narrows back to CLI power users. Serves Objective 1 (the prototype-cohort arm). Guardrail: the on-ramp must add *access* to the existing value, never become PM SaaS for the anti-persona — solving "can't run it" must not drift into "runs without an agent."

## 5. Solution hypotheses
Pointer only — stay in problem space. (Candidate directions: GUI-first install/launch path; the public viewer as the door; a guided first-run that doesn't require typing slash commands.)
