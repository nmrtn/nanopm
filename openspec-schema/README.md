# nanopm × OpenSpec schema

A community schema for [OpenSpec](https://openspec.dev) that adds nanopm's PM pipeline as an upstream planning layer.

## Install

Copy this schema into your project:

```bash
mkdir -p openspec/schemas/nanopm
curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/openspec-schema/schema.yaml \
  -o openspec/schemas/nanopm/schema.yaml
mkdir -p openspec/schemas/nanopm/templates
for f in proposal spec design tasks; do
  curl -fsSL https://raw.githubusercontent.com/nmrtn/nanopm/main/openspec-schema/templates/${f}.md \
    -o openspec/schemas/nanopm/templates/${f}.md
done
```

Then set it as default in `openspec/config.yaml`:

```yaml
schema: nanopm
```

Or use it per-command:

```bash
openspec new change my-feature --schema nanopm
```

## What this adds

The `nanopm` schema is aware of nanopm's output artifacts. When generating any artifact, it reads from `.nanopm/` if present:

- `proposal.md` reads from `.nanopm/CHALLENGES.md` + `.nanopm/prds/<feature>.md`
- `design.md` reads from `.nanopm/STRATEGY.md`
- `tasks.md` reads from `.nanopm/tasks/<feature>.md` if `/pm-breakdown` has already run
- `specs/` converts PRD requirements into SHALL statements

## The full chain

```
/pm-challenge-me → challenges the product thinking
/pm-strategy     → defines the strategic position
/pm-roadmap      → prioritizes what to build
/pm-prd          → writes the PRD
/pm-breakdown    → breaks into tasks (optionally writes openspec/changes/<feature>/)

openspec new change <feature> --schema nanopm
/opsx:apply      → implements
```

## Two layers, one workflow

| Layer | Tool | Answers |
|-------|------|---------|
| PM | nanopm | Why to build, what to build, for whom, strategy, roadmap |
| Engineering | OpenSpec | How to build it, what are the requirements, what are the tasks |
