# Changelog

## Unreleased

### Define skills: refine vs from-scratch context discipline

The five Define skills (`pm-vision-mission`, `pm-business-model`, `pm-org`, `pm-product`, `pm-personas`) used to pick their behavior by sniffing whatever evidence was lying around — and in "reverse-engineer" mode they read *every* prior `.nanopm/*.md` artifact, flooding the model's context with noise. Now behavior is driven by **one fact: does the target doc already exist?**

- **Refine mode** (doc exists) — anchors on the previous version of the doc and asks *sharpening* questions, instead of regenerating it from scratch.
- **Create mode** (doc missing) — reverse-engineers a draft from code/site, then asks *validating* questions before writing; never ships an `Assumed` claim unchecked. Falls back to a full interview when the repo is greenfield.

In both modes, cross-document context is gathered by a **retrieval subagent** that reads the *other* Define docs and returns only the relevant slices as a bounded digest — so the main agent works from signal, not raw dumps. Two new shared helpers in `lib/nanopm.sh` (`nanopm_define_mode`, `nanopm_retrieval_prompt`) keep all five skills branching identically. `pm-product` keeps the code as ground truth: in refine mode it maps only the code delta since the last run.

### Consolidated PM context brief — one source of truth, loaded everywhere

The Define phase produces five separate docs (vision, business model, org, product, personas). Downstream skills re-read them unevenly, so the agent's grasp of the company drifted from skill to skill. Now each Define skill, once its document is written, dispatches a **subagent** (Agent tool) that synthesizes whatever Define docs exist into a single ~1-page brief at **`.nanopm/CONTEXT-SUMMARY.md`** — what we do, who for, how we make money, why we exist, who decides, and what's not known yet. Each section carries a "More detail" pointer to its source Define doc, so the agent knows where to dig.

That brief is loaded automatically by `nanopm_preamble` (new `nanopm_load_context`, bounded to 8 KB) at the start of **every** skill run — Discover, Plan, Build, and Daily Ops all share the same baseline with zero per-skill wiring, on every host. Regenerated after each Define skill, so it never goes stale.

**macOS viewer:** clicking **Define** now leads with a **Context Brief** card that opens `CONTEXT-SUMMARY.md`; the doc also appears in the Define sidebar. Build clean.

### `/pm-audit` is now `/pm-challenge-me` — and it throws three punches

The audit always ended on one adversarial question; that question was the whole point. So the skill is now named for it. **`/pm-challenge-me`** keeps the same context engine (website bootstrap, connectors, CONTEXT.md intake, Define-doc synthesis) but reframes the output as a challenge session: a skeptical-CPO read of what you're building, who for, and the biggest gap — then **three direct challenges**, each from a different angle:

- **`strategy`** — *The Question You're Avoiding*. Still hard-gated: rubric-validated, written as a typed `question` decision via `nanopm_state_log` before the artifact can exist.
- **`users`** — challenges who you think you're serving, using persona/signal divergence.
- **`focus`** — challenges where the effort is going vs. the stated goals.

The `users` and `focus` challenges go through the same rubric but are droppable after two failed validations; the `strategy` one aborts the run if it can't land.

**Artifact rename:** `.nanopm/AUDIT.md` → `.nanopm/CHALLENGES.md` (same section numbering; Section 4 is now "The Challenges"). **Migration:** downstream skills (`pm-objectives`, `pm-strategy`, `pm-retro`, `pm-standup`, `pm-weekly-update`, `pm-run`, …) read `CHALLENGES.md` and fall back to a legacy `AUDIT.md`; the staleness check tracks both; prior `pm-audit` memory entries are still read; `uninstall` removes both skill directories.

### New phase: **Day to Day** — recurring PM ops

`/pm-challenge-me` no longer lives in Define — it joins `/pm-standup` and `/pm-weekly-update` in a new **Daily Ops** zone: the skills you run on any given day, outside the Define → Discover → Plan → Build pipeline.

**macOS viewer** gains a **Day to Day** section at the top of the sidebar with three skill rows — Standup (`STANDUP.md`), Weekly Update (`WEEKLY_UPDATE.md`), and Challenge Me (`CHALLENGES.md`) — and maps legacy `AUDIT.md` artifacts there too. Standup and Weekly Update get catalog entries (and run buttons) for the first time. Build clean.

