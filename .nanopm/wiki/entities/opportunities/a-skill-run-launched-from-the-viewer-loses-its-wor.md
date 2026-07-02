---
id: a-skill-run-launched-from-the-viewer-loses-its-wor
title: "A skill run launched from the viewer loses its work if the app quits mid-run"
theme: Adoption & form factor
status: ready-for-solutions
priority: medium              # high | medium | low  (judgment)
provenance: user-stated       # nano-hypothesis | user-stated | evidence-backed
evidence_sources: []
linked_objectives: []
related_to: [users-can-t-easily-install-the-viewer-and-launch-i]
last_updated: 2026-06-29
---

## 1. Problem summary
A user who launches a skill run from the viewer (e.g. `/pm-product`) and then quits — or has the app killed — while that run is in flight silently loses the run's work. The viewer spawns `claude` as a child process; when the app dies the child is not terminated cleanly (it dies on SIGPIPE once it next writes to the now-closed stdout pipe), so the run stops mid-task, partway through its writes. There is no warning before quit that runs are active, no session-id is persisted so the run can't be resumed, and on relaunch the in-memory run state is gone — leaving no in-app trace of what completed versus what was interrupted. The user is left to guess what state their `.nanopm/` is in.

## 2. Value to the user
### Job to be done
The user wants to launch a planning skill from the GUI, walk away, and trust that it either finishes or tells them clearly that it didn't — the same durability they'd get from a normal background task. The alternative today is to babysit every run, never quit while one is active, and manually inspect `.nanopm/` file timestamps afterward to reconstruct what happened — exactly the terminal-level vigilance the viewer is supposed to remove.

### Where we fall short
**No graceful shutdown of in-flight runs**
Quitting (or killing) the app does not SIGTERM the spawned `claude` children or flush their state; the run just stops mid-write.
- User-stated: observed live 2026-06-29 — a `/pm-product` run killed mid-way left 4 feature entity files written under `wiki/entities/features/` but `product.md` and the CONTEXT-SUMMARY regeneration incomplete.

**No warning before quit when runs are active**
The app lets the user quit while runs are in flight with no "N run(s) in progress — quit anyway?" prompt.

**No resume after restart**
Run state (and the `claude` session id) lives only in memory, so a relaunch can't reattach to or `--resume` an interrupted run, and the Activity Monitor shows no record of it.

**No completed-vs-interrupted signal**
After an interrupted run the user can't tell from inside the app which artifacts were fully written and which are half-done.

## 3. Value to the company
The viewer is the proof instrument for the non-terminal form-factor bet. A run engine that silently loses work on quit undermines exactly the trust that bet depends on — a non-terminal founder who loses a half-hour planning run with no explanation won't believe the GUI is a safe place to do PM work. This is a reliability gap in the form factor itself, adjacent to (but distinct from) the install/launch friction in `users-can-t-easily-install-the-viewer-and-launch-i`. Guardrail: the fix should stay proportionate to a throwaway prototype — a quit-warning + clean child termination is cheap; full session-resume persistence is a bigger bet to weigh, not assume.

## 5. Solution hypotheses
Pointer only — stay in problem space. (Candidate directions: warn-before-quit when runs are active; SIGTERM child processes cleanly on app termination; persist run session-ids so an interrupted run can be `claude --resume`d after relaunch; surface a "last run was interrupted" marker in the Activity Monitor.)

## Solutions
_Brainstormed via `/pm-solutions` on 2026-06-29 — full comparison in `.nanopm/wiki/entities/solutions/INDEX.md`._
- **[Warn before quit and cleanly terminate in-flight runs](../solutions/warn-before-quit-and-cleanly-terminate-in-flight-r.md)** · eng, design, business · small-bet · high · shortlisted
- **[Persist run state and show an Interrupted marker on relaunch](../solutions/persist-run-state-and-show-an-interrupted-marker-o.md)** · eng, design, business · small-bet · high · shortlisted
- **[One-tap resume of an interrupted run via the captured session id](../solutions/one-tap-resume-of-an-interrupted-run-via-the-captu.md)** · eng, design · big-bet · high · proposed
- **[Disclose the limitation and defer the fix until a cohort user names it](../solutions/disclose-the-limitation-and-defer-the-fix-until-a.md)** · business · small-bet · medium · proposed
