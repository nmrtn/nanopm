#!/usr/bin/env bash
# Tier 1 static check — wiki-canonical writes enforcement.
#
# Guards the invariant established by the wiki-canonical migration (Option A): a
# migrated Define/Plan skill writes its output ONLY into its wiki doc page
# (.nanopm/wiki/docs/<slug>.md), never a flat top-level .nanopm/<DOC>.md and never a
# .nanopm/reasoning/<DOC>.md sidecar. This is the regression gate — if a skill ever
# re-grows a flat write, this fails red.
#
# Scope: only skills that HAVE been migrated are checked (the 8 Define/Plan skills).
# As Discover/Daily-Ops skills migrate, add (skill, DOC) rows below and remove the
# doc from the still-flat allow-list. Reads of not-yet-migrated docs (FEEDBACK,
# CHALLENGES, …) and explanatory prose are intentionally NOT flagged — only writes.
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_PASS=0
_FAIL=0

ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm wiki-canonical enforcement"
echo "  ================================="

# Migrated skills and their RETIRED flat doc basename (parallel arrays).
_SKILLS=(pm-vision-mission pm-business-model pm-org pm-product pm-personas pm-objectives pm-strategy pm-roadmap)
_DOCS=(VISION-MISSION BUSINESS-MODEL ORG PRODUCT PERSONAS OBJECTIVES STRATEGY ROADMAP)

echo
echo "  No flat writes in migrated skills"
for i in "${!_SKILLS[@]}"; do
  skill="${_SKILLS[$i]}"
  doc="${_DOCS[$i]}"
  f="$_REPO_ROOT/$skill/SKILL.md"
  if [ ! -f "$f" ]; then
    fail "$skill — SKILL.md missing"
    continue
  fi

  # Write signals the migration removed (NOT mere references — reads/prose are fine):
  #  · a flat-doc path variable           _X_FILE=".nanopm/<DOC>.md"
  #  · mode detection on the flat path     nanopm_define_mode ".nanopm/<DOC>.md"
  #  · a prose write instruction           Write `.nanopm/<DOC>.md`
  #  · any reasoning-sidecar write          nanopm_reasoning_path
  _hits=""
  if grep -nE "_[A-Z_]+FILE=\"?\.nanopm/${doc}\.md" "$f" >/dev/null 2>&1; then
    _hits="${_hits} flat-path-var"
  fi
  if grep -nE "nanopm_define_mode[^\"]*\"?\.nanopm/${doc}\.md" "$f" >/dev/null 2>&1; then
    _hits="${_hits} define_mode-on-flat"
  fi
  if grep -nE "[Ww]rite[^.]{0,40}\.nanopm/${doc}\.md" "$f" >/dev/null 2>&1; then
    _hits="${_hits} prose-write"
  fi
  if grep -nE "nanopm_reasoning_path" "$f" >/dev/null 2>&1; then
    _hits="${_hits} reasoning-sidecar"
  fi

  if [ -n "$_hits" ]; then
    fail "$skill — flat-write signal(s):${_hits} (must write only .nanopm/wiki/docs/)"
    grep -nE "_[A-Z_]+FILE=\"?\.nanopm/${doc}\.md|nanopm_define_mode[^\"]*\.nanopm/${doc}\.md|[Ww]rite[^.]{0,40}\.nanopm/${doc}\.md|nanopm_reasoning_path" "$f" | head -3 | sed 's/^/        /'
  else
    ok "$skill — no flat .nanopm/${doc}.md write, no sidecar"
  fi
done

echo
echo "  Migrated skills write the wiki doc page"
for i in "${!_SKILLS[@]}"; do
  skill="${_SKILLS[$i]}"
  f="$_REPO_ROOT/$skill/SKILL.md"
  [ -f "$f" ] || continue
  if grep -q "nanopm_wiki_doc_path" "$f"; then
    ok "$skill — routes to nanopm_wiki_doc_path"
  else
    fail "$skill — never calls nanopm_wiki_doc_path (not routed to the wiki)"
  fi
done

echo
echo "  Foundation wired (lib)"
_LIB="$_REPO_ROOT/lib/nanopm.sh"
# R4: the preamble scaffolds the wiki on every run.
if awk '/^nanopm_preamble\(\)/{f=1} f{print} f&&/^}/{exit}' "$_LIB" | grep -q "nanopm_wiki_ensure"; then
  ok "nanopm_preamble calls nanopm_wiki_ensure (wiki always scaffolded)"
else
  fail "nanopm_preamble does not call nanopm_wiki_ensure (R4 — wiki not guaranteed)"
fi
for fn in nanopm_wiki_doc_path nanopm_wiki_doc_frontmatter nanopm_wiki_ensure; do
  if grep -q "^$fn()" "$_LIB"; then
    ok "$fn() defined in lib"
  else
    fail "$fn() missing from lib (wiki write contract)"
  fi
done
# The shared Plan brief reads the wiki, not the flat Plan docs.
if awk '/^nanopm_plan_brief_prompt\(\)/{f=1} f{print} f&&/^}/{exit}' "$_LIB" | grep -q "wiki/docs/"; then
  ok "nanopm_plan_brief_prompt reads the wiki Plan docs"
else
  fail "nanopm_plan_brief_prompt does not read .nanopm/wiki/docs/ (still flat?)"
fi

# ── summary ───────────────────────────────────────────────────────────────────
echo
echo "  ─────────────────────────────"
printf '  Passed: %d  Failed: %d\n' "$_PASS" "$_FAIL"
echo
if [ "$_FAIL" -gt 0 ]; then
  echo "  RESULT: FAILED"
  exit 1
else
  echo "  RESULT: PASSED"
  exit 0
fi
