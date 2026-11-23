#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
ROOT="$(pwd)"
mkdir -p "$ROOT/build/ios"
set +e
"$GODOT" --headless --path game --export-debug "iOS" "$ROOT/build/ios/LongNote.xcodeproj"
STATUS=$?
set -e
if [ ! -d build/ios/LongNote.xcodeproj ]; then
  echo "iOS export did not produce an Xcode project (exit $STATUS)."
  echo "Install the 4.7.2 iOS export templates and check the team ID in game/export_presets.cfg."
  exit 1
fi
if [ -f build/ios/LongNote/LongNote-Info.plist ]; then
  python3 tools/ios_post_export.py build/ios/LongNote/LongNote-Info.plist
fi
echo
echo "Xcode project ready: build/ios/LongNote.xcodeproj"
echo "Next: open it, choose your Apple team, set a unique bundle id, add iCloud if desired."
echo "Unsigned compile check:"
echo "  xcodebuild -project build/ios/LongNote.xcodeproj -scheme LongNote \\"
echo "    -configuration Debug -sdk iphoneos CODE_SIGNING_ALLOWED=NO build"
echo "A signed device build requires a provisioning profile; see docs/architecture/ios_build.md."
