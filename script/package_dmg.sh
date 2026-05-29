#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PastePaw"
BUNDLE_ID="local.pastepaw.app"
VERSION="${PASTEPAW_VERSION:-1.0.0}"
BUILD_NUMBER="${PASTEPAW_BUILD:-1}"
MIN_SYSTEM_VERSION="14.0"
ARM_TRIPLE="arm64-apple-macosx${MIN_SYSTEM_VERSION}"
INTEL_TRIPLE="x86_64-apple-macosx${MIN_SYSTEM_VERSION}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
DMG_STAGING_DIR="$DIST_DIR/dmg-staging"
DMG_OUTPUT="${1:-$ROOT_DIR/website/downloads/$APP_NAME.dmg}"
DMG_OUTPUT_DIR="$(dirname "$DMG_OUTPUT")"
DMG_OUTPUT_NAME="$(basename "$DMG_OUTPUT")"
VOLUME_NAME="$APP_NAME"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

require_tool swift
require_tool xcrun
require_tool hdiutil
require_tool codesign
require_tool ditto

cd "$ROOT_DIR"

swift build -c release --triple "$ARM_TRIPLE" --product "$APP_NAME"
swift build -c release --triple "$INTEL_TRIPLE" --product "$APP_NAME"

ARM_BIN_DIR="$(swift build -c release --triple "$ARM_TRIPLE" --show-bin-path)"
INTEL_BIN_DIR="$(swift build -c release --triple "$INTEL_TRIPLE" --show-bin-path)"
RESOURCE_BUNDLE="$ARM_BIN_DIR/PastePaw_PastePaw.bundle"

rm -rf "$APP_BUNDLE" "$DMG_STAGING_DIR" "$DMG_OUTPUT" "$DMG_OUTPUT.sha256"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$DMG_OUTPUT_DIR"

xcrun lipo -create "$ARM_BIN_DIR/$APP_NAME" "$INTEL_BIN_DIR/$APP_NAME" -output "$APP_BINARY"
chmod +x "$APP_BINARY"

if [ -f "$ROOT_DIR/Sources/PastePaw/Resources/AppIcon.icns" ]; then
  cp "$ROOT_DIR/Sources/PastePaw/Resources/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
fi

if [ -f "$ROOT_DIR/Sources/PastePaw/Resources/PastePawToolBarIcon.png" ]; then
  cp "$ROOT_DIR/Sources/PastePaw/Resources/PastePawToolBarIcon.png" "$APP_RESOURCES/PastePawToolBarIcon.png"
fi

if [ -d "$RESOURCE_BUNDLE" ]; then
  ditto "$RESOURCE_BUNDLE" "$APP_RESOURCES/PastePaw_PastePaw.bundle"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

codesign --force --deep --options runtime --sign - "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

mkdir -p "$DMG_STAGING_DIR"
ditto "$APP_BUNDLE" "$DMG_STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

hdiutil create -volname "$VOLUME_NAME" -srcfolder "$DMG_STAGING_DIR" -ov -format UDZO "$DMG_OUTPUT"
hdiutil verify "$DMG_OUTPUT"

(
  cd "$DMG_OUTPUT_DIR"
  shasum -a 256 "$DMG_OUTPUT_NAME" >"$DMG_OUTPUT_NAME.sha256"
)

echo "Created $DMG_OUTPUT"
