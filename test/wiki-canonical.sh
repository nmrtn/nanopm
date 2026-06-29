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
# Define/Plan (Phase 1) + Discover/Daily-Ops (Phase 2). pm-interview owns two docs
# (interview + the cumulative feedback page), so it appears twice. pm-standup/pm-retro
# write DATED wiki docs, so their retired flat doc is STANDUP/RETRO.
_SKILLS=(pm-vision-mission pm-business-model pm-org pm-product pm-personas pm-objectives pm-strategy pm-roadmap \
         pm-challenge-me pm-competitors-intel pm-user-feedback pm-interview pm-interview pm-data pm-discovery pm-weekly-update pm-standup pm-retro)
_DOCS=(VISION-MISSION BUSINESS-MODEL ORG PRODUCT PERSONAS OBJECTIVES STRATEGY ROADMAP \
       CHALLENGES COMPETITORS FEEDBACK INTERVIEW FEEDBACK DATA DISCOVERY WEEKLY_UPDATE STANDUP RETRO)

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
  # Most skills write a singleton doc page (nanopm_wiki_doc_path); the dated series
  # skills (pm-weekly-update, pm-standup) write into a per-series folder via
  # nanopm_wiki_series_path. Either counts as "routed to the wiki".
  if grep -qE "nanopm_wiki_doc_path|nanopm_wiki_series_path" "$f"; then
    ok "$skill — routes to a wiki write helper"
  else
    fail "$skill — never calls nanopm_wiki_doc_path / _series_path (not routed to the wiki)"
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
for fn in nanopm_wiki_doc_path nanopm_wiki_series_path nanopm_wiki_doc_frontmatter nanopm_wiki_ensure; do
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

echo
echo "  Confidence gate removed (engine refactor)"
# The Karpathy-faithful engine retired the pre-write confidence gate: writes apply
# directly and quality is enforced after the fact by the judgment lint (NANOPM-WIKI.md
# §11). This section is the regression gate — if the gate ever comes back, it fails red.
if [ -e "$_REPO_ROOT/bin/nanopm-confidence-gate" ]; then
  fail "bin/nanopm-confidence-gate still present (must be retired)"
else
  ok "bin/nanopm-confidence-gate retired"
fi
# No live invocation of the gate binary anywhere in lib / bins / skills.
_gate_calls=$(grep -rnE "nanopm-confidence-gate" "$_LIB" "$_REPO_ROOT/bin" "$_REPO_ROOT"/pm-*/SKILL.md 2>/dev/null || true)
if [ -n "$_gate_calls" ]; then
  fail "live nanopm-confidence-gate references remain:"
  printf '%s\n' "$_gate_calls" | head -5 | sed 's/^/        /'
else
  ok "no nanopm-confidence-gate references in lib, bins, or skills"
fi
# The drainer for the old review queue is gone (function + preamble call).
if grep -qE "^nanopm_load_reviews\(\)" "$_LIB"; then
  fail "nanopm_load_reviews() still defined in lib (review queue not removed)"
elif awk '/^nanopm_preamble\(\)/{f=1} f{print} f&&/^}/{exit}' "$_LIB" | grep -q "nanopm_load_reviews"; then
  fail "nanopm_preamble still calls nanopm_load_reviews (review surfacing not removed)"
else
  ok "nanopm_load_reviews removed (function + preamble call)"
fi
# The locked write the gate provided now lives in nanopm-ingest-agent `apply`.
if grep -qE "add_parser\(\"apply\"" "$_REPO_ROOT/bin/nanopm-ingest-agent"; then
  ok "nanopm-ingest-agent has an 'apply' subcommand (direct locked write)"
else
  fail "nanopm-ingest-agent missing 'apply' subcommand (gate's locked write not preserved)"
fi
# The ingest prompt writes via apply, not the gate.
if awk '/^nanopm_ingest_prompt\(\)/{f=1} f{print} f&&/^}/{exit}' "$_LIB" | grep -q "nanopm-ingest-agent apply"; then
  ok "nanopm_ingest_prompt writes via 'nanopm-ingest-agent apply' (gate-free)"
else
  fail "nanopm_ingest_prompt does not use 'nanopm-ingest-agent apply'"
fi

echo
echo "  Judgment lint wired (engine refactor)"
# The query primitive (read side of the recipe) exists.
if grep -qE "^nanopm_query_prompt\(\)" "$_LIB"; then
  ok "nanopm_query_prompt() defined in lib (the recipe read primitive)"
else
  fail "nanopm_query_prompt() missing from lib"
