# Changelog

## 0.6.1 — 2026-05-22

### Tests caught up with v0.6.0; partial typed-state migration

**Added — test coverage for v0.6.0:**
- `test/state-layer.sh` (25 checks): validates `bin/nanopm-state-log` and `bin/nanopm-state-read` end-to-end. Asserts valid records pass for each of the 4 types, invalid records (bad enum, missing required, oversized insight, bad key chars, out-of-range confidence) are rejected with non-zero exit and stderr message. Confirms `ts`/`slug` auto-injection. Validates the reader's `--latest`, `--filter KEY=VAL`, `--limit N` paths.
- `test/multi-host.sh` (14 checks): runs `lib/nanopm.sh` in isolated environments to verify `NANOPM_HOST` and `NANOPM_SKILLS_DIR` are set correctly under default (Claude), `VIBE_VERSION`, `CODEX_VERSION`, and `VIBE_SKILLS_DIR` override. Asserts `nanopm_skill_path` resolves to the right host and that `pm-run` has zero hardcoded `~/.claude/skills/` references left.
- `test/gates.sh` (29 checks): verifies the structural gate pattern is wired into `pm-audit` (`kind=question`), `pm-roadmap` (`kind=target`), `pm-prd` (`kind=bet` + `prd` record). Checks rubric output formats, falsifiability markers, `nanopm_state_log` calls, regression on `pm-strategy`'s 3-question rubric, and all 5 handoff targets in `pm-breakdown`.
- `test/run-all.sh`: single runner that executes all 6 local suites (excludes `adversarial.e2e.sh` which calls the live `claude` CLI; pass `--with-llm` to include it).

**Changed — `test/skill-syntax.sh`:**
- `_SKILLS` list now covers all 17 skills (was 13). The 4 daily-ops skills (`pm-interview`, `pm-standup`, `pm-weekly-update`, `pm-data`) were missing from the static checks.
- New v0.6.0 checks: gated skills call `nanopm_state_log`, no telemetry references leak through, state binaries are executable, `nanopm_skill_path()` is defined.
- 60 checks pass (was 44).

**Partial migration to typed state:**
- `/pm-strategy` Phase 8 now writes a typed `decision` of `kind=bet` (and one `kind=scope-out` per "What we're saying no to" item) before the legacy `nanopm_context_append`. Downstream skills can read the bet via `nanopm_state_read --type decision --filter kind=bet --latest` instead of grep on STRATEGY.md.
- Added `nanopm_skill_started` and `nanopm_skill_completed` helpers in `lib/nanopm.sh` for opt-in timeline events. Skills can adopt these one at a time without a forced sweep.

**Deferred (follow-up work):**
- Full typed-state migration of `pm-objectives` (per-KR `target` decisions), `pm-discovery` (early assumption `bet` decisions), `pm-user-feedback` (top unaddressed signal as `gap` decision), `pm-retro` (timeline events on shipped items).
- Live Vibe / Codex e2e — `test/multi-host.sh` validates the wiring without needing those CLIs installed. A real `claude` / `vibe` / `codex` invocation matrix is the next layer up; not in this release.

## 0.6.0 — 2026-05-22

### Sharpened scope: nanopm = the PM half, with symmetric handoffs

nanopm now explicitly owns the PM layer (audit → strategy → roadmap → PRD) and hands off cleanly to whatever delivers the work. Five peer handoff targets, no preferred default.

**Removed:**
- Entire telemetry stack (`bin/nanopm-telemetry-log`, `bin/nanopm-telemetry-sync`, `bin/nanopm-analytics`, `supabase/` directory with the edge function + migrations, and ~250 lines of per-skill `## Telemetry` boilerplate). Pre-PMF infrastructure that didn't earn its weight.
- `nanopm_telemetry_pending` from `lib/nanopm.sh`. Telemetry session/start variables stripped from `nanopm_preamble`. `~/.nanopm/sessions/` and `~/.nanopm/analytics/` no longer created or referenced.
- The "Analytics & Telemetry" section from `README.md`.
- Telemetry opt-in prompt from `setup`.
- On upgrade, `setup` proactively removes deprecated binaries and dirs (`bin/nanopm-telemetry-*`, `bin/nanopm-analytics`, `supabase/`, `analytics/`, `sessions/`).

