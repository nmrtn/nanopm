# Changelog

## 0.21.0 — 2026-06-25

### Wiki-canonical: everything nanopm generates now lives in the wiki

0.19.0–0.20.0 built the memory wiki and wired the ingest loop, but skills still wrote
flat `.nanopm/<X>.md` docs as their primary output and only *copied* a view into the
wiki — a double-write that drifts. This release finishes the migration: the wiki is the
single source of truth for everything nanopm produces, and a project's `.nanopm/` is now
exactly the three-layer model the schema describes: `NANOPM-WIKI.md` (the contract) +
`raw/` (immutable sources) + `wiki/` (all generated content).

**What's different for you**

- **Every skill writes the wiki, nothing else.** The 5 Define + 3 Plan skills, plus the
  9 Discover/Daily-Ops skills (challenge-me, competitors-intel, user-feedback, interview,
  data, discovery, weekly-update, standup, retro), write only into `.nanopm/wiki/docs/`
  (and entity pages). No flat top-level docs, no `reasoning/` sidecars — the
  Evidenced/Assumed rationale folds inline into each page's `## Provenance & assumptions`.
  standup/retro/weekly-update write dated pages so history is kept.
- **And they read it too.** Cross-skill context reads (pm-prd pulling personas/data,
  pm-objectives reading challenges/feedback, pm-run/pm-retro, the Define mode-detection
  scans) now resolve the wiki pages, with a legacy flat fallback for un-migrated projects.
- **Tools and data are where they belong.** PRDs → `wiki/docs/prds/`, breakdown tasks →
  `wiki/docs/tasks/`, handoffs → `wiki/docs/handoffs/`, the opportunity DB →
  `wiki/entities/opportunities/`. Competitor intel (snapshots + reports + config) moved
  from the incoherent `intel/` to `raw/competitors/`, matching the `competitors` entity.
- **New `nanopm-export <section>`.** Renders a wiki section (company, current-work, a doc)
  to one shareable markdown file on demand — generated output, never an edit surface — so
  retiring the flat docs doesn't cost you "send me the brief."
- **The macOS viewer follows.** It surfaces the migrated `wiki/docs/` pages under their
  phases, reads provenance per-page instead of a sidecar file, recognizes PRDs/competitors
  at their wiki paths, and the Run button works on the new locations.

**Migration + safety**

- `nanopm-migrate-to-wiki` relocates the whole tree (docs, sidecars→provenance, prds,
  tasks, handoffs, opportunities, weekly-updates, competitor intel) and `--finalize`
  removes the legacy copies only once mirrored — idempotent, dry-run-faithful, and scoped
  to migrated docs so it never deletes a not-yet-routed skill's output.
- New tier-1 `test/wiki-canonical.sh` is the regression gate: it fails the moment a
  migrated skill regrows a flat write.

**Follow-ups landed in this release**

- **Dated series get their own folders.** Weekly updates and standups move from flat
  `wiki/docs/weekly-update-<date>.md` to per-series folders `wiki/docs/weekly-updates/<date>.md`
  and `standups/<date>.md` — the same layout as `prds/` and `tasks/`. A new
  `nanopm_wiki_series_path <series> <date>` helper writes them, `nanopm-migrate-to-wiki`
  relocates pre-existing flat pages, and the viewer groups each series under one
  newest-first entry in Day to Day (structural, by folder prefix, not a filename guess).
- **The index stays bounded.** `reindex` now emits one `## Collections` pointer line per
  `docs/` subfolder (prds, tasks, weekly-updates, standups: title · N pages · latest date)
  instead of listing every page — so a daily standup can't grow the always-loaded catalog
  unboundedly. The `ingest → confidence-gate → reindex → log` loop is otherwise untouched
  (these are doc-view writes, never gated entity writes).
- **Fixes.** `nanopm_wiki_ensure` now scaffolds `raw/competitors/` (it lagged the
  `intel/`→`competitors/` rename, leaving a stray empty `raw/intel/` each run); the dead
  `nanopm_reasoning_path` helper and the retired-sidecar surfacing in the preamble are gone.
