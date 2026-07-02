# Cursor Changelog — snapshot 2026-06-10

## Bugbot Updates — 2026-06-10
- Average review ~90s (was ~5min); 10% more bugs (0.62 vs 0.56); 22% cost reduction
- Powered by Composer 2.5
- `/review` command for pre-push code analysis
- GitHub/GitLab integration with duplicate detection
- Configurable reviews of only new changes since last review

## Design Mode Improvements (v3.7) — 2026-06-05
- Multi-select elements in browser to adjust UI components collectively
- Voice input via Design Mode overlay
- Queue changes by voice during agent execution

## SDK Updates — 2026-06-04
- Custom tools via `local.customTools`
- Auto-review routing with classifier-based permission gates
- JSONL and custom store options for agent/run metadata persistence
- Nested subagents (unlimited depth)
- Run correlation via platform-generated `requestId`
- Reliable `wait()` for local runs
- HTTP/1.1 cloud streaming support
- Lighter SDK imports (deferred local runtime loading)
- TypeScript type improvements
- Composer 2 auto-routing to Composer 2.5

## Canvas Improvements (v3.7) — 2026-06-04
- Design Mode for direct canvas element selection/annotation
- Context usage report (token distribution)
- Full-screen shared canvas viewing
- Agent-embedded buttons for prompt execution
- Improved canvas error fixing
- Enhanced component styling and chart customization

## Enterprise Organizations — 2026-06-03
- Organization-level administration
- Multi-team support with independent security/governance
- User groups across team boundaries
- Org-level usage analytics and spend rollup
- Cross-team user movement via dashboard/API/CSV
- Automatic permission inheritance for new team members
