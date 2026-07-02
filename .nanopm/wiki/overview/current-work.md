---
type: overview
section: plan
generated: 2026-06-24
sources: []
---

# Plan Brief
Generated 2026-06-24 · Project: nanopm · Sources: OBJECTIVES.md, STRATEGY.md, ROADMAP.md

## What we're betting on
The primary blocker to nanopm's adoption is the **form factor** — working only inside a terminal, inside a repo, with artifacts buried in a local `.nanopm/` folder — **not the value** of the planning it produces. A visibility/orchestration layer above the agent (see runs, artifacts, connected sources, a timeline; be guided on what to run when) will unlock adoption beyond terminal-native power users. Q3 2026 is the proof quarter for that one belief, run in `solo-fast` mode where the build *is* the experiment: ship the smallest real prototype and gate it with a terminal-comfortable control that separates "form factor blocks" from "value blocks." If the control fails, the response is to fix the value, not build more app.
_More detail: `.nanopm/STRATEGY.md`_

## What we're aiming for
Period: 2026-06-15 → 2026-09-30.
- **Obj1 — Run the proof quarter to a clean cross-matrix read.** KR1: 10 terminal-comfortable control founders recruited + first full run (target slipped to 2026-09-15). KR2: 10 non-terminal-native prototype-cohort founders recruited + first run via the viewer (2026-09-15). KR3: cross-matrix read on voluntary 2nd full runs within 21 days — control PASS ≥ 3/10, prototype PASS ≥ 40% — by 2026-09-15. KR4: post-read decision {continue / fix value / pivot / kill} committed by 2026-09-30.
- **Obj2 — An honest top-of-funnel proxy.** KR1: GitHub stars 27 → 75 by 2026-09-30 (explicitly secondary). KR2: ≥ 3 non-friend repeated-engagement signals.
- Baseline: recruitment still **0** in both arms _(assumed — per latest context, no cohort recruited yet)_.
_More detail: `.nanopm/OBJECTIVES.md`_

## What we're building now
**NOW (through ~2026-08-15) — memory-wiki fan-out + hardening, the founder-chosen lead this cycle.** Note: the prior NOW bet (Discovery Opportunity DB v0) and the memory-wiki engine **shipped** this period and are out of NOW.
1. Validate the personas ingest pilot — go/no-go gate that gates fan-out — by 2026-07-08.
2. Entity-skill fan-out → people + features (≥3 + ≥3 pages, each ≥2 sources) — by 2026-08-05.
3. Brief coherence lint (non-blocking) — by 2026-07-22.
4. Debounce brief regen (each brief once per `/pm-run`) — by 2026-07-15.
5. Bound the wiki index by construction — by 2026-07-29.
6. Remove dead `nanopm_company_context()` (needs Nico's OK) — by 2026-07-15.
Capacity: ~3.75 eng-weeks vs ~4 effective → **no buffer for recruitment this cycle**.
**NEXT (→ 2026-09-30):** prototype cohort recruitment (Discovery DB pitch), terminal-comfortable control cohort, retention readback (`nanopm whoami`), Data Monitoring v0. ⚠ **Recruitment is deferred a third time — OBJ1 KR1/KR2 are now at material risk.**
_More detail: `.nanopm/ROADMAP.md`_

## What we're saying no to
Monetization/pricing until a proof arm reads PASS · a 22nd/23rd skill · viewer polish beyond what a NOW/NEXT item needs · a 16th connector / new ingestion source · promoting Designer-founder Dani to primary persona before the cross-matrix reads · telemetry on our own clones · rebuilding a tracker (Linear/GitHub Issues) · hosting the user's code · building the full macOS app before the prototype reads positive · Symphony-only positioning.

## Not yet planned
All three Plan docs exist (OBJECTIVES, STRATEGY, ROADMAP). **FEEDBACK.md is absent** — no validated-demand signal currently feeds the plan, so NOW/NEXT items carry no `📣 signal-backed` tags. `STRATEGY-DECISION-Q3-2026.md` (Obj1 KR4) does not exist yet — it's due after the cross-matrix read completes.
