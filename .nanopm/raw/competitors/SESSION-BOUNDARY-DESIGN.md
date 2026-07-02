# Session-Boundary Detection — Design Note
Resolves issue #8. Gates issue #9.
Written by builder on 2026-06-03.

## Context

The validation experiment's success metric requires detecting when a `decision.jsonl` read involves entries from a *different session* than the current one. Specifically: "≥ 3 of the first 10 external solo founders run a second skill that reads from `decision.jsonl` within 14 days." Without a deterministic session-boundary rule, the metric isn't measurable.

This note answers three questions before any code is written.

---

## Q1: What counts as a "different session"?

**Decision: a session is one skill invocation, marked by a UUID written to `~/.nanopm/projects/{slug}/.current_session` by `nanopm_preamble`.**

### Why this, and not the alternatives

| Option | Why rejected |
|---|---|
| **File mtime threshold** (e.g., ≥30 min since last write) | Heuristic. A user who closes a laptop for 6 hours, reopens, and immediately re-invokes pm-audit would falsely register as the "same session." Conversely, two genuinely separate sessions within 30 min (e.g., interrupted by a meeting) would falsely register as the "same session." Heuristics on time are noisy and project-uniform when sessions are user-uniform. |
| **Distinct `event: started` entries in `timeline.jsonl`** | Closer, but requires every skill to actually write a `started` event. Currently `nanopm_skill_started` exists in `lib/nanopm.sh` but is NOT called from any skill's preamble — opt-in helper, no call sites. Retrofitting 17 skills to call it adds 17 places to drift. |
| **Process ID (`$$`)** | Wrong granularity. On Vibe, each bash block is a fresh subprocess with a different `$$` — so a single skill invocation would produce N different "sessions" across its N bash blocks. Breaks across hosts. |
| **UUID file (chosen)** | One file write per skill invocation (in the preamble). All bash blocks within the same skill invocation read the same `.current_session` file. Survives subprocess boundaries on Vibe. Single source of truth. Deterministic. |

### How it works

- `nanopm_preamble` writes a fresh UUID to `~/.nanopm/projects/{slug}/.current_session`:
  ```bash
  export NANOPM_SESSION_ID="$(python3 -c 'import uuid; print(uuid.uuid4().hex[:16])')"
  echo "$NANOPM_SESSION_ID" > "$HOME/.nanopm/projects/$_SLUG/.current_session"
  ```
- Every `nanopm-state-log` write injects `"session": "<uuid>"` into the record (read from `.current_session` if `NANOPM_SESSION_ID` isn't in the environment of that subshell — which happens on Vibe).
- `nanopm-state-read` returns records with their `session` field intact.
- A read that finds records with `session != current_session_uuid` is a **cross-session read** — emit `memory-read`.

### Edge cases handled

- **First-ever invocation:** no `.current_session` file yet. `nanopm_preamble` creates it. No records exist with a different session, so no memory-read fires (correct).
- **Same skill run twice in 30s:** two distinct UUIDs. The second invocation reads decision.jsonl, finds session ≠ current → memory-read fires (correct — user did re-engage with prior decisions).
- **Bash block within a single skill calls nanopm-state-log multiple times:** all share the same UUID via `.current_session`. No spurious memory-reads within a single invocation.
- **Multiple parallel skills on the same project:** each writes its own UUID to `.current_session`, overwriting the previous. **Acceptable** — only one can be "current" at a time. The losing skill's writes will look cross-session from the perspective of its own later reads. This is rare enough (solo users don't run two skills in parallel on the same project) that we accept the misclassification.

---

## Q2: Do preamble reads count toward the bet, or only body-level reads?

**Decision: yes, preamble reads count.**

### Reasoning

The bet is "typed-state memory is the pull." When a user re-invokes any skill on a project that has prior `decision.jsonl` entries, the preamble's `nanopm_context_all` call reads those entries, surfaces them to the LLM, and the LLM in turn references them in its output to the user. That IS the memory paying off.

