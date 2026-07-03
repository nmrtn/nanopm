---
type: overview
section: plan
generated: 2026-07-03
sources: [objectives.md, strategy.md, roadmap.md, opportunities/INDEX.md]
---

# Plan Brief
Generated 2026-07-03 · Project: nanopm · Sources: objectives.md, strategy.md, roadmap.md, opportunities/INDEX.md

## What we're betting on
The primary blocker to nanopm's adoption is the **form factor** — working only inside a terminal, inside a repo, with artifacts buried in a local `.nanopm/` folder — **not the value** of the planning it produces. A visibility/orchestration layer above the agent (see runs, artifacts, connected sources, a timeline; be guided on what to run when) will unlock adoption beyond terminal-native power users. Q3 2026 is the proof quarter for that one belief, run in `solo-fast` mode where the build *is* the experiment: ship the smallest real prototype and gate it with a terminal-comfortable control that separates "form factor blocks" from "value blocks." If the control fails, the response is to fix the value, not build more app.
_More detail: `.nanopm/wiki/docs/strategy.md`_

## What we're aiming for
Period: 2026-06-15 → 2026-09-30.
- **Obj1 — Run the proof quarter to a clean cross-matrix read.** KR1: 10 terminal-comfortable control founders recruited + first full run (target 2026-08-15). KR2: 10 non-terminal-native prototype-cohort founders recruited + first run via the viewer (2026-08-15). KR3: cross-matrix read on voluntary 2nd full runs within 21 days — control PASS ≥ 3/10, prototype PASS ≥ 40% — by 2026-09-15. KR4: post-read decision {continue / fix value / pivot / kill} committed to `.nanopm/STRATEGY-DECISION-Q3-2026.md` by 2026-09-30.
- **Obj2 — An honest top-of-funnel proxy.** KR1: GitHub stars 27 → 75 by 2026-09-30 (explicitly secondary). KR2: ≥3 non-friend repeated-engagement signals (PRs merged, issues filed and discussed, active forks) by 2026-09-30.
- Baseline: recruitment stood at **0** in both arms as of the 2026-06-15 objectives run; no later regen has recorded a change.
_More detail: `.nanopm/wiki/docs/objectives.md`_

## What we're building now
**NOW (through ~2026-08-15) — memory-wiki fan-out + hardening, the founder-chosen lead this cycle.** The prior NOW bet (Discovery Opportunity DB v0) and the memory-wiki engine shipped this period and are out of NOW.
1. Validate the personas ingest pilot — go/no-go gate that gates item 2 — by 2026-07-08.
2. Entity-skill fan-out → people + features (≥3 + ≥3 pages, each ≥2 sources) — by 2026-08-05.
3. Brief coherence lint (non-blocking) — by 2026-07-22.
4. Debounce brief regen (each brief once per `/pm-run`) — by 2026-07-15.
5. Bound the wiki index by construction — by 2026-07-29.
6. Remove dead `nanopm_company_context()` (pending Nico's OK) — by 2026-07-15.
Capacity: ~3.75 eng-weeks vs ~4 effective → **no buffer for recruitment this cycle**.
**NEXT (→ 2026-09-30):** prototype cohort recruitment (Discovery DB pitch), terminal-comfortable control cohort, retention readback (`nanopm whoami`), Data Monitoring v0. **LATER** includes multi-writer git machinery for the wiki (gated on real concurrent-ingest contention). ⚠ **Recruitment is deferred a third time — OBJ1 KR1/KR2 are at material risk.**
_More detail: `.nanopm/wiki/docs/roadmap.md`_

## Top open opportunities
- **[No single mechanism prioritizes across ALL work types into one next-best-action list](../entities/opportunities/no-single-mechanism-prioritizes-across-all-work-ty.md)** · high · user-stated · 2026-07-03 — freshest signal, and the connective layer the next two items below both feed: nothing today ranks opportunities, solutions, bugs, small improvements, and raw feedback as one pool competing for the same next slot.
- **[The PM has to remember to invoke each step; the loop doesn't run itself](../entities/opportunities/loop-runs-itself-on-a-cycle.md)** · high · user-stated · 2026-07-03 — the solo builder wants a closed, self-driving Phase 1→4 loop instead of manually invoking each skill; no roadmap item currently scopes this.
- **[Builders can't repeatably tell which user problem is highest-leverage](../entities/opportunities/prioritize-opportunities-by-strategic-impact.md)** · high · user-stated · 2026-07-02 — a list of problems exists but there's no repeatable, strategy-tied way to rank which is worth building against next.
- **[The roadmap doesn't orchestrate opportunities, solutions, and objectives into a living, prioritized plan](../entities/opportunities/roadmap-doesnt-orchestrate-into-living-plan.md)** · high · user-stated · 2026-06-30 — capture→process bricks exist but nothing turns them into a standing prioritized queue.
- **[Opportunities and plans go stale with no freshness signal](../entities/opportunities/opportunities-and-plans-go-stale-with-no-freshness.md)** · high · evidence-backed · 2026-06-30 — nanopm waits to be asked rather than proactively flagging staleness.

*(Two medium-priority opportunities directly follow from the in-flight Supabase cloud-sync branch (`feat/supabase-cloud-sync`) but are excluded from the top slots above high-priority items: [team-cant-collaborate-on-shared-nanopm-state](../entities/opportunities/team-cant-collaborate-on-shared-nanopm-state.md) (2026-07-02) and its more specific follow-on [concurrent-edits-to-the-same-nanopm-files-cause-sy](../entities/opportunities/concurrent-edits-to-the-same-nanopm-files-cause-sy.md) (2026-07-03, no conflict-resolution process once two teammates sync the same files). Also excluded: "no scheduling primitive" (2026-07-03, medium — the same self-driving-loop gap captured above as the #2 item, mechanism-level not problem-level); "pipeline only fits EPIC-scale work, not micro-tasks" (2026-07-03, medium, a Build-handoff gap); and the flat-wiki-index gap (NOW item 5 already scopes it).)*
_More detail: `.nanopm/wiki/entities/opportunities/INDEX.md`_

## What we're saying no to
Monetization/pricing until a proof arm reads PASS · a 22nd/23rd skill · viewer polish beyond what a NOW/NEXT item needs · a 16th connector / new ingestion source · promoting Designer-founder Dani to primary persona before the cross-matrix reads · telemetry on our own clones · rebuilding a tracker (Linear/GitHub Issues) · hosting the user's code · building the full macOS app before the prototype reads positive · Symphony-only positioning.

## Not yet planned
All three Plan docs exist (objectives.md, strategy.md, roadmap.md), and the opportunity DB exists. `STRATEGY-DECISION-Q3-2026.md` (Obj1 KR4) still does not exist — it's due after the cross-matrix read completes, which has not happened.
