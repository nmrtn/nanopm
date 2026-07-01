---
type: overview
section: plan
generated: 2026-06-26
sources: [wiki/docs/objectives.md, wiki/docs/strategy.md, wiki/docs/roadmap.md, wiki/entities/opportunities/INDEX.md]
---

# Plan Brief
Generated 2026-06-26 · Project: nanopm · Sources: objectives, strategy, roadmap, opportunities/INDEX

## What we're betting on
Get ≥3 external users to complete a full nanopm pipeline and return for a second session — unprompted — within 60 days of the plugin going live. If the habit loop is observed in the wild, the context-compounding thesis is confirmed and every downstream automation investment (autonomous loop, continuous discovery) is unlocked. If no external user returns unprompted, the strategy forks: either demand is wrong or the habit loop isn't legible enough, and both require a fundamentally different direction. The Claude Code plugin marketplace is the assumed zero-friction distribution entry; passive-only discovery gets 14 days before active Discord seeding is triggered as the fallback.
_More detail: `.nanopm/wiki/docs/strategy.md`_

## What we're aiming for
Period: Q3 2026 (Jul–Sep)

- **Obj 1 — Prove the loop works for strangers (July):** 5 distinct external installs with ≥3 skill runs; ≥2 return unprompted within 14 days; location-assumption poll live with ≥20 responses. KR3 (the poll) was the #1 NOW item since March 2026 and was still unexecuted as of 2026-06-26 — must ship in July.
- **Obj 2 — Use Symphony as the distribution lever (August, gated on Obj 1 KR1):** pm-breakdown → Symphony handoff working end-to-end; ≥3 Symphony users through the full pipeline; awareness post reaches ≥150 views or ≥10 upvotes.
- **Obj 3 — Make "context compounds" real (September, gated on Obj 1 KR2):** cold-start eliminated (nanopm_preamble returns a loaded brief at session 2+); ≥2 Obj 1 users run a second full pipeline in a new month; staleness detection ships (≥1 Define doc flags when >30 days old).

_More detail: `.nanopm/wiki/docs/objectives.md`_

## What we're building now
**NOW (one item only):** Validation experiment — get at least 3 of the first 10 external solo founders running `/pm-run` to invoke a second skill that reads from `~/.nanopm/projects/{slug}/decision.jsonl` within 14 days (~3 eng-days, 14 elapsed days). Sub-tasks: wire return-ping logging (`memory-read` event to `timeline.jsonl`); post the location poll across 4 channels (Claude Code Discord, r/ClaudeAI, Show HN, Vibe community); follow up with first 10 completers at +24h/+72h/+7d/+14d; daily automated check on `decision.jsonl` reads across non-`nanopm` slugs. Tied to Obj 1 KR1–KR3.

**NEXT (conditional on NOW passing):** Convert validated users into a sustained install rate (3/week for 4 weeks) via marketplace + Discord/HN; wire `/pm-retro` to read `decision.jsonl` and close the planning loop. If NOW fails: decide library-mode pivot vs. park within 7 days of result.
_More detail: `.nanopm/wiki/docs/roadmap.md`_

## Top open opportunities
Freshest signal (opportunity DB, 2026-06-18) — high-priority user problems not yet a roadmap line item:

1. **Cold-start context** (high) — every session re-explains who the company is instead of building on a current baseline; the core compounding promise is unproven end-to-end.
2. **Stale context docs** (high) — foundational docs (vision, product, personas) drift as the code and market move, but re-maintaining them is a chore that keeps being skipped.
3. **Loop runs itself on a cycle** (high, user-stated) — the solo builder must invoke each PM step manually; no self-driving autoresearch→autobuild cycle exists yet.
4. **Discovery runs only when I remember** (high, user-stated) — signal slips through when discovery is fully on-demand; no continuous monitoring.
5. **Feed learning back into context and discovery** (high) — what a builder learns from a shipped build never re-enters context, discovery, or the opportunity DB, so the next cycle repeats the same mistakes.

_More detail: `.nanopm/wiki/entities/opportunities/INDEX.md`_

## What we're saying no to
- No 18th+ skill — cap holds at 17 until ≥3 external users complete a full pipeline AND request the same missing skill by name.
- No team features or web UI — nobody has asked; CLI is the differentiation.
- No distribution infrastructure (install counters, funnel automation, marketplace listings) until validation passes — the most important "no."
- No autonomous PM loop — until ≥2 external users return for session 2 unprompted, automating session 3+ is optimization without a baseline.
- No new handoff targets beyond the current 6 — bottleneck is distribution, not handoff breadth.
- No monetization — revisit at ≥10 returning external users.
- No polished marketing README — revisit only if an external user reports it is unreadable.
- No passive-only distribution beyond 14 days — zero organic installs at day 14 triggers immediate Discord seeding.

## Not yet planned
All three Plan docs exist (objectives, strategy, roadmap). The roadmap was last generated 2026-06-03 against the prior strategy; objectives and strategy were both regenerated 2026-06-26 and supersede it. A roadmap refresh (`/pm-roadmap`) is recommended to align NOW/NEXT items with the Q3 2026 framing — the Symphony integration and the Obj 1 → Obj 2 → Obj 3 sequence are not yet reflected in the current roadmap.
