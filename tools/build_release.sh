#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
GODOT="${GODOT:-godot}"
VERSION="0.1.2"
OUT="$ROOT/build/release"
APP="$OUT/macos/LongNote.app"
rm -rf "$OUT"
mkdir -p "$OUT/macos" "$OUT/dmg"

echo "== release export: macOS =="
"$GODOT" --headless --path game --export-release "macOS" "$APP"

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  codesign --deep --force --options runtime --sign "$CODESIGN_IDENTITY" "$APP"
else
  # Ad-hoc signing is enough for a local download; it is not notarization.
  codesign --force --deep --sign - "$APP"
fi

echo "== package: zip =="
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/TheLongNote-$VERSION-macOS.zip"

echo "== package: dmg =="
cp -R "$APP" "$OUT/dmg/The Long Note.app"
cat > "$OUT/dmg/Read Me.txt" <<'EOF'
The Long Note — 0.1.2

A valley kept alive by a song. A song made of people.

This build is ad-hoc signed, not notarized. On first launch macOS will ask you to
confirm: right-click the app and choose Open. If you prefer, run once:

  xattr -dr com.apple.quarantine "/Applications/The Long Note.app"

Controls: WASD, mouse; middle-drag or Ctrl-drag for the camera; J/K attack;
Space dodge; E interact; F listen; Esc pause. The pause notebook has every screen.

The game saves locally at every lantern, region threshold, and app pause. It
never sends notifications and never asks you to come back.

The valley will wait.
EOF
ln -sf /Applications "$OUT/dmg/Applications"
hdiutil create -volname "The Long Note" -srcfolder "$OUT/dmg" -ov -format UDZO "$OUT/TheLongNote-$VERSION-macOS.dmg" >/dev/null

echo "== Windows release =="
mkdir -p "$OUT/windows"
"$GODOT" --headless --path game --export-release "Windows Desktop" "$OUT/windows/TheLongNote.exe"
(cd "$OUT/windows" && zip -q -9 "TheLongNote-$VERSION-Windows.zip" TheLongNote.exe)

echo "== iOS Xcode project =="
mkdir -p "$OUT/ios"
set +e
"$GODOT" --headless --path game --export-debug "iOS" "$OUT/ios/LongNote.xcodeproj"
set -e
if [ -d "$OUT/ios/LongNote.xcodeproj" ]; then
  if [ -f "$OUT/ios/LongNote/LongNote-Info.plist" ]; then
    python3 tools/ios_post_export.py "$OUT/ios/LongNote/LongNote-Info.plist"
  fi
  cat > "$OUT/ios/README-iOS.txt" <<'EOF'
The Long Note — iOS Xcode project (unsigned)

This is not a signed IPA. It is the generated Godot iOS project and runtime.

1. Open LongNote.xcodeproj in Xcode.
2. Choose your Apple team and a unique bundle identifier.
3. Build to a connected iPhone, or Product > Archive for distribution.

iCloud sync needs the iCloud capability and container; see
docs/architecture/ios_build.md. Without it, the game falls back to local saves
and explicit .longnote export/import.

Godot 4.7.2's iOS template supplies x86_64 simulator slices, so an Apple Silicon
simulator build fails; use a device or an x86_64/Rosetta simulator.
EOF
  (cd "$OUT/ios" && zip -q -r "$OUT/TheLongNote-$VERSION-iOS-Xcode.zip" .)
fi

shasum -a 256 "$OUT"/*.dmg "$OUT"/*.zip "$OUT"/windows/*.zip 2>/dev/null > "$OUT/SHA256SUMS.txt" || true
ls -lh "$OUT"/*.dmg "$OUT"/*.zip "$OUT"/windows/*.zip 2>/dev/null || true
echo "Release artifacts are in $OUT"
