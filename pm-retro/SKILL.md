---
name: pm-retro
version: 0.1.0
description: "PM retrospective. Compares the roadmap page's NOW items against actual commits since the last roadmap run. Surfaces what shipped, what drifted, and what to carry forward. Closes the planning loop."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

<!-- portability-v2 -->
> **Multi-host portability rules.** When invoking `AskUserQuestion`:
> 1. The `header` field MUST be a short noun phrase (≤ 12 characters). Mistral Vibe
>    rejects longer headers with `string_too_long`. Pick from: `Start`, `Target`,
>    `Scope`, `Audience`, `Methodology`, `Feature`, `Question`.
> 2. The `options` list MUST have at least 2 items. Vibe rejects empty/single-option
>    calls. For free-text input, always provide ≥ 2 framing options (e.g. `Yes, here's the input` /
>    `Skip`) — never call `ask_user_question` with `options: []`.


## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
_RETRO_FILE="$(nanopm_wiki_doc_path "retro-$(date +%F)")"
```

## Phase 0: Prior context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
nanopm_context_read pm-retro
nanopm_context_all
```

If prior retro found: "Prior retro from {ts}. This run covers commits since then."

## Phase 1: Check for required artifacts

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_ROADMAP="$(nanopm_wiki_doc_path roadmap)"; [ -f "$_ROADMAP" ] || _ROADMAP=".nanopm/wiki/docs/roadmap.md"  # legacy flat fallback
[ -f "$_ROADMAP" ] && echo "ROADMAP_EXISTS" || echo "ROADMAP_MISSING"
_CHALLENGES="$(nanopm_wiki_doc_path challenges)"; [ -f "$_CHALLENGES" ] || _CHALLENGES=".nanopm/wiki/docs/challenges.md"; [ -f "$_CHALLENGES" ] || _CHALLENGES=".nanopm/AUDIT.md"  # legacy pre-rename name
[ -f "$_CHALLENGES" ] && echo "CHALLENGES_EXISTS" || echo "CHALLENGES_MISSING"
[ -d ".git" ]               && echo "GIT_REPO"        || echo "NOT_GIT_REPO"
```

If ROADMAP_MISSING and CHALLENGES_MISSING: "No roadmap or challenges page found in the wiki (`.nanopm/wiki/docs/`). Run /pm-challenge-me and /pm-roadmap first to get full retro value. Continuing with git history only."

If NOT_GIT_REPO: "This directory is not a git repo — can't read commit history. Run `git init` or navigate to your project root."

## Phase 2: Determine retro window

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
# When was the roadmap last written? Use as retro start point. Anchor on the wiki
# page, falling back to the legacy flat file so older history still resolves.
_ROADMAP="$(nanopm_wiki_doc_path roadmap)"; [ -f "$_ROADMAP" ] || _ROADMAP=".nanopm/wiki/docs/roadmap.md"
_ROADMAP_COMMIT=$(git log --oneline -1 -- "$_ROADMAP" .nanopm/wiki/docs/roadmap.md 2>/dev/null | awk '{print $1}')
_CHALLENGES="$(nanopm_wiki_doc_path challenges)"; [ -f "$_CHALLENGES" ] || _CHALLENGES=".nanopm/wiki/docs/challenges.md"; [ -f "$_CHALLENGES" ] || _CHALLENGES=".nanopm/AUDIT.md"  # legacy pre-rename name
_CHALLENGES_COMMIT=$(git log --oneline -1 -- "$_CHALLENGES" 2>/dev/null | awk '{print $1}')

if [ -n "$_ROADMAP_COMMIT" ]; then
  echo "WINDOW_START: $_ROADMAP_COMMIT"
  _COMMITS=$(git log --oneline "${_ROADMAP_COMMIT}..HEAD" 2>/dev/null)
  _COMMIT_COUNT=$(git rev-list --count "${_ROADMAP_COMMIT}..HEAD" 2>/dev/null || echo 0)
else
  # Fall back to last 30 commits if no roadmap commit found
  echo "WINDOW_START: last 30 commits (no roadmap anchor)"
  _COMMITS=$(git log --oneline -30 2>/dev/null)
  _COMMIT_COUNT=30
fi

echo "COMMITS_IN_WINDOW: $_COMMIT_COUNT"
echo "$_COMMITS"
```

Tell the user: "Reviewing {N} commits since roadmap was written {date or 'recently'}."

## Phase 3: Extract roadmap items

