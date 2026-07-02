---
id: multi-host-portability
type: feature
title: "Multi-host portability"
status: active
provenance: evidence-backed
sources: [README.md, setup, lib/nanopm.sh, test/multi-host.sh]
relates_to: [skill-pack, claude-plugin-packaging]
last_updated: 2026-06-29
---

## Summary
nanopm installs and runs across three coding-agent hosts — Claude Code, Mistral Vibe, and OpenAI Codex — from one `setup` script. Skills are written to host-portable conventions (a shared bash runtime sourced at the top of every block, an `AskUserQuestion` header rule, a deny-list-only tool gating rule) so the same pack works everywhere, and one auto-detect install picks up whichever hosts are present.

## What it does
- One install command, three targets: `./setup` auto-detects installed agents and writes skills to `~/.claude/skills/`, `~/.vibe/skills/`, and/or `~/.codex/skills/`; `--host=claude|vibe|codex|all` targets explicitly.
- Skills follow Vibe-safe conventions: `AskUserQuestion` headers ≤ 12 chars (Vibe rejects longer), `options` ≥ 2 items (Vibe rejects empty/single-option calls), and a `source lib/nanopm.sh` guard at the top of every bash block (Vibe/Codex don't persist shell state between blocks).
- Tool gating uses **deny-lists**, not allow-lists — verified live that `--allowedTools` alone does not gate in headless default mode; the `--disallowedTools` flag is the real control.
- Sessions are resumed through the **host's native** session picker (Claude `--resume`, Vibe `--resume`, Codex `resume`) — no hand-rolled transcript persistence.

## How it works
- `setup` ships `lib/nanopm.sh` and the `bin/` runtime once at `~/.nanopm/` (host-agnostic), then copies the `pm-*/SKILL.md` directories into each host's skills directory.
- `nanopm_skill_path` resolves the right host directory at runtime; `nanopm_config_get/set` partition keys into global (`~/.nanopm/config`) vs per-project (`~/.nanopm/projects/<slug>/config`) so per-project values don't leak across hosts or repos.
- Mechanics that need no LLM — ingest, lint, state-log, migrate, export — are pure Python or bash so the same `bin/nanopm-*` commands run identically on every host.

## Status
Shipped — Claude/Vibe/Codex install paths in `setup`; portability rules enforced by `test/headers.sh` (`source lib/nanopm.sh` guard in every Define skill, since 0.12.x), `test/multi-host.sh` (resolution), and `test/skill-syntax.sh`.

## Related
- [[skill-pack]] — the markdown skills that ride this portability layer.
- [[claude-plugin-packaging]] — an additive, Claude-Code-only install path alongside the `curl | bash` installer.

*Sources: `setup`, `lib/nanopm.sh` (`nanopm_skill_path`, `nanopm_config_get/set`), `test/headers.sh`, `test/multi-host.sh`, CHANGELOG 0.11.0 (per-project config), 0.12.x (Define skills source guard), 0.13.0 (host-native resume).*
