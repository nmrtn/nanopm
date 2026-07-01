# product-on-purpose/pm-skills — releases snapshot
# Captured: 2026-06-26

## Latest Releases

**v2.29.1** (24 Jun 07:13)
Complete package including PM skills library, sample output library, slash commands, workflows, Claude plugin manifest, and documentation. Installation available for Claude Code/openskills via sync helper scripts or direct use of skills/commands directories.

**v2.29.0** (24 Jun 02:36)
Identical content package to v2.29.1 with the same comprehensive PM skills toolkit, sample outputs, and workflow orchestrators.

**v2.28.0** (20 Jun 08:23)
Additive MINOR release. The catalog grew from 66 to 67 skills (foundation capabilities increased from 9 to 10). Introduces "foundation-stakeholder-briefings" skill that creates audience-tailored communications from source artifacts while maintaining a canonical master document. Features nine stakeholder lenses (Executive, Board, Engineering, UX/Design, PMM, Sales, CS, Legal, and Data/Analytics) plus custom audience support.

**v2.27.1** (17 Jun 06:47)
Maintenance PATCH release. Enhanced consistency checking for classification and phase sub-counts in documentation. The "foundation-stakeholder-briefings" skill introduced in v2.28.0 represents "one piece of work rewritten for multiple audiences" with "claims numbered and projected across briefings" while maintaining accuracy across versions.

**v2.27.0** (16 Jun 00:43)
Introduces measurable quality infrastructure: trigger evaluation fixtures (580 labeled queries across 29 skills), controlled router evaluation, and output-quality evaluation harness. Generated skill manifests and surface documentation prevent hand-sync drift. New skills ship with evaluation-ready assets.

**v2.26.0** (11 Jun 03:22)
Catalog expands to 66 skills. Introduces "utility-pm-workflow-builder" (66th skill) and "/chain" ad-hoc runner enabling ephemeral multi-skill sequences. All 26 original-generation skills updated with boundary definitions and output contracts. Smoke-tested orchestrator engine on installed plugin confirmed successful artifact production and checkpoint mechanics.

**v2.25.2** (10 Jun 15:09)
Complete package snapshot with no behavior changes.

**v2.25.1** (06 Jun 23:35)
Maintenance release consolidating documentation site reorganization (Pattern S conformance), generated CI-gated resource index, root-document link repair, and em-dash character cleanup. No skill behavior changes; catalog remains 65 skills.

**v2.25.0** (03 Jun 18:45)
Introduces activation-and-trust machinery: opt-in guardrails hook blocking em-dash characters at write time, confident-only phase router via SessionStart hook, and output-quality evaluation harness with deterministic validators.

**v2.24.0** (01 Jun 16:29)
Ships workflow orchestrator component with Mode A and Mode B engines enabling skill sequencing and checkpointing.
