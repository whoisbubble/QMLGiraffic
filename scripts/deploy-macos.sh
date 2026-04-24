#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-build/Release/Giraffic.app}"
QML_DIR="${2:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="$(basename "$APP_PATH" .app)"
APP_DIR="$(cd "$(dirname "$APP_PATH")" && pwd)"
DMG_ROOT="$APP_DIR/${APP_NAME}-dmg"
DMG_PATH="$APP_DIR/${APP_NAME}.dmg"

if ! command -v macdeployqt >/dev/null 2>&1; then
    echo "macdeployqt is not in PATH. Add your Qt bin directory to PATH first."
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "App bundle not found: $APP_PATH"
    echo "Build the Release target on macOS first."
    exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
    echo "hdiutil is not available. This script must run on macOS."
    exit 1
fi

macdeployqt "$APP_PATH" -qmldir="$QML_DIR"

rm -rf "$DMG_ROOT"
rm -f "$DMG_PATH"
mkdir -p "$DMG_ROOT"

cp -R "$APP_PATH" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

if [ -f "$PROJECT_ROOT/config/giraffic.ini.example" ]; then
    cp "$PROJECT_ROOT/config/giraffic.ini.example" "$DMG_ROOT/giraffic.ini.example"
fi

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_ROOT"
echo "Created $DMG_PATH"
