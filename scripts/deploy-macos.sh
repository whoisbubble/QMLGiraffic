#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-build/Release/Giraffic.app}"
QML_DIR="${2:-.}"

if ! command -v macdeployqt >/dev/null 2>&1; then
    echo "macdeployqt is not in PATH. Add your Qt bin directory to PATH first."
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "App bundle not found: $APP_PATH"
    echo "Build the Release target on macOS first."
    exit 1
fi

macdeployqt "$APP_PATH" -qmldir="$QML_DIR" -dmg
