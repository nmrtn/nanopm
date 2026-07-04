---
name: pm-archive
version: 0.1.0
description: "Archive one entity (opportunity, solution, objective, competitor, or persona) with a polished, contextual reason sentence. Argument: <type>/<slug> (e.g. opportunity/cold-start-context or solution/inline-viewer-pane). User context: the raw reason and kind — 'implemented: ...', 'dropped: ...', 'absorbed: ...' for opportunities/solutions; 'completed: ...', 'abandoned: ...' for objectives; 'defunct: ...', 'pivoted: ...', 'irrelevant: ...' for competitors; 'outgrown: ...', 'dropped: ...' for personas."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

<!-- portability-v2 -->


## Preamble (run first)

```bash
source ~/.nanopm/lib/nanopm.sh 2>/dev/null || \
  source .nanopm/lib/nanopm.sh 2>/dev/null || \
  { echo "ERROR: nanopm not installed. Run: curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/setup | bash"; exit 1; }
nanopm_preamble
```

## What this skill does

Archives one entity — writes `status: archived` and a polished `archived_reason` sentence to its
frontmatter, then re-indexes (if an opportunity) and pushes the change to Supabase.

The raw reason from the user is always **rephrased** by the agent into one specific, contextual sentence
that references the actual feature, PR, or decision. The user's wording is never stored verbatim.

**Kind → opening phrase mapping:**
- `implemented` → "Implemented via …"
- `dropped` → "Dropped — …"
- `absorbed` → "Absorbed into … — …"
- `completed` → "Completed — …"
- `abandoned` → "Abandoned — …"
- `defunct` → "Defunct — …"
- `pivoted` → "Pivoted — …"
- `irrelevant` → "No longer relevant — …"
- `outgrown` → "Outgrown — …"

## Steps

### 1. Resolve the entity

Parse the argument (`opportunity/cold-start-context` → type=`opportunity`, slug=`cold-start-context`).

```bash
_ARG="${1:-}"
_TYPE="${_ARG%%/*}"
_SLUG="${_ARG#*/}"
[ -n "$_TYPE" ] && [ -n "$_SLUG" ] && [ "$_TYPE" != "$_SLUG" ] || {
  echo "ERROR: argument must be <type>/<slug>, e.g. opportunity/cold-start-context"
  exit 1
}
_ENTITY_DIR=".nanopm/wiki/entities/${_TYPE}s"
_ENTITY_FILE="$_ENTITY_DIR/$_SLUG.md"
[ -f "$_ENTITY_FILE" ] || {
  echo "ERROR: entity file not found: $_ENTITY_FILE"
  exit 1
}
```

### 2. Read the entity for context

Read `$_ENTITY_FILE` — you need the title, theme (if any), and first paragraph of the summary to
write a specific, accurate reason.

### 3. Parse kind and raw detail from the launch context

The launch context (user context) contains the raw reason. Extract:
- **kind** — the first word before the colon (e.g. `implemented`, `dropped`, `absorbed`)
- **detail** — everything after the colon (e.g. `shipped in Supabase sync PR`)

If no colon is found, treat the whole string as the detail and infer the most likely kind from the
entity's content (e.g. if the entity describes a shipped feature, prefer `implemented`; if it was
superseded, prefer `absorbed`; if just not worth pursuing, prefer `dropped`).

### 4. Rephrase into a polished archived_reason sentence

Produce one polished sentence in the format `{Opening phrase} {specific details}`.

Rules:
- **One sentence only** — no line breaks, no bullet points.
- **Specific** — reference the actual feature name, PR slug, or decision (e.g. "Supabase cloud sync
  (feat/supabase-cloud-sync, merged 2026-07-03)"), not vague descriptions.
- **Contextual** — draw on the entity's title and content to make the reason accurate and
  informative to a reader encountering it cold.
- **No "superseded"** — that word is banned. Use the kind-appropriate phrase instead.
- Opening phrase is determined by the kind:
  - `implemented` → "Implemented via …"
  - `dropped` → "Dropped — …"
  - `absorbed` → "Absorbed into … — …"
  - `completed` → "Completed — …"
  - `abandoned` → "Abandoned — …"
  - `defunct` → "Defunct — …"
  - `pivoted` → "Pivoted — …"
  - `irrelevant` → "No longer relevant — …"
  - `outgrown` → "Outgrown — …"

The rephrased sentence is stored in `_ARCHIVED_REASON`.

### 5. Write the frontmatter

```bash
nanopm_archive_entity "$_TYPE" "$_SLUG" "$_ARCHIVED_REASON"
```

### 6. Re-index if opportunity

```bash
if [ "$_TYPE" = "opportunity" ]; then
  nanopm_opportunities_reindex
  echo "nanopm: INDEX.md updated"
fi
```

### 7. Push to Supabase

```bash
nanopm-ingest-agent push-pending 2>/dev/null || true
echo "nanopm: archived $_TYPE/$_SLUG — pushed"
```

## Output

Print a one-line confirmation:

```
✓ Archived: <entity title>
  Reason: <the polished archived_reason sentence>
```
