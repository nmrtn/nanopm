# prawduct — repo tree snapshot
# Captured: 2026-06-26

## Structure (key additions vs last snapshot)
.claude-plugin/marketplace.json
.claude-plugin/plugin.json
.claude/settings.json
CHANGELOG.md
VERSION
bin/prawduct-hook
bin/test-reference-verify
docs/doctor-vs-janitor.md
docs/governance-telemetry.md
docs/principles.md
docs/project-structure.md
docs/release-process.md
docs/waivers.md
hooks/banner.py
hooks/digest.py
hooks/gates.json
hooks/hooks.json
lib/ (26 Python modules: advisory_cmd, advisory_store, api_versioning_probes, audit_learnings_cmd, backlog, backlog_probes, briefing, bug_inbox, buildplan_refs, common_words, compliance, core, coverage, critic_marker, critic_mode, gates, gitstate, init_product, ledger, migrate_plugin, operator_verification, repo_toggle, risk, telemetry, upstream_probes, views, waivers, work_model_index)
methodology/agent-stance.md
methodology/building.md
methodology/discovery.md
methodology/planning.md
methodology/reflection.md
skills/ (advisory, backlog, building, critic, discovery, doctor, janitor, learnings, methodology, migrate, onboard, ping, planning, pr, reflection, repo-disable, report-bug)
tests/ (50+ unit test files, 8 scenario files)

## Notable vs prior snapshot
- Full marketplace plugin distribution (.claude-plugin/)
- Dedicated bin/ directory with prawduct-hook and test-reference-verify
- 26 Python lib modules (expanded from previous)
- migrate skill (new)
- tests/ expanded to 50+ unit tests + 8 scenarios
