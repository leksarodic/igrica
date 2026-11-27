# Playtesting and Verification

**Build:** 0.1.0 vertical slice
**Date:** 23 November 2026
**Hardware:** Apple M3, 16 GB, macOS 27.2.1, 2560×1664 internal display
**Engine:** Godot 4.7.2 stable (Metal 4 Forward Mobile)
**Xcode:** iOS 27.2 SDK, iPhone 18 Pro simulator available (not used for a successful build; see limitations)
**Repo:** `github.com/leksarodic/the-long-note`

This document records what was actually run, what passed, and what is still broken. It deliberately does not claim a feature is complete because a file exists.

---

## 1. Automated suites

### 1.1 Content and constraint validation

```sh
python3 tests/validate_content.py
```

Result: **OK**

- Novella: 8,996 words, 8 chapters, no placeholder text.
- Data: 31 items, 12 recipes, 4 quests, 8 dialogue graphs, 6 enemies, 5 regions, 8 skills, 5 buildables.
- Every recipe output, cost, enemy drop, build kit, dialogue target, quest stage, and region factory reference resolves.
- All required documents exist.
- No banned notification/retention APIs or strings in shipped scripts.
- No hardcoded credentials.
- Godot version pinned to 4.7, Mobile; iPhone orientation landscape; isolated user directory.

### 1.2 Logic, save, and sync suite

```sh
godot --headless --path game res://tests/TestScene.tscn
```

Result: **47 passed, 0 failed**

Coverage includes:

- Content loading and validation.
- Character creation, inventory add/remove, equipment stat recomputation, quest stage/choice, echoes/attunement, marks.
- Save round-trip (name, inventory, quests, flags, slot listing).
- Checksum rejection of a tampered save, with quarantine rather than deletion.
- Backup recovery after a deliberately corrupted main file.
- Two-device sync conflict, remote device identification, *Keep both* archival, local preservation, clean-device pull and progress verification.
- Atomic write and canonical checksum stability across JSON re-read.

### 1.3 Integration suite

```sh
godot --headless --path game res://tests/Integration.tscn
```

Result: **47 passed, 0 failed**

Coverage includes:

- Real region construction for Bellhollow, Reedwater, and the Sunken Choir.
- Player spawn, lantern registration, 196+ region children.
- Real Wren, Pell, Sable, Nissa, Brannoc, and Stag Choice dialogue graphs, including effects and conditions.
- Quest progression through main_01, main_02.
- Nissa becoming an active companion; main_01 completion.
- Chime Gate solved with the carving's chord; quest stage advanced.
- Hollow Stag shell puzzle, damage, defeat, and world flag.
- Workbench craft action through the UI code path.
- Building a lantern post, persistence in state, restore after region rebuild, no duplicate records.
- Explicit cross-device transfer: `Save and continue on another device` writes a verified shared snapshot.
- Save/load with quest and boss flags after the ending.
- Player movement under injected input (0.8 s forward, >0.3 m displacement).

### 1.4 End-to-end playthrough

```sh
godot --headless --path game res://tests/Playthrough.tscn
```

Result: **36 passed, 0 failed**

This test does not mock the game. It:

1. Creates a new character and builds Bellhollow.
2. Talks to Wren, Pell, Sable, and Nissa through the real dialogue UI and choices.
3. Picks up the real copper, humstone, and resin pickups.
4. Verifies the resonance fork is craftable.
5. Takes the real ferry transition to Reedwater.
6. Clears the real choke and solves the real Chime Gate.
7. Descends into the real Sunken Choir.
8. Solves the real sluice (open/shut/open).
9. Rings the real boss chimes in the window order, breaks the shell, and defeats the Stag.
10. Takes the real Choir Chime, resolves the real three-way choice, and confirms the quest is done.
11. Writes and reloads the ending save.

This is the strongest evidence that the slice is completable.

---

## 2. Build verification

### macOS

```sh
godot --headless --path game --export-debug "macOS" build/macos/LongNote.app
./build/macos/LongNote.app/Contents/MacOS/"The Long Note" --headless --quit-after 8 -- --world bellhollow
./build/macos/LongNote.app/Contents/MacOS/"The Long Note" --resolution 1440x810 -- --world bellhollow --capture /tmp/exported.png
```

