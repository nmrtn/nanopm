# Launch drafts — for the Symphony-lever moment
Written 2026-06-03 after passing level 1 schema validation (21/21 checks).

## Status of the launch package

| Piece | Status | Blocked on |
|---|---|---|
| Symphony WORKFLOW.md schema validation (level 1) | ✓ PASSED 21/21 | — |
| `bin/nanopm-symphony-validate` shipped | ✓ in repo | — |
| `test/symphony-validator.sh` (7/7 checks) | ✓ in repo | — |
| Demo video (issue #15) | ⏳ not recorded | requires your screen + voice |
| HN post | ✗ skipping this round | (you used your Show HN in April; current Symphony threads are stale) |
| Symphony GitHub discussion (DRAFT 1 below) | ⏳ ready to post | optional level 2 test for stronger posture |
| Twitter thread (DRAFT 2 below) | ⏳ ready to post | demo video for tweet 6 |
| Reddit r/ClaudeAI post (DRAFT 3 below) | ⏳ ready to post | demo video |

---

## DRAFT 1 (revised) — Symphony GitHub discussion

**Where:** https://github.com/openai/symphony/discussions/new
**Category:** Show and tell, or General
**Title:** `nanopm — Symphony WORKFLOW.md upstream (passes 21/21 schema checks against SPEC.md §5)`

```markdown
Hey Symphony team — thanks for shipping the SPEC.md. It's specific enough to implement against, which is what made this possible.

I shipped a tool called **nanopm** that runs the PM half of the pipeline (audit, strategy, roadmap, PRD) inside Claude Code, Vibe, or Codex, then hands off to one of six peer downstreams. Symphony is the 6th: `/pm-breakdown --target=symphony` writes a `WORKFLOW.md` to the repo root + creates Linear issues.

The `WORKFLOW.md` body is a Liquid-compatible prompt template that embeds:

1. The source PRD path
2. The typed `bet` decision pulled from a per-project `decision.jsonl` (so the Codex agent has the strategic context, not just the ticket text)
3. The PRD's `Falsification` field — a structured "how would we know this is wrong" paragraph nanopm requires (4-element rubric: number, segment, behavior, timeframe)
4. The explicit out-of-scope items

I shipped a schema validator (`bin/nanopm-symphony-validate`) that checks output against SPEC.md §5 — required fields, enum values, Liquid variables only referencing `issue.*` and `attempt` per §5.4 strict-rendering. Current output passes 21/21 checks.

**The thing I'd love your input on:** is there field-name drift between SPEC.md and the Elixir reference implementation that I should account for? I validated against the spec but haven't run the Elixir daemon against my output yet. If you've seen people implement-against-spec and have it break against the reference, I'd want to fix that before more people pick this up.

Spec compatibility: v1 / Linear tracker / §10 protocol fields.

Links:
- Repo: https://github.com/nmrtn/nanopm
- Symphony handoff lives in `pm-breakdown/SKILL.md` Phase 7f
- Validator: `bin/nanopm-symphony-validate`
- Test report (21/21): `.nanopm/intel/SYMPHONY-LEVEL1-TEST-2026-06-03.md` (gitignored, paste on request)
- {DEMO_URL when recorded}

Not affiliated with anyone. Solo project, MIT.
```

**Posture difference vs the pre-test draft:** opens with the concrete claim ("passes 21/21 schema checks") instead of asking the team to validate something untested. The specific question now is about field-name drift between spec and reference impl, which is a real engineering question the Symphony team is uniquely positioned to answer.

---

## DRAFT 2 — Twitter / X thread (5–6 tweets)

**Tags placed on the relevant tweet, not all on tweet 1:**
- Symphony authors (@AlexK_io @vzhu @zbrock) — tweet 4
- @OpenAIDevs — tweet 4
- @garrytan (gstack) — tweet 5
- @lineardev or @karrisaarinen — optional, only if Linear-relevant signal warrants

### Tweet 1 (hook)

> AI coding agents are getting good at closing tickets.
>
> Something has to produce the tickets — with the right context, the right scope, and a falsifiable "how would we know this is wrong" before any code gets written.
>
> Built nanopm for that.
>
> https://github.com/nmrtn/nanopm

### Tweet 2 (the architecture)

> nanopm is the PM half:
>
> audit → strategy → roadmap → PRD → /pm-breakdown
>
> Hands off to 6 peer downstreams: Linear, GitHub, OpenSpec, gstack, Symphony, or a single markdown file you paste into anything.
>
> One PM upstream. Your choice of delivery layer.

### Tweet 3 (the typed-state moat)

> Every decision lands as a typed record in ~/.nanopm/projects/{slug}/decision.jsonl:
>
> bet, antigoal, target, gap, question, scope-in, scope-out
>
> Each carries confidence 1–10 and provenance (observed / user-stated / adversarial / derived).
>
> Re-run six months later — context survives.

### Tweet 4 (Symphony hook — tag here)

> @AlexK_io @vzhu @zbrock — shipped a Symphony target.
>
> nanopm writes a WORKFLOW.md (your SPEC.md §5 frontmatter + a Liquid prompt template embedding the PRD bet, Falsification, and scope-outs) plus Linear tickets.
>
> Schema-validated against your spec: 21/21 checks pass. Would love your feedback.

### Tweet 5 (broader pitch — re-anchor)

> Same nanopm artifacts work for OpenSpec (change folders), for gstack (CEO plans), and for a human reading a markdown file.
>
> Symphony's one of six. The PM layer doesn't care which delivery layer you pick.
>
> Repo: https://github.com/nmrtn/nanopm

### Tweet 6 (demo — only when recorded)

> Demo (90s, end-to-end pipeline → Symphony → PR):
>
> {DEMO_URL}

---

## DRAFT 3 — r/ClaudeAI Reddit post

**Subreddit:** r/ClaudeAI
**Title:** `nanopm v0.7 — PM upstream for Claude Code / Vibe / Codex that hands off to 6 targets including OpenAI Symphony`

```markdown
Shipped a PM skill pack for AI coding agents in April; just shipped v0.7 with Symphony support as the 6th handoff target.

**What nanopm does:** runs the PM cycle inside your editor — audit, strategy, roadmap, PRD — producing typed decisions (bet, scope-outs, falsifiable targets) in a per-project state file. `/pm-breakdown` then hands off to your choice of:

- Linear (issues)
- GitHub Issues
- OpenSpec (change folder)
- gstack (CEO plan)
- Symphony (WORKFLOW.md + Linear tickets — new in v0.7)
- Human-readable markdown (paste anywhere)

**Multi-host:** works on Claude Code, Mistral Vibe, OpenAI Codex. Same skills, host-specific tool translation handled at install time.

**The interesting bit for r/ClaudeAI specifically:** the typed-state layer means context survives across sessions. Re-run `/pm-audit` 6 months later and it reads your prior decisions before asking anything new. Schema-validated JSONL, not grep-on-markdown.

**The Symphony integration:** nanopm produces a `WORKFLOW.md` that passes 21/21 schema checks against OpenAI's SPEC.md §5 (validator shipped at `bin/nanopm-symphony-validate`). The Symphony orchestrator picks up the tickets and spawns Codex agents.

Repo: https://github.com/nmrtn/nanopm
Symphony integration: pm-breakdown/SKILL.md Phase 7f
Demo: {DEMO_URL}

Direct question for the community: anyone using mycelium, prawduct, deanpeters' Product-Manager-Skills, or rolling your own? Curious how this compares for solo founders.
```

---

## Posting order recommendation

1. **First (today/tomorrow):** Symphony GitHub discussion (Draft 1). Doesn't need the demo video; the validator output and the `.nanopm/intel/SYMPHONY-LEVEL1-TEST-2026-06-03.md` are sufficient evidence. Highest leverage audience (Symphony team), schema-validated foundation.

2. **After recording demo (issue #15):** Twitter thread (Draft 2). Tweet 6 includes the video.

3. **A few days after Twitter:** Reddit post (Draft 3). Uses the demo + any Twitter engagement as social proof.

Skip HN this round — Symphony wave is 5+ weeks old, prior Show HN slot already used.

---

## Optional level 2 test before posting Draft 1

If you want even stronger ground for Draft 1, do level 2 testing:

1. Install Elixir (asdf or homebrew)
2. Clone `github.com/openai/symphony`
3. Install Symphony's deps (`mix deps.get`)
4. Point Symphony at our `WORKFLOW.md` (no Linear key required — just verify the daemon parses it without error and starts polling)

If level 2 surfaces any "field drift" from SPEC.md, fix the generator and re-run level 1. Then Draft 1's posture becomes even stronger: "passes schema validation AND parses successfully against the Elixir reference."

~1 hour of work. Optional. Draft 1 is already defensible at level 1.

---

*Source: STRATEGY.md re-rewrite 2026-06-03 (symmetric-handoff-symphony-lever), level 1 test passing 21/21, validator + behavioral test shipped in v0.7.1.*
