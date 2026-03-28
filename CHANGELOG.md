# Changelog

## 0.3.0 — 2026-03-28

### New skill
- **`/pm-user-feedback`** — aggregate user feedback from Dovetail, Productboard, Notion, Linear, and GitHub; cluster into themes with severity and frequency; map to current roadmap; produce `FEEDBACK.md` as primary input for all downstream skills

### Pipeline reorganization
- `/pm-run` pipeline is now: `pm-user-feedback → pm-audit → pm-objectives → pm-strategy → pm-roadmap → pm-prd`
- `FEEDBACK.md` is a first-class artifact: every downstream skill checks for it, uses it to skip redundant questions, and grounds outputs in real user signal
- `pm-audit`: pre-fills Q6 from FEEDBACK.md top unaddressed signal; uses it in Phase 4 synthesis
- `pm-objectives`: surfaces top feedback themes as KR candidates
- `pm-strategy`: bet validated against top unaddressed signal before drafting
- `pm-roadmap`: NOW/NEXT items tagged `📣 signal-backed` when they address a top feedback theme
- `pm-prd`: checks FEEDBACK.md first for verbatim quotes (replaces direct Dovetail pull)

### New connector
- **`connectors/productboard.md`** — tier 2 (API via `PRODUCTBOARD_TOKEN`) and tier 3 (browser); fetches features by vote count + user notes

### Updates
- `/pm-run` summary now shows top user signal from FEEDBACK.md and links to `/pm-competitors-intel`

## 0.2.0 — 2026-03-28

### New skills
- **`/pm-upgrade`** — check for updates and upgrade nanopm in-place; supports auto-upgrade, snooze with escalating backoff, and changelog diff
- **`/pm-competitors-intel`** — monitor competitor changelogs, API docs, pricing, and product pages; snapshot + diff per run; produces `INTEL-{date}.md` and a persistent `COMPETITORS.md`

### Artifact quality improvements (all 5 core skills)
- Every artifact section now ends with an imperative **Action:** directive
- Context-aware question skipping: each skill derives answers from prior artifacts before asking
- `pm-strategy`: adversarial FALSIFICATION must include specific number + user segment + behavior + timeframe
- `pm-prd`: required "What will be different in commits after this ships?" row in Success Criteria; max 3 user stories; "Design notes" replaced with "The One UX Decision"; open questions table adds "Blocks" column
- `pm-objectives`: anti-goals require re-open conditions
- `pm-roadmap`: LATER items require re-open conditions; NOT-on-roadmap items require re-open conditions
- Fixed: `/pm-prd` completion text referenced non-existent `/pm-watch` — now points to `/pm-retro`

### Infrastructure
- `lib/nanopm.sh`: added `nanopm_update_check()` — 24h cached version check against GitHub, with snooze backoff
- `setup`: writes installed version to `~/.nanopm/VERSION` (required by update check)
- `test/quality-examples/`: added `INVENTORY.md` (diagnostic of generic output patterns) and before/after structure for regression testing

## 0.1.0 — 2026-03-25

Initial release.

- Full PM pipeline: `/pm-discovery`, `/pm-audit`, `/pm-objectives`, `/pm-strategy`, `/pm-roadmap`, `/pm-prd`, `/pm-breakdown`, `/pm-retro`, `/pm-run`
- Shared runtime: `lib/nanopm.sh` (config, context/memory, connectors, browser, staleness check)
- Connector tiers: MCP (tier 1), API key (tier 2), browser (tier 3), manual CONTEXT.md (tier 4)
- Test suite: `test/skill-syntax.sh` (tier 1), `test/adversarial.e2e.sh` and `test/context-threading.e2e.sh` (tier 2)
