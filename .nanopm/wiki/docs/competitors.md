---
type: doc
skill: pm-competitors-intel
provenance: evidence-backed
generated: 2026-06-24
sources: [competitors.json, intel snapshots]
---

# Competitive Landscape
Last updated by /pm-competitors-intel (analyze mode) on 2026-06-15
Project: nanopm

---

## ChatPRD

**Website:** https://www.chatprd.ai
**Monitored pages:**
- Changelog: https://www.chatprd.ai/changelog *(fetch failed 2026-06-15 — 404, same as 2026-06-10; URL needs replacement)*
- Pricing: https://www.chatprd.ai/pricing *(fetched 2026-06-15)*
- Homepage: https://www.chatprd.ai *(fetched 2026-06-15)*

**Latest notable change:** Integrations expanded to the AI-builder stack — v0, Granola, Bolt, Lovable, Replit, Cursor added (was 8+ tools; now "12+ connections"). New case-study claims: "3x doc quality" and "~50% less time on PRDs (LaunchDarkly)". Pricing unchanged.

**Strategic note:** The most direct AI-PM competitor by intent. By integrating with the AI-builder stack (v0/Bolt/Lovable/Replit) ChatPRD is positioning itself for the prosumer no-code-AI-builder PM — closer to nanopm's aspirational "Designer-founder Dani" than to "Terminal-native Theo". If Dani is ever promoted to primary persona, this is the head-to-head fight.

---

## Linear

**Website:** https://linear.app
**Monitored pages:**
- Changelog: https://linear.app/changelog *(fetched 2026-06-15)*
- Agents API: https://linear.app/developers/agents *(fetched 2026-06-15)*
- Pricing: https://linear.app/pricing *(fetched 2026-06-15)*
- Agents landing: https://linear.app/agents *(fetched 2026-06-15)*

**Latest notable change:** **Coding Sessions in Linear (2026-06-11)** — Linear Agent writes code via Claude Code and Codex inside the platform, consuming AI credits. Combined with Diffs (code review in-app), Code Intelligence (codebase access for agents), Shared Skills, and MCP support, Linear now runs the end-to-end workflow from ticket → code → review without leaving the platform. Pricing unchanged ($10/$16 Business).

**Strategic note:** The structural threat the 2026-06-10 run flagged is now active product. The nanopm → Linear handoff (`/pm-breakdown`) is inverting: Linear is the orchestration surface calling into Claude Code (where nanopm runs). STRATEGY.md needs an explicit answer to "what does nanopm do that Linear's Agent + Coding Sessions + Skills + Code Intelligence stack cannot?" — and that answer likely has to live in Define-phase work, not breakdown-to-ship.

---

## Cursor

**Website:** https://cursor.com
**Monitored pages:**
- Changelog: https://cursor.com/changelog *(fetched 2026-06-15)*
- Docs: https://cursor.com/docs *(fetched 2026-06-15)*
- Pricing: https://cursor.com/pricing *(fetched 2026-06-15)*
- Features: https://cursor.com/features *(fetched 2026-06-15)*

**Latest notable change:** No new versioned changelog entries since 2026-06-10. **Marketplace** and **Design Mode** promoted to first-class named features on the features page; multi-model lineup now names versions (GPT-5.5, Opus 4.8, Gemini 3.1 Pro, Grok 4.3). Pricing tier sub-bundles (Pro/Pro+/Ultra, Standard/Premium) collapsed — packaging simplification. Skills/MCP/Hooks remain Individual+ entitlements.

**Strategic note:** Cursor continues to commoditize the "skill pack distribution" model — the Teams marketplace for internal rules/skills/plugins is now first-tier marketing. The Composer planning loop and Cloud Agents reproduce the `/pm-prd → /pm-breakdown` sequence from inside the coding agent surface. nanopm's moat must be (a) the Define phase that runs before code agents start, and (b) the adversarial gate that refuses to ship a non-falsifiable bet — neither of which Cursor ships.

---

## GitHub Spec Kit

**Website:** https://github.com/github/spec-kit
**Monitored pages:**
- Homepage / README: https://github.com/github/spec-kit *(baseline captured 2026-06-15)*

**Latest notable change:** *Baseline captured. Diff available on next run.* ~112,000 stars, MIT, packaged CLI (`specify-cli` via uv), supports 30+ AI agents. Workflow: Constitution → Specify → Clarify → Plan → Tasks → Implement, with extensions/presets/template overrides and task-to-GitHub-Issues conversion.

**Strategic note:** The 4,000×-larger incumbent in nanopm's exact philosophical territory — same multi-phase, multi-agent skill-pack shape, but engineering-led. Spec Kit assumes you already know what to build (the spec is the start); nanopm's Define→Discover phases (vision/business model/personas/feedback/intel) and the falsifiable-bet gate are the wedge — Spec Kit has neither.

---

## BMad Method

**Website:** https://docs.bmad-method.org
**Monitored pages:**
- Docs home: https://docs.bmad-method.org *(baseline captured 2026-06-15)*

**Latest notable change:** *Baseline captured. Diff available on next run.* v6 release with documented upgrade path; supports Claude Code, Cursor, GitHub Copilot, plus any tool with custom-system-prompt support; named PM/Architect persona agents; explicit "Adversarial Review" phase; extensible via BMad Builder + module marketplace; verticals into Creative Intelligence Suite and Game Dev Studio.

**Strategic note:** The closest conceptual analogue to nanopm's skill-pack shape: multi-phase, multi-agent, full-SDLC. Its "Adversarial Review" phase is named but the gating criteria are not specified; nanopm's gate is concrete (segment + behavior + metric + timeframe) and refusal-based. License and pricing are not publicly disclosed — a legal-clarity differentiator nanopm should keep loud.

---

## PM Skills 2.0 (productcompass / phuryn)

**Website:** https://www.productcompass.pm/p/pm-skills-2-red-team-ship (catalog page; repo `phuryn/pm-skills`)
**Monitored pages:**
- Catalog page: https://www.productcompass.pm/p/pm-skills-2-red-team-ship *(baseline captured 2026-06-15)*

**Latest notable change:** *Baseline captured. Diff available on next run.* 9 plugins / 68 skills / 42 commands across discovery → strategy → execution → shipping; supports Claude Code, Claude Cowork, Codex CLI, Cursor, Gemini CLI, OpenCode, Kiro (7 hosts); marketplace-native install (`claude plugin install`, GitHub marketplace); MIT; includes shipped-code quality skills (`/security-audit-static`, `/performance-audit-static`, `/derive-tests`).

**Strategic note:** The most direct head-to-head on the "PM skill pack for AI coding agents" wedge — same intent, ~3× the surface area, 7 hosts vs nanopm's 3, marketplace-native distribution. The differentiator nanopm needs to defend: (a) pipeline-compounding typed JSONL state vs plugin-style independent skills, (b) a hard refusal-based adversarial gate vs a callable `/red-team-prd` command, and (c) the Define-phase artifacts (vision/business-model/org/personas) absent from PM Skills' surface.

