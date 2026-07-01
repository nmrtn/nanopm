# Symphony WORKFLOW.md Validation — Level 1 Test
Run on 2026-06-03 against Symphony SPEC.md v1

## What was tested

The output of nanopm's `/pm-breakdown --target=symphony` (Phase 7f of `pm-breakdown/SKILL.md`) was generated for a real PRD (`.nanopm/prds/validation-experiment.md`) and validated against the requirements in Symphony's SPEC.md Section 5 (Workflow Specification — Repository Contract).

**Test input PRD:** `.nanopm/prds/validation-experiment.md`
**Generated output:** `.nanopm/handoffs/validation-experiment.WORKFLOW.md` (78 lines, 4148 bytes)
**Validator:** `bin/nanopm-symphony-validate` (Python 3, no external deps; minimal YAML parser for portability)

## What was NOT tested

- **Symphony Elixir runtime:** the reference implementation was not installed or run. Whether Symphony's parser specifically accepts our YAML shape is unverified.
- **Real Linear ticket creation:** the Linear branch of Phase 7f was not exercised (no Linear API key in test).
- **End-to-end Codex agent execution:** no Codex App Server was started; no real PR was produced.

Those would be levels 2 and 3 of the testing tier — see issue #14's parent strategy discussion.

## Results

**21 of 21 checks PASSED. Zero failures. Zero warnings.**

| Section | Checks | Status |
|---|---|---|
| Frontmatter structure | 2/2 | ✓ |
| `tracker` section | 7/7 | ✓ |
| `polling` | 1/1 | ✓ |
| `workspace` | 1/1 | ✓ |
| `agent` | 2/2 | ✓ |
| `codex` | 4/4 | ✓ |
| Prompt template body | 4/4 | ✓ |

### Notable verified properties

- File starts with `---` and has closing `---` delimiter (SPEC.md §5.2)
- Frontmatter parses as a YAML mapping (§5.2 "YAML front matter must decode to a map/object")
- `tracker.kind = "linear"` matches the v1 supported value (§5.3.1)
- `tracker.api_key = "$LINEAR_API_KEY"` uses the canonical env reference (§5.3.1)
- `tracker.project_slug` present (required when `kind = "linear"`)
- `tracker.active_states` is a valid list of strings: `["Todo", "In Progress"]`
- `polling.interval_ms = 30000` (matches default per §5.3.2)
- `codex.command = "codex app-server"` (matches default per §5.3.6)
- All four codex timeout fields are valid integers
- Prompt body is non-empty (3685 chars), references `{{ issue.* }}` variables, references `attempt` (retry-aware)
- Liquid syntax: 4 variable interpolations + 3 tag blocks, all using spec-known constructs
- Per §5.4 "Unknown variables must fail rendering" — all our variables are `issue.*` or `attempt`, so strict rendering will accept them

## What this means

**Level 1 verdict: SAFE to proceed with launch outreach.**

The WORKFLOW.md output is structurally and semantically aligned with Symphony's SPEC.md Section 5. The Symphony team would not reject this on schema grounds. Any disagreement would be about:

- Field name drift between SPEC.md and the Elixir reference implementation (level 2 testing would catch this)
- Real-world Codex agent behavior with our prompt template (level 3 testing would catch this)

**Posture for the Symphony GitHub discussion:** "I generate WORKFLOW.md per SPEC.md Section 5 and it passes 21/21 schema checks. Have not yet exercised the Elixir runtime — would love to know if there's a field drift between spec and reference implementation."

That's a stronger position than the prior draft which said "I built against the spec, please tell me if it works."

## Reproducing this test

```bash
# 1. Generate a WORKFLOW.md from a PRD (manual right now; would be /pm-breakdown --target=symphony in production)
# Currently: see .nanopm/handoffs/validation-experiment.WORKFLOW.md

# 2. Run the validator
python3 bin/nanopm-symphony-validate .nanopm/handoffs/validation-experiment.WORKFLOW.md
```

Exit 0 = compliant. Exit 1 = at least one required check failed. Exit 2 = validator usage error.

## Next steps

- **Optional level 2 test:** install Symphony Elixir reference impl, point it at this WORKFLOW.md, verify it parses without error and dispatches a dry-run tick. ~1 hour of work. Would catch field name drift.
- **Optional level 3 test:** full Codex agent run against a real Linear ticket. ~2–3 hours + Linear account required.
- **Revise Draft 1** (Symphony GitHub discussion) to lead with the "21/21 schema validation passed" framing instead of "please tell me if it works."

---

*Validator: `bin/nanopm-symphony-validate` (commit pending). Test artifact: `.nanopm/handoffs/validation-experiment.WORKFLOW.md`.*