- **Viewer Settings.** A native macOS Settings window (⌘,) with a "Display entities" toggle
  to hide the wiki entity groups from the sidebar.

## 0.20.0 — 2026-06-24

### Memory wiki, phase 2: the ingest loop is wired and verified

0.19.0 shipped the memory-wiki engine (schema, migration, ingest/lint/gate CLIs) but nothing dispatched it — the wiki could be migrated into existence, yet no skill filled or maintained it. This release connects it end-to-end.

**What's different for you**

- **Five skills now feed the wiki.** `/pm-personas`, `/pm-interview`, `/pm-user-feedback`, `/pm-data`, and `/pm-competitors-intel` dispatch the ingest bookkeeper after each run — integrating their output into the right entity pages (personas, opportunities, competitors, objectives) through the confidence gate, then reindexing and logging. Advisory and non-blocking, with an inline fallback on hosts without a subagent tool.
- **Held writes don't strand.** Low-confidence and reversal writes parked by the confidence gate are surfaced at the top of every run (`WIKI_REVIEWS: N…`) with the commands to approve or reject them.
- **The wiki self-checks.** A throttled (once/day) structural lint pass surfaces stale pages, orphans, and index drift. No-op for projects without a wiki.
- **Overviews stay fresh.** The company/current-work briefs are now written to the canonical wiki path when the wiki exists, so a migrated project no longer reads a frozen overview while the skill updates a legacy copy.

**Correctness + hardening**

- Citation dedup is anchored to whole citation lines (was an unanchored substring match that dropped distinct records); a dead always-false index guard fixed; `datetime.utcnow()` modernized.
- Writers take an advisory lock (`.nanopm/wiki/.lock`) so parallel ingest can't tear `index.md` or lose a log line.
- The episodic event log resolves the git toplevel, fixing a split-brain when a project ran from a subdirectory.
- New `nanopm_wiki_ensure` scaffolds the wiki idempotently without the heavy one-time migration.

**Verification**

- New `test/memory-wiki.e2e.sh` and `test/migrate-wiki.e2e.sh` cover the mechanical loop (dedup, gate routing, reindex/log, concurrent-write safety) and the migration (repair, idempotency, `--finalize` safety). A real ingest run against a live `PERSONAS.md` produced five conformant persona pages, correctly routed one ambiguous persona to review, and passed lint clean.

## 0.19.0 — 2026-06-23

### Memory: a compounding wiki, not an ever-growing logbook

Every skill run used to reload nanopm's *entire* history — an append-only log that grew forever, was never deduplicated, and quietly drifted from reality. Handy at run five, noise by run fifty. This release rebuilds memory as a **maintained wiki** (the pattern from Karpathy's "LLM wiki"): each run starts from a small, always-current set of pages instead of replaying the whole transcript, and a background bookkeeper keeps the wiki tidy. The result is sharper, cheaper runs that actually compound — and a viewer that shows who you are and what you're working on at a glance.

**What's different for you**

- **Runs start from a clean baseline.** A skill now loads a one-line index plus two consolidated briefs — *who the company is* and *what you're working on right now* — instead of the full event log. Context stays small and on-point no matter how long you've used nanopm.
- **Knowledge compounds on pages, not log lines.** Personas, competitors, opportunities, objectives, features, and people each get their own wiki page that many sources update over time, with citations. The same fact stops piling up — it gets refined in place.
- **The wiki keeps itself honest.** A lint pass flags stale pages, broken links, and contradictions; the bookkeeper deduplicates by citation and *supersedes* old claims instead of deleting them, so you keep the history of what you believed and when.
- **No silent overwrites.** Confident updates apply automatically; anything ambiguous — a strategy reversal, a shaky match — waits for your yes/no.
- **The viewer speaks the new layout.** The Context and Plan briefs render atop Define and Plan; entity pages tuck under one collapsible **Entities** group per phase instead of dozens of flat rows; the Memory tab reads the new log location.

**Under the hood**

