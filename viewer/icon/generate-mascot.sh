#!/usr/bin/env bash
# Renders the Nano mascot alone — coral on plain white — with openai/gpt-image-2/edit
# using the brand sheet as the visual reference, then removes the background with
# Photoroom to produce a tight transparent PNG (for in-app use, e.g. the homepage).
#
# Reuses the fal/Photoroom helpers from the ios-app-icon skill.
#
# Usage:
#   ./generate-mascot.sh <brand-sheet.png> [--out mascot.png] [--prompt "extra instructions"]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SCRIPTS="$HOME/.claude/skills/ios-app-icon/scripts"
[ -f "$SKILL_SCRIPTS/fal_common.sh" ] || { echo "ios-app-icon skill not found at $SKILL_SCRIPTS" >&2; exit 1; }
. "$SKILL_SCRIPTS/fal_common.sh"

SHEET="${1:-}"; shift || true
OUT="$SCRIPT_DIR/nanopm-mascot.png"
EXTRA=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out)    OUT="$2";   shift 2;;
    --prompt) EXTRA="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done
[ -f "$SHEET" ] || { echo "Usage: generate-mascot.sh <brand-sheet.png> [--out P] [--prompt S]" >&2; exit 2; }

load_keys; require_fal; require_photoroom

echo "→ uploading brand sheet…" >&2
SHEET_URL=$(fal_upload "$SHEET")

PROMPT="Using the attached brand sheet as the exact visual reference, draw ONLY the brand's blob \
mascot exactly as it appears in the big hero lockup at the top of the sheet: the coral-orange \
(#FF5A3C) friendly organic amoeba-splat leaning left, with its two vertical oval off-white eyes, \
and the small detached coral-orange round dot floating just above its upper-right edge. Centered \
on a PLAIN PURE WHITE background with generous empty margin all around. Perfectly flat solid \
vector shapes, no gradients, no shadows, no outline, no square frame, no text, no watermark. ${EXTRA}"

REQ=$(python3 - "$PROMPT" "$SHEET_URL" <<'PY'
import json, sys
print(json.dumps({
    "prompt": sys.argv[1],
    "image_urls": [sys.argv[2]],
    "image_size": {"width": 1024, "height": 1024},
    "quality": "low",
    "output_format": "png",
}))
PY
)

echo "→ rendering with openai/gpt-image-2/edit…" >&2
IFS=$'\t' read -r STATUS_URL RESP_URL <<<"$(fal_submit "openai/gpt-image-2/edit" "$REQ")"
fal_wait "$STATUS_URL" 180
GEN_URL=$(fal_first_image_url "$RESP_URL")

echo "→ removing background (Photoroom)…" >&2
photoroom_cutout "$GEN_URL" "$OUT"
echo "$OUT"
