---
id: pm-run-as-sanctioned-front-door
type: solution
title: "/pm-run as sanctioned front door — resumable, guided, Y-default"
opportunity: pipeline-sequence-opaque
status: proposed
lens: eng, design, business
appetite: small-bet
impact: high
provenance: assumed
linked_objectives: []
last_updated: 2026-07-01
---

## Pitch
Rework `/pm-run` to be resumable and opinionated: check `.nanopm/` for existing artifacts, skip completed phases, and before each skill print one line — "Last: `<X>`. Next: `/pm-<Y>` — delivers `<Z>`. Continue? [Y/n]." Slash-command menu becomes the escape hatch, not the front door; README leads with `/pm-run`, skills relegated to an appendix. First ten seconds for a fresh user: type `/pm-run`, press Enter, see one sentence, press Y. The state-aware recommendation logic stays *inside* `/pm-run` — no 22nd skill.

## Riskiest assumption
Terminal-native Theo will trust a single opinionated next-step prompt over cherry-picking — "type one command and trust I'm on the right path" beats his instinct to browse the menu.

## Cheapest test
Ship the `/pm-run` rewrite + README lead-swap to the next 5 control-cohort recruits. If ≥4/5 stay on the rail (complete the first full pipeline via `/pm-run` rather than bouncing to individual skills), ship it.

## Dissent/tension note
Eng: concentrates all pipeline risk in one command — if `/pm-run` breaks or feels railroaded, users bounce entirely instead of picking a working sub-skill. Design: Y-default is paternalistic to a terminal-native who values raw command surface; wrong even 20% of the time and he loses trust in the guide. Business: subtracting individual-skill discoverability may tank the "look how much this does" GitHub-star surface that Obj2 KR depends on.
