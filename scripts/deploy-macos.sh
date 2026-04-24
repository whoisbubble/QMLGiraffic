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
CONTENTS_DIR="$APP_PATH/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
PLUGINS_DIR="$CONTENTS_DIR/PlugIns"
SQLDRIVERS_DIR="$PLUGINS_DIR/sqldrivers"
TEMP_QT_SQL_BACKUP_DIR=""
QT_SQLDRIVERS_SOURCE_DIR=""

restore_qt_sql_plugins() {
    if [ -z "$TEMP_QT_SQL_BACKUP_DIR" ] || [ ! -d "$TEMP_QT_SQL_BACKUP_DIR" ] || [ -z "$QT_SQLDRIVERS_SOURCE_DIR" ]; then
        return 0
    fi

    if [ -f "$TEMP_QT_SQL_BACKUP_DIR/libqsqlpsql.dylib.original" ]; then
        cp -f "$TEMP_QT_SQL_BACKUP_DIR/libqsqlpsql.dylib.original" "$QT_SQLDRIVERS_SOURCE_DIR/libqsqlpsql.dylib"
    fi

    local backed_up_plugin
    for backed_up_plugin in "$TEMP_QT_SQL_BACKUP_DIR"/libqsql*.dylib; do
        [ -e "$backed_up_plugin" ] || continue

        if [ "$(basename "$backed_up_plugin")" = "libqsqlpsql.dylib.original" ]; then
            continue
        fi

        mv -f "$backed_up_plugin" "$QT_SQLDRIVERS_SOURCE_DIR/"
    done

    rm -rf "$TEMP_QT_SQL_BACKUP_DIR"
}

cleanup() {
    restore_qt_sql_plugins
}
trap cleanup EXIT

rewrite_dependency() {
    local target_file="$1"
    local old_path="$2"
    local base_name
    base_name="$(basename "$old_path")"
    local new_path

    case "$target_file" in
        "$SQLDRIVERS_DIR"/*)
            new_path="@loader_path/../../Frameworks/$base_name"
            ;;
        "$FRAMEWORKS_DIR"/*)
            new_path="@loader_path/$base_name"
            ;;
        "$MACOS_DIR"/*)
            new_path="@executable_path/../Frameworks/$base_name"
            ;;
        *)
            return 0
            ;;
    esac

    install_name_tool -change "$old_path" "$new_path" "$target_file" 2>/dev/null || true
}

bundle_non_system_dependencies() {
    local target_file="$1"
    local dep

    while IFS= read -r dep; do
        [ -z "$dep" ] && continue

        case "$dep" in
            /System/*|/usr/lib/*|@executable_path/*|@loader_path/*|@rpath/*)
                continue
                ;;
        esac

        case "$dep" in
            *.framework/*)
                continue
                ;;
        esac

        local dep_name
        dep_name="$(basename "$dep")"
        local bundled_dep="$FRAMEWORKS_DIR/$dep_name"

        if [ ! -f "$bundled_dep" ]; then
            cp -fL "$dep" "$bundled_dep"
            chmod 644 "$bundled_dep"
            install_name_tool -id "@rpath/$dep_name" "$bundled_dep" 2>/dev/null || true
            bundle_non_system_dependencies "$bundled_dep"
        fi

        rewrite_dependency "$target_file" "$dep"
    done < <(otool -L "$target_file" | tail -n +2 | awk '{print $1}')
}

find_qt_psql_plugin() {
    local candidates=()

    if command -v qtpaths >/dev/null 2>&1; then
        candidates+=("$(qtpaths --plugin-dir 2>/dev/null)/sqldrivers/libqsqlpsql.dylib")
    fi

    if command -v qmake >/dev/null 2>&1; then
        candidates+=("$(qmake -query QT_INSTALL_PLUGINS 2>/dev/null)/sqldrivers/libqsqlpsql.dylib")
    fi

    if [ -n "${QT_ROOT_DIR:-}" ]; then
        candidates+=("$QT_ROOT_DIR/plugins/sqldrivers/libqsqlpsql.dylib")
    fi

    local candidate
    for candidate in "${candidates[@]}"; do
        if [ -n "$candidate" ] && [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

find_brew_libpq() {
    if ! command -v brew >/dev/null 2>&1; then
        return 1
    fi

    local brew_prefix
    brew_prefix="$(brew --prefix libpq 2>/dev/null || true)"
    if [ -z "$brew_prefix" ] || [ ! -d "$brew_prefix/lib" ]; then
        return 1
    fi

    local candidate
    for candidate in \
        "$brew_prefix/lib/libpq.5.dylib" \
        "$brew_prefix/lib/libpq.dylib" \
        "$brew_prefix/lib/libpq"*.dylib
    do
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

prepare_qt_sql_plugins() {
    local psql_plugin="$1"
    QT_SQLDRIVERS_SOURCE_DIR="$(cd "$(dirname "$psql_plugin")" && pwd)"
    TEMP_QT_SQL_BACKUP_DIR="$(mktemp -d)"

    local sql_plugin
    for sql_plugin in "$QT_SQLDRIVERS_SOURCE_DIR"/libqsql*.dylib; do
        [ -e "$sql_plugin" ] || continue

        if [ "$sql_plugin" != "$psql_plugin" ]; then
            mv -f "$sql_plugin" "$TEMP_QT_SQL_BACKUP_DIR/"
        fi
    done

    cp -f "$psql_plugin" "$TEMP_QT_SQL_BACKUP_DIR/libqsqlpsql.dylib.original"

    local current_libpq
    current_libpq="$(otool -L "$psql_plugin" | awk '/libpq.*dylib/{print $1; exit}')"
    local brew_libpq
    brew_libpq="$(find_brew_libpq || true)"

    if [ -n "$current_libpq" ] && [ -n "$brew_libpq" ] && [ "$current_libpq" != "$brew_libpq" ]; then
        install_name_tool -change "$current_libpq" "$brew_libpq" "$psql_plugin"
    fi
}

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

QT_PSQL_PLUGIN="$(find_qt_psql_plugin || true)"
if [ -z "$QT_PSQL_PLUGIN" ]; then
    echo "Qt PostgreSQL plugin libqsqlpsql.dylib not found. QPSQL deployment cannot continue."
    exit 1
fi

prepare_qt_sql_plugins "$QT_PSQL_PLUGIN"

macdeployqt "$APP_PATH" -qmldir="$QML_DIR"

mkdir -p "$FRAMEWORKS_DIR" "$SQLDRIVERS_DIR"

cp -fL "$QT_PSQL_PLUGIN" "$SQLDRIVERS_DIR/libqsqlpsql.dylib"
chmod 755 "$SQLDRIVERS_DIR/libqsqlpsql.dylib"
bundle_non_system_dependencies "$SQLDRIVERS_DIR/libqsqlpsql.dylib"

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
