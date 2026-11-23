#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
ROOT="$(pwd)"
mkdir -p "$ROOT/build/macos"
"$GODOT" --headless --path game --export-debug "macOS" "$ROOT/build/macos/LongNote.app"
if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  echo "Signing with $CODESIGN_IDENTITY"
  codesign --deep --force --options runtime --sign "$CODESIGN_IDENTITY" build/macos/LongNote.app
else
  echo "Unsigned build. Set CODESIGN_IDENTITY to sign, then notarize for distribution."
fi
echo "Run: open build/macos/LongNote.app"