## 0.10.0 — 2026-06-11

### New phase: **Define** — company & product context, established first

Adds a fourth phase ahead of the pipeline: **Define → Discover → Plan → Build**. Define is the ground-truth layer a PM or founder needs *before* planning — the company and the product, mapped or defined from scratch. It answers the questions the rest of the pipeline used to assume.

**Four new skills**, each dual-mode (auto-detects existing-codebase/site vs. greenfield, like `/pm-personas`):

- **`/pm-vision-mission`** → `VISION-MISSION.md` — mission, vision, values, company stage.
- **`/pm-business-model`** → `BUSINESS-MODEL.md` — model, revenue, pricing & packaging, GTM motion.
- **`/pm-org`** → `ORG.md` — org map, key roles, decision-makers, ways of working.
- **`/pm-product`** → `PRODUCT.md` — deep product map (surface area, features, core workflow, technical bets). Reads the codebase **and** the public site for existing products; interviews the concept for greenfield, stamping `Completeness: complete` only when the four essentials (problem, primary user, concept, core workflow) are filled.

**`/pm-scan` is retired.** Its codebase reverse-engineering folds into `/pm-product`'s existing mode — one descriptive product doc instead of a scan that drifted into judgment. `SCAN.md` readers (`pm-personas`, `pm-run`) repoint to `PRODUCT.md`; a legacy `SCAN.md` is still read as migration input.

**`/pm-personas` and `/pm-audit` move into Define.** `pm-audit` is re-partitioned to *evaluate* against `PRODUCT.md` + the company docs instead of re-deriving the basics — no more scan/audit overlap. This leaves **Discover** as the three external signals: market (`/pm-competitors-intel`), user research (`/pm-user-feedback`, `/pm-interview`), data (`/pm-data`).

**Advisory, not a gate.** `/pm-run` Phase 1 establishes Define context first by default but never blocks — you can skip ahead, and downstream skills warn (not fail) when context is thin. This keeps adoption measurable rather than forced.

**Pipeline integration.** Eight downstream skills now read the new Define docs where it sharpens output: `pm-strategy`, `pm-objectives`, `pm-prd`, `pm-roadmap`, `pm-data`, `pm-competitors-intel`, `pm-interview`, `pm-weekly-update` — all degrading gracefully when a doc is absent.

**macOS viewer** renders Define as the first phase (six skill rows), maps the new artifacts, and drops the Codebase Scan row. Build clean.

**Registered** in `setup`, `test/skill-syntax.sh`, `README.md`, `llms.txt`, `CLAUDE.md`, and `viewer/README.md`. Static checks: 74 passed, 0 failed; context-threading gate passed.

## 0.9.0 — 2026-06-11

### New skill: `/pm-personas` — define who you're building for

Adds a planning skill that answers the one question the rest of the pipeline assumes an answer to: **who is this for?** Produces `.nanopm/PERSONAS.md` — 1-3 JTBD proto-personas plus an explicit **anti-persona** (the tempting user you are deliberately NOT serving).

**Adaptive by design.** The skill auto-detects its mode:

- **Reverse-engineer** — when the repo has code and/or prior nanopm artifacts (`SCAN.md`, `DISCOVERY.md`, `FEEDBACK.md`, `AUDIT.md`, `DATA.md`), it reads them, scans the codebase for who-signals (roles, pricing tiers, route names, onboarding copy — dispatching a subagent for large repos), drafts the personas the product *implies*, then asks you to confirm or correct.
- **From-scratch** — when the repo is empty / pre-product, it interviews you with four JTBD questions and builds the personas from your answers.

Every claim is tagged **Evidenced** or **Assumed**, so the artifact is honest about how much is inference. The skill surfaces reality-vs-aspiration gaps (who uses it today vs. who you want) and names "the one bet" — the riskiest belief about the user.

**Pipeline integration.** `pm-personas` is a Zone-1 **Inputs** skill. `/pm-run` now runs it as a new phase (`feedback → personas → audit → …`), and six downstream skills read `PERSONAS.md` where they reason about "who":

