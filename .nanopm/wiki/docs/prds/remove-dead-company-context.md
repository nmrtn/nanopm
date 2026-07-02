# PRD: Remove the inert company-tier context brief
Hand-drafted 2026-06-24 (gates not executed)
Project: nanopm
Status: PROPOSED — NOW (founder OK required before removal)

## Problem
`nanopm_company_context()` (lib/nanopm.sh:929) loads an 8 KB company-tier brief from `~/.nanopm/companies/<slug>/CONTEXT-SUMMARY.md` — but **nothing ever generates that file, and the preamble never calls the function** (verified: the only references are its own definition + a planning doc). It is dead code that *looks like a feature*: a contributor reading the lib reasonably assumes company-tier briefs work, and builds on a foundation that isn't there. Its own comment admits it: "nothing writes company docs or loads them into a brief yet — that's the next step." Meanwhile the genuinely-working company-tier behavior — sharing the Define DOCS across a company's repos via symlink (`nanopm_company_publish`) — stays untouched. The one-company / many-repos *brief* is a scale problem nanopm doesn't have yet; the maintainers' own projects are single-repo. Half-built seams rot.

## Scope
### In scope
- Remove `nanopm_company_context()` and the unreferenced company-brief loader path.
- Keep the working doc-sharing seam: `nanopm_company_link` / `nanopm_company_publish` / the committed `.nanopm-company` file — these work and are used.
- Add a one-line note in `docs/memory-foundation-plan.md` that a company-tier *brief* is deliberately deferred until a real multi-repo company appears, with the revisit trigger below — so the removal reads as a deliberate "not yet," not a silent gap.

### Out of scope
- Removing the company doc-sharing (symlink) machinery.
- Building the company-tier brief (deferred; its own PRD if/when triggered).

## Revisit trigger (when to build the company-tier brief instead)
Build it when a real user links **≥2 repos to one company** and asks for a unified company brief — not before.

## Success criteria
- `grep -rn nanopm_company_context` returns zero hits outside `docs/`.
- All tier-1 + tier-2 tests pass.
- The deferral + trigger are written in the design doc, so the gap is owned, not hidden.

## Ties to
- Parent: memory-foundation-plan (company tier).
- Strategy/Objective: less dead code = fewer future bugs + less contributor confusion (ETHOS: don't ship infrastructure ahead of need). Note: Nico owns the remove-vs-build call — gate the actual deletion on his OK.