- Debug export: **succeeded**, 178 MB universal bundle; boot and capture verified.
- Release export: **succeeded**, 163 MB universal bundle; ad-hoc signed (`codesign --sign -`) and booted; frame capture verified.
- Bundle is **ad-hoc signed, not notarized**. Developer ID signing and notarization were not possible without credentials; the release notes explain the first-launch confirmation.
- Release assets: macOS DMG 67.2 MB, macOS ZIP 59.5 MB, iOS Xcode ZIP 112.6 MB (uploaded sizes). The DMG checksum verified, and the app launched from the mounted DMG and captured a frame.

### Windows

```sh
godot --headless --path game --export-release "Windows Desktop" build/windows/TheLongNote.exe
file build/windows/TheLongNote.exe
```

- Export: **succeeded**, 104 MB 64-bit PE32+ GUI executable with the PCK embedded.
- Icon resources: multi-size ICO (16–256 px), no remaining icon warnings.
- GitHub Actions Windows 11 runner: **passed** — Godot import, Windows release export, and headless smoke tests for Bellhollow, Reedwater, and the Sunken Choir (exit code 0, no `SCRIPT ERROR`).
- Artifact tested by CI is the one attached to the release (39.5 MB ZIP, 109.5 MB exe).
- Artifact: `TheLongNote-0.1.0-Windows.zip` (36 MB).

### iPhone

```sh
godot --headless --path game --export-debug "iOS" build/ios/LongNote.xcodeproj
xcodebuild -project build/ios/LongNote.xcodeproj -scheme LongNote \
  -configuration Debug -sdk iphoneos CODE_SIGNING_ALLOWED=NO build
```

- Export: **produced** `LongNote.xcodeproj`, `LongNote.pck`, `LongNote.xcframework`, `MoltenVK.xcframework`, `PrivacyInfo.xcprivacy`.
- Device build (`iphoneos`, unsigned): **BUILD SUCCEEDED**.
- Signed archive / IPA: **not possible** — no Apple Developer account/team and no provisioning profile in this environment. The preset uses a placeholder team ID so the project can be generated.
- Simulator build: **failed** because Godot 4.7.2's iOS template provides x86_64 simulator slices and this Apple Silicon simulator expects arm64 (`_main` undefined after x86_64 objects are ignored). A physical device or an x86_64/Rosetta simulator is required.
- No physical iPhone run, no TestFlight, no on-device performance or touch validation.

### Performance sample (macOS, M3, 1440×810)

```sh
godot --path game -- --world bellhollow --benchmark
```

```text
fps=60  draws=336  primitives=118,920  memory=86.7 MB
```

336 draw calls is above the initial ≤150 target. It is playable at 60 fps on an M3, but the iPhone budget needs a batching pass (MultiMesh for reeds/rocks/trees and merged house meshes). This is recorded as a defect, not hidden.

---

## 3. Visual review

Captured from the running build:

| Capture | What it verifies |
|---|---|
| `docs/screenshots/bellhollow.png` | hub composition, tower silhouette, houses, NPC, path, lighting, grade |
| `docs/screenshots/dialogue.png` | paper dialogue panel, speaker, text, continue affordance |
| `docs/screenshots/journal.png` | pause notebook, sidebar, quest log, hint button |
| `docs/screenshots/workbench.png` | recipe list, costs, disabled states |
| `docs/screenshots/build.png` | build vocabulary and place actions |
| `docs/screenshots/touch.png` | floating stick, action cluster, menu pill |
| `docs/screenshots/ending.png` | one ending variant, statistics, clear completion |
| `docs/screenshots/sunken_choir.png` | dungeon entrance, lighting, door sightline |

Reviewed against the art-direction checklist: silhouettes read, palette is restrained, UI is paper/ink/copper, touch targets are large, the world is visible behind menus. The Bellhollow foreground is still darker and sparser than intended; the path ribbon is not consistently visible from the spawn camera. This is a real art defect.

---

## 4. Manual checks performed

- Launched the title screen and opened the character sheet.
- Created a character with name/pronouns/ear/coat and entered the world.
- Walked, sprinted, dodged, attacked, listened.
- Opened the pause notebook with Esc, visited every screen, and closed it.
- Opened dialogue via the real interaction path in capture mode; validated choices/continue layout.
- Forced the touch HUD and reviewed layout at 1440×810.
- Built a lantern post in ghost mode; confirmed the placement prompt and validity tint.
- Reviewed the ending screen for the Reedfolk choice.
- Exported and booted the macOS app.

Not performed manually: a complete keyboard-only playthrough by a human (the automated playthrough covers the same chain), a gamepad session, a real iPhone session, an audio listening pass, and a long-session memory soak.

