# prawduct — README snapshot
# Captured: 2026-06-03

## Tagline (refreshed)
"Prawduct is a product development framework for Claude Code that adds structured
planning, independent quality reviews, and continuous per-project learning to
AI-assisted software development."

## What changed since 2026-05-21

### Positioning shift
- Was: file-sync distribution model (had `tools/` CLI for init/migrate/sync)
- Now: plugin-based delivery. Emphasizes "zero committed framework files" and
  "clean product repos."
- Same convergent move as gstack and mycelium toward plugin-based install.

### Skills reorganized under /prawduct:* namespace
- /prawduct:critic
- /prawduct:doctor
- /prawduct:migrate (NEW — handles v1→v2 transitions)
- /prawduct:building (NEW)
- /prawduct:learnings

### Learning system formalized
- Two-tier structure: concise standing rules (learnings.md) separated from
  detailed context (learnings-detail.md).
- Lifecycle explicit: **provisional → confirmed → incorporated**.
- Accessed via /prawduct:learnings in forked context, surfacing only relevant knowledge.

### Governance enforcement (4 structural levels)
1. Session briefing with staleness detection
2. Critic review blocking (separate context, restricted tools)
3. Reflection gates
4. Compliance canary checks
- Critic tool restrictions prevent test execution — review happens against
  test evidence logs instead.

## Strategic context
- Prawduct has formalized the structure that nanopm has been adding: typed
  lifecycle (provisional → confirmed → incorporated), separate concise rules
  vs detailed context, namespaced skills.
- The plugin migration story (`/prawduct:migrate` skill for v1→v2) suggests
  this was a non-trivial breaking change — they invested in the upgrade path.
