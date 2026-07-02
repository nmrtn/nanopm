# PASTE-READY — Symphony GitHub discussion (rewritten)
For posting to: https://github.com/openai/symphony/discussions/new
Category: Show and tell

---

## What I learned from reading the existing discussions

| Discussion | Engagement | Length | Why it worked / didn't |
|---|---|---|---|
| #31 Chorus — "what handles idea→issue?" | 6 comments | 1 sentence + 2 screenshots | Posed the question itself; let others fill the slot |
| #30 locusai — GitHub as backend | 4 comments | 3 sentences | Specific architectural decision; raised a real Q |
| #32 Swim Code | 0 comments | 2 sentences + 🌊 | Read as promo |
| #45 Overture | 0 comments | 200+ words | Too long, too prose-heavy |
| #36 Symphony in TypeScript | 0 comments | 2 sentences | "here's my thing" with no hook |

**Tone rules I'm applying:**
- Under 120 words
- Lead with what the tool does, in one sentence
- One concrete claim (the 21/21 number)
- One specific question (the field-drift one)
- Drop the URL, end the post
- No bullet lists, no headers, no thank-you sign-offs

---

## Title (copy verbatim)

```
nanopm — generates Symphony WORKFLOW.md + Linear tickets from a PRD
```

---

## Body (copy verbatim)

```markdown
nanopm runs the PM cycle inline in your editor (audit → strategy → roadmap → PRD), then `/pm-breakdown` writes a `WORKFLOW.md` + Linear tickets Symphony picks up.

The WORKFLOW.md embeds the source PRD, the strategic bet from per-project state, and a Falsification field the PRD requires — must have a named user segment, a number, an observable behavior, and a timeframe, or the skill blocks shipping. Codex agents read all of that as the per-issue prompt template.

Schema-validated against SPEC.md §5: 21/21 checks on `bin/nanopm-symphony-validate` I shipped. Haven't run against the Elixir reference yet — if you know of field-name drift between spec and impl, would love to know what to fix.

https://github.com/nmrtn/nanopm

Solo project, MIT.
```

That's ~110 words. Three short paragraphs + URL + sign-off.

---

## What's gone vs the prior draft

- ❌ "Hey Symphony team — thanks for shipping the SPEC.md" — buttery opener, dropped
- ❌ Numbered list of what the WORKFLOW.md embeds — too organized, AI-feel
- ❌ Cross-vendor section (you asked for this removed)
- ❌ "### What I'd love your input on" header — too structured
- ❌ Links list section with bullet points — too organized
- ❌ "Thanks for putting the spec in the open — most of this took a day to build because your contract was clear" — sycophantic
- ❌ Mention of "21/21 schema checks AGAINST THE VALIDATOR I SHIPPED" inflated — toned to "21/21 checks on bin/nanopm-symphony-validate I shipped"

## What stayed

- ✅ Specific 21/21 number (concrete claim, earns attention)
- ✅ Field-drift question at the end (real engineering Q only they can answer)
- ✅ The Falsification rubric description (genuinely interesting and unusual)
- ✅ MIT + solo sign-off (matches what other posts do)

---

## One more option — if you want even shorter

Looking at #31 again, the post that earned the most engagement was literally one sentence. If you want to go shorter:

```
nanopm runs audit → strategy → roadmap → PRD inside your editor, then `/pm-breakdown --target=symphony` writes a WORKFLOW.md + Linear tickets. The WORKFLOW.md embeds the strategic bet from a typed-state JSONL and a Falsification field the PRD requires.

Validator: 21/21 against SPEC.md §5. Haven't hit the Elixir reference yet — pointers on field-drift welcome.

https://github.com/nmrtn/nanopm — MIT.
```

~70 words. Cuts the second paragraph entirely. More like #31's brevity. Probably under-explains, but the URL does the heavy lifting.

Decision yours: 110-word version (default above) or 70-word version (option). I'd post the 110-word — the Falsification rubric description is the most distinctive thing nanopm has and the short version drops it.

---

## Posting checklist

- [ ] Tuesday–Thursday, 9–11am PT
- [ ] Category: **Show and tell**
- [ ] Read the body out loud once. Anything sound off? Edit it.
- [ ] Click submit
- [ ] Capture URL in `.nanopm/intel/SYMPHONY-DISCUSSION-2026-06-XX.md` (template below)
- [ ] Do NOT comment back-to-back with your own post. Wait for someone else.

---

## Template for tracking responses (after posting)

Create `.nanopm/intel/SYMPHONY-DISCUSSION-2026-06-XX.md`:

```markdown
# Symphony GitHub Discussion — Tracking
Posted: 2026-06-XX HH:MM PT
URL: https://github.com/openai/symphony/discussions/XX
Title: nanopm — generates Symphony WORKFLOW.md + Linear tickets from a PRD

## Day-by-day

| Day | Date | 👍 | ❤️ | 🎉 | 👀 | Comments | OpenAI engagement | Notes |
|---|---|---|---|---|---|---|---|---|
| 0 | 2026-06-XX | 0 | 0 | 0 | 0 | 0 | none | posted at HH:MM PT |
| 1 | | | | | | | | |
| 7 | | | | | | | | |
| 14 | | | | | | | | (verdict day) |
```

Update once a day. At day 14, write the verdict per issue #13.