---

## 5. Known defects and gaps

| # | Severity | Area | Description | Status |
|---|---|---|---|---|
| D1 | High | Platform | No signed iPhone build, no physical iPhone run; simulator template mismatch. | Documented; exact signing steps in `ios_build.md` |
| D1b | Medium | Platform | Windows build is exported and CI-smoke-tested, but not manually played on a physical Windows machine in this environment. | Documented |
| D2 | High | Content | Only chapters 1–2 and the slice finale are built; Glasswood, Hush, Quarry Door, Vault, Low Water are designed only. | Stated in README/GDD |
| D3 | Medium | Sync | iOS iCloud container path is implemented with fallback but unverified without entitlements/signing. | Documented |
| D4 | Medium | Art | Bellhollow foreground is too dark/sparse; path ribbon visibility is inconsistent; some props intersect terrain. | Open |
| D5 | Medium | Camera | Simple raycast + fixed indoor distance; tight corners can still clip. | Open |
| D6 | Medium | Audio | Audio is implemented and runs without errors but has not been auditioned on external speakers/phone. | Open |
| D7 | Medium | Performance | 336 draw calls on Mac; iPhone budgets need MultiMesh/merged meshes. | Open |
| D8 | Low | Combat | Chime Staff is not yet a true ranged weapon; it has a silhouette and stats. | Open |
| D9 | Low | Input | Full remapping, haptics, and gamepad glyph presentation are not shipped. | Designed |
| D10 | Low | Test harness | The visual capture harness depends on macOS GUI; headless CI covers logic only. | Documented |
| D11 | Low | Save UI | Conflict screen is implemented but was exercised with simulated devices; no manual two-Mac/iCloud session. | Partially verified |
| D12 | Low | Localization | English-only; all strings are in data/UI but no translation pipeline. | Designed |

---

## 6. Manual playtest protocol (next session)

### A. First 30 minutes (new player, no developer help)

1. Start from the title, create a character, and reach Bellhollow.
2. Without prompts: find Wren, Pell, Sable, Nissa; complete the fork and reach Reedwater.
3. Observe: where do they get stuck? Do they understand Listen? Do they find the bench? Do they know where the choke is?
4. Record time-to-first-puzzle, time-to-first-combat, and any moment of confusion.
5. Stop at a lantern; quit; relaunch; confirm Continue restores position, quest, inventory, and built structures.

### B. Return after absence (30 minutes, one week later)

1. Continue the save; confirm no timers, decay, or "welcome back" pressure.
2. Check the journal can reconstruct what was happening.
3. Finish the Choir and make the choice; read the ending.

### C. Touch-only (iPhone or forced touch HUD)

1. Landscape, one hand or two; reach and use every button.
2. Check safe areas, text size, camera drag, stick re-centering.
3. Pause, craft, build, save, and background the app; relaunch.

### D. Accessibility

1. Text scale 80/100/160%; subtitles and sound captions; colour-blind marks; reduced motion; difficulty change mid-fight.
2. Play muted and confirm every audio cue has a visual counterpart.

### E. Adversarial save/sync

1. Kill the app during a save; relaunch.
2. Corrupt a save; confirm quarantine + backup.
3. Create divergent progress on two folders; confirm all three resolutions preserve data.
4. Remove the shared folder mid-sync; confirm local save remains.

---

## 7. Acceptance checklist for this build

| Criterion | Status |
|---|---|
| Original identity, world, story | Yes — novella, bible, original names/art/audio |
| ~30-page story fully written | Yes — 8,996 words |
| Genuinely playable on macOS | Yes — editor and exported app |
| Designed and buildable for iPhone | Project generated, unsigned device build succeeds; signed/run blocked by credentials |
| Save and continue on another device | Implemented and tested with simulated devices; iCloud macOS path exists; iOS unverified |
| Offline complete and enjoyable | Yes for the slice; no network dependency |
| AI companions and enemies | Nissa + four archetypes + boss; tested in playthrough |
| Logic puzzles substantial | Four puzzle instances; automated and playthrough verified |
| Crafting/exploration integrated | Yes; resources, recipes, bench, pickups, building |
| No notifications/streaks/daily pressure | Yes; validator scans scripts |
| Polished interface | Strong notebook UI; art/foreground polish incomplete (D4) |
| Maintainable/documented code | Yes; architecture docs, content validator, tests |

---

*The test results above are from this machine and this build. Nothing is projected from an untested device.*
