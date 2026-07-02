---
id: pipeline-sequence-opaque
title: "A user doesn't know which skill to run when, why the phases come in that order, or what value a given skill delivers"
theme: Onboarding & guidance
status: ready-for-solutions
priority: medium
provenance: user-stated
evidence_sources: [user-verbatim]
linked_objectives: []
related_to: [first-run-value-unprovable]
last_updated: 2026-07-01
---

## 1. Problem summary
nanopm ships ~21 skills across four phases with a deliberate sequence (Define → Discover → Plan → Build), but that ordering lives in the README and CLAUDE.md, not in the run experience itself. A new user facing a long slash-command menu has no in-flow way to know which skill is the right next one or why the order matters — paralysis at the menu, or running skills out of order so the compounding state layer has thin inputs and silently degrades. The founder self-interview added a sharper, per-skill version of the same gap: even for a user who knows the sequence, an individual skill's *value* can read as opaque — he couldn't find the value of `/pm-challenge-me` or how to use it, despite the persona/strategy docs leaning on it heavily.

## 2. Value to the user
### Job to be done
Theo wants to be told what to do next without studying the system first — type one command and trust he's on the right path — and, for any given skill, to understand *why he'd run it and what he gets back*. His alternative today is to read documentation up front (which a terminal-native solo founder skips) or to guess.

### Where we fall short
**The sequence is documented, not guided in-flow**
PRODUCT.md describes the four-phase pipeline and notes downstream skills "warn rather than fail when Define docs are thin" — so running out of order produces quietly weaker output. Skills emit a "Recommended Next Skill" at the *end* of a run, but there is no equivalent guidance at the *entry* point for someone who hasn't run anything yet. Corroborated by the second founder, who loses the thread across the ~23 interdependent skills:
- "Moi je suis un peu perdu... les vingt-trois, je ne sais plus lesquels sont interdépendants, lesquels il faut faire avant lesquels... le produit paraît complexe et complet alors qu'il devrait être simple, comme une séquence. Je ne sais plus vraiment par où commencer." — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)

**More surface area without more guidance**
- CONTEXT-SUMMARY.md / PRODUCT.md flag that v0.10.0 added a fourth phase + four Define skills before the loop was measured on one external user — "yet another step that delays the first end-to-end run." More skills without proportionally stronger onboarding raises the odds a new user can't find the right start. Inferred, no observed user — nano-hypothesis.

**A skill's own value can be opaque even to an experienced user**
challenge-me is a skill the persona/strategy docs lean on, yet the actual user can't locate its value or figure out how/when to run it. The "why/when do I run this" is not legible per-skill, not just per-sequence.
- "pm challenge me, je ne sais pas, pour l'instant je n'ai pas trouvé vraiment la valeur dans cette skill, je ne sais pas comment faire." — self-interview, 2026-06-29 (Granola dc61e5c2)

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: an entry-point next-skill recommender; a one-line "what you get / when to run this" on each skill; a worked example or sample output for value-opaque skills like challenge-me. -->

## Solutions
_Brainstormed via `/pm-solutions` on 2026-07-01 — full comparison in `.nanopm/wiki/entities/solutions/INDEX.md`. Shortlisted: A + B + D (founder pick, 2026-07-01)._
- **[Cull the roster before adding guidance](../solutions/cull-the-roster-before-adding-guidance.md)** · eng, business · small-bet · high · **shortlisted**
- **[Entry-banner in every skill preamble](../solutions/entry-banner-in-every-skill-preamble.md)** · eng, design, business · small-bet · high · **shortlisted**
- **[README phase-first reframe + HOW-TO-USE.md](../solutions/readme-phase-first-reframe-plus-how-to-use-guide.md)** · business · small-bet · medium · **shortlisted**
- **[/pm-run as sanctioned front door](../solutions/pm-run-as-sanctioned-front-door.md)** · eng, design, business · small-bet · high · proposed
- **[ASCII trail-map in every preamble](../solutions/ascii-trail-map-in-every-preamble.md)** · design · small-bet · medium · proposed
- **[skills.yaml manifest as single source of truth](../solutions/skills-yaml-manifest-as-single-source-of-truth.md)** · eng · big-bet · medium · proposed

## Open / superseded
**Provenance upgraded nano-hypothesis → user-stated (2026-06-29)** and scope widened from sequence-only to include per-skill value opacity, on the founder self-interview's challenge-me signal. — self-interview, 2026-06-29 (Granola dc61e5c2)
**Corroborated by second founder (2026-06-30)** — Nico independently named the same "where do I start / which skills depend on which" confusion on the strategy call; stays user-stated (internal founder signal, not external user demand). — Granola call w/ Nico, 2026-06-30 (raw/interviews/2972bcf0bb4c.md)
