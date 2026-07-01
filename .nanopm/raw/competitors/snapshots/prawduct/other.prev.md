# prawduct — repo tree snapshot
# Captured: 2026-05-21

## Structure
.claude/skills/: critic, critic-test (NEW), janitor, learnings, pr, prawduct-doctor
agents/: critic (+ framework-checks.md, review-cycle.md — NEW), critic-test (NEW), pr-reviewer
methodology/: discovery, planning, building, reflection phases
templates/: product briefs, governance, observability, security, HI specs (extensive)
  - human-interface/: accessibility, design-direction, IA, localization, onboarding, screen specs
  - unattended-operation/: configuration, failure-recovery, monitoring, pipeline-architecture, scheduling
.prawduct/: active state, change logs, reviews, governance docs, learnings, artifacts
docs/: principles, project structure, observability examples
tests/: 8 scenario files (data pipeline, quiz platform, medication tracker, arcade game, etc.)

## Changes vs April 7
- tools/ directory REMOVED (was: CLI tools — init, migrate, sync, validate, setup)
- agents/critic-test added (new independent critic test harness)
- agents/critic expanded with framework-checks.md, review-cycle.md
- .claude/skills/critic-test added
- Extensive templates/ expansion (human-interface/, unattended-operation/ subdirectories)