- New `NANOPM-WIKI.md` schema (the contract every skill reads) and a three-layer layout — immutable `raw/` sources → an LLM-maintained `wiki/` → the schema. A one-time `nanopm-migrate-to-wiki` repairs the old corrupted log and seeds the wiki with zero content loss; `--finalize` removes the legacy summaries once the loaders cut over.
- The preamble drops `nanopm_context_all` across all 15 pipeline skills (pm-retro keeps full history); loaders read `wiki/index.md` + the two overviews. The episodic log is now canonical at the project-local `.nanopm/raw/events.jsonl`, with a safe fallback to the legacy global log.
- Three new CLIs wired into `setup`, all pure markdown + git (no database, no server, host-agnostic across Claude / Vibe / Codex): `nanopm-ingest-agent` (citation dedup / reindex / log), `nanopm-confidence-gate` (gated writes), `nanopm-lint-agent` (health pass). The reasoning halves ship as gated subagent prompts in `lib`.
- Two follow-ups are scoped but deferred, each with its own spec: a search engine over the wiki, and multi-writer git machinery.

## 0.18.0 — 2026-06-18

### Opportunities: launch /pm-opportunities from the viewer + a reusable dedup agent

The Discovery Opportunity DB could be browsed in the viewer but only *grown* from a terminal — a dead end for the non-terminal PM the viewer exists to serve. This pass adds an **Add** menu to the viewer's Opportunities page and the skill machinery behind it: a reusable opportunity-dedup subagent and an additive `generate` mode. `pm-opportunities` → v0.2.0; plus viewer and lib.

- **Add to the DB from the viewer, no terminal.** The Opportunities page gets an **Add ▾** menu: *Describe one myself…* (a sheet — you type one user problem) or *Let Nano suggest more* (across all themes, or in one theme). On an empty DB it collapses to Bootstrap. Reuses the existing `RunManager` launch + completion-refresh; no new run primitives in the viewer.
- **A reusable dedup agent gates every write.** New `nanopm_opportunity_dedup_prompt` (lib) is a standalone subagent with a stable contract — for each candidate it returns `new` / `duplicate-of` / `merge-into` plus a confidence. Strict by default: callers treat **confidence ≥ 8** as a high-confidence match. Built so a future transcript→opportunity extractor reuses it unchanged. Adds the optional `related_to` frontmatter field for sub-threshold links.
- **An additive `generate` mode.** `/pm-opportunities` learns `add:` / `generate:` launch hints and a new `generate` mode: it drafts N candidates (reusing the bootstrap per-theme drafter), runs each through the dedup agent, and writes the survivors as `nano-hypothesis` — never overwriting, tagging `related_to` on a loose match, and guarding against a hallucinated merge target. The `add` path is now deduped too, with an interactive merge / keep / cancel prompt.

## 0.17.0 — 2026-06-18

### pm-breakdown: parallel-by-default plans, GUI test criteria, and PRD write-back

`/pm-breakdown` turned a PRD into a flat task list and handed it off. This pass makes the breakdown built for many builders working at once, records the result back in the PRD, and adds runnable acceptance for UI work. Skill-only — `pm-breakdown/SKILL.md`, bumped to v0.4.0.

- **Optimize for parallelism (foundation first, then waves).** Decomposition now identifies the shared foundation (schema, types, API contracts, shared components) as **Wave 0** — built and merged first by one builder — then splits the rest into parallel **Waves 1+**. Every task carries `Wave:` and `Depends on:`, and the skill emits a **Build Plan** (waves, max parallel width, critical path) rendered in the confirmation, the tasks markdown, and every handoff target. Within-wave tasks are guaranteed collision-free (no shared file both edit). Execution stays the handoff target's job — the skill produces the plan, it doesn't build.
- **Automated GUI test criteria.** Tasks touching a GUI surface get a `GUI test:` field with tool-agnostic `navigate → act → assert` steps a capable build agent runs with whatever harness it has (Playwright, browser MCP, computer-use), or that double as a manual QA checklist otherwise. Non-GUI tasks omit it.
- **Write the breakdown back into the PRD.** New Phase 8b rewrites a `## Task Breakdown` section into the source PRD — delimited by `<!-- nanopm:breakdown:start/end -->` markers so re-runs replace rather than duplicate — holding the Build Plan plus a task → wave → effort → ticket table. The PRD becomes the single place to see what was decided and where the work went.
- **Two gated subagents.** A brownfield-only grounding subagent (`Explore`) maps the real code surface (`SHARED` / `LANDS` / `COLLISIONS` / `GAPS`) so waves are based on actual files, not guesses; an adversarial collision-check subagent verifies within-wave independence, Wave 0 minimality, and DAG validity — advisory in `solo-fast`, blocking in `team-traditional`. Both follow the established gating convention: presence-gating for the grounding pass, `build_mode`-gating for the reviewer, and control always stays with the main agent.

