# Memory foundation: fix project identity + config leak

Branch: `fix/memory-identity-base`

Goal: give nanopm a clean, collision-free memory base so the company-memory tier
and the broader memory system can be built on top without inheriting today's bugs.

## The two bugs we're fixing

1. **Slug collisions.** `nanopm_slug()` is just the repo/folder **basename**
   (`basename "$(git rev-parse --show-toplevel || pwd)"`). Global memory lives at
   `~/.nanopm/memory/<slug>.jsonl` and `~/.nanopm/projects/<slug>/`. Two projects
   with the same name (two repos called `api`, a clone, a fork) → same slug → they
   **share memory**.

2. **Config leak.** `~/.nanopm/config` is one flat key=value file with **no project
   key at all**. Per-project values written through `nanopm_config_set` (today:
   `company_website`, connector `<tool>_url`) are **global** — set in project A,
   read by project B.

## The model we move to

- **Stable project identity** instead of a basename:
  - `nanopm_project_id` → a filesystem-safe key that is stable across clones/locations.
  - `nanopm_project_label` → the human name (basename) for display only.
- **Config split:**
  - Truly-global keys (telemetry, update-check) stay in `~/.nanopm/config`.
  - Per-project keys move to `~/.nanopm/projects/<id>/config`.
- Everything per-project consolidates under `~/.nanopm/projects/<id>/`
  (memory journal + typed state + per-project config).

## DECISION POINT — the identity rule

What computes `nanopm_project_id`? Recommended precedence:

1. **Normalized git remote `origin`** → `host/owner/repo` (lowercased, sanitized).
   Stable across clones and locations, unique per repo. (This is how gbrain-style
   tools key a "source".)
2. **Fallback (no remote):** a generated id in a **committed** `.nanopm-id` file at
   the repo root — stable, survives clone, shared with teammates.
3. **Last resort (no remote, can't write):** a hash of the absolute toplevel path.

Open question for the team: are we OK keying on the remote URL (and writing a
committed `.nanopm-id` when there's no remote), or do we want a different rule?
This is the one call to settle before Phase B.

## Plan (sequenced cheapest-and-safest first)

### Phase A — Per-project config (fixes the leak; small, isolated, low risk)
1. Add `nanopm_project_config_get` / `nanopm_project_config_set` writing to
   `~/.nanopm/projects/<id>/config`.
2. Repoint the per-project keys (`company_website`, connector `<tool>_url`) from
   the global config to the per-project config.
3. Keep truly-global keys in `~/.nanopm/config`.
4. One-time, idempotent migration: move any per-project keys found in the global
   config into the current project's config on first run.

### Phase B — Robust project identity (fixes collisions)
5. Implement the DECISION-POINT rule: `nanopm_project_id` + `nanopm_project_label`.
   Keep `nanopm_slug` as a thin alias → label (display) so nothing breaks loudly.
6. Repoint storage to `nanopm_project_id`: memory journal + typed state + per-project
   config, consolidated under `~/.nanopm/projects/<id>/`.
7. Update consumers: `bin/nanopm-state-log`, `bin/nanopm-state-read`, and the
   viewer's `MemoryView` slug logic (it replicates `nanopm_slug` and must match).
8. One-time, idempotent migration: if old basename-keyed data exists and the new
   id-keyed location is empty, move it once.

### Phase C — Verify
9. `test/skill-syntax.sh`, `test/context-threading.e2e.sh`, `test/state-layer.sh`
   pass. Manual: two same-named repos get separate memory; `company_website` set in
   two projects doesn't leak; migration moves old data exactly once.

### Phase D — (next branch) build on the clean base
- Company-memory tier (`~/.nanopm/companies/<name>/`, the `nanopm_company_context`
  helper, the company/project doc split). See the company-layer plan.

## Notes
- Migration + backward-compat (Phases A.4, B.8) is the only risky part — it must be
  idempotent and silent, and must never lose an existing user's memory.
- Blast radius: `lib/nanopm.sh`, `bin/nanopm-state-{log,read}`, viewer `MemoryView`
  (+ `Competitor*`, `ProjectView`, `SmokeTest` references), `test/` expectations.