**Added:**
- **Typed state layer** under `~/.nanopm/projects/{slug}/`. Schema-validated JSONL via two new binaries: `bin/nanopm-state-log` (write + validate) and `bin/nanopm-state-read` (latest-wins / filtered read). Mirrors gstack's append-only JSONL pattern, implemented in pure python3 (no new deps).
  - **Types:** `timeline` (skill events), `decision` (typed PM decisions: bet/antigoal/target/methodology/gap/question/scope-in/scope-out), `prd` (per-feature metadata + status), `handoff` (which target each artifact went to, when).
  - **Schema enforcement at write time:** required-field checks, enum allowlists, alphanumeric key validation, confidence range 1–10, length caps. Bad JSON is rejected with a clear stderr message and non-zero exit — no silent appends.
  - Shell convenience wrappers: `nanopm_state_log` and `nanopm_state_read` in `lib/nanopm.sh`.
- **`nanopm_skill_path` helper** in `lib/nanopm.sh`. Resolves a sibling skill's `SKILL.md` to the active host (`~/.claude/skills/`, `~/.vibe/skills/`, or `~/.codex/skills/`). Replaces every hardcoded `~/.claude/skills/...` reference in `pm-run` — the pipeline inline-orchestration now works on Vibe and Codex, not just Claude.
- **`NANOPM_SKILLS_DIR`** environment variable exported by host detection. Vibe/Codex installs can override via `VIBE_SKILLS_DIR` / `CODEX_SKILLS_DIR`.

**Changed:**
- **`/pm-breakdown` is now symmetric across five peer handoff targets**: Linear, GitHub Issues, OpenSpec, gstack, Human-readable markdown. Phase 3 asks once which target to use — no preferred recommendation, no "additional output" framing.
  - **New gstack target:** writes `~/.gstack/projects/{slug}/ceo-plans/{YYYY-MM-DD}-{feature}.md` with `status: ACTIVE` frontmatter matching what gstack's `/plan-ceo-review` reads from its `gbrain.context_queries` glob. Output includes a Vision section, NOT-in-scope, full task list, acceptance, open questions.
  - **New Human target:** writes `.nanopm/handoffs/{feature}.md` — a single self-contained markdown with the PRD body plus copy-paste-ready ticket blocks. Pastes anywhere (Notion, Jira, Slack, email).
  - Every successful handoff logs to `~/.nanopm/projects/{slug}/handoff.jsonl` via validated state write, and updates `prd.jsonl` status to `handed-off`.
- **README "Works with OpenSpec" section replaced with "Handoffs"** — five peers, one paragraph each, no preferred default. OpenSpec is now described at the same tier as Linear, GitHub, gstack, and Human.
- All-skills list line for `/pm-breakdown` updated in `README.md`, `llms.txt`, `CLAUDE.md`.
- `setup` no longer asks about telemetry. Default install is faster (no opt-in prompt) and quieter.

**ETHOS principles → structural gates:**
The principles in `~/.nanopm/ETHOS.md` are no longer prose hopes — three skills now enforce them with a two-layer gate: an adversarial subagent against a strict rubric, plus the typed state validator. A skill cannot complete unless a well-formed record lands in `decision.jsonl`.

- **`/pm-audit`** — replaces the old "Adversarial self-challenge" with a gated *"Question You're Avoiding"* (ETHOS §3). Subagent must emit `QUESTION:` / `KEY:` / `CONFIDENCE:` / `RATIONALE:` lines that pass a rubric (ends in `?`, starts with Is/Does/Will/Would/Can/Should/Are, ≤200 chars, named actor or behavior). On pass, writes a typed `decision` of kind `question`. Two failed retries abort the audit.
- **`/pm-roadmap`** — new Phase 4b iterates every committed item (NOW row, Shape Up Bet, or Scrum sprint focus row). One batched subagent checks each outcome statement for 4 elements (SEGMENT, BEHAVIOR, METRIC, TIMEFRAME). Failed items are rewritten in-place with a `⚠ rewritten by gate` tag. Every committed item writes a typed `decision` of kind `target` via `nanopm_state_log`. Vague outcomes don't ship.
- **`/pm-prd`** — both Shape Up pitch and standard PRD formats now require a `## Falsification` section. New Phase 4b validates it against the same 4-element rubric (NUMBER + SEGMENT + BEHAVIOR + TIMEFRAME), rewrites the paragraph on FAIL, and writes typed records: a `decision` of kind `bet` (keyed by feature slug) and a `prd` row with `status: ready`. The PRD lands as ready-for-handoff in state — `/pm-breakdown` will read this on the next call.