## 0.16.0 — 2026-06-18

### Viewer: the Opportunity DB gets a real home — ranked table + detail page

The `/pm-opportunities` artifact landed last release, but the viewer just listed `.nanopm/opportunities/` as flat sidebar rows and rendered each opportunity as a raw markdown blob, frontmatter and all. This pass gives the Discovery Opportunity DB a proper surface in the macOS viewer. Viewer-only — the throwaway prototype; no skill or lib changes.

- **One collapsible entry, not a row per file.** The opportunity files now fold under a single expandable **Opportunities** entry in Discover — `INDEX.md` is the landing, `LOG.md` and `SCHEMA.md` stay out of the nav as DB machinery, and the individual `<slug>.md` opportunities hang off the disclosure group. Mirrors how PRDs and Competitors already collapse. New `OpportunityFiles` helper in `Models.swift` owns the is-opportunity / is-index / is-reserved checks.
- **A ranked, sortable table.** Clicking **Opportunities** opens a `Table` with columns Opportunity, Theme, Priority, Provenance, Status, and Updated — priority-ranked by default (high → medium → low), every column sortable. Priority, provenance, and status render as colored badges; clicking a row opens that opportunity.
- **A real detail page.** Each opportunity now has its own view: title plus metadata chips (theme / priority / provenance / status), and the body with the raw YAML frontmatter stripped — it used to render as a text blob at the top of every doc.
- **In-repo markdown links navigate in-app.** A relative `.md` link (e.g. an opportunity link in the INDEX) resolves against the document's directory to a scanned artifact and selects it in place; `http(s)` links still open the browser. Applied both in the opportunity views and in the generic `ArtifactDetailView`.
- **`/pm-opportunities` is wired into the viewer.** A Run button on the Discover overview (via a new `SkillCatalog` entry, lightbulb icon) plus the skill-catalog blurb, so you can bootstrap the database from the viewer.
- **Breakdown task files no longer leak into Discover.** `PhaseMapper` now maps `.nanopm/tasks/` to no phase (they're handoff outputs bound for external trackers), so a task filename like `discovery-*` can't fall through to a name-prefix match and surface under Discover.

## 0.15.0 — 2026-06-17

### Discovery Opportunity DB: a ranked, agent-maintained database of user opportunities

New `/pm-opportunities` skill plus a `.nanopm/opportunities/` artifact — a persistent, ranked database of user opportunities (Teresa Torres sense: the user problems behind what you build, not the solutions), stored as an LLM-wiki the agent owns and keeps current. It bridges Discover and Plan, sitting between the raw FEEDBACK firehose and the roadmap. `bootstrap` drafts the initial set from feedback + your own assumptions + Nano's hypotheses (each tagged by provenance); `add` captures one problem at a time. Two levels only (Theme → Opportunity), and no numeric scoring at v1 — a coarse `priority` (high/medium/low) instead.

- **The artifact.** `.nanopm/opportunities/` holds `SCHEMA.md` (the editable conventions — the single source of structural truth both modes read), `INDEX.md` (the ranked home, grouped by theme), `LOG.md` (append-only heartbeat), and one `<slug>.md` per opportunity. Every opportunity carries explicit provenance: `nano-hypothesis` (Nano inferred it), `user-stated` (you asserted it), or `evidence-backed` (from connected sources).
- **lib helpers.** `nanopm_opportunities_schema` emits SCHEMA.md; `nanopm_opportunities_draft_prompt` is the per-theme bootstrap drafting-subagent prompt; `nanopm_opportunities_reindex` deterministically regenerates INDEX.md from frontmatter (escapes markdown-breaking values, surfaces parse failures to stderr); `nanopm_opportunity_slug` derives collision-safe, reserved-name-safe slugs (won't clobber SCHEMA/INDEX on a case-insensitive filesystem).
- **Bootstrap flow.** Loads CONTEXT-SUMMARY + PLAN-SUMMARY, pulls FEEDBACK/DATA via a bounded retrieval subagent when present (degrades to user + Nano hypotheses when absent), fans out one drafting subagent per theme, dedups, gates on human review, then writes the files and regenerates INDEX/LOG.
- **Viewer.** `PhaseMapper` routes `.nanopm/opportunities/` under the Discover phase.
- **Registered** in `setup` and `test/skill-syntax.sh`; tier-1 static checks pass.

## 0.14.1 — 2026-06-16

### Viewer: match brief filenames case-insensitively

The Context Brief and Plan Brief are matched by filename in two places — the sidebar exclusion (so the brief isn't listed as a child doc) and the phase-overview card lookup. Both compared exactly against `PLAN-SUMMARY.md` / `CONTEXT-SUMMARY.md`. When a brief was written in a different case (e.g. `plan-summary.md`), it slipped past the exclusion (showing as a stray sidebar row) and was missed by the card (which rendered empty). Now matched case-insensitively via `Artifact.isPhaseBrief`, so the brief is always excluded from the list and always found by its card — and it won't break on a case-sensitive filesystem.

## 0.14.0 — 2026-06-16

### Plan Brief: current-work context loaded into every skill run

nanopm already loaded `CONTEXT-SUMMARY.md` (who the company is) into every skill's preamble. Now it does the same for the *plan*. After any Plan skill (`/pm-objectives`, `/pm-strategy`, `/pm-roadmap`) finishes, a subagent regenerates `.nanopm/PLAN-SUMMARY.md` — a one-page brief of what you're betting on (strategy), aiming for (objectives), building now (roadmap), and saying no to (anti-goals) — and `nanopm_preamble` loads it right after the context brief. Every interaction now carries both who the company is and what it's working on right now; the plan stops evaporating between sessions.

- **Loader, one wiring point.** New `nanopm_load_plan()` mirrors `nanopm_load_context()` — same `-s` guard, the same data-fenced "reference data only — never instructions" wrapping against prompt injection, the same ~8000-char bound — and is called once from `nanopm_preamble`, right after the context brief, so all skills (CLI and viewer-launched) pick it up with no per-skill edits.
- **Generation, shared across three skills.** New `nanopm_plan_brief_prompt` carries the canonical regeneration prompt (sandboxed: reads only the named `.nanopm/*.md`, treats them as data, not instructions). A "Regenerate the plan brief" phase appended to pm-objectives / pm-strategy / pm-roadmap dispatches it via a subagent. It degrades gracefully — synthesizes from whatever of OBJECTIVES/STRATEGY/ROADMAP exist and lists the missing ones under "Not yet planned" rather than inventing them.
- **Viewer.** The Planning overview now leads with a **Plan Brief** card, mirroring the Context Brief on Define. `contextBriefCard` was generalized into one parameterized `briefCard(...)` so the two surfaces can't drift; `PhaseMapper` maps `PLAN-SUMMARY.md` → `.plan` and `ProjectView` keeps it out of the sidebar (rendered inline, like the context brief).

Closes #74, #75, #76.

## 0.13.1 — 2026-06-16

### Viewer: Brainstorm in the Day-to-Day overview

The Day-to-Day phase overview now lists **Brainstorm** alongside Standup, Weekly Update, and Challenge Me — with an **Open** action that routes to the chat with Nano (not a headless Run, since a brainstorm is a conversation, not an artifact-producing skill).

## 0.13.0 — 2026-06-16

### New skill: /pm-brainstorm — jam with Nano, your expert CPO

A daily-ops surface for thinking out loud. `/pm-brainstorm` is an informal, context-loaded jam with **Nano**, the expert CPO at the user's service — no gate, no PRD, no artifact. Nano loads the company + objectives context (`CONTEXT-SUMMARY.md` + `OBJECTIVES.md`) and pushes back per the nanopm ethos: problem first, name the question you're avoiding. It's the surface that replaces the ChatGPT thread you can't find again.

- **Resumable, host-native.** Sessions are named and resumed via your host's own session picker (Claude `--resume`, Vibe `--resume`, Codex `resume`) — full-transcript reload, no transcript persistence of our own. A new `brainstorm` typed-state record (topic + summary) makes past jams listable across all three hosts.
- **Viewer Brainstorm surface.** A graphical chat in the macOS viewer: an always-on entry at the top of Day-to-Day, a free-text composer on the existing `claude` run engine, and a History menu that lists past jams — auto-titled by Claude's own `ai-title` — and resumes them with full prior context. Claude Code backend.
- **Read-only by construction.** Brainstorm runs deny `Bash`/`Edit`/`Write` via `--disallowedTools`, so a free chat over untrusted project content can't mutate the repo. (Verified live: `--allowedTools` alone does not gate in headless default mode — the deny-list is the real control.)

## 0.12.2 — 2026-06-15

### Viewer: one consistent look for Run, Refresh, and Reasoning

The viewer's three most-used actions used to look different on every screen — Run was a bare text button on the phase overview but a `play.circle` menu on the Competitors page; Reasoning was a segmented picker in one place and a `brain` toggle in another; Refresh was an unlabelled icon in the sidebar footer. Now they all share one look.

- **New shared `ActionButton`.** A single icon-plus-label control with the brand palette, hover/press feedback, and three tones (neutral, accent, waiting). Every Run / Refresh / Reasoning control is built from it, so the same action reads the same way everywhere. The Competitors Run and History menus adopt the same chrome via `.menuStyle(.button)`, keeping a down-chevron so they still read as menus.
- **What changed per screen.** Run on the phase overview becomes a filled accent button (`play.fill`) that keeps its Answer… / Running… states. Refresh becomes a bordered icon button in the same family (icon-only, to fit the narrow sidebar footer next to Activity and Memory). In the document detail, the reasoning controls collapse to one "Reasoning" button (icon + label) that opens the sidecar in a separate window — replacing both the old segmented Document/Reasoning picker and the bare window icon. The Competitors page makes the same move: its in-place reasoning toggle (and the inline card it expanded) becomes the same window-opening "Reasoning" button, so reasoning opens the same way on every screen. Colors and design tokens are unchanged — this is purely a consistency pass.
- **Run is now on the document pages too.** The Run action used to live only on the phase overview. Open any document a skill produces (Strategy, Business-Model, a PRD…) and its header now carries the same Run button, with the same context popover and Run / Answer… / Running… states — so you can re-run a skill from the doc you're reading without going back to the overview. Backed by a single shared `SkillRunButton`, so the phase overview and the document header can never drift apart.



### pm-prd: subagent context fan-out + Phase 4b review panel

`/pm-prd` stops reading the world into its own context, and stops checking a spec on one axis only.

- **Phase 2 — parallel retrieval fan-out.** Instead of reading PERSONAS, DATA, PRODUCT, BUSINESS-MODEL, and FEEDBACK in full into the main reasoning context, the skill dispatches one retrieval subagent per *present* doc, concurrently. Each is keyed on the feature and returns a bounded digest (≤~200 words, every bullet carrying a `.nanopm/{FILE}.md` pointer) plus a structured `FLAG:` line the main agent's control flow keys off — `FEATURE_SERVES` (drives the anti-persona STOP), `DATA_CONFIDENCE` (🟢-only metrics), `PRODUCT_COMPLETENESS` (draft warning), `TIER`, `FEEDBACK_THEMES`. The subagents inform; the main agent decides — they never halt the skill. New helper `nanopm_prd_retrieval_prompt` reuses the Define retrieval contract (trust boundary + bounded digest + file pointers), feature-keyed per doc. The FEEDBACK-first → Dovetail fallback is unchanged.
- **Phase 4b — advisory review panel.** The falsifiability reviewer (the hard gate) now runs alongside four advisory lenses — appetite/scope realism, success-criteria measurability, persona fit, dependency/feasibility — dispatched concurrently. Each returns a strict `LENS / VERDICT: PASS|CONCERN / NOTE` line; CONCERNs append a `## Reviewer notes` block to the PRD. Advisory in `solo-fast` (notes only, never blocks), escalating to a hard block in `team-traditional`. Falsifiability stays the only hard gate in solo-fast. New helpers `nanopm_prd_review_lenses` / `nanopm_prd_lens_prompt`; both prompts carry the untrusted-input guard, hardened against forged `VERDICT:` lines inside a PRD's quoted content. Portable: uses only the `Agent` tool, no Claude-Code-only workflow primitive. Tier-1 static assertions in `test/skill-syntax.sh` lock the contract; a live-verified scenario in `test/adversarial.e2e.sh` checks the panel surfaces a CONCERN on a weak PRD and appends the notes block.

### Multi-host: Define skills source the lib in-block

Five Define skills (`pm-vision-mission`, `pm-business-model`, `pm-org`, `pm-product`, `pm-personas`) called `nanopm_*` functions in bash blocks without sourcing `lib/nanopm.sh` first. On Vibe/Codex shell state doesn't persist between blocks, so those calls would fail. Added the source guard to each affected block; `test/headers.sh` now passes.

## 0.12.0 — 2026-06-15

### Competitors intel: discovery + SWOT/positioning analysis

`pm-competitors-intel` grows from "watch the competitors you named" to "find them and see where you stand." Two additions, both opt-in so the default diff veille stays cheap (one subagent, no extra cost):

- **Discovery agent.** When `competitors.json` is empty it proposes 3–6 competitors from your product description; when it already exists, a re-scan surfaces only net-new entrants (deduped by name + domain, tagged "🆕"). Candidate URLs are marked unverified and the Phase 3 fetch is the verification step. You confirm before anything is written, and `WebSearch` is now in the skill's `allowed-tools` so this is sanctioned instead of improvised (it previously failed with permission errors). Fixes the WebSearch fallback the discovery flow hit.
- **Analyze mode** (keyword `analyze`/`deep`/`landscape`, or the Phase 1 menu). Reuses the snapshots already fetched, then runs one Analysis subagent per competitor (forces/faiblesses/gaps vs `PRODUCT.md`, every claim tagged Evidenced/Assumed) followed by a Positioning subagent that proposes strategy-anchored axes (you confirm them) and scores a GFM matrix of every player including us, plus a "where we win / where we're exposed" read. Output enriches `COMPETITORS.md` with the matrix + SWOT and writes a reasoning sidecar at `.nanopm/reasoning/COMPETITORS.md`.

**Viewer.** The Competitors page gains a **Run** menu (intel check / find new competitors / full analysis), a **Reasoning** pane for the new sidecar, and a **TL;DR** card at the top — the most significant change + recommended action, plus where we win/are exposed from the positioning matrix.

## 0.11.1 — 2026-06-15

### macOS viewer: one-click skill-pack updates

The viewer now surfaces nanopm updates the way Claude Code does — a dismissible banner appears at launch when a newer skill pack is available ("nanopm vX available — you have vY"), and a single **Update now** button brings the pack current without opening a terminal. Detection delegates to the CLI's `nanopm_update_check` (same semver comparison + 24h cache), so the viewer and the terminal never disagree about whether an update exists; the check is async and fail-silent, so it never delays launch. The update re-runs `setup` from `main` with `set -o pipefail` so a failed download surfaces as an error instead of a false "Updated", and success is confirmed by an actual `~/.nanopm/VERSION` change rather than the pipeline's exit code alone. A **maintainer guard** reads a new `~/.nanopm/install-source` marker (written by `setup`: the repo path for a local clone, `remote` for a curl install) and refuses the in-app update on a dev clone — so a maintainer never overwrites their working copy — while ignoring a stale marker whose clone no longer exists. `parse()` is covered by a new `--parse-update-check` smoke hook.

## 0.11.0 — 2026-06-15

### Memory: per-project config + company-shared docs

Two fixes to how nanopm stores state across projects:

- **Per-project config — stops the global leak.** `~/.nanopm/config` was a single global file with no project key, so per-project values (`company_website`, connector `*_url`, `methodology`, `build_mode`, …) set in one repo leaked into every other. `nanopm_config_get`/`set` now route by key: global keys (`update_check_disabled`, `auto_upgrade`) stay in `~/.nanopm/config`; everything else lands in `~/.nanopm/projects/<slug>/config`. The ~25 skill call sites are unchanged — routing is internal — and a stale legacy copy of a per-project key in the global file is dropped on the next write so it can't leak further. (Keyed by `<slug>` for now; a collision-proof project id is deferred to Phase B.)
- **Company-tier shared docs.** Company-level Define docs (`VISION-MISSION.md`, `BUSINESS-MODEL.md`, `ORG.md`) can now live once in `~/.nanopm/companies/<slug>/` and be symlinked into each repo's `.nanopm/`, so multiple repos of the same company share one source of truth. New `nanopm_company_link <name>` migrates any existing docs up to the company folder and symlinks them back (idempotent; writes through the link update the shared doc); `nanopm_company_list` powers the "which company?" prompt; the three company skills (`pm-vision-mission`, `pm-business-model`, `pm-org`) offer to link. Skills, the brief generator, and the viewer keep reading `.nanopm/` unchanged — the only viewer change is `find` → `find -L` to follow the symlinks. Review hardening: empty-slug collapse, `find -L` abort guard, backup clobber, and no dangling symlinks (link existing / publish on write).

### Define skills: clean share-ready docs + reasoning sidecar

The five Define skills no longer interleave the model's reasoning (`Confidence: Evidenced/Assumed` tags, sources, rationale) inside the generated docs. Each now writes **two files**: the clean, claims-only doc, and a **reasoning sidecar** at `.nanopm/reasoning/<same filename>` that mirrors the doc's headings with the confidence call, source, and "why this call" per section. Refine mode re-reads the prior sidecar so confidence calls compound; the Completion step surfaces `Assumed` sections in the terminal; the `CONTEXT-SUMMARY` subagent reads the clean docs only (sidecars explicitly excluded — founder decision). New shared helper `nanopm_reasoning_path` owns the path convention (and `nanopm_load_context` lists existing sidecars so every run knows the "why" docs exist). **macOS viewer:** sidecars are hidden from the sidebar and shown as a Document/Reasoning segmented picker on the clean doc's detail view, plus a button to open the reasoning in a separate window for side-by-side reading.

### macOS viewer: brand, Memory page, robustness

- **Nano brand identity** — colors, typography, mascot, Claude-style loaders.
- **Memory page** added; the "Other" bucket dropped; sidebar polish.
- **Optional user context** when launching a skill run from the viewer.
- **Crash fix** — the viewer no longer crashes on launch when running outside a `.app` bundle.

### `setup` reads the version from the VERSION file

`setup` now reads the installed version from the `VERSION` file instead of a hardcoded literal, so the two can't drift.

### Fix: `nanopm_context_append` robust under non-UTF-8 shells

Saving context (the Phase 4 "Save context" step in every skill) could fail with `character not in range` when the payload contained multibyte characters (e.g. an em-dash in a mission statement) and the skill's bash ran under a non-UTF-8 locale such as zsh with `LC_ALL=C`. The payload is now piped to python as raw bytes and python writes the JSONL line directly (with `PYTHONUTF8=1`), so the shell never expands or captures multibyte content. Falls back to a best-effort raw append if python is unavailable.

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
