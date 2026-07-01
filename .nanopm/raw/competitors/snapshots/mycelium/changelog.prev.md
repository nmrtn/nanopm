# mycelium — changelog snapshot
# Captured: 2026-06-03

## Latest: v0.39.3 (2026-06-02)
Title: "SessionStart CHECK 8: cross-repo activity surfacing (AP#8 cross-repo arm)"

## Mechanism shipped in v0.39.3
- SessionStart hook CHECK 8.
- If MYCELIUM_CROSS_REPO_WATCH env var is set (colon-separated list of sibling
  repo paths, PATH-style), the hook scans each repo's last 24h of commits for
  canvas-ID patterns: opp-XXX, sol-XXX, comp-XXX, ht-XXX, cyc-XXX, sce-XXX.
- Matches surface in SessionStart additionalContext block.
- Fail-open, NUDGE tier, opt-in.

## Class
- Patch (single observability check, no behavior gate, opt-in via env var)

## Attribution
- cross-repo-stale-state-arm-2026-06-02
- Anti-Pattern #8 (Stale State Read) — cross-repo manifestation
- User correction surfaced the gap (dogfood signal)

## Strategic context vs prior snapshot (v0.23.30, 2026-05-21)
- 16 minor versions shipped in 12 days (very high cadence, comparable to gstack)
- Theme: observability of dev context across repos. They are noticing the same
  problem nanopm solves at the PM layer — "what state is the agent operating on"
  — but at the sub-task observability tier.
- New "anti-pattern" naming convention (AP#1 through AP#8+) hints at a growing
  internal taxonomy of failure modes the framework catches structurally.