The state validator's enum allowlists are the gate's structural backbone: if the LLM tries to write an invalid kind, source, or out-of-range confidence, `nanopm_state_log` rejects with a clear stderr message and non-zero exit. The skill must retry or escalate — there is no silent append.

**Migration notes:**
- Old `~/.nanopm/memory/{slug}.jsonl` is left untouched. Skills still write to it via the legacy `nanopm_context_append` shim for back-compat. Future work will migrate skills to the typed state layer; until then both paths coexist.
- If you previously enabled telemetry, the `telemetry=anonymous` line in `~/.nanopm/config` is now ignored — nothing reads it. You can leave it or remove it.

## 0.5.2 — 2026-05-21

### Daily ops layer (from PRs #6 and #7 by @alexhumeau)

**New skills:**
- **`/pm-standup`** — morning briefing that reads recent commits, Google Calendar events, and Granola meeting notes. Surfaces what shipped, today's meetings, and top 1-3 priorities. Works standalone from a Product OS folder (no codebase required).
- **`/pm-interview`** — user interview guide generator and transcript debrief. Draws on Teresa Torres (story-based), Rob Fitzpatrick (Mom Test), Bob Moesta (JTBD Switch), and Cindy Alvarez (Lean Customer Dev). Imports transcripts from Granola automatically. Writes signal to `FEEDBACK.md`.
- **`/pm-weekly-update`** — drafts stakeholder update email adapted to audience (CEO, investor, or team). Reads ROADMAP.md, RETRO.md, and recent commits. Adapts tone per audience.
- **`/pm-data`** — answers a specific product question using PostHog or Amplitude (trends, funnels, retention, paths). Writes findings to `DATA.md`. Consumed by `/pm-audit` and `/pm-prd`.

**New connectors (6):**
- **`connectors/intercom.md`** — conversations, support themes (Tier 2 API)
- **`connectors/slack.md`** — channel decisions and customer mentions (Tier 1 MCP + Tier 2 API)
- **`connectors/mixpanel.md`** — event trends, funnels (Tier 2 API)
- **`connectors/jira.md`** — active sprint, blockers (Tier 1 MCP preview + Tier 2 API)
- **`connectors/google-drive.md`** — PRDs, research docs, strategy docs (Tier 1 MCP)
- **`connectors/hubspot.md`** — pipeline, ICP signal, deal notes (Tier 2 API)

**Existing connectors added (from PRs #6 and #7):**
- **`connectors/google-calendar.md`** — today's events and meeting prep signal for `/pm-standup`
- **`connectors/granola.md`** — meeting transcripts for `/pm-standup` and `/pm-interview`
- **`connectors/posthog.md`** — trends, funnels, retention for `/pm-data`
- **`connectors/amplitude.md`** — trends, funnels, retention for `/pm-data`

**Skill integrations:**
- **`/pm-audit`** now reads `DATA.md` if present — quantitative findings are folded into Phase 4 synthesis. Contradictions between quanti and quali are flagged explicitly. Removed SCAN.md pre-fill block (simplified).
- **`/pm-prd`** now reads `DATA.md` if present — 🟢 high-confidence metrics used in Problem Statement and Success Criteria.

**README and docs:**
- All-skills section split into "Planning pipeline" and "Daily ops" groups
- Pipeline diagram updated with daily ops layer (pm-standup, pm-interview, pm-weekly-update, pm-data)
- Connectors table expanded from 5 to 15 connectors
- `llms.txt` updated with new skills and connector list
- `CLAUDE.md` updated: header changed to "AI coding agents", new skills added

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