---

## Positioning matrix

*Dimensions (provenance below in the reasoning sidecar) · Scored 1–5 (1 = weak, 5 = strong) · Generated 2026-06-15*

| Dimension | nanopm | ChatPRD | Linear | Cursor | Spec Kit | BMad | PM Skills |
|---|---|---|---|---|---|---|---|
| PM-layer depth | 5 | 3 | 1 | 1 | 2 | 4 | 3 |
| Adversarial / falsifiability gate | 5 | 1 | 1 | 1 | 1 | 3 | 2 |
| Host-neutrality / multi-agent portability | 4 | 2 | 2 | 1 | 5 | 3 | 5 |
| Typed compounding state | 5 | 2 | 2 | 3 | 2 | 2 | 1 |
| Distribution / install base | 1 | 5 | 5 | 5 | 5 | 3 | 2 |

**Where we win:** nanopm scores highest on PM-layer depth, adversarial / falsifiability gate, and typed compounding state.
**Where we're exposed:** nanopm is most out-scored on distribution / install base (by ChatPRD, Linear, Cursor, and Spec Kit) and on host-neutrality (by Spec Kit and PM Skills).

---

## Forces / weaknesses / gaps

### ChatPRD
**Strengths:** Massive distribution and social proof (100,000+ PMs, 750,000+ docs, 4.5★); documented enterprise ROI (LaunchDarkly ~50% less time, 3x quality); paid commercial business with clear tiers ($15 Pro / $29 Teams / Enterprise); built-in team collaboration (shared workspaces, real-time collab, comments, custom personas); enterprise controls (SSO, dedicated support, data controls); broad integration surface (Linear, Notion, Slack, Google Drive, Confluence, GitHub, plus v0/Bolt/Lovable/Replit/Cursor); zero-install hosted SaaS; premium AI models bundled.
**Weaknesses:** Free tier heavily gated (3 chats); changelog 404s on two consecutive fetches; Linear integration paywalled behind Teams ($29/seat); positioning centers on docs (PRDs, one-pagers, user stories) and coaching, not full PM lifecycle.
**Gaps vs us:** They have hosted SaaS, paying customers, enterprise controls, team collab, AI-builder integrations, and a published quantified case study — we don't. We have a compounding multi-phase pipeline with typed JSONL state, an adversarial gate refusing non-falsifiable bets, multi-host portability across Claude/Vibe/Codex, code-grounded reading from the repo, and a SwiftUI macOS viewer — they don't.

### Linear
**Strengths:** Native in-app coding agent shipped 2026-06-11 (Claude Code + Codex inside Linear); first-class Agent platform across all tiers including Free; structured Agent Sessions API with Thought activity, Delegate model, OAuth2 actor=app; 11 named third-party agent integrations live; native code review (Linear Diffs); Slack-native agent surface; MCP support; Code Intelligence (controlled codebase access); auto-generated release notes; "shared skills" as a tracker primitive; SAML/SCIM on Enterprise; mature brand and install base.
**Weaknesses:** Core PM upstream work (vision, personas, discovery, OKRs, strategy, roadmap, PRD) absent from the surface; agent scoped to ticket-shaped objects; coding sessions metered ("AI credits required across all tiers"); key features gated to Business+; free tier capped at 2 teams / 250 issues.
**Gaps vs us:** They have a native in-app coding agent, native code review, Slack-native execution, a published Agent Sessions API, CI/CD release tracking, and Teams + Slack surfaces — we don't. We have 21 PM skills spanning Define → Discover → Plan → Build, adversarial falsifiability gates, compounding typed-JSONL state, and we hand off TO Linear via `/pm-breakdown` — Linear doesn't hand off upstream from any PM-planning tool, the upstream artifacts simply don't exist in its model.

### Cursor
**Strengths:** Owns the coding agent surface (Agents, Composer, Tab, Cloud Agents); enterprise governance (SOC 2, SAML/OIDC, audit logs, AI code tracking); first-party multi-model access (GPT-5.5, Opus 4.8, Gemini 3.1 Pro, Grok 4.3); Codebase Indexing (semantic index at scale); Bugbot automated PR review (~90s after Jun 10 perf update); Cloud Agents for parallel remote execution; Design Mode + Canvas; SDK (TS + Python) with custom tools, auto-review routing, JSONL persistence, nested subagents; public Marketplace + internal team marketplace for rules/skills/plugins; Slack integration; paid tiers ($20 Individual / $40 Teams / Enterprise).
**Weaknesses:** No PM-layer artifacts in docs nav or features page (vision/mission, OKRs, strategy, roadmap, PRD absent); host-locked — features only run inside Cursor; pricing gates the core loop; "Skills" is a first-party concept but scoped to coding capabilities, not a PM pipeline; no falsifiable-bet gate; no macOS-native viewer for PM artifacts.
**Gaps vs us:** They have a first-party SDK with nested subagents + JSONL persistence, Cloud Agents, Codebase Indexing, Bugbot, Design Mode + Canvas, Enterprise Organizations, a public Marketplace, and native Slack integration — we don't. We have host-neutral skill packs across 3 agents, an end-to-end PM pipeline (Define → Discover → Plan → Build), an adversarial gate refusing non-falsifiable strategy/roadmap/PRD, schema-validated typed JSONL state for PM artifacts, a reasoning-sidecar pattern, and a SwiftUI macOS viewer — they don't.

