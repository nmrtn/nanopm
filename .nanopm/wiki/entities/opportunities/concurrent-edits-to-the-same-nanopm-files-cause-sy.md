---
id: concurrent-edits-to-the-same-nanopm-files-cause-sy
title: "Concurrent edits to the same nanopm files cause sync conflicts, with no resolution process"
theme: Adoption & form factor
status: draft
priority: medium
provenance: user-stated
evidence_sources: [user-verbatim]
linked_objectives: []
related_to: [team-cant-collaborate-on-shared-nanopm-state]
last_updated: 2026-07-03
---

## 1. Problem summary
Now that nanopm state can sync to Supabase cloud, two teammates working in the same repo checkout can independently edit the same `.nanopm/` wiki files at the same time. When both sync, there's no conflict detection or resolution step — unlike git, which surfaces a merge conflict and lets you resolve it deliberately. Today a later push can silently clobber an earlier one, or the sync layer has to pick a winner without the user ever knowing two versions diverged.

## 2. Value to the user
### Job to be done
A team wants to edit shared nanopm state (wiki docs, opportunities, plans) concurrently without losing each other's work — the same trust git gives them for code. The alternative today is either accepting silent overwrites or manually coordinating "who's touching what file" out of band, which breaks down as soon as more than one person is active.

### Where we fall short
**No conflict detection on push/sync**
The sync layer (`.nanopm/raw` + wiki push/pull to Supabase) has no notion of a version conflict — it doesn't detect that the remote copy changed since the local copy was last pulled before overwriting it.
- "when 2 team mates are working on the same files. it can cause conflicts when syncing via cloud supabase. we should consider adding a conflict process like git." — Nicolas Martin, 2026-07-02
- "We have a cloud sync mechanism via supabase for team work, with no conflict resolution. We might want to implement a simple solution for that." — Nicolas Martin, 2026-07-03

**No resolution workflow**
Even if a conflict were detected, there's no defined process (merge markers, three-way diff, "keep mine / keep theirs / merge") for a user to resolve it — this is new territory the cloud-sync feature (`feat/supabase-cloud-sync`) hasn't addressed yet.

## 3. Value to the company
This directly follows from shipping cloud sync — it's the failure mode that turns "team can finally share state" into "team loses work and stops trusting the sync." Left unaddressed, it undermines the very collaboration capability [[team-cant-collaborate-on-shared-nanopm-state]] was meant to unlock: a team burned by one silent overwrite will route back to manual file-passing.

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: last-write-wins with a warning + diff shown before overwrite; per-file optimistic locking (version/etag check on push, reject + prompt on mismatch); git-style conflict markers written into the MD file for manual resolution; field-level merge for structured frontmatter + append-only sections (like LOG.md) where safe. -->
