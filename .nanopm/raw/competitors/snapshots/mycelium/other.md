# mycelium — repo tree snapshot
# Captured: 2026-06-26

## Structure
.claude-plugin/
.claude-plugin/marketplace.json
.claude/README.md
.claude/canvas/ (README.md + ~20 .yml canvas files)
.claude/diamonds/README.md, active.yml
.claude/evals/ (README, assumption-tests, dogfood-reports, overhead-measurements, pass-history.json, scenarios/)
.claude/harness/decision-log.md
.claude/manifest.yml
.claude/memory/ (README, cluster-instances, corrections, delivery-journal, patterns, product-journal)
.claude/settings.json
.claude/state/README.md
AGENTS.md
CLAUDE.md
CONTRIBUTORS.md
LICENSE
PRIVACY.md
README.md
docs/ (changelog.md, context-surface.md, faq.md, get-started.md, glossary.md, install-paths.md, mental-model.md, migration.md, philosophy.md, theories.md, threat-model.md)
docs/contributing/
docs/design/
docs/integrations/
docs/receipts/cases/ (many dated case files)
docs/skills/
plugins/mycelium/ (.claude-plugin/plugin.json)
plugins/mycelium/domains/ (delivery, discovery, quality)
plugins/mycelium/engine/ (~25 .md/.yml files: adaptive-thresholds, autonomous-mode, diamond-rules, evidence-decay, etc.)
plugins/mycelium/harness/ (~15 .md files: anti-patterns, behavioral-contract, guardrails-*, security-trust, etc.)
plugins/mycelium/hooks/ (hooks.json, hooks.codex.json, hooks.cursor.json, ~10 .sh scripts)
plugins/mycelium/integrations/opencode/
plugins/mycelium/jit-tooling/
plugins/mycelium/orchestration/
plugins/mycelium/schemas/ (canvas + diamonds JSON schemas)
plugins/mycelium/scripts/ (~15 Python scripts + shell scripts)
plugins/mycelium/skills/ (~60 skills, each as SKILL.md)

## Notable vs prior snapshot
- OpenCode integration added (plugins/mycelium/integrations/opencode/)
- JIT tooling directory (plugins/mycelium/jit-tooling/)
- Orchestration directory (plugins/mycelium/orchestration/)
- Hooks now multi-platform: hooks.codex.json, hooks.cursor.json added
- .claude/memory/ directory with cluster-instances, corrections, delivery-journal, patterns, product-journal
- PRIVACY.md and CONTRIBUTORS.md added
- AGENTS.md added
- docs/integrations/ directory
