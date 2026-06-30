#!/usr/bin/env bash
# Tier 1 behavioral check — raw-archive idempotency + manifest link.
#
# Exercises the immutable-source write substrate the ingestion loop depends on
# (NANOPM-WIKI.md §1/§2.1): the bash helpers nanopm_archive_raw / nanopm_raw_manifest
# in lib/nanopm.sh, plus the Python pre-check `nanopm-ingest-agent raw-check`. The
# invariants under test:
#
#   · archiving identical content twice (stdin AND file) yields the SAME content-hash
#     id and writes NO second file (idempotent, content-addressed);
#   · different content yields a different id;
#   · a file source preserves its extension; stdin defaults to .md;
#   · the echoed path is raw/<type>/<id>.<ext> and the file exists on disk;
#   · the manifest is append-only, injects `ts` when absent, and stays valid JSON;
#   · raw-check returns DUPLICATE (exit 0) for archived content, NEW (exit 1) otherwise,
#     with hash PARITY against the bash archiver (same id);
#   · a malicious <type> with ../ cannot escape raw/.
#
# Self-contained: an isolated mktemp -d project (git init, since _nanopm_project_root
# resolves via `git rev-parse --show-toplevel`) so nothing touches the real .nanopm/.
set -euo pipefail

_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_LIB="$_REPO_ROOT/lib/nanopm.sh"
_INGEST="$_REPO_ROOT/bin/nanopm-ingest-agent"
_PASS=0
_FAIL=0

ok()   { printf '  \033[0;32m✓\033[0m %s\n' "$*"; _PASS=$(( _PASS + 1 )); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; _FAIL=$(( _FAIL + 1 )); }

echo
echo "  nanopm raw-archive idempotency + manifest"
echo "  ========================================="

# ── isolated project sandbox ──────────────────────────────────────────────────
# git init so _nanopm_project_root (git rev-parse --show-toplevel) resolves to it.
_PROJ=$(mktemp -d)
trap 'rm -rf "$_PROJ"' EXIT
git -C "$_PROJ" init -q
# Run everything from inside the sandbox so the archiver writes under $_PROJ/.nanopm/.
cd "$_PROJ"
# shellcheck disable=SC1090
source "$_LIB"

RAW="$_PROJ/.nanopm/raw"

# ── 1. idempotency: identical content via stdin → same id, one file ────────────
echo
echo "  Idempotency (stdin)"
_p1=$(printf 'hello world feedback\n' | nanopm_archive_raw feedback)
_p2=$(printf 'hello world feedback\n' | nanopm_archive_raw feedback)
if [ "$_p1" = "$_p2" ]; then
  ok "two identical stdin archives return the SAME path ($_p1)"
else
  fail "identical stdin content returned different paths: '$_p1' vs '$_p2'"
fi
_count=$(find "$RAW/feedback" -maxdepth 1 -type f ! -name '*.manifest.jsonl' ! -name '.archive.tmp.*' | wc -l | tr -d ' ')
if [ "$_count" = "1" ]; then
  ok "no second file written for identical content (1 file on disk)"
else
  fail "expected 1 archived file, found $_count"
fi

# ── 2. idempotency: identical content via a FILE source → same id ──────────────
echo
echo "  Idempotency (file source)"
# Same bytes as above but fed from a .md file: content hash is identical, so the id
# must match the stdin archive (stdin also defaults to .md, so even the path matches).
_src="$_PROJ/source.md"
printf 'hello world feedback\n' > "$_src"
_pf1=$(nanopm_archive_raw feedback "$_src")
_pf2=$(nanopm_archive_raw feedback "$_src")
if [ "$_pf1" = "$_pf2" ]; then
  ok "two identical file archives return the SAME path ($_pf1)"
else
  fail "identical file content returned different paths: '$_pf1' vs '$_pf2'"
fi
if [ "$_pf1" = "$_p1" ]; then
  ok "file source and stdin with identical bytes yield the SAME id+path"
else
  fail "file/stdin parity broken: file='$_pf1' stdin='$_p1'"
fi
_count=$(find "$RAW/feedback" -maxdepth 1 -type f ! -name '*.manifest.jsonl' ! -name '.archive.tmp.*' | wc -l | tr -d ' ')
if [ "$_count" = "1" ]; then
  ok "still 1 file on disk after file-source re-archive (idempotent)"
else
  fail "expected 1 archived file after file re-archive, found $_count"
fi

# ── 3. different content → different id ────────────────────────────────────────
echo
echo "  Distinct content → distinct id"
_pd=$(printf 'a completely different source\n' | nanopm_archive_raw feedback)
if [ "$_pd" != "$_p1" ]; then
  ok "different content produced a different path ($_pd)"
else
  fail "different content collided on the same path ($_pd)"
fi
_count=$(find "$RAW/feedback" -maxdepth 1 -type f ! -name '*.manifest.jsonl' ! -name '.archive.tmp.*' | wc -l | tr -d ' ')
if [ "$_count" = "2" ]; then
  ok "now 2 distinct files on disk"
else
  fail "expected 2 archived files, found $_count"
fi

# ── 4. extension handling + path shape + file existence ───────────────────────
echo
echo "  Extension + path shape"
# File source: extension preserved.
_csv="$_PROJ/data.csv"
printf 'col1,col2\n1,2\n' > "$_csv"
_pcsv=$(nanopm_archive_raw data "$_csv")
if printf '%s' "$_pcsv" | grep -qE '^raw/data/[0-9a-f]{12}\.csv$'; then
  ok "file extension preserved: $_pcsv"
else
  fail "expected raw/data/<id>.csv, got '$_pcsv'"
