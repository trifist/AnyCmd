#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME=""
ENABLE_LOGGING=0
APP_NAME_WAS_SET=0

usage() {
  cat <<'USAGE'
Usage: Scripts/build-app.sh [options]

Options:
  --with-logs              Build a diagnostic app that writes ~/Library/Logs/AnyCmd.log.
  --no-logs               Build a release-style app with logging compiled out. This is the default.
  --configuration VALUE    Swift build configuration: release or debug. Default: release.
  --app-name VALUE         Override output app bundle name without .app.
  -h, --help               Show this help.

Examples:
  Scripts/build-app.sh
  Scripts/build-app.sh --with-logs
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-logs)
      ENABLE_LOGGING=1
      shift
      ;;
    --no-logs)
      ENABLE_LOGGING=0
      shift
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --app-name)
      APP_NAME="$2"
      APP_NAME_WAS_SET=1
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$APP_NAME_WAS_SET" == "0" ]]; then
  if [[ "$ENABLE_LOGGING" == "1" ]]; then
    APP_NAME="AnyCmd-Logs"
  else
    APP_NAME="AnyCmd"
  fi
fi

if [[ "$ENABLE_LOGGING" == "1" ]]; then
  BIN_DIR="$(swift build -c "$CONFIGURATION" -Xswiftc -D -Xswiftc ANYCMD_ENABLE_LOGGING --show-bin-path)"
  swift build -c "$CONFIGURATION" -Xswiftc -D -Xswiftc ANYCMD_ENABLE_LOGGING
else
  BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
  swift build -c "$CONFIGURATION"
fi

APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$ROOT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$BIN_DIR/AnyCmd" "$APP_DIR/Contents/MacOS/AnyCmd"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

echo "Built $APP_DIR"
if [[ "$ENABLE_LOGGING" == "1" ]]; then
  echo "Logging: enabled"
else
  echo "Logging: disabled"
fi
