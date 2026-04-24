#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build-linux}"
APPDIR="${2:-dist/linux/AppDir}"
APP_NAME="${APP_NAME:-Giraffic}"

BIN_PATH="$BUILD_DIR/$APP_NAME"
if [ ! -f "$BIN_PATH" ]; then
    BIN_PATH="$(find "$BUILD_DIR" -maxdepth 3 -type f -name "$APP_NAME" | head -n 1)"
fi

if [ -z "${BIN_PATH:-}" ] || [ ! -f "$BIN_PATH" ]; then
    echo "Executable not found in $BUILD_DIR"
    exit 1
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

cp "$BIN_PATH" "$APPDIR/usr/bin/$APP_NAME"
cp config/giraffic.ini.example "$APPDIR/usr/bin/giraffic.ini.example"
cp assets/app_icon.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"

cat > "$APPDIR/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=$APP_NAME
Icon=$APP_NAME
Categories=Office;
Terminal=false
EOF

echo "Linux AppDir prepared at $APPDIR"
