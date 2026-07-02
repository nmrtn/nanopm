---
id: users-can-t-easily-install-the-viewer-and-launch-i
title: "Users can't easily install the viewer and launch it"
theme: Adoption & form factor
status: ready-for-solutions
priority: high
provenance: user-stated
evidence_sources: []
linked_objectives: []
related_to: [cant-run-without-terminal]
last_updated: 2026-06-29
---

## 1. Problem summary
A user who wants to try the NanoPM Viewer GUI can't easily install it and get it running. The viewer ships as a SwiftUI prototype inside the nanopm repo (`viewer/`) — there's no packaged macOS app, no signed `.dmg`, no one-click install; the path is "clone the repo, open in Xcode (or `swift run`), wait for it to build." Even users who clear that bar then hit a second step (the viewer needs nanopm itself installed in the same project, the CLI's state in `.nanopm/` and `~/.nanopm/`, the right host skill pack) before anything useful renders. The non-terminal segment the viewer is supposed to serve bounces somewhere in those steps.

## 2. Value to the user
### Job to be done
The user wants to *see and steer* their nanopm planning artifacts in a GUI — the bet, the OKRs, the roadmap, the opportunities — without dropping into a terminal each time. The alternative today is to either give up and keep reading raw markdown in their editor, or to push through an install path that assumes Xcode comfort and shell familiarity (which is exactly what the viewer is meant to spare them from). There is no "download the app, open it, point it at a project" flow.

### Where we fall short
**No packaged distribution**
The viewer is delivered as source in `viewer/Sources/NanoPMViewer/` — no `.dmg`, no `.app` bundle, no Homebrew cask, no release artifact. A user has to clone the repo and build it.
- User-stated: "Users can't easily install the viewer and launch it" — 2026-06-18

**Launch flow assumes terminal + project state**
Even once built, the viewer expects a project to point at, with the nanopm CLI already installed and `.nanopm/` already populated. Empty-state for a fresh user is not handled like a normal app first-run.
- Inferred from PRODUCT.md and the viewer's reliance on `.nanopm/` artifacts produced by `nanopm_preamble`.

## 3. Value to the company
This is the load-bearing test of the form-factor bet: the viewer is the answer to "PM discipline without becoming a terminal person," but it currently re-imposes the very barrier it was supposed to remove. If install + launch isn't truly one-click, the viewer can't recruit the non-terminal prototype cohort the Q3 plan needs. Adjacent to `cant-run-without-terminal` (which calls out the broader CLI-install funnel and the viewer not being a public door) — this opportunity scopes the friction *inside* the viewer's own first-run path, once the door exists. Guardrail: a frictionless install must still keep the viewer tethered to a real project, not become a standalone PM SaaS for the anti-persona.

## 5. Solution hypotheses
Pointer only — stay in problem space. (Candidate directions: signed `.dmg` release, Homebrew cask, in-app first-run that installs the nanopm CLI for the user, a project-picker empty-state that explains what's missing.)

## Solutions
_Brainstormed via `/pm-solutions` on 2026-06-29 — full comparison in `.nanopm/wiki/entities/solutions/INDEX.md`._
- **[Cohort-only signed .dmg + empty-state installer (1:1 distribution)](../solutions/cohort-only-signed-dmg-with-empty-state-installer.md)** · eng+design+business · small-bet · high · proposed
- **[Self-contained .app with the nanopm CLI bundled inside](../solutions/self-contained-app-with-bundled-cli.md)** · eng · big-bet · high · proposed
- **[Concierge install — the install is a 45-min Zoom call, not a .dmg](../solutions/concierge-install-as-the-product.md)** · business · small-bet · high · proposed
- **[Viewer as a host-plugin /viewer command — no separate app](../solutions/viewer-as-host-plugin-slash-command.md)** · design · small-bet · high · proposed
- **[Demo project on first launch — earn the install by showing value first](../solutions/demo-project-first-launch-earn-the-install.md)** · design+business · small-bet · medium · proposed
- **[Recruitment-first Typeform gate — no installer build this cycle](../solutions/recruitment-first-typeform-gate.md)** · business · small-bet · medium · proposed
