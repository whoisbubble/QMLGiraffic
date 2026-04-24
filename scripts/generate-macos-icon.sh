#!/usr/bin/env bash
set -euo pipefail

SOURCE_PNG="${1:-assets/app_icon.png}"
OUTPUT_ICNS="${2:-assets/app_icon.icns}"

if ! command -v sips >/dev/null 2>&1; then
    echo "sips is not available. Run this script on macOS."
    exit 1
fi

if ! command -v iconutil >/dev/null 2>&1; then
    echo "iconutil is not available. Run this script on macOS."
    exit 1
fi

if [ ! -f "$SOURCE_PNG" ]; then
    echo "PNG icon not found: $SOURCE_PNG"
    exit 1
fi

OUTPUT_DIR="$(dirname "$OUTPUT_ICNS")"
mkdir -p "$OUTPUT_DIR"

WORK_DIR="$(mktemp -d)"
ICONSET_DIR="$WORK_DIR/app_icon.iconset"
mkdir -p "$ICONSET_DIR"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

create_icon() {
    local width="$1"
    local height="$2"
    local output="$3"
    sips -z "$height" "$width" "$SOURCE_PNG" --out "$output" >/dev/null
}

create_icon 16 16 "$ICONSET_DIR/icon_16x16.png"
create_icon 32 32 "$ICONSET_DIR/icon_16x16@2x.png"
create_icon 32 32 "$ICONSET_DIR/icon_32x32.png"
create_icon 64 64 "$ICONSET_DIR/icon_32x32@2x.png"
create_icon 128 128 "$ICONSET_DIR/icon_128x128.png"
create_icon 256 256 "$ICONSET_DIR/icon_128x128@2x.png"
create_icon 256 256 "$ICONSET_DIR/icon_256x256.png"
create_icon 512 512 "$ICONSET_DIR/icon_256x256@2x.png"
create_icon 512 512 "$ICONSET_DIR/icon_512x512.png"
create_icon 1024 1024 "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"
echo "Generated $OUTPUT_ICNS from $SOURCE_PNG"
