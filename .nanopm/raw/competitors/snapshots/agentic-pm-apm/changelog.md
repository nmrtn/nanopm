# Agentic Project Management (APM) — CHANGELOG snapshot
# Captured: 2026-06-26

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning (SemVer)](https://semver.org/spec/v2.0.0.html) for the **core CLI package** published on NPM.

> **Note:** APM uses a decoupled versioning system. The CLI (`agentic-pm` on NPM) and template releases (GitHub Releases) version independently but share major version for compatibility. This changelog primarily tracks CLI changes, but major template releases may also be noted. See [VERSIONING.md](VERSIONING.md) for full details.

---

## [1.0.2] - Unreleased

### Breaking Changes

* **Gemini CLI Migration:** Transitioned support from Gemini CLI to the new Antigravity platform. The configuration directory has moved from `.gemini` to `.agents`, and the rules file has been renamed from `GEMINI.md` to `AGENTS.md`. Output format has been updated from TOML to Markdown.

### Added

* **Antigravity Support:** Full support for the new Antigravity (CLI and IDE), including optimized directory structure (`.agents/workflows/`, `.agents/skills/`) and agent-first subagent guidance.

## [1.0.1] - 2026-04-24

### Fixed

* **Codex CLI fixes:** Resolved issues with Codex CLI command invocation and path handling.

## [1.0.0] - 2026-04-12

v1.0.0 is a complete redesign of the APM workflow. The scope of changes across both the codebase and the workflow itself is too large to cover exhaustively here. This is a concise summary of the most significant changes.

### Breaking Changes

* **Workflow redesigned.** Two-phase workflow: Planning Phase (Context Gathering + Work Breakdown) produces three planning documents (Spec, Plan, Rules). Implementation Phase cycles through Task Assignment, Task Execution, Task Logging, and Task Review, with support for batch and parallel dispatch across multiple Workers. All coordination is User-mediated through a file-based Message Bus, with Agents guiding the User at every step.

* **Agent roles changed.** Setup Agent → Planner. Implementation Agent → Worker. Ad-Hoc Agents removed (subagents are now spawned natively by Planner, Manager, and Workers). Manager unchanged.

* **9 commands** (up from 5): `apm-1-initiate-planner`, `apm-2-initiate-manager`, `apm-3-initiate-worker`, `apm-4-check-tasks`, `apm-5-check-reports`, `apm-6-handoff-manager`, `apm-7-handoff-worker`, `apm-8-summarize-session`, `apm-9-recover`.

* **New artifact structure.** Spec (`.apm/spec.md`), Plan with dependency graphs (`.apm/plan.md`), Rules (platform rules file), Tracker (`.apm/tracker.md`), Memory hierarchy (`.apm/memory/` with Index, Task Logs, Handoff Logs).

* **Platform support narrowed** to Claude Code, Cursor, GitHub Copilot, Antigravity, and OpenCode.

* **CLI redesigned.** New commands: `apm archive`, `apm add`, `apm remove`, `apm status`, `apm custom`. `apm init` is fresh-install only. Per-file install tracking via `installedFiles` in metadata.

* **Decoupled versioning.** CLI and templates version independently.

### Added

* **Message Bus** (`.apm/bus/`): file-based Agent communication with Task Bus, Report Bus, and Handoff Bus per Worker.
* **Session continuation:** archive completed sessions, start fresh with archived context carried forward via Planner detection.
* **Recovery command** (`/apm-9-recover`): reconstructs working context after platform auto-compaction.
* **Handoff system:** structured context transfer between Agent instances with Handoff Log (persistent) and Handoff Prompt (ephemeral).
* **Standalone skills** (`skills/`): independently installable skills for migration and customization.
* **Custom repository support** (`apm custom`): install templates from forked or third-party repositories.

### Removed

* Ad-Hoc Agents and Delegate commands.
* Support for Windsurf, Kilo Code, Roo Code, Auggie CLI, Google Antigravity, and Qwen Code.

---

## [0.5.4] - 2026-01-24

### Added

* **Google Antigravity Support:** Added support for Google Antigravity as the 11th AI assistant.

### Deprecated

* **Bootstrap Prompt:** The Bootstrap Prompt has been deprecated and will be removed in v1.0.0.

---

## [0.5.3] - 2025-12-05

### Fixed

* **NPM Package:** Fixed `.npmignore` to exclude `dist/` directory from published package.

---

## [0.5.2] - 2025-11-26

### Added

* **Header Templates:** CLI now creates `Implementation_Plan.md` and `Memory_Root.md` with pre-filled header templates containing placeholders.

### Changed

* **Workflow Streamlining:** Removed Enhancement phase and `Implementation_Plan_Guide.md`. Setup workflow now consists of 4 steps instead of 5.
* **Error Handling:** Strengthened Implementation Agent error handling protocol with 3-attempt limit before mandatory delegation (increased from 2 attempts).

---

## [0.5.0] - 2025-10-29

### Added

* **NPM CLI Tool (`agentic-pm`):** Introduced a command-line interface for managing APM installations.
* **`apm init` Command:** Automates project setup, including AI assistant selection, asset download from GitHub Releases, and creation of the `.apm` directory structure.
* **`apm update` Command:** Allows users to update their local APM installation to the latest compatible template version.
* **Support for 10 AI Assistants:** CLI downloads and installs specific bundles tailored for Cursor, GitHub Copilot, Claude Code, Antigravity, Qwen Code, OpenCode, Windsurf, Kilo Code, Auggie CLI, and Roo Code.

### Changed

* **Installation Method:** APM is now installed via NPM instead of Git clone or GitHub Template.

---

## [0.4.0] - 2025-08-19

APM v0.4 represents a complete framework refinement.

### Major Changes

* **Expanded from 2 to 4 agent types**: Added Setup Agent for project initialization and Ad-Hoc Agents for specialized delegation
* **Two-phase workflow**: Setup Phase for comprehensive planning, Task Loop Phase for execution
* **Advanced memory system**: Dynamic Memory Bank with multiple variants and progressive creation
* **Sophisticated dependency management**: Cross-agent coordination with comprehensive context integration

### License Change
* **Updated from MIT to Mozilla Public License 2.0 (MPL-2.0)**

---

## [0.3.0] - 2025-05-21

### Changed

* **Memory System Robustness:** Updated Memory Bank Guide to mandate strict adherence to `Implementation_Plan.md` for all directory/file naming.
* **Handover Protocol Enhancement:** Modified to include a new mandatory step for the Outgoing Manager Agent to review recent conversational turns.

---

## [0.2.0] - 2025-05-14

### Added

* New Manager Agent Guide for dynamic Memory Bank setup.
* Cursor Rules system with 3 initial rules.

---

## [0.1.0] - 2025-05-12

### Added

* Initial framework structure.
* Defined Memory Bank log format and Handover Artifact formats.
* Created core documentation: Introduction, Workflow Overview, Getting Started, Glossary, Cursor Integration Guide, Troubleshooting.
