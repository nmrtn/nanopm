---
type: doc
skill: pm-competitors-intel
provenance: user-stated
generated: 2026-06-25
sources: []
---

# Competitive Landscape
Last updated by /pm-competitors-intel on 2026-06-03
Project: nanopm

---

## mycelium

**Website:** https://github.com/haabe/mycelium
**Monitored pages:** README.md (2026-06-03), docs/changelog.md (2026-06-03), repo tree (2026-05-21)
**Latest notable change:** v0.23.30 → **v0.39.3** in 13 days (16 minor versions). README rewritten with sharp new tagline: *"AI has made building cheap. It hasn't made deciding cheap."* Three interaction modes formalized (mentor/guardrails/checklists). Explicit anti-positioning against "49 skills dumped simultaneously." SessionStart hook now scans sibling repos for canvas-ID activity (AP#8 cross-repo arm).
**Strategic note:** **The leader in the discovery-rigor lane.** Sharpest one-line positioning in the space, aimed at the same audience as nanopm. Mycelium is project-local (no global memory) and Claude Code only; nanopm's differentiation is multi-host + symmetric handoffs to 5 delivery targets. nanopm should either match the headline sharpness or commit to a different axis.

---

## gstack

**Website:** https://github.com/garrytan/gstack
**Monitored pages:** CHANGELOG.md (2026-06-03), README.md (2026-06-03)
**Latest notable change:** v1.42.2.0 → **v1.55.1.0** in 12 days (13 minor versions, ~1/day cadence). Tagline shifted from "Engineering Team" to "Software Factory". Now ships transparent telemetry by default — opt-in screen states exactly what's collected and pins it with regression tests. Slug helper now sanitizes output via `[a-zA-Z0-9._-]`. Platform list expanded: Codex, OpenCode, Cursor, Factory Droid, Slate, Kiro, Hermes, GBrain. Windows 11 (WSL/Git Bash) now explicit.
**Strategic note:** Engineering layer; complement to nanopm. Note the explicit divergence on telemetry: nanopm dropped it as pre-PMF over-engineering (v0.6.0), gstack shipped it with explicit consent + test-pinned guarantees (v1.55). Both defensible.

---

## prawduct

**Website:** https://github.com/brookstalley/prawduct
**Monitored pages:** README.md (2026-06-03), repo tree (2026-05-21)
**Latest notable change:** Plugin migration completed. Moved from file-sync distribution to plugin-based delivery — "zero committed framework files." Skills now under `/prawduct:*` namespace (critic, doctor, migrate, building, learnings). New `/prawduct:migrate` skill handles v1→v2 transitions. Learning system formalized: two-tier (concise rules vs detailed context), lifecycle explicit (provisional → confirmed → incorporated). Four governance enforcement levels documented.
**Strategic note:** Same convergent move as mycelium and gstack toward plugin-based brownfield-safe install. The two-tier learning system (concise rules + detailed context) is the structure nanopm has been adding informally — worth studying their formalization.

---

## deanpeters/Product-Manager-Skills

**Website:** https://github.com/deanpeters/Product-Manager-Skills
**Monitored pages:** README.md (2026-06-03), PLANS.md (2026-05-21), repo tree (2026-05-21)
**Latest notable change:** None since the May 21 sweep. Still v0.79, 49 skills, latest release 2026-05-15. The only one of four monitored projects that hasn't shipped in 13 days.
**Strategic note:** Now the slowest-moving of the four direct/adjacent competitors. Mycelium's explicit anti-positioning ("49 skills dumped simultaneously") is aimed here. Risk: deanpeters' skill catalog could be reframed by competitors as "broad but undisciplined" while mycelium/prawduct/nanopm tighten around discipline narratives.

---

*Run /pm-competitors-intel to refresh.*
