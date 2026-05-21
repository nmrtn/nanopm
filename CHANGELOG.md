# Changelog

## 0.5.1 — 2026-05-21

### Multi-host support (Mistral Vibe + OpenAI Codex)
- **`setup --host` flag** — install to a specific agent: `--host=claude`, `--host=vibe`, `--host=codex`, `--host=all`. Default (`auto`) detects installed agents and installs to all of them.
- **Mistral Vibe translation** — setup rewrites `allowed-tools` from Claude's PascalCase comma-separated format to Vibe's snake_case space-separated format. Tool mapping: `Bash→bash`, `Read→read_file`, `Write→write_file`, `Edit→search_replace`, `Grep→grep`, `AskUserQuestion→ask_user_question`, `Agent→task`, `WebFetch→webfetch`. Glob is dropped (no Vibe equivalent; bash accomplishes the same).
- **OpenAI Codex translation** — setup strips `allowed-tools` from the frontmatter entirely (Codex rejects unknown frontmatter keys). Skill body runs as-is; Codex handles AskUserQuestion blocks conversationally.
- **Host detection in `lib/nanopm.sh`** — `$NANOPM_HOST` is exported at source time (`claude` / `vibe` / `codex`), detected via environment variables set by each agent.
- **README updated** — install section now shows all four host variants with a host → install path → invocation table.
- **CLAUDE.md updated** — development setup section covers all `--host` options.

## 0.5.0 — 2026-05-21

### OpenSpec integration
- **`/pm-breakdown` writes OpenSpec change folders** — choose "OpenSpec" as a write target to produce `openspec/changes/<feature>/` with `proposal.md`, `design.md`, `tasks.md`, and `specs/` in OpenSpec format. Run `/opsx:apply` to implement directly.
- **`/pm-scan` reads OpenSpec specs** — if `openspec/specs/` exists, scans specs before synthesis and surfaces spec/test gaps in SCAN.md
- **Community schema** — `openspec-schema/` is a valid OpenSpec schema that nanopm users can copy into their project. Listed in the OpenSpec community catalog.
- **README "Works with OpenSpec" section** — explains the two-layer model (nanopm = PM layer, OpenSpec = engineering layer)

### Bug fixes (16 issues from alignment review)
- `pm-retro`: fixed missing closing fence and merged section headers
- `pm-audit`: now explicitly reads SCAN.md to use pm-scan pre-fills for Q1–Q4
- `pm-run`: fixed PRD path in summary (`.nanopm/prds/` not `.nanopm/PRD-`)
- `pm-prd`: fixed `context_append` next value (`implement` → `pm-breakdown`)
- `pm-competitors-intel`: fixed unclosed string in Completion section
- `pm-user-feedback`: removed dead `/tmp/nanopm-feedback-cluster.txt` path
- `pm-upgrade`: removed misleading local CHANGELOG.md path reference
- `setup`: removed dead community telemetry tier (removed in v0.4.3 but code remained)
- `README`: fixed install path, pipeline description, mermaid diagram, connector list
- `CLAUDE.md`: fixed install path, removed non-existent `--local` flag
- `llms.txt`: added `pm-upgrade`, fixed pipeline description
- `connectors/README.md`: added Productboard row
- `connectors/dovetail.md`: fixed Q6 description

## 0.4.3 — 2026-04-07

### Simplification
- **Removed community tier** — telemetry now has only two tiers: `off` and `anonymous`
- **No installation tracking** — removed `installation_id` from all code, schema, and documentation
- Simpler setup experience with clearer privacy guarantees

## 0.4.2 — 2026-04-07

### Bug fixes
- **Telemetry sync now works** — setup installs `supabase/config.sh` so sync can find Supabase URL
- **Edge function accepts JSONL format** — fixed field name validation (`session_id` vs `session`)
- Events now successfully sync to Supabase cloud

## 0.4.1 — 2026-04-07

### Bug fix
- **All skills now log telemetry** — added telemetry footers to all 13 skills (0.4.0 only had pm-audit)
- Events now properly sync to Supabase when skills complete

## 0.4.0 — 2026-04-07

### Anonymous telemetry system
- **Three-tier telemetry** (off/anonymous/community) — understand which skills are most useful across all installations
- **Local analytics always available** — `~/.nanopm/bin/nanopm-analytics` shows your usage stats (7d/30d/all time windows)
- **Batched remote sync** — events sync to Supabase in background (rate-limited, non-blocking, silently fails if offline)
- **Crash recovery** — pending markers ensure events are logged even if skill crashes
- **Transparent disclosure** — setup prompts for tier choice, README documents what's collected and NOT collected
- **Privacy-first** — no code, project names, or PII collected; only skill usage patterns (name, duration, outcome, OS, arch, version)
- **Public anon key** — safely distributed in repo (RLS prevents unauthorized access, all writes validated through edge function)

### Infrastructure
- **Supabase backend** — edge function validates and stores telemetry events; SQL migration creates table with proper indexes and RLS policies
- **Session tracking** — concurrent session count included in telemetry for aggregate stats
- **Installation ID** — community tier includes anonymous installation ID for unique user counts (opt-in)

### Setup improvements
- Interactive telemetry tier selection during install (default: anonymous)
- Clear explanation of what's collected vs. NOT collected
- Easy opt-out instructions shown during setup

## 0.3.1 — 2026-04-01

### New skill
- **`/pm-scan`** — scan an existing codebase to reverse-engineer what it actually does; reads routes, data models, tests, git history, and README; produces `SCAN.md` with pre-filled answers for pm-audit Q1–Q4; run this before pm-audit when joining an existing project or after going heads-down for months

### Pipeline improvements
- **`/pm-run`** now asks a starting-point question when no prior context exists: existing project (runs pm-scan inline) vs. greenfield (runs pm-discovery inline) vs. skip to audit
- Pipeline diagram updated: pm-scan and pm-discovery shown as distinct entry points with labels ("existing codebase" vs. "greenfield")
- `setup`: pm-scan added to install loop and skill summary

### Competitor monitoring
- prawduct (`brookstalley/prawduct`) added to `competitors.json` — governance-layer tool with structural Critic agent that blocks code completion

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
