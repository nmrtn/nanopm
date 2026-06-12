#!/bin/bash
# Builds NanoPMViewer and assembles a runnable .app bundle in build/.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP_DIR="build/NanoPM Viewer.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp .build/release/NanoPMViewer "$APP_DIR/Contents/MacOS/NanoPMViewer"
cp icon/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"
# SPM resource bundle (phase icons) — Bundle.module looks for it in Contents/Resources.
cp -R .build/release/NanoPMViewer_NanoPMViewer.bundle "$APP_DIR/Contents/Resources/"

# App accent color (bleu nuit) — compiled asset catalog referenced by NSAccentColorName.
xcrun actool assets/Accent.xcassets --compile "$APP_DIR/Contents/Resources" \
  --platform macosx --minimum-deployment-target 14.0 > /dev/null

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>NanoPMViewer</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>dev.nanopm.viewer</string>
  <key>CFBundleName</key><string>NanoPM Viewer</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSAccentColorName</key><string>AccentColor</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force -s - "$APP_DIR" 2>/dev/null || true
echo "Built: $APP_DIR"
echo "NOTE: ad-hoc signed, not sandboxed, not notarized — DEV USE ONLY."
echo "      Runs spawn the 'claude' CLI on your machine. Before distributing to"
echo "      external testers: Developer ID + hardened runtime + notarization +"
echo "      an in-app run-consent step. See viewer/README.md -> Safety."