If ROADMAP_EXISTS, extract the NOW items (planned work) from the wiki roadmap page:

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_ROADMAP="$(nanopm_wiki_doc_path roadmap)"; [ -f "$_ROADMAP" ] || _ROADMAP=".nanopm/wiki/docs/roadmap.md"
grep -A 50 '## NOW' "$_ROADMAP" 2>/dev/null | \
  grep -B 50 '## NEXT\|## LATER\|^---' | \
  grep -v '^##\|^---' | grep -v '^$' | head -30
```

Also extract NEXT items (look for any that may have been pulled forward early):
```bash
grep -A 50 '## NEXT' "$_ROADMAP" 2>/dev/null | \
  grep -B 50 '## LATER\|^---' | \
  grep -v '^##\|^---' | grep -v '^$' | head -20
```

## Phase 4: Synthesize — what shipped vs. what was planned

Analyze the commit messages from Phase 2 against the roadmap items from Phase 3.

For each roadmap NOW item, classify as:
- ✅ **Shipped** — commits clearly cover this item
- 🔄 **In progress** — partial commits suggest work started but not completed
- ❌ **Not started** — no commit signal for this item
- ➡️ **Moved forward** — something from NEXT appeared in commits (pulled in early)

Also identify:
- **Unplanned work** — commits that don't map to any roadmap item (off-roadmap or scope creep)
- **Carry forward** — NOW items not shipped that should move to the next cycle

Be specific: quote commit messages when attributing work. Don't guess — if a commit is ambiguous, mark it as unclear.

## Phase 5: One clarifying question (optional)

If the commit messages are ambiguous about intent (e.g., very terse messages), ask via AskUserQuestion:

**"A few commits weren't clear from message alone — can you tell me what {commit X} was about? (e.g., 'that was the payment flow refactor' or 'skip — it was minor cleanup')"**

Only ask if genuinely unclear. Skip if all commits are parseable. Max one question.

## Phase 6: Write the dated wiki Retro page

Retros are **dated wiki docs** — one page per retro, so history is preserved across cycles (each run writes a new `retro-YYYY-MM-DD.md`, never overwriting prior retros).

Write the page to `$(nanopm_wiki_doc_path "retro-$(date +%F)")` (i.e. `.nanopm/wiki/docs/retro-YYYY-MM-DD.md`). The file begins with the frontmatter emitted by `nanopm_wiki_doc_frontmatter pm-retro evidence-backed "$(date +%Y-%m-%d)" "{sources}"` (substitute the real docs/connectors used — roadmap, git log, challenges — for `{sources}`), immediately followed by the body below:

```markdown
# PM Retrospective
Generated by /pm-retro on {date}
Project: {slug}
Window: {N} commits ({start date or commit} → HEAD)

---

## What Shipped

{For each shipped roadmap item: item name + supporting commit(s). Be specific.}

| Item | Status | Evidence |
|------|--------|----------|
| {item} | ✅ Shipped | {commit sha/msg} |
| {item} | 🔄 In progress | {commit sha/msg} |
| {item} | ❌ Not started | — |

---

## Unplanned Work

{Commits that weren't in the roadmap. Be neutral — unplanned ≠ bad.
Sometimes the right thing appears and you do it. But flag the pattern if it's >30% of commits.}

{list commits with one-line interpretation}

---

## Drift Signal

{If >30% of commits are off-roadmap: flag it. Name the pattern.
If the strategy or challenge session is stale: call it out.
If carry-forward items outnumber shipped items: flag capacity/planning issue.
If nothing to flag: "No significant drift — execution is tracking the plan."}

---

## Carry Forward

{NOW items not shipped that should move into the next cycle. Copy them here verbatim
from the roadmap page so the next /pm-roadmap run can pull them in.}

- {item from the roadmap page's NOW section}

---

## Recommended Next Skill

**Run: /pm-roadmap**

Update your roadmap with carry-forward items and new priorities from this retro.

---

*Sources: roadmap page, git log, challenges page (if present)*
```

## Phase 7: Save context

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || source .nanopm/lib/nanopm.sh 2>/dev/null || true
_RETRO_FILE="$(nanopm_wiki_doc_path "retro-$(date +%F)")"
nanopm_context_append "{\"skill\":\"pm-retro\",\"outputs\":{\"shipped\":\"$(grep -c '✅' "$_RETRO_FILE" 2>/dev/null || echo 0) items shipped\",\"window_commits\":\"${_COMMIT_COUNT:-?} commits\",\"next\":\"pm-roadmap\"}}"
```

## Completion

Tell the user:
- Retro written to the dated wiki page `.nanopm/wiki/docs/retro-YYYY-MM-DD.md` (one page per retro — prior retros are preserved)
- How many roadmap items shipped, in progress, not started
- Whether significant drift was detected
- Carry-forward items for the next planning cycle
- Recommended next skill: `/pm-roadmap`

**STATUS: DONE**
