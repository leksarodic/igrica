# iPhone Build and Platform Integration

**Status:** Xcode project generated; unsigned device build succeeded; signed build, TestFlight, and physical-device testing are blocked by missing Apple Developer credentials and a device.

This document is the exact remaining path. It does not claim a signed iPhone app exists.

---

## 1. What is shared

100% of gameplay, content, UI logic, save logic, art generation, and audio are shared with macOS. Platform-specific code is limited to:

- input presentation (touch HUD vs keyboard/gamepad),
- lifecycle notifications (background/focus),
- safe-area layout,
- iCloud container path discovery (path adapter with fallback),
- export settings.

There is no forked gameplay codebase.

---

## 2. Prerequisites

1. macOS with Xcode (this build used the iOS 27.2 SDK).
2. Godot 4.7.2 stable + iOS export templates installed.
3. An Apple Developer account with a team ID.
4. A provisioning profile for the bundle identifier.
5. A physical iPhone (recommended) or an x86_64 simulator.

The project bundle identifier is `com.leksarodic.longnote`. Change it if you do not control that identifier.

---

## 3. Export the Xcode project

```sh
cd game
mkdir -p ../build/ios
godot --headless --path . --export-debug "iOS" ../build/ios/LongNote.xcodeproj
```

The preset (`export_presets.cfg`) intentionally uses a placeholder team ID:

```ini
application/app_store_team_id="XXXXXXXXXX"
```

Godot requires a non-empty team ID to generate the project. Replace it with your team ID before archiving.

Generated artifacts:

```
build/ios/
  LongNote.xcodeproj
  LongNote/                 # Xcode target sources, Info.plist, assets
  LongNote.pck              # game content
  LongNote.xcframework      # Godot runtime
  MoltenVK.xcframework
  PrivacyInfo.xcprivacy
  libgodot_camera.visionos...
```

---

## 4. Build

### Unsigned device build (verification only)

```sh
cd build/ios
xcodebuild -project LongNote.xcodeproj -scheme LongNote \
  -configuration Debug -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Result in this environment: **BUILD SUCCEEDED**. The resulting `.app` is unsigned and cannot be installed on a device.

### Signed build

1. Open `LongNote.xcodeproj` in Xcode.
2. Select the `LongNote` target → Signing & Capabilities.
3. Choose your team; let Xcode create a profile.
4. Set a unique bundle identifier if needed.
5. Select a connected iPhone and Run, or Product → Archive for distribution.
6. Add the iCloud capability if you want automatic iCloud sync (see §5).

### Simulator limitation

`xcodebuild -sdk iphonesimulator` on this Apple Silicon machine fails because the Godot 4.7.2 iOS template supplies **x86_64** simulator slices while the simulator expects **arm64**:

```text
ld: warning: ignoring file .../libgodot.a(...x86_64.simulator.o)
found architecture 'x86_64', required architecture 'arm64'
Undefined symbols for architecture arm64: _main
```

Options:

- Use a physical iPhone (recommended).
- Use an x86_64 simulator under Rosetta (not validated here).
- Use a Godot build/template with arm64 simulator slices (not available in the installed 4.7.2 template).

No successful simulator run is claimed.

---

## 5. iCloud and file sharing

The game's sync model is file-level and offline-first. It does **not** require CloudKit or a custom account.

### macOS

The game detects `~/Library/Mobile Documents/com~apple~CloudDocs/LongNote` and uses it as the sync root. This is the path shown in the Save & Sync screen on this machine. If iCloud Drive is not mounted, it falls back to `user://sync`.

### iOS

The game looks for:

```
~/Library/Mobile Documents/iCloud~com~leksarodic~longnote/Documents
```

This path is only accessible when the app is signed with:

- the **iCloud** capability,
- an ubiquity container identifier, e.g. `iCloud.com.leksarodic.longnote`,
- an entitlement that includes `com.apple.developer.ubiquity-container-identifiers`,
- `NSUbiquitousContainers` in `Info.plist`.

Without the entitlement, the path check fails and the game silently uses local storage plus the explicit package export, which is honest and safe.

### Recommended Xcode configuration

In Signing & Capabilities:

1. Add **iCloud**.
2. Enable **iCloud Documents**.
3. Add container `iCloud.com.leksarodic.longnote`.

Add to `Info.plist`:

```xml
<key>NSUbiquitousContainers</key>
<dict>
  <key>iCloud.com.leksarodic.longnote</key>
  <dict>
    <key>NSUbiquitousContainerIsDocumentScopePublic</key>
    <true/>
    <key>NSUbiquitousContainerName</key>
    <string>The Long Note</string>
    <key>NSUbiquitousContainerSupportedFolderLevels</key>
    <string>Any</string>
  </dict>
</dict>
```

Add an entitlements file with:

```xml
<key>com.apple.developer.ubiquity-container-identifiers</key>
<array>
  <string>iCloud.com.leksarodic.longnote</string>
</array>
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)com.leksarodic.longnote</string>
```

The game does not use CloudKit records or an account. The container is a file folder.

### File sharing / manual transfer

Without iCloud, the player can use Save & Sync → **Export journey…** to write a `.longnote` package and transfer it by AirDrop, Files, Finder, or a shared folder, then **Import journey…** on the other device. To expose the app's Documents folder in the Files app, add:

```xml
<key>UIFileSharingEnabled</key><true/>
<key>LSSupportsOpeningDocumentsInPlace</key><true/>
```

These keys are not added automatically by the export preset; add them in Xcode or via `plutil` after export.

---

## 6. iPhone-specific behavior in the project

- **Orientation:** landscape (`display/window/handheld/orientation=0`).
- **Safe area:** HUD, joystick, and action cluster inset by `DisplayServer.get_display_safe_area()` scaled to the viewport.
- **Touch HUD:** floating left stick (appears where the thumb lands), right-side camera drag, thumb-arc cluster: Strike (76 dp), Use (72), Heavy (68), Dodge (68), Listen (64), abilities (60), Menu pill (44).
- **Text:** body text uses a minimum effective 15 pt in landscape; text scale 80–160%.
- **Quality:** Low (battery) / Balanced / High; Low disables the color grade, shadow quality is reduced, and 3D resolution scale is 0.7.
- **Lifecycle:** pause + save + sync on background/focus loss; resume restores state.
- **Audio:** no autoplay before input; session deactivated on pause; mono option.

Verified on macOS with the touch HUD forced on (`--touch`). Not verified on a physical iPhone.

---

## 7. Remaining requirements for a shippable iPhone build

1. Replace the placeholder team ID with a real team.
2. Set a unique bundle identifier and create/download a provisioning profile.
3. Add the iCloud capability and container if automatic sync is desired.
4. Add `UIFileSharingEnabled` / `LSSupportsOpeningDocumentsInPlace` for manual transfer.
5. Build and run on a physical iPhone or an x86_64 simulator.
6. Profile on the device: frame time, thermal state, memory, battery, audio session interruptions, background save.
7. Test safe areas on a notched and a non-notched device.
8. Test the touch layout one-handed and with the device rotated; ensure no controls sit under the home indicator.
9. Test iCloud download-before-open behavior and conflicts with two signed devices.
10. Produce a signed archive and TestFlight build; not possible here.

None of these are claimed complete.
