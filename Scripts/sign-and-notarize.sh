#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_PATH=""
IDENTITY=""
NOTARY_PROFILE=""
TEAM_ID=""

usage() {
  cat <<'USAGE'
Usage: Scripts/sign-and-notarize.sh --app PATH --identity "Developer ID Application: Name (TEAMID)" [options]

Options:
  --app PATH               Path to .app bundle.
  --identity VALUE         Developer ID Application signing identity from Keychain.
  --notary-profile VALUE   notarytool keychain profile name. If set, submit and staple.
  --team-id VALUE          Apple Developer Team ID, used for codesign when needed.
  -h, --help               Show this help.

Before notarizing, create a notarytool profile once:
  xcrun notarytool store-credentials anycmd-notary --apple-id you@example.com --team-id TEAMID --password APP_SPECIFIC_PASSWORD
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP_PATH="$2"
      shift 2
      ;;
    --identity)
      IDENTITY="$2"
      shift 2
      ;;
    --notary-profile)
      NOTARY_PROFILE="$2"
      shift 2
      ;;
    --team-id)
      TEAM_ID="$2"
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

if [[ -z "$APP_PATH" || -z "$IDENTITY" ]]; then
  usage >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH" >&2
  exit 1
fi

CODESIGN_ARGS=(
  --force
  --deep
  --options runtime
  --timestamp
  --sign "$IDENTITY"
)

if [[ -n "$TEAM_ID" ]]; then
  CODESIGN_ARGS+=(--team-id "$TEAM_ID")
fi

codesign "${CODESIGN_ARGS[@]}" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose "$APP_PATH" || true

if [[ -z "$NOTARY_PROFILE" ]]; then
  echo "Signed $APP_PATH"
  echo "Notarization skipped because --notary-profile was not provided."
  exit 0
fi

ZIP_PATH="${APP_PATH%/}.zip"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_PATH"
spctl --assess --type execute --verbose "$APP_PATH"

echo "Signed and notarized $APP_PATH"