fi
# stdin defaults to .md.
_pmd=$(printf 'stdin defaults to markdown\n' | nanopm_archive_raw data)
if printf '%s' "$_pmd" | grep -qE '^raw/data/[0-9a-f]{12}\.md$'; then
  ok "stdin defaults to .md: $_pmd"
else
  fail "expected raw/data/<id>.md for stdin, got '$_pmd'"
fi
# The echoed path resolves to an actual file under .nanopm/raw/<type>/.
if [ -f "$_PROJ/.nanopm/$_pcsv" ] && [ -f "$_PROJ/.nanopm/$_pmd" ]; then
  ok "echoed paths exist on disk under .nanopm/raw/"
else
  fail "echoed path(s) do not exist: $_pcsv / $_pmd"
fi

# ── 5. manifest: append-only, valid JSON, ts injected ─────────────────────────
echo
echo "  Manifest (append-only + ts injection)"
# Derive <id> from the path echoed by the archiver (basename minus extension).
_id=$(basename "$_p1"); _id="${_id%.*}"
_mf="$RAW/feedback/$_id.manifest.jsonl"
# First line: no ts in the payload → helper must inject it.
nanopm_raw_manifest feedback "$_id" '{"opportunity_slug":"onboarding-friction","claim":"users churn at step 2"}'
# Second line: a different link → must APPEND, not overwrite.
nanopm_raw_manifest feedback "$_id" '{"opportunity_slug":"slow-export","claim":"export takes minutes","ts":"2020-01-01T00:00:00Z"}'
if [ -f "$_mf" ]; then
  ok "manifest written at raw/feedback/$_id.manifest.jsonl"
else
  fail "manifest file missing: $_mf"
fi
_lines=$(wc -l < "$_mf" | tr -d ' ')
if [ "$_lines" = "2" ]; then
  ok "two calls → two lines (append-only)"
else
  fail "expected 2 manifest lines, found $_lines"
fi
# Every line is valid JSON and carries a ts (injected on line 1, preserved on line 2).
if python3 - "$_mf" <<'PY'
import sys, json
ok = True
with open(sys.argv[1], encoding="utf-8") as f:
    lines = [l for l in f if l.strip()]
for l in lines:
    try:
        d = json.loads(l)
    except Exception:
        ok = False; break
    if "ts" not in d or not d["ts"]:
        ok = False; break
# line 2's explicit ts must be preserved verbatim
if ok and json.loads(lines[1]).get("ts") != "2020-01-01T00:00:00Z":
    ok = False
sys.exit(0 if ok else 1)
PY
then
  ok "every manifest line is valid JSON with a ts (injected when absent, preserved when present)"
else
  fail "manifest lines failed JSON / ts validation"
fi

# ── 6. raw-check parity with the bash archiver ────────────────────────────────
echo
echo "  raw-check (DUPLICATE/NEW + hash parity)"
if [ -x "$_INGEST" ]; then
  # Already-archived content → DUPLICATE, exit 0. Pipe the exact bytes we archived.
  set +e
  _dup_out=$(printf 'hello world feedback\n' | "$_INGEST" --project "$_PROJ" raw-check --type feedback)
  _dup_rc=$?
  set -e
  if [ "$_dup_rc" = "0" ] && printf '%s' "$_dup_out" | grep -q '^DUPLICATE '; then
    ok "archived content → DUPLICATE, exit 0 ($_dup_out)"
  else
    fail "expected DUPLICATE/exit 0, got rc=$_dup_rc out='$_dup_out'"
  fi
  # Hash parity: the id raw-check reports must equal the id the bash archiver used.
  _check_id=$(printf '%s' "$_dup_out" | awk '{print $2}')
  if [ "$_check_id" = "$_id" ]; then
    ok "raw-check id matches the bash archiver id ($_check_id) — Python/bash hash parity"
  else
    fail "hash parity broken: raw-check='$_check_id' archiver='$_id'"
  fi
  # Never-archived content → NEW, exit 1.
  set +e
  _new_out=$(printf 'brand new never-seen source\n' | "$_INGEST" --project "$_PROJ" raw-check --type feedback)
  _new_rc=$?
  set -e
  if [ "$_new_rc" = "1" ] && printf '%s' "$_new_out" | grep -q '^NEW '; then
    ok "unseen content → NEW, exit 1 ($_new_out)"
  else
    fail "expected NEW/exit 1, got rc=$_new_rc out='$_new_out'"
  fi
else
  fail "bin/nanopm-ingest-agent missing or not executable — cannot test raw-check"
fi

# ── 7. path-safety: a malicious <type> cannot escape raw/ ──────────────────────
echo
echo "  Path-safety (type cannot escape raw/)"
_before=$(find "$_PROJ" -name 'pwned*' 2>/dev/null | wc -l | tr -d ' ')
# The '/' and '.' in ../ are stripped by the sanitizer, collapsing to a single safe
# segment — so nothing is written outside raw/.
_pesc=$(printf 'escape attempt\n' | nanopm_archive_raw '../../pwned' 2>/dev/null || true)
# Nothing must land outside .nanopm/raw/.
_escaped=$(find "$_PROJ" -path "$RAW" -prune -o -name 'pwned*' -print 2>/dev/null | wc -l | tr -d ' ')
if [ "$_escaped" = "0" ]; then
  ok "no file escaped raw/ via a ../ type ($_pesc)"
else
  fail "a ../ type escaped raw/: found $_escaped stray file(s)"
fi
# And whatever path it echoed must stay under raw/.
if [ -z "$_pesc" ] || printf '%s' "$_pesc" | grep -qE '^raw/[a-z0-9-]+/[0-9a-f]{12}\.'; then
  ok "echoed path (if any) stays within raw/<safe-type>/"
else
  fail "echoed path leaked outside raw/: '$_pesc'"
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
