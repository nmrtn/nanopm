---
id: opportunities-and-plans-go-stale-with-no-freshness
title: "Opportunities and plans go stale, and nanopm waits to be asked rather than proactively offering to refresh"
theme: Trust & evidence
status: defining
priority: high
provenance: evidence-backed
evidence_sources: [user-verbatim, external-prospect]
linked_objectives: []
related_to: [no-signal-rerunning-the-loop-is-worth-it, roadmap-doesnt-orchestrate-into-living-plan]
last_updated: 2026-06-30
---

## 1. Problem summary
Once an opportunity or plan artifact is written, it can sit untouched for weeks while the product, the market, and the user's understanding all move on. Nothing flags that an item hasn't been revisited and may no longer be true — silent rot. The founder's self-interview sharpened this from a passive staleness-signal gap into an active one: nanopm waits to be invoked rather than *watching* the repo (merged PRs, new commits) and artifact age and *opening the conversation itself* — proposing to update `/product` or revisit a stale roadmap before the user starts working against out-of-date context.

## 2. Value to the user
### Job to be done
A founder wants to trust that what nanopm shows reflects reality *now* — so they can act on the top opportunity or the roadmap without first re-auditing whether it's still true. They want nanopm to behave like a partner who notices "your repo moved on, your context is probably stale, want me to refresh it?" rather than a generator that silently serves whatever was last written. The alternative today is the founder having to remember to re-run skills and interpret a `last_updated` date himself.

### Where we fall short
**No staleness signal on individual items**
Priority and provenance are shown, but "how stale is this?" is not. An opportunity last touched two months ago looks identical to one updated yesterday, so the user can't tell which claims to re-validate before relying on them.

**Not git-aware — doesn't react to repo activity**
nanopm doesn't detect that PRs were merged or commits landed and proactively offer to update the affected artifacts (e.g. `/product`). It stays passive against a repo that has visibly moved on.
- "Si je détecte que dans mon repo il y a eu des pull requests qui ont été mergées, alors automatiquement je devrais faire un travail sur /product... ou me proposer de le faire, soit proactif." — self-interview, 2026-06-29 (Granola dc61e5c2)

**No proactive freshness check at session start (terminal)**
On a new terminal session nanopm doesn't open with "I noticed things emerged, your context may be out of date — want me to update it before we start?" The freshness burden is entirely on the user.
- "En mode terminal, ce serait bien que tu fasses un check quand je relance une nouvelle session : 'tiens, je viens de voir qu'il y a eu des choses qui ont émergé, peut-être que ton contexte n'est pas à jour' — en me proposant de l'updater avant de commencer." — self-interview, 2026-06-29 (Granola dc61e5c2)

**No artifact-age nudge to revisit the plan**
nanopm doesn't notice "the roadmap hasn't been revisited in N weeks" and suggest looking at new opportunities. Aging is invisible until the user happens to check.
- "Des fois NanoPM doit faire des checks et dire 'dis donc la roadmap, elle est plus vieille que tant de temps, elle n'a pas été revisitée, peut-être que ça vaut le coup qu'on regarde des nouvelles opportunités.'" — self-interview, 2026-06-29 (Granola dc61e5c2)

**Externally corroborated — continuously-updated summaries on new context**
A CPTO wants exactly this auto-refresh: solution descriptions that update on their own when new context, problems, or solution opportunities arrive.
- "À terme, j'aimerais avoir des descriptions/résumés de solutions qui se mettent à jour en continu lorsqu'il y a un contexte nouveau ou évolutif, ou lorsqu'il faut prendre en compte de nouveaux problems ou de nouvelles opportunités de solution." — Lachlan Laycock (CPTO, Livestorm), iMessage 2026-06-30 (raw/feedback/dae1853ac1c1.md)

## 3. Value to the company
Proactive freshness is what turns nanopm from a *generator you invoke* into a *partner that stays current* — one of the three H-severity gaps the only pipeline-completing user named. It directly supports the retention bet: a context that nudges itself current is a context worth returning to. Adjacent to (but distinct from) NOW item 3's coherence lint, which is not git-aware.

## 5. Solution hypotheses
<!-- pointer only — stay in problem space. Candidate directions: a freshness badge derived from last_updated; a git-aware preamble check that diffs merged PRs/commits since last artifact write and offers to refresh /product; a session-start nudge in CLI + viewer; a "review overdue" filter on aging roadmaps. -->

## Open / superseded
**Provenance upgraded nano-hypothesis → user-stated (2026-06-29).** Originally an inferred staleness-signal gap (2026-06-18); the founder self-interview asserted the proactive/git-aware dimension directly, replacing the inference. — self-interview, 2026-06-29 (Granola dc61e5c2)
**Provenance upgraded user-stated → evidence-backed (2026-06-30).** External signal: a CPTO (Livestorm) independently asked for continuously self-updating solution summaries on new context — the same living/autopilot loop. — Lachlan Laycock, iMessage 2026-06-30 (raw/feedback/dae1853ac1c1.md)