fi
# The judgment-lint prompt is gate-free and surfaces findings to the log.
_lint_body=$(awk '/^nanopm_lint_prompt\(\)/{f=1} f{print} f&&/^}/{exit}' "$_LIB")
if printf '%s' "$_lint_body" | grep -q "nanopm-confidence-gate"; then
  fail "nanopm_lint_prompt still routes through the confidence gate"
elif printf '%s' "$_lint_body" | grep -q "log --op lint"; then
  ok "nanopm_lint_prompt is gate-free and surfaces findings via 'log --op lint'"
else
  fail "nanopm_lint_prompt does not surface findings to log.md (log --op lint missing)"
fi
# The dispatch trigger is wired into the throttled preamble check.
if awk '/^nanopm_wiki_lint_check\(\)/{f=1} f{print} f&&/^}/{exit}' "$_LIB" | grep -q "LINT_JUDGMENT_DUE"; then
  ok "nanopm_wiki_lint_check emits LINT_JUDGMENT_DUE (judgment-lint dispatch trigger)"
else
  fail "nanopm_wiki_lint_check does not emit LINT_JUDGMENT_DUE (judgment lint not wired)"
fi
# Behavioral: a wiki with a seeded cross-page contradiction (2 entity pages) fires the
# dispatch trigger that would surface it. Run in a child bash with an empty HOME so the
# trigger proves it fires independent of the structural pre-filter bin being installed.
_TMPL=$(mktemp -d)
mkdir -p "$_TMPL/home" "$_TMPL/.nanopm/wiki/entities/personas"
printf '%s\n' '# Wiki Index' > "$_TMPL/.nanopm/wiki/index.md"
printf -- '---\nid: theo\ntype: persona\ntitle: "Theo"\n---\n## Summary\nLives in the terminal; never touches a GUI.\n' > "$_TMPL/.nanopm/wiki/entities/personas/theo.md"
printf -- '---\nid: nina\ntype: persona\ntitle: "Nina"\n---\n## Summary\nRefuses the terminal; only uses the GUI.\n' > "$_TMPL/.nanopm/wiki/entities/personas/nina.md"
_LINT_OUT=$(HOME="$_TMPL/home" bash -c '
  source "'"$_LIB"'"
  _nanopm_project_root() { echo "'"$_TMPL"'"; }
  nanopm_wiki_lint_check 2>/dev/null
' 2>/dev/null || true)
rm -rf "$_TMPL"
if printf '%s' "$_LINT_OUT" | grep -q "LINT_JUDGMENT_DUE"; then
  ok "seeded 2-page contradiction triggers the LINT_JUDGMENT_DUE dispatch"
else
  fail "seeded contradiction did NOT trigger LINT_JUDGMENT_DUE (judgment lint would not run)"
fi

# ── Every wiki-page write journals to the global log ──────────────────────────
# Regression gate for the global-heartbeat fix: a skill that WRITES a wiki page must
# also call nanopm_wiki_doc_log so the mutation lands in wiki/log.md (NANOPM-WIKI.md
# §8 — "one line per operation"). Without this the viewer's primary memory surface
# under-reports real work (the exact symptom that motivated the fix: pm-product wrote
# docs/product.md but left no heartbeat). If a new page-writing skill forgets the call,
# this fails red. The helper lives in lib/nanopm.sh; callers are the Define/Plan doc
# skills plus the entity skills (opportunities, solutions) and pm-prd.
echo
echo "  Page-writing skills journal to wiki/log.md"
_LOG_SKILLS=(pm-vision-mission pm-business-model pm-org pm-product pm-personas \
             pm-objectives pm-strategy pm-roadmap pm-challenge-me pm-discovery \
             pm-user-feedback pm-interview pm-data pm-competitors-intel \
             pm-weekly-update pm-standup pm-retro pm-opportunities pm-solutions pm-prd)
for skill in "${_LOG_SKILLS[@]}"; do
  f="$_REPO_ROOT/$skill/SKILL.md"
  if [ ! -f "$f" ]; then
    fail "$skill — SKILL.md missing"
    continue
  fi
  if grep -q "nanopm_wiki_doc_log" "$f"; then
    ok "$skill calls nanopm_wiki_doc_log"
  else
    fail "$skill writes a wiki page but never calls nanopm_wiki_doc_log (no global heartbeat)"
  fi
done
# The helper itself must exist in the shared runtime, or every call above is a silent no-op.
if grep -q "^nanopm_wiki_doc_log()" "$_LIB"; then
  ok "nanopm_wiki_doc_log defined in lib/nanopm.sh"
else
  fail "nanopm_wiki_doc_log missing from lib/nanopm.sh — the page-write heartbeat is unwired"
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
