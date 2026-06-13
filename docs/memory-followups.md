# Memory system — deferred follow-ups

What's shipped, and what we consciously parked. Each item has a **trigger** (when
it's worth doing) so we don't do it prematurely or forget it.

## Shipped (on main)
- Context brief loaded into every skill, hardened (framed as data, char-safe bound) — #23 / #24
- Per-project config (fixed the global config leak) — #26
- Company tier: `VISION-MISSION` / `BUSINESS-MODEL` / `ORG` shared across a company's
  repos via `~/.nanopm/companies/<slug>/` + symlinks into `.nanopm/`, with the
  `nanopm_company_*` helpers and the 3 skills' link/publish steps — #27 / #28

---

## Deferred

### 1. Competitors → company tier
**Today:** repo layer. `COMPETITORS.md`, `competitors.json`, and the `intel/` tree
write to the repo's `.nanopm/`; they are NOT shared across a company's repos.

**Why it belongs at company level eventually:** the competitive set is external market
context (same bucket as the business model) and is usually a company-wide truth. The
intel history is expensive to gather (web fetches), so re-gathering per repo is wasteful.

**Why deferred:** it's a *directory tree*, not a single doc, so sharing it is a bigger
move than the 3 company docs — and symlinking the `intel/` directory into `.nanopm/`
would trip follow-up #2 (the `find -L` dir-symlink over-scan). For a solo founder /
single-product company it makes no practical difference.

**Trigger:** two repos that genuinely share a competitor set.

**Sequencing when we do it:**
1. Fix follow-up #2 first (constrain the viewer's `find -L`).
2. Extend the company-tier adopt/publish to also handle `competitors.json`,
   `COMPETITORS.md`, and the `intel/` tree.
3. Update `pm-competitors-intel` and the viewer's Competitors section, which read
   `.nanopm/intel/` and `.nanopm/competitors.json`.

### 2. Viewer `find -L` over-scan on a directory symlink
**Today:** `ArtifactScanner` uses `find -L` (to follow the company-doc *file* symlinks).
A non-zero exit is now tolerated (symlink loops won't blank the scan — fixed in #28).
But if a *directory* symlink ever lands in `.nanopm/`, `find -L` would recurse into it
and list the external tree as repo artifacts.

**Why deferred:** the company tier only links *files* today, so no directory symlink
exists — it's latent.

**Trigger:** before sharing any directory (e.g. follow-up #1's `intel/`).

**Fix:** constrain the find (`-xtype f`, a `-maxdepth`, or an explicit doc allowlist)
so it doesn't follow directory symlinks out of `.nanopm/`.

### 3. Slug collisions (project identity)
**Today:** per-project memory is keyed by the repo's folder *basename*
(`nanopm_slug`). Two repos with the same basename (two `api`, a clone, a fork) share
memory. The config leak (the higher-impact half) is already fixed (#26).

**Why deferred:** rare for a solo founder with a handful of distinctly-named repos, and
the fix is a synchronized change across bash (lib), Python (`bin/nanopm-state-*`), and
Swift (viewer `MemoryView`) plus a migration — disproportionate for a rare bug. The
company-tier work may also reshape project identity, so fixing once, in that context,
avoids doing it twice. Full design: `docs/memory-foundation-plan.md` (Phase B).

**Trigger:** a real same-basename collision, or any work that already rewrites the
identity code.

**Fix:** key per-project storage by the repo's absolute path (with a readable label),
not the basename. Local-first; revisit cross-machine identity only when sync is real.

### 4. `company_website` → company tier
**Today:** per-project config (`~/.nanopm/projects/<slug>/config`), set by the Define /
competitors skills. But the company website is arguably company-level (shared).

**Why deferred:** minor; per-project is correct-enough and the leak (the real bug) is
fixed. Low value to move on its own.

**Trigger:** fold in when follow-up #1 or any other company-config work happens.

### 5. CWD-from-subdir
**Today:** `nanopm_company_dir` resolves via `git rev-parse --show-toplevel`, but
`_nanopm_company_adopt` operates on the relative `.nanopm/`. Running a skill from a
subdirectory would mismatch.

**Why deferred:** consistent with nanopm's existing "run from repo root" convention
(all of `.nanopm/` is relative today) — pre-existing, not introduced by the company tier.

**Trigger:** if we ever support running skills from a subdirectory.

**Fix:** resolve the repo root once and use `"$root/.nanopm/..."` throughout.