### GitHub Spec Kit
**Strengths:** Massive distribution lead (~112,000 stars vs nanopm's 27); backed by GitHub/Microsoft; supports 30+ AI agents out of the box (Copilot, Claude Code, Gemini CLI, Cursor, Codex, Qwen, opencode, Tabnine, Kiro, Pi, Forge, Goose, Mistral Vibe, more); proper packaged CLI (`specify-cli` via `uv`, Python 3.11+, cross-platform); extensions system, presets, and project-local template overrides; native task-to-GitHub-Issues conversion; parallel execution markers + TDD structure built into Tasks/Implement.
**Weaknesses:** Workflow starts at Constitution → Specify with no Define phase (no vision, business model, org, personas, audit); no discovery layer (no user-feedback, interview, data, or competitive-intel skills); no PM planning layer (no objectives/OKRs, strategy, or roadmap as artifacts — "Plan" is implementation planning); no adversarial/falsifiable-bet gate described; no connector ecosystem beyond GitHub Issues; no GUI/viewer.
**Gaps vs us:** They have the full Constitution → Specify → Clarify → Plan → Tasks → Implement engineering workflow with parallel markers + TDD, native GitHub Issues conversion, an extensions/presets/template-overrides system, a packaged CLI, 30+ AI agent support, and 112k stars — we don't. We have a Define phase, a Discover phase, a Plan phase with OKRs/strategy/roadmap/PRD as distinct artifacts, an adversarial falsifiability gate with concrete criteria, 16 PM-tool connector specs with 4-tier fallback, a SwiftUI viewer, schema-validated typed JSONL state, daily ops skills, and reasoning sidecars — they don't.

### BMad Method
**Strengths:** Full SDLC coverage (ideation → agentic implementation), broader than nanopm's PM scope; mature product line with explicit v6 release and upgrade path; supports Claude Code, Cursor, GitHub Copilot, plus "any tool supporting custom system prompts or project context"; extensible via BMad Builder, module marketplace, custom/community modules; named persona agents (PM, Architect); explicit Adversarial Review phase as a first-class workflow; vertical extensions (Creative Intelligence Suite, Game Dev Studio integration); document sharding + project context management; interactive `bmad-help` setup.
**Weaknesses:** License not disclosed on the page (legal ambiguity for enterprise adopters); pricing not disclosed (unclear commercial model); workflow names ("Party Mode," "Forensic Investigation," "Quick Dev") evocative but non-self-describing; no typed/schema-validated state evidence; no falsifiable-bet criteria specified for the Adversarial Review; no native data connectors visible; no GUI/viewer.
**Gaps vs us:** They have multi-assistant reach via "any system-prompt tool", a module marketplace + Builder for custom modules, full SDLC coverage through agentic implementation, vertical extensions, and named persona agents — we don't. We have a published MIT OSS license, 16 documented connector specs (Linear, GitHub, Notion, Dovetail, PostHog, Amplitude, Granola...), schema-validated typed JSONL state compounding across the pipeline, a falsifiable-bet gate with specified criteria (segment + behavior + metric + timeframe) that actually blocks downstream skills, a SwiftUI macOS viewer, and a Define phase producing a consolidated CONTEXT-SUMMARY — they don't (or it isn't visible on the docs surface).

### PM Skills 2.0 (productcompass)
**Strengths:** Broader raw surface area (9 plugins, 68 skills, 42 commands — ~3× nanopm's 21); wider host coverage (7: Claude Code, Claude Cowork, Codex CLI, Cursor, Gemini CLI, OpenCode, Kiro vs nanopm's 3); marketplace-native install (GitHub marketplace + `claude plugin install` + Claude Cowork "Browse plugins" UX); shipped-code quality skills (`/security-audit-static`, `/performance-audit-static`, `/derive-tests`, `/ship-check`); a dedicated `intended-vs-implemented` skill closing the spec-vs-shipped loop; "red-team" framing more legible to PMs than "falsifiable bet"; MIT.
**Weaknesses:** No explicit Define phase artifacts in the snapshot (no vision-mission, business-model, org, personas); no typed-state / schema-validated JSONL — skills look like prompts, not a compounding state machine; no connector ecosystem advertised (no Linear/Notion/Dovetail/PostHog/Amplitude/Granola); no GUI / viewer; skills appear independent plugin-style rather than pipeline-compounding; `/red-team-prd` is a callable command, not a refusal mechanism; no user-research ingestion path; same pre-PMF profile (free MIT OSS, unknown traction).
**Gaps vs us:** They have marketplace-native install across 7 hosts, shipped-code quality and test-derivation skills, and ~3× the raw skill count — we don't. We have a Define phase, typed JSONL state with schema validators driving compounding, 16 connector specs with MCP → API → browser → manual fallback, a hard adversarial gate refusing strategy/roadmap/PRD without segment+behavior+metric+timeframe, a dedicated quantitative-data skill (`/pm-data` on PostHog/Amplitude), user-research ingestion (`/pm-interview`, `/pm-user-feedback`), a SwiftUI macOS viewer, and a daily-ops cadence (`/pm-standup`, `/pm-weekly-update`) outside the pipeline — they don't.

---

*Run /pm-competitors-intel to refresh.*

## Provenance & assumptions

Generated by /pm-competitors-intel (analyze mode) on 2026-06-15

## Positioning axes — provenance

| Axis | Provenance | Why this axis |
|---|---|---|
| PM-layer depth | `.nanopm/PRODUCT.md` (Surface Area & Main Features: Define → Discover → Plan → Build) | The whole nanopm shape is its four-phase coverage upstream of code. If a competitor only ships "Plan" or "Specify," that's the structural gap to measure. |
| Adversarial / falsifiability gate | `.nanopm/STRATEGY.md` "How We Win" #3 ("Adversarial gates + schema-validated typed state remain the rigor underneath") + `.nanopm/PRODUCT.md` technical bets | nanopm's stated moat: a hard gate refusing strategy/roadmap/PRD without a falsifiable bet (segment + behavior + metric + timeframe). A "red-team command" that doesn't block downstream work scores lower than a refusal. |
| Host-neutrality / multi-agent portability | `.nanopm/PRODUCT.md` technical bets ("Multi-host portability (Claude / Vibe / Codex)") | One of nanopm's load-bearing claims; the ongoing maintenance tax (portability-v2 headers, Vibe subshell handling) is paid against this axis. |
| Typed compounding state | `.nanopm/PRODUCT.md` technical bets ("Typed cross-session state is the durable value") + `.nanopm/STRATEGY.md` #3 | Schema-validated JSONL state that the next skill reads. nanopm's strategy declared the typed-memory bet "dead" in v0.7.0 but the architecture still leans on it — so it must show on the matrix. |
| Distribution / install base | `.nanopm/STRATEGY.md` baseline + `.nanopm/BUSINESS-MODEL.md` Unit Economics Signals | Reach and adoption signal. nanopm is pre-PMF (27 stars, 1 fork, 0 retention measured); the axis must exist because the other four are claims nobody has adopted yet. |

User-confirmed in this run as "Use these 5 axes". No user edits applied.

## Scoring rationale

Each cell is justified below. Where a score reflects an Evidenced bullet from the SWOT ledger, the bullet is referenced. Where a score reflects an Assumed bullet, that is called out.

### PM-layer depth (1 = none, 5 = end-to-end Define→Build)

- **nanopm = 5** — 21 skills spanning vision-mission, business-model, org, product, personas, audit, user-feedback, interview, data, competitors-intel, objectives, strategy, roadmap, PRD, breakdown, retro, plus daily ops (PRODUCT.md surface area).
- **ChatPRD = 3** — "AI Documentation (PRDs, one-pagers, user stories)" + "AI Coaching (CPO-level reviews and gap analysis)" plus team collab; the SWOT weakness bullet "framing centers on docs… not full PM lifecycle" caps the score below 5.
- **Linear = 1** — SWOT weakness: "Core PM upstream work (vision, personas, discovery, OKRs, strategy, roadmap, PRD) absent from the changelog and pricing tiers". Linear's surface is tickets/diffs/releases — no upstream PM artifacts.
- **Cursor = 1** — SWOT weakness: "No PM-layer artifacts in docs top-level (Agent, Rules, MCP, Skills, CLI) or features page — vision/mission, OKRs, strategy, roadmap, PRD, retro are absent."
- **Spec Kit = 2** — Workflow starts at Constitution → Specify. SWOT weakness: "no Define phase covering vision, business model, org, personas, or audit before specs begin… no discovery layer… no planning layer in the PM sense — no objectives/OKRs, strategy, or roadmap skills; the 'Plan' phase is implementation planning, not product strategy." Constitution offers something for principles, hence 2 not 1.
- **BMad = 4** — Phases include Analysis, Brainstorming, Advanced Elicitation, Solutioning, plus named PM/Architect agents and "Adversarial Review" — full SDLC framing through implementation. Capped at 4 because typed-state evidence is absent (Assumed: "no evidence of typed/schema-validated state between phases — handoff likely prose-only") and Define-phase artifacts are not enumerated.
- **PM Skills = 3** — Covers discovery, strategy & assumption mapping, execution & roadmap planning, shipping. Skills: strategy-red-team, shipping-artifacts, intended-vs-implemented, /discover, /strategy, /write-prd. SWOT weakness: "No explicit Define phase artifacts (vision-mission, business-model, org, personas) visible in snapshot."

### Adversarial / falsifiability gate (1 = none, 5 = hard refusal on segment+behavior+metric+timeframe)

- **nanopm = 5** — adversarial gates refuse strategy/roadmap/PRD without a falsifiable bet (PRODUCT.md + STRATEGY.md).
- **ChatPRD = 1** — "AI Coaching / CPO-level reviews" is mentioned but is advisory, not a refusal mechanism. No falsifiability criteria evidenced.
- **Linear = 1** — SWOT weakness: "No adversarial/falsifiability gating before tickets get created — Linear Asks templates issues from Slack with no PM rigor in between."
- **Cursor = 1** — SWOT weakness: "No evidence of an adversarial reviewer gate refusing work without a falsifiable bet — the closest is Bugbot, which reviews code not strategy."
- **Spec Kit = 1** — SWOT weakness: "No adversarial/falsifiable-bet gate is described in the workflow — Specify → Clarify → Plan assumes the spec is the right thing to build."
- **BMad = 3** — explicit "Adversarial Review" phase as a first-class workflow ([E] strength bullet). Score capped at 3 because the gating criteria are not specified ([A] weakness: "criteria not specified on the page") — nanopm's segment+behavior+metric+timeframe contract is concrete; BMad's is named but unspecified.
- **PM Skills = 2** — `/red-team-prd` exists, "attacks live assumptions before launch; ranks risks by impact, likelihood, and testability". SWOT weakness: it is "a callable command, not a refusal mechanism" — does not block downstream skills. Hence 2, not 3.

### Host-neutrality / multi-agent portability (1 = single host, 5 = broad multi-host coverage)

- **nanopm = 4** — Claude Code + Mistral Vibe + OpenAI Codex (3 hosts, per PRODUCT.md). Strong but not the broadest in the field.
- **ChatPRD = 2** — Hosted SaaS web product; not an AI-agent skill pack. Integrates downstream into many tools (Linear, Notion, Cursor, v0, Bolt, Lovable, Replit) — that's downstream connectivity, not multi-host runtime. Score 2 reflects that it runs in the browser independent of any agent host.
- **Linear = 2** — Hosted SaaS. Integrates with 11 named agent partners ([E] strength bullet) and supports MCP, but its product runs on Linear's infrastructure. Same logic as ChatPRD.
- **Cursor = 1** — SWOT weakness: "Host-locked: features (Composer, Tab, Cloud Agents, Bugbot) only run inside Cursor — a Claude Code / Mistral Vibe / OpenAI Codex user can't adopt them without switching IDE."
- **Spec Kit = 5** — "30+ supported AI agents (Copilot, Claude Code, Gemini CLI, Cursor, Codex, Qwen, opencode, Tabnine, Kiro, Pi, Forge, Goose, Mistral Vibe, others)" — the broadest host coverage of any player.
- **BMad = 3** — Claude Code, Cursor, GitHub Copilot, plus "any tool supporting custom system prompts or project context." Broader than nanopm's 3 named hosts but vaguer than Spec Kit's enumerated 30+.
- **PM Skills = 5** — Claude Code, Claude Cowork, Codex CLI, Cursor, Gemini CLI, OpenCode, Kiro (7 enumerated hosts) plus marketplace-native install. Tied with Spec Kit at the top.

### Typed compounding state (1 = none, 5 = schema-validated state compounding across sessions)

- **nanopm = 5** — schema-validated JSONL state, the next skill reads the prior's typed record (PRODUCT.md technical bet; STRATEGY.md "How We Win" #3).
- **ChatPRD = 2** — "Projects with saved knowledge" exists (pricing tier listing) but is workspace-shaped, not schema-validated typed state compounding across a pipeline. Hence 2.
- **Linear = 2** — Agent Sessions API with structured Activities ([E] strength bullet) is a typed primitive but scoped to ticket lifecycle, not PM-artifact compounding. Hence 2.
- **Cursor = 3** — SDK Updates Jun 4 explicitly ship "JSONL and custom store persistence" with nested subagents ([E] strength bullet). That is typed-ish persistence at the SDK layer, though scoped to agent tool runs, not PM artifacts. Highest among non-nanopm players, hence 3.
- **Spec Kit = 2** — Phases (Constitution → Specify → Clarify → Plan → Tasks → Implement) are sequenced but [A] "the snapshot describes a linear phase flow but not a typed compounding state contract." Templates + presets exist, but no JSONL/schema evidence.
- **BMad = 2** — Document Sharding + Project Context management are evidenced but [A] "No evidence of typed/schema-validated state between phases — handoff likely prose-only."
- **PM Skills = 1** — SWOT weakness: "No visible typed-state / schema-validated JSONL — skills look like prompts, not a compounding state machine… skills appear independent plugin-style." Lowest score.

### Distribution / install base (1 = pre-PMF, 5 = market leader)

- **nanopm = 1** — STRATEGY.md baseline: 27 stars · 1 fork · 0 external issues · 0 retention measured. Pre-PMF by the doc's own framing.
- **ChatPRD = 5** — "Trusted by 100,000+ PMs"; 750,000+ docs; 4.5★; paid commercial business with quantified case study (LaunchDarkly).
- **Linear = 5** — Mature SaaS, 11 named agent partners, broad enterprise install base.
- **Cursor = 5** — "SOC 2, 40,000+ engineers at scale" ([E] strength bullet); paid Individual/Teams/Enterprise tiers; cadence of June 2026 releases implies a large org.
- **Spec Kit = 5** — ~112,000 stars; backed by GitHub/Microsoft. Largest install base on the matrix.
- **BMad = 3** — v6 release with documented upgrade path + module marketplace ([E]) implies an established community, but no quantified install figures in the snapshot. Lower than the 5-graders, higher than pre-PMF.
- **PM Skills = 2** — 9 plugins / 68 skills / 42 commands ([E]) and marketplace-native install ([E]), but no install-base figures in the snapshot. Above nanopm's hand-built `setup` distribution, below the established players.

## SWOT evidence ledger

The full tagged bullets from the Analysis subagents, preserving [E] / [A] tags and inline proof. The clean COMPETITORS.md carries claims only; this ledger carries the "why."

### ChatPRD

**STRENGTHS**
- [E] Massive distribution and social proof: "Trusted by 100,000+ PMs", 750,000+ docs, 4.5★ — vs nanopm's 27 GitHub stars
- [E] Documented enterprise validation: LaunchDarkly case study claims "~50% less time on PRDs" and "3x improvement in doc quality scores"
- [E] Paid commercial business with clear monetization tiers ($15 Pro / $29 Teams / Enterprise) — nanopm is free MIT with no revenue
- [E] Team collaboration built in: shared workspaces, real-time doc collab, comments, custom AI personas, centralized billing, admin controls
- [E] Enterprise-readiness signals: SSO, dedicated support, data controls on Enterprise tier
- [E] Broader downstream integration surface shipped today: Linear, Notion, Slack, Google Drive, Confluence, GitHub, Granola plus AI-builder stack (v0, Bolt, Lovable, Replit, Cursor) — "12+ tool connections"
- [E] Zero-install hosted SaaS web product accessible to PMs without an agent runtime — covers nanopm's explicit anti-persona
- [E] Premium model access bundled (GPT-4o, Claude, o1) without user bringing their own
- [A] Likely lower time-to-first-value: open browser, type, get a PRD — vs cloning a repo and running setup
- [A] Brand recognition in the PM community is already established, reducing CAC

**WEAKNESSES**
- [E] Free tier is heavily gated: only "3 chats limited" — friction for evaluation
- [E] Changelog endpoint 404s on two consecutive fetches (2026-06-15, 2026-06-10) — public release cadence is opaque or broken
- [E] Linear integration paywalled behind Teams ($29/seat) — solo PMs on Pro can't connect to their tracker
- [E] Positioned as "AI product manager" / documentation tool — framing centers on docs (PRDs, one-pagers, user stories) and coaching, not the full PM lifecycle
- [A] Hosted SaaS means customer data (PRDs, strategy, roadmap) lives on ChatPRD's servers — a blocker for security-sensitive orgs
- [A] No evidence of code-aware grounding: a web chat product likely cannot read the user's repo directly
- [A] Per-seat pricing scales poorly for whole-team rollout vs a free OSS alternative
- [A] Lock-in risk: docs and "saved knowledge" live in their workspace, not in the user's repo

**GAPS_VS_US**
- [E] They have a hosted web product with 100k+ users; we don't — we require an agent runtime (Claude Code / Vibe / Codex)
- [E] They have paying customers and revenue tiers; we don't — nanopm is free MIT pre-PMF
- [E] They have team collaboration (shared workspaces, real-time collab, comments, custom personas); we don't
- [E] They have enterprise controls (SSO, admin, data controls); we don't
- [E] They have a public case study with quantified ROI (LaunchDarkly, ~50% less time); we don't — "0 retention measured"
- [E] They have AI-builder integrations (v0, Bolt, Lovable, Replit, Cursor); we don't list these as connectors
- [E] They have Confluence integration; we don't (our 16 connectors don't include it)
- [E] We have a compounding multi-phase pipeline (Define → Discover → Plan → Build) with typed JSONL state across sessions; they appear chat/doc-centric with "saved knowledge" projects but no equivalent phased pipeline
- [E] We have adversarial subagent gates that refuse strategy/roadmap/PRD without a falsifiable bet (segment + behavior + metric + timeframe); they offer "AI Coaching / CPO-level reviews" but no described hard-gate mechanism
- [E] We have multi-host portability across Claude / Vibe / Codex; they are a single hosted product
- [E] We have a code-grounded read (skills read the codebase) plus a SwiftUI macOS viewer; they have neither — their surface is web + integrations
- [E] We have a 4-tier connector fallback (MCP → API → browser → manual); they list integrations but no described fallback model
- [E] We have an open-source MIT codebase users can fork and modify; they don't — closed SaaS
- [A] They likely have a polished onboarding/UX layer; we don't — ours is CLI + markdown
- [A] They likely have analytics on doc usage to justify the "3x quality" claim; we explicitly have "0 retention measured"

### Linear

**STRENGTHS**
- [E] Native code-writing agent inside the product (Jun 11, 2026 changelog: "Linear Agent writes code using Claude Code and Codex inside the platform") — execution loop is in-app, not just handoff
- [E] First-class Agent platform across all pricing tiers including Free (pricing: "Agent platform, Linear Agent beta" listed on $0 tier)
- [E] Structured agent primitives in the API: Agent Sessions, Agent Session Events, Agent Activities, Thought activity with 10s ack, Delegate model, OAuth2 actor=app
- [E] 11 named third-party agent integrations already live (OpenAI Codex, Cursor, GitHub Copilot, Sentry, Devin, ChatPRD, Oz by Warp, Factory, Charlie, Ranger, Tembo)
- [E] Native code review surface (May 28: "Linear Diffs... agents iterate while humans review") — closes the loop between ticket and merged code
- [E] Slack-native agent surface (May 21: "Project Slack Channels — Linear Agent answers/executes in Slack"; "Linear Asks Agent... @Linear Asks → templated issues")
- [E] MCP support shipped (Apr 23) — same protocol nanopm-host agents speak
- [E] Controlled codebase access for agents (May 14: "Code Intelligence — agents get controlled codebase access")
- [E] Release tracking with agent-generated release notes (Apr 30: "Releases — CI/CD tracking; agents generate release notes")
- [E] Team Documents as "shared skills for agent standardization" (Jun 4) — Linear shipping its own skill-like primitive inside the tracker
- [A] Mature enterprise posture (SAML/SCIM on Enterprise tier listed) and a paid distribution channel nanopm lacks
- [A] Brand + install base + funded team vs. nanopm's 27 stars and pre-PMF status

**WEAKNESSES**
- [E] Core PM upstream work (vision, personas, discovery, OKRs, strategy, roadmap, PRD) is absent from the changelog and pricing tiers — Linear's surface is issues, diffs, releases, agent sessions
- [E] Agent capabilities scoped to ticket-shaped objects: "@mention in issues/docs, issue delegation as delegate, comments, project membership" — no Define/Discover/Plan primitives
- [E] Coding sessions metered: "Coding sessions require AI credits across all tiers" — variable cost per agent run vs. nanopm running on user's own agent subscription
- [E] Key agent features gated to higher tiers (Business $16: "Linear Agent automations beta, Code Intelligence beta"; Triage Intelligence behind Business)
- [E] Free tier capped at 2 teams / 250 issues — friction for small teams to fully evaluate the agent platform
- [A] Closed SaaS — no local-first, no self-host, no MIT fork path
- [A] Strategy/PRD work assumed to happen in Notion/Docs/ChatPRD then land as Linear issues — Linear itself doesn't generate the upstream artifacts
- [A] No adversarial/falsifiability gating before tickets get created — Linear Asks templates issues from Slack with no PM rigor in between
- [A] Lock-in risk: artifacts live in Linear's DB, not as portable markdown/JSONL in a repo

**GAPS_VS_US**
- [E] They have a native in-app coding agent (Jun 11 "Coding Sessions... writes code using Claude Code and Codex inside the platform"); we don't — nanopm hands off to the agent's own session
- [E] They have Linear Diffs / native code review (May 28); we don't — nanopm stops at PRD/tasks
- [E] They have Slack-native agent execution (May 21 Project Slack Channels + Linear Asks); we don't
- [E] They have a published Agent Sessions API with Thought activity + Delegate model; we don't expose an API — nanopm is markdown skills + bash + JSONL on disk
- [E] They have 11 integrated agent partners listed on the agents page; we ship as skills for 3 hosts (Claude Code, Mistral Vibe, OpenAI Codex)
- [E] They have CI/CD release tracking with auto-generated release notes (Apr 30); we don't
- [E] They have Microsoft Teams + Slack channel surfaces (Apr 16, May 21); we are CLI + macOS SwiftUI viewer only
- [E] We have 21 PM skills covering Define/Discover/Plan/Build phases; their changelog/pricing show no equivalent vision-mission, personas, discovery, OKR, strategy, roadmap, or PRD primitives
- [E] We have adversarial subagent gates that refuse strategy/roadmap/PRD without a falsifiable bet (segment+behavior+metric+timeframe); no equivalent in Linear's snapshots
- [E] We have a compounding typed-JSONL state pipeline across skills; Linear's agent surface is session/activity-event shaped around issues, not a Define→Plan compounding artifact chain
- [E] We hand off TO Linear via /pm-breakdown; Linear doesn't hand off upstream to any PM-planning tool in the snapshot
- [E] We're free MIT OSS running on the user's own agent; they meter coding sessions with AI credits across all tiers
- [A] We have schema-validated typed state (Python validators); Linear's GraphQL is typed at the API layer but the snapshot shows no equivalent for upstream PM artifacts because those artifacts don't exist in their model
- [A] They have a macOS/web/mobile product surface and team collab UI; our viewer is a SwiftUI macOS prototype only

### Cursor

**STRENGTHS**
- [E] Massive distribution and revenue surface — pricing page lists Individual $20/mo, Teams $40/user/mo, Enterprise tiers vs nanopm's free MIT pre-PMF posture
- [E] Enterprise-ready governance shipped Jun 3, 2026: "Enterprise Organizations (multi-team, org-level governance + analytics, group permissions)" plus SOC 2 and SAML/OIDC on Teams
- [E] Owns the coding agent surface itself (Agents, Composer, Tab, Cloud Agents) — nanopm only operates above whatever agent the user already has
- [E] First-party multi-model access (GPT-5.5, Opus 4.8, Gemini 3.1 Pro, Grok 4.3, plus Cursor models) bundled in subscription
- [E] Codebase Indexing provides "semantic project understanding at any scale" — durable retrieval substrate nanopm doesn't ship
- [E] Bugbot automated PR review at "~90s" after Jun 10, 2026 perf update — productized code-review loop
- [E] Cloud Agents give "remote compute for parallel feature dev + demos" — async/parallel execution nanopm has no equivalent for
- [E] Design Mode + Canvas (Jun 4–5, 2026) covers visual/UI prompting, a workflow nanopm doesn't address
- [E] SDK (TS + Python) shipped Jun 4, 2026 with "custom tools, auto-review routing with permission gates, JSONL/custom store persistence, NESTED SUBAGENT capability" — programmatic extensibility
- [E] Teams plan includes "internal team marketplace for rules/skills/plugins" + public Marketplace — distribution channel for third-party skills
- [E] Slack Integration ships as a first-class feature for team workflows
- [A] Likely a much larger eng + GTM org behind the cadence of June 2026 releases vs nanopm's 27-star solo/small-team footprint

**WEAKNESSES**
- [E] No PM-layer artifacts in docs top-level (Agent, Rules, MCP, Skills, CLI) or features page — vision/mission, OKRs, strategy, roadmap, PRD, retro are absent from the surface
- [E] Host-locked: features (Composer, Tab, Cloud Agents, Bugbot) only run inside Cursor — a Claude Code / Mistral Vibe / OpenAI Codex user can't adopt them without switching IDE
- [E] Pricing gates the core loop ($20–$40/user/mo + usage-based Bugbot) vs nanopm being free MIT
- [A] "Skills" as a first-party concept (listed in docs nav) competes structurally with nanopm but appears scoped to coding capabilities, not a 21-skill PM pipeline with adversarial gates
- [A] No evidence of typed/schema-validated state that compounds across sessions — Composer/Agents are presented as per-task agentic loops
- [A] No evidence of an adversarial reviewer gate refusing work without a falsifiable bet — the closest is Bugbot, which reviews code not strategy
- [A] No macOS-native viewer surface mentioned — product appears editor/CLI/cloud-centric

**GAPS_VS_US**
- [E] They have a first-party SDK with nested subagents and JSONL persistence ("SDK Updates (TypeScript & Python): custom tools... JSONL/custom store persistence, NESTED SUBAGENT capability"), we don't — nanopm's state is bash + Python validators
- [E] They have Cloud Agents for parallel/remote execution, we don't
- [E] They have Codebase Indexing as a productized semantic index, we don't (nanopm reads code per-skill at runtime)
- [E] They have Bugbot automated PR code review, we don't
- [E] They have Design Mode + Canvas for visual/UI prompting, we don't
- [E] They have Enterprise Organizations with SAML/OIDC, SCIM, audit logs, AI code tracking, we don't
- [E] They have a Marketplace + internal team marketplace for distributing rules/skills/plugins, we don't
- [E] They have native Slack Integration, we don't
- [E] We have host-neutral skill packs shipping to Claude Code, Mistral Vibe, and OpenAI Codex, they don't — Cursor features are Cursor-only
- [A] We have an end-to-end PM pipeline (Define → Discover → Plan → Build with 21 skills covering vision, OKRs, strategy, roadmap, PRD, retro), they don't — their docs/features surface no PM artifacts
- [A] We have an adversarial subagent gate refusing strategy/roadmap/PRD without a falsifiable bet (segment + behavior + metric + timeframe), they don't
- [A] We have typed schema-validated JSONL state that compounds across sessions for PM artifacts, they don't (their JSONL persistence is SDK-level for agent tools, not PM state)
- [A] We have a reasoning sidecar pattern (Evidenced/Assumed sourcing on every Define doc), they don't
- [E] We have a SwiftUI macOS viewer for browsing artifacts, they don't surface an equivalent
- [E] We are free MIT OSS, they are paid SaaS ($20–$40/user/mo + custom)

### GitHub Spec Kit

**STRENGTHS**
- [E] Massive distribution lead: ~112,000 stars vs our 27 — three orders of magnitude more developer adoption.
- [E] Backed by GitHub (Microsoft), giving institutional credibility, funding, and a built-in surface for Copilot users.
- [E] Broader agent coverage: 30+ supported AI agents (Copilot, Claude Code, Gemini CLI, Cursor, Codex, Qwen, opencode, Tabnine, Kiro, Pi, Forge, Goose, Mistral Vibe, others) vs our 3 hosts.
- [E] Proper CLI distribution via `uv tool install specify-cli` on Python 3.11+ across Linux/macOS/Windows — a real packaged tool, not a curl/setup script.
- [E] Extensions system, presets system, and project-local template overrides make the workflow customizable per team.
- [E] Native task-to-GitHub-Issues conversion ships in-product (we list GitHub as a connector spec but they own the integration end-to-end).
- [E] Built-in parallel execution markers + TDD structure in the Tasks/Implement phases — opinionated engineering execution model.
- [A] "Spec-driven development" is a recognizable category label with prior mindshare; "PM upstream layer" is a newer positioning we still need to teach.

**WEAKNESSES**
- [E] Workflow starts at Constitution → Specify; there is no Define phase covering vision, business model, org, personas, or audit before specs begin.
- [E] No discovery layer mentioned (no user-feedback, interview, data, or competitive-intel skills) — they jump straight from constitution to specifying a solution.
- [E] No planning layer in the PM sense — no objectives/OKRs, strategy, or roadmap skills; the "Plan" phase is implementation planning, not product strategy.
- [E] No adversarial/falsifiable-bet gate is described in the workflow — Specify → Clarify → Plan assumes the spec is the right thing to build.
- [E] No connector ecosystem named (Linear, Notion, Dovetail, Productboard, PostHog, Amplitude, Granola, etc.) — the only integration surfaced is GitHub Issues.
- [E] No GUI/viewer mentioned — CLI + agent slash commands only.
- [A] Python + `uv` install requirement is heavier than a markdown skill drop for non-Python teams and adds a runtime dependency.
- [A] Optimized for engineers writing specs for themselves; PMs without a coding agent already wired up are not the target user.

**GAPS_VS_US**
- [E] They have an entire Constitution → Specify → Clarify → Plan → Tasks → Implement engineering workflow with parallel markers and TDD; we don't — our Build phase stops at breakdown + retro.
- [E] They have native task-to-GitHub-Issues conversion built in; we have it only as one of 16 connector specs.
- [E] They have an extensions system, presets system, and project-local template overrides; we don't — our skills are a fixed pack.
- [E] They support 30+ AI agents out of the box; we support 3 (Claude Code, Mistral Vibe, OpenAI Codex).
- [E] They have a proper packaged CLI (`specify-cli` via `uv`); we ship a setup script + markdown skills.
- [E] We have a Define phase (vision-mission, business-model, org, product, personas, audit); they don't — their workflow starts at Constitution/Specify.
- [E] We have a Discover phase (user-feedback, interview, data, competitors-intel); they don't.
- [E] We have a Plan phase with objectives, strategy, roadmap, and PRD as distinct artifacts; they collapse this into a single Specify step.
- [E] We have an adversarial subagent gate refusing strategy/roadmap/PRD without a falsifiable bet (segment + behavior + metric + timeframe); they don't.
- [E] We have 16 connector specs across PM tooling (Linear, Notion, Dovetail, Productboard, PostHog, Amplitude, Mixpanel, Granola, Calendar/Drive, Intercom, HubSpot, Jira, Slack, GitHub); they have GitHub Issues only.
- [E] We have a SwiftUI macOS viewer rendering artifacts as a GUI with in-app skill runs; they don't.
- [E] We have schema-validated typed JSONL state compounding across sessions so each skill reads prior typed output; their snapshot describes a linear phase flow but not a typed compounding state contract.
- [E] We have Daily Ops skills (challenge-me, standup, weekly-update) running outside the pipeline; they don't.
- [A] We have reasoning sidecars separating share-ready claims from Evidenced/Assumed rationale; they don't appear to.

### BMad Method

**STRENGTHS**
- [E] Broader coverage of the full SDLC — "from ideation and planning all the way through agentic implementation," not just PM scope
- [E] Mature product line — explicit v6 release with documented upgrade path signals iteration and staying power
- [E] Wider AI assistant support — Claude Code, Cursor, GitHub Copilot, plus "any tool supporting custom system prompts or project context"
- [E] Extensible ecosystem — BMad Builder for custom modules, a module marketplace, and community/custom modules installable
- [E] Named persona agents (PM, Architect) give users a mental model of "who" is doing what
- [E] Has its own adversarial mechanism — explicit "Adversarial Review" phase as a first-class workflow
- [E] Lifestyle/vertical expansion — Creative Intelligence Suite and Game Dev Studio integrations suggest reach beyond pure software
- [E] Onboarding affordance — `bmad-help` skill guides interactive setup
- [E] Document Sharding + Project Context management — explicit handling of large-context engineering
- [A] Likely larger user base and community given v6 maturity and marketplace existence

**WEAKNESSES**
- [E] License not disclosed on the page — legal ambiguity for enterprise/OSS adopters
- [E] Pricing not disclosed on the page — unclear commercial model
- [E] Workflow names ("Party Mode," "Forensic Investigation," "Quick Dev") are evocative but non-self-describing — discoverability cost
- [A] Broad SDLC scope risks shallow PM depth — spreading across ideation→implementation likely dilutes planning rigor
- [A] No evidence of typed/schema-validated state between phases — handoff likely prose-only, prone to drift
- [A] No evidence of a falsifiable-bet gate — "Adversarial Review" is named but criteria not specified on the page
- [A] No evidence of native data connectors (Linear, PostHog, etc.) — context likely manual or doc-sharded
- [A] No evidence of a GUI/viewer — CLI/agent-only surface
- [A] Marketplace + Builder + Web Bundles + Sharding suggests conceptual surface area that may overwhelm new users

**GAPS_VS_US**
- [E] They have multi-assistant reach (Cursor, Copilot, "any tool"), we don't — we ship 3 hosts (Claude Code, Vibe, Codex)
- [E] They have a module marketplace and Builder for custom modules, we don't — our 21 skills are a fixed pack
- [E] They have full SDLC coverage through agentic implementation, we don't — we stop at breakdown/handoff
- [E] They have vertical extensions (Game Dev, Creative Intelligence), we don't — we're software-PM-only
- [E] They have named persona agents (PM/Architect), we don't — our skills are functional, not persona-framed
- [E] We have a published MIT OSS license, they don't disclose license
- [E] We have 16 documented data connector specs (Linear, GitHub, Notion, Dovetail, PostHog, Amplitude, etc.), they don't show any — their context is [A] doc-sharded/manual
- [E] We have typed schema-validated JSONL state compounding across the pipeline; [A] they don't show typed state — likely prose handoff
- [E] We have a falsifiable-bet adversarial gate (segment + behavior + metric + timeframe) blocking strategy/roadmap/PRD; [E] they have an "Adversarial Review" phase but no specified gating criteria
- [E] We have a SwiftUI macOS viewer rendering artifacts as GUI with in-app runs; [A] they don't show one
- [E] We have a Define phase (vision-mission, business-model, org, product, personas) producing a consolidated context summary; [E] they have an "Analysis Phase" with Brainstorming/Elicitation but no evidence of persistent company-context artifacts

### PM Skills 2.0 (productcompass)

**STRENGTHS**
- [E] Broader scope: 9 plugins, 68 skills, 42 commands vs nanopm's 21 skills — roughly 3x surface area
- [E] Wider host coverage: Claude Code, Claude Cowork, Codex CLI, Cursor, Gemini CLI, OpenCode, Kiro (7 hosts) vs nanopm's 3 (Claude Code, Mistral Vibe, Codex)
- [E] Native marketplace distribution: discoverable via GitHub marketplace + Claude Code CLI `claude plugin install` + Claude Cowork browser — nanopm requires bash `./setup` clone
- [E] Covers post-PRD engineering quality: /security-audit-static, /performance-audit-static, /derive-tests, /ship-check — nanopm's Build phase stops at /pm-breakdown handoff
- [E] Dedicated "intended-vs-implemented" skill closes spec-vs-shipped loop explicitly; nanopm's /pm-retro covers similar ground but isn't called out as a first-class artifact
- [A] Red-team framing ("ranks risks by impact/likelihood/testability") is more legible to PMs than nanopm's "falsifiable bet" gate phrasing
- [A] "Plugin" packaging suggests modular install (pick what you want) vs nanopm's monolithic pipeline

**WEAKNESSES**
- [E] No explicit Define phase artifacts (vision-mission, business-model, org, personas) visible in snapshot — appears to start at discovery/strategy
- [E] No visible typed-state / schema-validated JSONL — skills look like prompts, not a compounding state machine
- [E] No connector ecosystem advertised (no Linear/Notion/Dovetail/PostHog/Amplitude/Granola integrations listed) — nanopm has 16 specs with 4-tier fallback
- [E] No GUI / viewer surface — nanopm has SwiftUI macOS viewer
- [A] Skills appear independent (plugin-style) rather than pipeline-compounding — each /command likely re-reads codebase from scratch
- [A] No adversarial gate that blocks downstream skills — /red-team-prd is a callable command, not a refusal mechanism
- [A] No stated user-research ingestion path (interview debrief, feedback aggregation) — discovery looks framework-driven not data-driven
- [A] Same pre-PMF risk: free MIT OSS, no paid tier, unknown traction

**GAPS_VS_US**
- [E] They have marketplace-native install (`claude plugin install`); we don't — nanopm requires clone + bash setup
- [E] They have 4 additional hosts beyond ours (Cursor, Gemini CLI, OpenCode, Kiro, Claude Cowork)
- [E] They have shipped-code quality skills (/security-audit-static, /performance-audit-static, /derive-tests); we don't
- [E] They have ~3x raw skill count (68 vs 21); we don't
- [E] We have Define phase (vision-mission, business-model, org, product, personas, audit); they don't — foundational context layer
- [E] We have typed JSONL state + schema validators → compounding pipeline across sessions; they don't
- [E] We have 16 connector specs with MCP→API→browser→manual fallback; they don't
- [E] We have a hard adversarial gate that refuses strategy/roadmap/PRD without segment+behavior+metric+timeframe bet; they don't (callable /red-team-prd only)
- [E] We have a dedicated quantitative data skill (/pm-data on PostHog/Amplitude); they don't
- [E] We have user-research ingestion (/pm-interview, /pm-user-feedback, FEEDBACK.md aggregation); they don't
- [E] We have a SwiftUI macOS viewer rendering artifacts as GUI; they don't
- [E] We have a daily-ops cadence (/pm-standup, /pm-weekly-update) outside the pipeline; they don't

## Sources

- `.nanopm/intel/snapshots/chatprd/` — homepage, pricing (fetched 2026-06-15); changelog FETCH_FAILED (HTTP 404, persistent across 2026-06-10 and 2026-06-15 — URL needs replacement)
- `.nanopm/intel/snapshots/linear/` — changelog, api_docs (Agents), pricing, agents-landing (fetched 2026-06-15)
- `.nanopm/intel/snapshots/cursor/` — changelog, docs, pricing, features (fetched 2026-06-15)
- `.nanopm/intel/snapshots/spec-kit/other.md` — baseline captured 2026-06-15 from `github.com/github/spec-kit` README
- `.nanopm/intel/snapshots/bmad-method/other.md` — baseline captured 2026-06-15 from `docs.bmad-method.org`
- `.nanopm/intel/snapshots/pm-skills/other.md` — baseline captured 2026-06-15 from `productcompass.pm` PM Skills 2.0 catalog page
- Internal context: `.nanopm/PRODUCT.md`, `.nanopm/STRATEGY.md`, `.nanopm/BUSINESS-MODEL.md`, `.nanopm/CONTEXT-SUMMARY.md`
- Fetch transport: WebFetch (Claude headless; BROWSE_NOT_AVAILABLE)
- Unverified URLs flagged in `competitors.json` until they fetch successfully on a subsequent run

## Honest limits of this analysis

- All baseline competitors (Spec Kit, BMad, PM Skills) were captured from a single page fetch each — features that live deeper in subpages are likely undercounted. The diff vs. next run will refine the picture.
- BMad's license and pricing are not disclosed on the page fetched; both are scored / discussed accordingly but warrant a deeper look.
- The matrix scores nanopm a 5 on PM-layer depth, adversarial gate, and typed compounding state — these are claims about the codebase's *capabilities*, not adoption: the Distribution score (1) is the load-bearing counterweight, and the cross-read in `STRATEGY.md` ("capability without retention is empty house") still applies.
