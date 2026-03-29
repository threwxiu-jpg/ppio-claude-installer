#!/bin/bash
# Build the app and package as DMG
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_NAME="PPIO Claude Installer"
DMG_NAME="PPIOClaudeInstaller"
OUTPUT_DIR="$PROJECT_DIR/dist"

echo "=== Building $APP_NAME ==="

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

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
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
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
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

echo "=== Creating DMG ==="

DMG_PATH="$OUTPUT_DIR/$DMG_NAME.dmg"
rm -f "$DMG_PATH"

# Create DMG with hdiutil
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$APP_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

echo "=== Done ==="
echo "DMG: $DMG_PATH"
echo "App: $APP_DIR"
