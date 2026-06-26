#!/usr/bin/env bash
# Build MDFlux as a native macOS .app bundle.
# The .app contains the Rust binary + the Svelte frontend + the Python sidecar
# sources (resources/). On first launch the app downloads uv + Python + deps to
# ~/Library/Application Support/com.projektvisyo.mdflux — same online-provisioning
# model as the Windows build, fully offline afterwards.
#
# Usage:  scripts/make-macos.sh            # build the .app
#         scripts/make-macos.sh --zip      # build, then zip the .app for archiving
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/app"

# Make cargo available even in a non-login shell.
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

cd "$APP_DIR"

# Build the .app bundle (frontend build + release Rust compile happen via Tauri).
# tauri.macos.conf.json activates the "app" bundle target on macOS only.
npm run tauri build -- --bundles app

# Locate the produced .app (path depends on the active Rust target triple).
BUNDLE_DIR="$APP_DIR/src-tauri/target/release/bundle/macos"
APP_PATH="$(/usr/bin/find "$BUNDLE_DIR" -maxdepth 1 -name '*.app' -print -quit)"
[ -n "$APP_PATH" ] || { echo "No .app found under $BUNDLE_DIR" >&2; exit 1; }

echo "Built: $APP_PATH"

if [ "${1:-}" = "--zip" ]; then
  VERSION="$(/usr/bin/grep '"version"' "$APP_DIR/src-tauri/tauri.conf.json" | head -1 | sed -E 's/.*"version": "([^"]+)".*/\1/')"
  DIST="$ROOT/dist"
  mkdir -p "$DIST"
  ZIP="$DIST/MDFlux_${VERSION}_macos.zip"
  rm -f "$ZIP"
  /usr/bin/ditto -c -k --keepParent "$APP_PATH" "$ZIP"
  echo "Zipped: $ZIP"
fi
