# GitHub Spec Kit (github.com/github/spec-kit) — fetched 2026-06-15

## Tagline
"Build high-quality software faster" via spec-driven development — specifications become executable, generating working implementations rather than just guiding them.

## Workflow phases
1. Constitution (project principles)
2. Specify (requirements)
3. Clarify (refine underspecified areas)
4. Plan (technical implementation strategy)
5. Tasks (actionable breakdown)
6. Implement (execute all tasks)

## Supported AI agents (30+)
GitHub Copilot, Claude Code, Gemini CLI, Cursor, Codex, Qwen, opencode, Tabnine, Kiro, Pi, Forge, Goose, Mistral Vibe, others.

## License
MIT.

## Pricing / monetization
None — open source.

## Install
`uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@vX.Y.Z` (uv or pipx; Python 3.11+; Linux/macOS/Windows).

## Star count
~112,000 stars.

## Features
- Core slash commands: constitution, specify, plan, tasks, implement
- Optional commands: clarify, analyze, checklist
- Extensions system
- Presets system
- Project-local template overrides
- Task-to-GitHub-Issues conversion
- Parallel execution markers + TDD structure
