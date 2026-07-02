---
id: self-contained-app-with-bundled-cli
type: solution
title: "Self-contained .app with the nanopm CLI bundled inside"
opportunity: users-can-t-easily-install-the-viewer-and-launch-i
status: proposed
lens: eng
appetite: big-bet
impact: high
provenance: assumed
linked_objectives: [obj1-kr2]
last_updated: 2026-06-29
---

## Pitch
Embed the nanopm CLI + shared runtime directly inside the `.app` bundle (`Contents/Resources/nanopm/`) and have the viewer shell out to its own bundled copy instead of requiring a separate `curl | bash` setup. First launch runs `setup --deps-only` against `~/.nanopm/` automatically; the app becomes a single artifact that does everything. Closes BOTH gaps in the opportunity — no packaging story AND no CLI prereq — in one move.

## Riskiest assumption
That bundling the CLI doesn't break the host-skill-pack model — the CLI normally installs skills into `~/.claude/skills/` (or Vibe/Codex equivalents), which a sandboxed-style `.app` launching from `/Applications` may or may not be allowed to write to without user prompts, and which collides with users who already have nanopm installed via `curl | bash` or the Claude plugin (and with the `~/.nanopm/install-source` dev-clone guard).

## Cheapest test
Manually copy the current repo's `lib/` + `setup` into a built `.app`'s Resources, launch it from `/Applications`, and observe whether `setup --host=claude` cleanly writes to `~/.claude/skills/` and reconciles with an existing install. One hour, no CI changes.

## Dissent/tension note
Eng: eliminates the second-step prereq that other options leave on the table, but doubles the surface area maintained (the `.app` now owns CLI lifecycle too) and risks divergence between the bundled CLI version and the user's `curl`-installed one — exactly the kind of structural cost a throwaway prototype shouldn't carry. Anti-goal flagged twice: "Building the full macOS app before the prototype cross-matrix reads positive."