If we excluded preamble reads, the only thing that would count is *deliberately* invoking `nanopm_state_read --type decision` from a skill body — and only `pm-audit`, `pm-roadmap`, `pm-prd`, `pm-strategy` do that today. Excluding preambles would mean a user who re-runs `pm-discovery` (which has no body-level decision read) gets credit only by accident if they happen to run a different skill — biased measurement.

### Caveat: empty reads don't fire

A memory-read event fires ONLY if the read returns ≥ 1 record with a non-current session. So the *first ever* invocation of any skill on a project — where `decision.jsonl` doesn't exist or has 0 entries — does not fire. The user benefitting from memory requires the memory to exist in the first place.

---

## Q3: Re-running `/pm-audit` semantics?

**Decision: yes, re-running pm-audit counts toward the 3-of-10 metric. Qualitative analysis distinguishes which-skill-was-re-invoked.**

### Reasoning

The bet, restated: do users return because prior decisions are surfaced? If a user re-invokes pm-audit specifically — and that invocation's preamble reads decision.jsonl from a prior session and writes prior decisions into the LLM's context — then yes, the memory pulled them back. The skill identity doesn't matter for the bet's central claim.

What *does* matter for qualitative reporting: knowing whether returns are concentrated on one skill (suggesting the use case is "audit-and-re-audit") or distributed across the pipeline (suggesting the full PM cycle has pull). The results write-up (Task #13) must report:

> Of the N memory-reads from cohort completers, K were from re-invocations of the same skill the user first ran; (N-K) were from a different skill in the pipeline.

The split tells the qualitative story even though both contribute to the headline 3-of-10 number.

---

## Schema changes required (for issue #9)

`bin/nanopm-state-log`:
- Add optional `session` field to the **timeline / decision / prd / handoff** schemas (all four record types).
- Validator: if `session` is set, it MUST match `^[a-f0-9]{16}$` (UUID hex, 16 chars).
- Inject `session` from `$NANOPM_SESSION_ID` env var, OR from `~/.nanopm/projects/{slug}/.current_session` if env var is unset (the Vibe subprocess case).
- If neither is available (e.g., direct binary call outside a skill), leave `session` empty — schema-OK because field is optional.

`lib/nanopm.sh`:
- `nanopm_preamble` writes a fresh UUID to `~/.nanopm/projects/$_SLUG/.current_session` at the start, exports `NANOPM_SESSION_ID`.
- `nanopm_state_read` (the shell wrapper): after calling the binary, check returned records for any `session != $NANOPM_SESSION_ID`. If found, emit a memory-read timeline event via `nanopm-state-log --type timeline`.

`bin/nanopm-state-read`:
- No behavioral change required. The wrapper in `lib/nanopm.sh` handles the cross-session check, not the binary itself. This keeps the binary single-purpose and the heuristic in shell where it can be turned off easily.

### Memory-read event shape

```json
{
  "skill": "<calling-skill-name>",
  "event": "memory-read",
  "branch": "<git-branch>",
  "project_slug_hash": "<sha256(slug)[0:16]>",
  "session": "<current-session-uuid>"
}
```

The `project_slug_hash` field handles NFR1 (privacy). Raw project names never appear in the emitted event.

---

## Reversibility check (NFR2)

If validation fails and we want to rip out the instrumentation:
1. Delete the `session` field write logic in `nanopm-state-log` (one block).
2. Delete the post-read check in `nanopm_state_read` wrapper (one block).
3. Delete the `.current_session` file writes in `nanopm_preamble` (one line).
4. Delete the `memory-read` event handling (nothing — it just stops emitting).

No data migration needed. Old records with `session` fields are still valid (the field becomes informational, not load-bearing).

---

## What this doc explicitly does NOT decide

- The wording of the poll template (Task #10).
- The wording of the check-in DM scripts (Task #11).
- The cohort spreadsheet schema (Task #13).

Those are deliberately deferred. This doc only resolves the technical questions blocking Task #9.

---

*Issue #8 closed by this doc. Issue #9 unblocked.*
