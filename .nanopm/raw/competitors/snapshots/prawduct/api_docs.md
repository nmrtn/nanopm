# prawduct — README snapshot
# Captured: 2026-06-26

## Tagline
"Planned discovery, governed building, independent review, and continuous learning"

## Distribution
Prawduct v2: marketplace plugin
Install: claude plugin marketplace add brookstalley/prawduct

## Key features
- Governance Architecture: four enforcement levels — session briefing (staleness detection), independent Critic review (separate context fork, restricted tools), session reflection requirements, compliance canary checks
- Scaled Rigor: discovery depth and review intensity adapt based on project structural characteristics (human interface, API exposure, sensitive data handling, distributed processes)
- Independent Critic Review: separate Claude Code skill with context: fork — cannot access builder reasoning
- Zero-repo-diff updates: "framework updates arrive with zero repo diff"

## Commands
/prawduct:onboard . — initial setup
/prawduct:repo-disable — disable in specific repos
/prawduct:doctor — health check

## Testing & Architecture
- 714 unit tests
- 8 scenario-based end-to-end evaluations
- 23 documented principles
- Python-based runtime hooks (zero external dependencies)
- MIT-licensed, dogfoods itself