- **`/pm-audit`** — pre-fills the "who for" section; flags drift toward the anti-persona as a strategic leak.
- **`/pm-objectives`** — every objective must move the primary persona; vanity goals get challenged.
- **`/pm-strategy`** — the bet must win for the primary persona; names which one.
- **`/pm-roadmap`** — every NOW/NEXT item must map to a persona.
- **`/pm-prd`** — user stories written in the persona's voice; stops if a feature mainly serves the anti-persona.
- **`/pm-discovery`** — bidirectional: pre-fills "who is the user" from `PERSONAS.md` when it exists, recommends `/pm-personas` when discovery lands on a sharp user definition.

**Registered** in `setup`, `test/skill-syntax.sh`, `README.md`, `llms.txt`, and `CLAUDE.md`. Static checks: 64 passed, 0 failed.

## 0.8.0 — 2026-06-05

### Mode-aware adversarial gates — ETHOS principle 4 corrected for the AI-native audience

**Background:** Two external users reported in 36 hours that nanopm's `/pm-roadmap` and `/pm-strategy` push "Wizard of Oz" / instrumentation-first validation that doesn't fit solo founders shipping with AI coding agents. The bias propagates from ETHOS principle 4 ("Evidence Before Conviction") through the adversarial gates — implicitly assuming builds are expensive (multi-week engineering work), which makes faking-it-first the cheapest test.

For solo + AI builders, **cost-to-build ≈ cost-to-fake**, and the build IS the experiment. The implicit bias was structural, not skill-specific.

**Tracked as** typed `gap` decision `ethos-slow-validation-bias` (written 2026-06-05). Resolved in this release.

**Two operational modes now explicit:**

- **`solo-fast`** — solo founder + AI agents, ship in hours-to-days. Cost-to-build ≈ cost-to-fake. Build IS the experiment. *Default if `build_mode` is unset.*
- **`team-traditional`** — 2+ humans on the build, cycles in days-to-weeks. Build cost dominates. Wizard of Oz, prototype-and-invite-testers, paid pilots, shadow launches are the cheapest tests.

**Changes:**

- **`ETHOS.md` principle 4 rewritten.** Same Cagan / Torres / Graham quotes retained. New sub-section makes the cost calculus explicit and maps it to the two modes. New `When advising:` paragraph instructs to read `build_mode` from config (default `solo-fast`). New anti-patterns called out per-mode.

- **`/pm-audit` Q12 added.** New CONTEXT.md question: *"How does this project ship?"* with explicit options (a) Solo + AI agents — build IS the cheapest test, (b) Traditional team — Wizard of Oz pattern. Asked via `AskUserQuestion` with header `Build mode`. Phase 3 logic writes `build_mode` to `~/.nanopm/config` via `nanopm_config_set`. Backward-compat: existing CONTEXT.md (Q1–Q11) detected as "Q12 missing" by the audit's standard skip-already-answered logic.

- **3 adversarial gate prompts updated** (`/pm-strategy`, `/pm-roadmap`, `/pm-prd`). Each gate now reads `build_mode` from config before dispatching the subagent. The CHEAPEST TEST / BEHAVIOR rubric element branches on the mode:
  - **solo-fast:** "ship the real feature in N days, observe git log + 3-5 DM responses + qualitative reactions" is a valid CHEAPEST TEST. Small-N qualitative observation is valid evidence. Don't demand pre-built instrumentation.
  - **team-traditional:** Wizard of Oz, prototype-and-invite-testers, paid pilots, shadow launches, tracked analytics events.
  - **The 4-element falsifiability rubric (segment + number + behavior + timeframe) stays in both modes.** What varies is the *form* the evidence takes.

- **`test/gates.sh` extended.** 38 checks (was 29). New cases:
  - Q12 present in pm-audit CONTEXT.md template
  - `build_mode` config write present after Q12
  - Each of `/pm-strategy`, `/pm-roadmap`, `/pm-prd` reads `build_mode` from config
  - Each subagent prompt branches on `solo-fast` vs `team-traditional`

- `test/run-all.sh` — **ALL 9 SUITES PASSED** (38/38 in gates).

