# gstack — CHANGELOG snapshot
# Captured: 2026-06-03

## Latest: v1.55.1.0 (2026-06-02)
Title theme: "Telemetry now tells you exactly what it records and where it stays.
The project-slug helper hands the shell a safe identifier on every path."

## v1.55.1.0 highlights
- Telemetry opt-in screen now states exactly what it shares: skill name, duration,
  crashes, stable device ID. No code. No file paths. Repo name local-only and
  stripped before any upload.
- gstack-slug helper now sanitizes its output via [a-zA-Z0-9._-] filter, including
  the cached path. Defense against shell-character injection via slug.
- Two new regression tests pin the guarantees (telemetry-repo-strip,
  gstack-slug-sanitize) so they can't quietly drift back.
- Repo-identity strip covers all 3 producer fields: repo, _repo_slug, _branch.

## Strategic context vs prior snapshot (v1.42.2.0, 2026-05-21)
- 13 minor versions shipped in 12 days (avg ~1 minor/day cadence)
- Theme: transparent + safe by default; tests pin behavior contracts
- Strikingly parallel to nanopm v0.6.x topics (telemetry, slug sanitization) but
  opposite stance: gstack ships telemetry transparently with proof, nanopm dropped it
