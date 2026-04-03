#!/bin/bash
# Build the app and package as DMG
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_NAME="PPIO Claude Installer"
DMG_NAME="PPIOClaudeInstaller"
OUTPUT_DIR="$PROJECT_DIR/dist"
VERSION=$(cat "$PROJECT_DIR/VERSION" | tr -d '[:space:]')

echo "=== Building $APP_NAME v$VERSION ==="

cd "$PROJECT_DIR"

# Build release binary
swift build -c release

echo "=== Creating .app bundle ==="

APP_DIR="$OUTPUT_DIR/$APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/PPIOClaudeInstaller" "$APP_DIR/Contents/MacOS/"

# Generate .icns from PNG icons
ICONSET_DIR="$OUTPUT_DIR/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
ICON_SRC="$PROJECT_DIR/PPIOClaudeInstaller/Assets.xcassets/AppIcon.appiconset"
cp "$ICON_SRC/icon_16x16.png"     "$ICONSET_DIR/icon_16x16.png"
cp "$ICON_SRC/icon_32x32.png"     "$ICONSET_DIR/icon_16x16@2x.png"
cp "$ICON_SRC/icon_32x32.png"     "$ICONSET_DIR/icon_32x32.png"
cp "$ICON_SRC/icon_64x64.png"     "$ICONSET_DIR/icon_32x32@2x.png"
cp "$ICON_SRC/icon_128x128.png"   "$ICONSET_DIR/icon_128x128.png"
cp "$ICON_SRC/icon_256x256.png"   "$ICONSET_DIR/icon_128x128@2x.png"
cp "$ICON_SRC/icon_256x256.png"   "$ICONSET_DIR/icon_256x256.png"
cp "$ICON_SRC/icon_512x512.png"   "$ICONSET_DIR/icon_256x256@2x.png"
cp "$ICON_SRC/icon_512x512.png"   "$ICONSET_DIR/icon_512x512.png"
cp "$ICON_SRC/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET_DIR"

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>PPIO Claude Installer</string>
    <key>CFBundleDisplayName</key>
    <string>PPIO Claude Installer</string>
    <key>CFBundleIdentifier</key>
    <string>com.ppio.claude-installer</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>PPIOClaudeInstaller</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>This app needs to open Terminal to complete setup.</string>
</dict>
</plist>
PLIST

# Ad-hoc sign to prevent "damaged" error
codesign --force --deep --sign - "$APP_DIR"
xattr -cr "$APP_DIR"

echo "=== Creating DMG ==="

DMG_PATH="$OUTPUT_DIR/$DMG_NAME.dmg"
ICNS_PATH="$APP_DIR/Contents/Resources/AppIcon.icns"
RW_DMG="$OUTPUT_DIR/${DMG_NAME}_rw.dmg"
rm -f "$DMG_PATH" "$RW_DMG"

# Create read-write DMG first (to set volume icon)
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$APP_DIR" \
    -ov -format UDRW \
    "$RW_DMG"

# Mount, set volume icon, unmount
MOUNT_DIR=$(hdiutil attach "$RW_DMG" -readwrite -noverify | grep "/Volumes/" | awk -F'\t' '{print $NF}')
if [[ -n "$MOUNT_DIR" && -f "$ICNS_PATH" ]]; then
    cp "$ICNS_PATH" "$MOUNT_DIR/.VolumeIcon.icns"
    SetFile -a C "$MOUNT_DIR"
    echo "Volume icon set"
fi
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed DMG
hdiutil convert "$RW_DMG" -format UDZO -o "$DMG_PATH"
rm -f "$RW_DMG"

# Set DMG file icon in Finder
if [[ -f "$ICNS_PATH" ]]; then
    # Use DeRez/Rez to embed icon into the DMG file resource fork
    TEMP_RSRC="$OUTPUT_DIR/_icon_rsrc.r"
    sips -i "$ICNS_PATH" 2>/dev/null || true
    DeRez -only icns "$ICNS_PATH" > "$TEMP_RSRC" 2>/dev/null || true
    if [[ -s "$TEMP_RSRC" ]]; then
        Rez -append "$TEMP_RSRC" -o "$DMG_PATH"
        SetFile -a C "$DMG_PATH"
        echo "DMG file icon set"
    fi
    rm -f "$TEMP_RSRC"
fi

echo "=== Done ==="
echo "DMG: $DMG_PATH"
echo "App: $APP_DIR"