**Backward compatibility:**
- Existing projects with CONTEXT.md (Q1–Q11 only) get Q12 asked once on next `/pm-audit` run.
- If `build_mode` is unset when a gate runs, it defaults to `solo-fast` (matching nanopm's stated target audience per STRATEGY.md). This is a behavior change: existing users mid-pipeline who run `/pm-strategy` without first re-running `/pm-audit` will get the new default cheapest-test guidance. Documented intentionally — the new default is more correct for the audience.

**Resolves the typed `gap` decision** `ethos-slow-validation-bias` (written 2026-06-05). Builder's chat instinct ("ça devrait être le seul Mode en fait") guided the default-to-solo-fast choice.

## 0.7.1 — 2026-06-03

### Symphony WORKFLOW.md schema validator (level 1 test)

**Why:** v0.7.0 shipped the Symphony handoff target without testing the generated `WORKFLOW.md` against Symphony's SPEC.md. The user pushed back — correctly — that posting a "please review this" message to the Symphony GitHub discussions without testing first burns the highest-leverage audience on a half-cocked ask.

**Added — `bin/nanopm-symphony-validate`:**

Python3 validator that checks a `WORKFLOW.md` against Symphony's SPEC.md §5 (Workflow Specification). Standalone (minimal inline YAML parser, no external dependencies). Runs against any file path; exits 0 on full compliance, non-zero with diagnostics on failure.

Checks performed (21 in the canonical run):
- Frontmatter structure: `---` delimiters present, parses as YAML map
- `tracker.kind` required (must match v1 supported value `linear`)
- `tracker.api_key` required (recommends `$LINEAR_API_KEY` canonical env reference)
- `tracker.project_slug` required when `kind=linear`
- `tracker.active_states` / `terminal_states` are lists of strings if present
- `polling.interval_ms` is integer or string-integer
- `workspace.root` is a string path
- `agent.max_concurrent_agents`, `agent.max_turns` are valid integers
- `codex.command` is a non-empty string
- `codex.turn_timeout_ms`, `read_timeout_ms`, `stall_timeout_ms` are valid integers
- Prompt body is non-empty
- Prompt references `{{ issue.* }}` variables
- Prompt references `attempt` (retry/continuation aware)
- All Liquid variables are spec-known (`issue.*` or `attempt`) — per §5.4 "Unknown variables must fail rendering"
- All Liquid tag blocks use portable keywords (`if`/`else`/`endif`/`for`/`endfor`)

**Added — `test/symphony-validator.sh` (7 behavioral checks):**

- Binary exists and executable
- Positive: minimal valid WORKFLOW.md (only required fields) accepted
- Positive: full WORKFLOW.md (mirroring nanopm /pm-breakdown output) accepted
- Negative: missing `tracker.kind` rejected
- Negative: missing `tracker.api_key` rejected
- Negative: missing `tracker.project_slug` when `kind=linear` rejected
- Negative: missing frontmatter delimiter rejected

**Test results:**
- Level 1 schema validation against nanopm-generated output: **21/21 PASSED**
- Validator behavioral tests: **7/7 PASSED**
- Full suite: **9 suites, ALL PASSED**

**Updated:**
- `setup` installs `bin/nanopm-symphony-validate` alongside the existing state binaries
- `test/skill-syntax.sh` extended state-binaries check from 2 to 3 binaries
- `test/run-all.sh` now runs 9 suites (was 8)

**Strategic posture shift:**

Pre-test draft of the Symphony GitHub discussion said: *"I built this against the spec, please tell me if it works."* That's a weak posture.

Post-test draft (saved in `.nanopm/intel/LAUNCH-DRAFTS-2026-06-03.md`) leads with: *"I generate WORKFLOW.md per SPEC.md §5; it passes 21/21 schema checks against the validator I shipped. Would love to know whether the Elixir reference implementation has any field-name drift from SPEC.md that I should account for."*

Concrete claim. Specific question. Stronger ground.

**Still TODO before launch (issues #15 and #12):**
- Demo recording (issue #15)
- Symphony GitHub discussion post (Draft 1 in `.nanopm/intel/LAUNCH-DRAFTS-2026-06-03.md`)
- Twitter thread (Draft 2)
- Reddit r/ClaudeAI post (Draft 3)

**Optional level 2 / level 3 testing:**

Level 1 (this release) validates against SPEC.md. Level 2 would install the Elixir reference impl and verify it parses our output. Level 3 would run a full Codex agent against a real Linear ticket. Both deferred — level 1 is defensible posture for the Symphony GitHub discussion.

## 0.7.0 — 2026-06-03

### Symphony as the 6th peer handoff target

Closes issue #14. Adds `Symphony` as the 6th of six peer handoff targets in `/pm-breakdown`. The strategy here is **symmetric handoff across N targets** — Symphony is the timing lever for an upcoming launch (OpenAI announced Symphony 2026-06-02), but the architectural pitch is the symmetry itself.

**`/pm-breakdown` (v0.3.0):**
- New Phase 3 option E: Symphony.
- New Phase 4 setup branch: reuses Linear setup (Symphony is Linear-only per its v1 SPEC), plus stores `linear_project_slug` for the WORKFLOW.md frontmatter.
- New Phase 7f branch: writes `WORKFLOW.md` to the repo root + creates Linear issues. The `WORKFLOW.md` body is a per-issue Liquid-compatible prompt template that embeds: source PRD path, typed `bet` from `decision.jsonl`, Falsification criterion, out-of-scope items, success criteria. Frontmatter configures the Symphony orchestrator + Codex App Server runtime.
- Phase 9 handoff path: `symphony://<workflow>+linear://<team>`.

**README updates:**
- Pipeline section "3. Handoffs" table — 6 rows (was 5).
- `## Handoffs` section — new Symphony paragraph between gstack and Human.

**Test updates:**
- `test/gates.sh`: now asserts all 6 handoff targets are case branches in pm-breakdown (was 5).
- ALL 8 SUITES PASSED.

**Strategy rewrite (2026-06-03):**
- The prior `validate-typed-memory-pulls-return` bet from v0.6.x was dead (the builder didn't internalize the metric after the pipeline produced it — a real signal the framework was producing artifacts the builder didn't own).
- Replaced with `symmetric-handoff-symphony-lever`: solo founders and small teams will value an upstream PM tool that produces well-formed artifacts (typed bet, falsifiable acceptance, scope-outs) and lets them choose their delivery layer across 6 peer targets. Symphony's launch is the timing lever, not the strategy.
- A first attempt at the rewrite was Symphony-only; the builder rejected it as too narrow. Final framing positions Symphony as one of six, with launch copy emphasizing the architecture and using Symphony as the lead example because of timing.
- New scope-out: `not-symphony-only-positioning` (confidence 9) — explicit guard against collapsing into Symphony-specific positioning.
- New scope-out: `not-cohort-validation` (the 14-day cohort experiment from v0.6.x is dead).
- New target: `symmetric-launch-week-one` (replaces `symphony-launch-week-one`).
- GitHub issues #10 and #11 closed as won't-do. Issues #12 and #13 retitled and rebodied for the symmetric framing. New issues #14 (this work) and #15 (demo recording) filed.

## 0.6.5 — 2026-06-03

### Memory-read instrumentation — the validation experiment's core probe

Closes issues #8 and #9 (the first two tasks of the v0.6.5 validation experiment plan committed by `/pm-breakdown`). This ships the *measurement* needed by the validation cohort that begins once issue #12 is posted.

**Design decision (issue #8, written up at `.nanopm/intel/SESSION-BOUNDARY-DESIGN.md`):**
- A **session** = one skill invocation, marked by a 16-char hex UUID written to `~/.nanopm/projects/{slug}/.current_session` by `nanopm_preamble`. Survives Vibe subprocess boundaries because every bash block reads the same marker file.
- **Preamble reads count** toward the bet. The user benefits from memory when prior decisions are surfaced into the LLM's context — that IS the memory paying off.
- **Empty reads don't fire.** A read against a `decision.jsonl` with zero records (or only current-session records) emits no event.
- **Re-running pm-audit counts.** Qualitative analysis distinguishes same-skill-re-invoked vs different-skill in the cohort report.

**Implementation (issue #9):**
- `bin/nanopm-state-log` adds a new `session` field (optional) to all 4 record types (timeline / decision / prd / handoff). Format validator: `^[a-f0-9]{16}$`. Auto-injected from `NANOPM_SESSION_ID` env var; falls back to `.current_session` file on Vibe-style fresh subshells; silent skip outside skill invocations.
- `nanopm_preamble` (in `lib/nanopm.sh`) generates a fresh UUID per invocation, exports `NANOPM_SESSION_ID`, and writes the marker file. Preamble output now includes `SESSION: <id>` for visibility.
- `nanopm_state_read` (the shell wrapper) detects cross-session reads of `decision.jsonl` and emits a `memory-read` event to `timeline.jsonl`. **Privacy (NFR1):** the event captures `project_slug_hash` (SHA-256 of slug, 16-char prefix) — raw project names never leave the local file. **Reversibility (NFR2):** single function, removable in one commit if validation fails.

**Test coverage:**
- `test/state-layer.sh` extended from 25 to 34 checks. New cases:
  - Invalid session string rejected
  - Valid 16-hex session accepted
  - Auto-inject from env var
  - Auto-inject from `.current_session` file when env var unset
  - Env var precedence over file
  - Session injected into all 4 record types
  - **Cross-session decision read emits memory-read event**
  - **Same-session decision read does NOT emit**
  - Memory-read event uses hashed slug (NFR1 privacy check)
- All 8 suites pass.

**What this unlocks:** issue #10 (poll template), #11 (check-in script), #12 (post to 4 channels), #13 (run cohort). Tasks #10 and #11 are blocked on user input — they're copy in the builder's voice. Tasks #12 and #13 require the builder's authenticated accounts.

## 0.6.4 — 2026-05-25

### Hotfix: two more Mistral Vibe portability bugs

Both reported by a user running `/pm-discovery` on Vibe.

**Bug A — `nanopm_context_append: command not found`**

The legacy `nanopm_context_append` (and 8 other lib helpers — `nanopm_context_read`, `nanopm_context_all`, `nanopm_config_get`, `nanopm_config_set`, `nanopm_has_connector`, `nanopm_state_log`, `nanopm_state_read`, `nanopm_skill_path`) are shell functions defined in `lib/nanopm.sh`. The preamble sources the lib once, but on Vibe each subsequent bash code block runs in a fresh subshell — the functions aren't defined. Claude Code preserves state across blocks and didn't expose the bug.

Audit found **61 bash blocks across 16 skills** that called `nanopm_*` functions without re-sourcing the lib. All 61 now have a guarded source line prepended:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
```

Idempotent injector preserved as `/tmp/inject_lib_source.py`. The injector skips blocks that already source, and skips the preamble block itself (which is the source).

**Bug B — `ask_user_question: options too_short, must be at least 2 items`**

Vibe's `ask_user_question` validates `len(options) ≥ 2`. Claude Code permits empty options (treats them as free-text). `/pm-discovery` Phase 1 used `Ask via AskUserQuestion — ONE question:` with no enumerated options — the Vibe LLM passed `options: []` and got rejected.

Fix:
- `/pm-discovery` Phase 1 restructured. Now provides 6 framing options (Build-vs-don't / Why users churn / Market exists? / What next? / Direction check / Other), then prompts for the specific question as free-text in chat after the choice. Multi-host hosts get a valid `ask_user_question` call; Claude users get the same UX.
- The `<!-- portability-v1 -->` block at the top of every SKILL.md was upgraded to `<!-- portability-v2 -->`, which now covers both constraints: header ≤12 chars AND options ≥2 with explicit example framing.

**Extended `test/headers.sh`:**
- New regression check: `pm-discovery` Phase 1 must provide ≥2 options (the actual options=[] bug).
- New check: all 17 skills carry the `portability-v2` rule (no leftover v1).
- New check: every bash block that calls a `nanopm_*` function sources the lib first (or is the preamble block).
- Total: 8 checks, all passing.

`test/run-all.sh` — ALL 8 SUITES PASSED.

## 0.6.3 — 2026-05-22

### Hotfix: Mistral Vibe AskUserQuestion header crash

**Bug report (from a user testing on Mistral Vibe):**

```
ask_user_question: Invalid arguments: 1 validation error for AskUserQuestionArgs
questions.0.header
  String should have at most 12 characters [type=string_too_long,
                                            input_value='Starting point']
```

**Root cause:**
Mistral Vibe's `ask_user_question` tool validates `header ≤ 12 chars`. Claude Code allows longer. nanopm SKILL.md files didn't prescribe a `header` value — they left the LLM to pick one. On Vibe, the LLM read the phase heading `## Phase 0b: Starting point` and used "Starting point" (14 chars) as the header. Crash.

**Three-layer fix:**
1. **Explicit prescribed headers** added to `pm-run` Phase 0b (`Start`) and Phase 1 (`Pipeline`) — the call sites the user actually hit.
2. **Global portability rule** injected at the top of every SKILL.md (17 files) right after the YAML frontmatter, as a `<!-- portability-v1 -->` block. Tells the LLM: *"`header` field MUST be ≤ 12 characters (Mistral Vibe rejects longer with string_too_long)"* with example values. The LLM sees this before reading any AskUserQuestion instruction in the body.
3. **Preamble hint** in `nanopm_preamble` echoes `PORTABILITY: AskUserQuestion 'header' MUST be a short noun phrase ≤12 chars` on every skill invocation. Adds `HOST: claude/vibe/codex` to the preamble output so the LLM knows which host it's on.

**Added — `test/headers.sh` (3 checks + per-skill coverage warnings):**
- Audits every prescribed header in every SKILL.md and fails on any >12 chars.
- Per-skill coverage warning: lists skills where AskUserQuestion call count exceeds prescribed-header count (LLM picks the rest, still at risk).
- Regression check: `pm-run` Phase 0b prescribes a `Start*` header.

`test/run-all.sh` now runs 8 suites.

**Still soft-enforced (warning level):** 9 skills (`pm-audit`, `pm-competitors-intel`, `pm-data`, `pm-discovery`, `pm-interview`, `pm-objectives`, `pm-prd`, `pm-roadmap`, `pm-weekly-update`) still have AskUserQuestion calls without explicit prescribed headers. The portability note at the top of each file plus the preamble hint reduce the failure risk substantially, but explicit prescription would be belt-and-suspenders. Follow-up work tracked in the test output.

## 0.6.2 — 2026-05-22

### Hotfix: auto-upgrade bugs + README pipeline rewrite

**Fixed — `nanopm_update_check` was misfiring (could suggest a downgrade):**
- Old logic compared cached remote vs local with `!=`. If a stale cache held an older remote version than the now-bumped local (e.g. cache says `0.5.2` but local is `0.6.0`), the check fired `UPGRADE_AVAILABLE 0.6.0 0.5.2` — telling the user to install an older version.
- New helper `nanopm_semver_gt` does proper component-by-component comparison (so `0.10.0 > 0.9.0` and `1.42.2 > 0.15.16` work correctly).
- `nanopm_update_check` rewritten to: resolve remote (cache or fetch) → compare semver-strictly-greater → only then check snooze.
- Test `test/update-check.sh` (16 checks) covers the regression: stale-cache downgrade scenario, equal versions stay silent, disabled flag honored, snooze active/expired.

**Fixed — snooze compared against the wrong version:**
- The "Not now" snooze stored the remote version the user dismissed. But the check then compared against the *local* version. Two bugs in one: if the user snoozed `0.7.0` and then `0.8.0` came out, the snooze comparison didn't fire correctly.
- Now snooze suppresses notifications only when the snoozed version equals the currently-resolved remote version, and we're still within the backoff window. Different remote → user gets notified.

**Fixed — `setup` accumulated duplicate `telemetry=anonymous` lines:**
- Pre-v0.6.0 setup runs appended on each install. My local `~/.nanopm/config` had 13 copies after testing.
- Setup now does a single-pass awk cleanup on every install: strip deprecated keys (telemetry=), dedupe remaining KEY=VALUE lines (last write wins, original order preserved), pass comments through unchanged.
- One subtle bug caught and fixed during this work: the first cleanup attempt used `grep -v | awk` and the `pipefail` shell flag killed the pipeline when grep returned 1 (no lines left after filtering). Folded into a single awk pass.

**Fixed — setup now clears `~/.nanopm/last-update-check` on every install:**
- This prevents a fresh install from inheriting a stale cache from a prior version that's about to be replaced.

**Changed — README "Pipeline" section rewritten in markdown:**
- The mermaid diagram is gone. Replaced with a 3-zone table summary + drill-down sections for Inputs, Pipeline, Handoffs, plus a callout for the parallel daily ops skills (`/pm-standup`, `/pm-weekly-update`, `/pm-retro`).
- Each pipeline step now names its typed-state output (kind, source) inline. Each input skill names its artifact. Each handoff target gets a one-line spec.

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
