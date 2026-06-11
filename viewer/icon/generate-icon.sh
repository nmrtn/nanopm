#!/usr/bin/env bash
# Renders the NanoPM Viewer app icon with openai/gpt-image-2/edit, passing the
# Nano brand sheet as the visual reference, then (optionally) packages the
# macOS AppIcon.icns (Big Sur grid: rounded 824px body centered on a 1024
# transparent canvas, exported at every size via iconutil).
#
# Reuses the fal helpers (keys, upload, queue) from the ios-app-icon skill.
#
# Usage:
#   ./generate-icon.sh <brand-sheet.png> [--out master.png] [--icns AppIcon.icns]
#                      [--prompt "extra render instructions"]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SCRIPTS="$HOME/.claude/skills/ios-app-icon/scripts"
[ -f "$SKILL_SCRIPTS/fal_common.sh" ] || { echo "ios-app-icon skill not found at $SKILL_SCRIPTS" >&2; exit 1; }
. "$SKILL_SCRIPTS/fal_common.sh"

SHEET="${1:-}"; shift || true
OUT="$SCRIPT_DIR/nanopm-viewer-icon-1024.png"
ICNS=""
EXTRA=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out)    OUT="$2";   shift 2;;
    --icns)   ICNS="$2";  shift 2;;
    --prompt) EXTRA="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done
[ -f "$SHEET" ] || { echo "Usage: generate-icon.sh <brand-sheet.png> [--out P] [--icns P] [--prompt S]" >&2; exit 2; }

load_keys; require_fal

echo "→ uploading brand sheet…" >&2
SHEET_URL=$(fal_upload "$SHEET")

PROMPT="Using the attached brand sheet as the exact visual reference, render the 'Symbol / App Icon' \
mark shown at the bottom-left of the sheet as ONE flat square 1:1 app icon, full bleed edge to edge, \
no rounded corners: a solid coral-orange (#FF5A3C) background with the brand's friendly off-white \
(#F7F6F4) organic blob mascot centered with comfortable margin, its two vertical oval eyes punched \
through showing the coral background, and the small detached round white dot floating at its upper \
right, exactly as drawn on the sheet. Perfectly flat solid vector shapes, no gradients, no shadows, \
no outline, no text, no watermark. ${EXTRA}"

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
curl -fsS "$(fal_first_image_url "$RESP_URL")" -o "$OUT"
echo "$OUT"

# ---- optional: package the macOS .icns --------------------------------------
if [ -n "$ICNS" ]; then
  echo "→ packaging $ICNS…" >&2
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  python3 - "$OUT" "$TMP/master.png" <<'PY'
import sys
from PIL import Image, ImageDraw
src = Image.open(sys.argv[1]).convert("RGBA").resize((824, 824), Image.LANCZOS)
mask = Image.new("L", (824, 824), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, 823, 823], radius=185, fill=255)
canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
canvas.paste(src, (100, 100), mask)
canvas.save(sys.argv[2])
PY
  ICONSET="$TMP/AppIcon.iconset"; mkdir "$ICONSET"
  for s in 16 32 128 256 512; do
    sips -z "$s" "$s" "$TMP/master.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
    d=$((s * 2))
    sips -z "$d" "$d" "$TMP/master.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$ICNS"
  echo "$ICNS"
fi
