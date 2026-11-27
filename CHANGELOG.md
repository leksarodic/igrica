# Changelog

## 0.1.2 — 2026-11-27

### Fixed

- **W/S were inverted.** Keyboard input used Godot's `get_vector` convention (+Y = back), while the touch stick used +Y = forward. `InputRouter` now normalizes both to +Y = forward, so W walks toward the camera's forward direction and S walks back. Added assertions for both directions.
- The camera follows correctly in the same pass; the movement regression test now checks direction, not just distance.

### Verified

- 47 logic/save/sync checks, 52 integration checks (spawn, forward, backward, visible terrain, quest/puzzle chain), 36 end-to-end playthrough checks.
- macOS release booted and direction-checked; Windows CI rebuilt and smoke-tested.

## 0.1.1 — 2026-11-27

### Fixed

- **Critical movement fix:** outdoor terrain collision was one-sided, so a player spawned exactly on the heightfield could fall through and become wedged inside a terrain seam. Terrain now uses two-sided trimesh collision, and an integration regression test verifies the player spawns on the ground and walks across Bellhollow.
- The camera follows the player correctly now that the player can move; the previous behavior looked like a frozen backdrop because the body was stuck.

### Added

- **Windows 10/11 64-bit build** (`TheLongNote-0.1.1-Windows.zip`), built and smoke-tested on a GitHub Actions Windows runner for Bellhollow, Reedwater, and the Sunken Choir.
- Multi-size Windows icon, Windows export preset, release script support, and Windows instructions.

### Verified

- 47 logic/save/sync checks, 49 integration checks (including outdoor movement), 36 end-to-end playthrough checks.
- macOS release boot and capture; Windows CI export and three-region smoke test; iOS unsigned device build.

## 0.1.0 — 2026-11-27

**The Long Note — playable vertical slice**

### Added

- Original world, story, and 8,996-word novella (“The Long Note”).
- Bellhollow hub, Reedwater, the Sunken Choir dungeon, and a seeded Undersong side-cave.
- Third-person movement, camera, sprint, dodge, Listen pulse, interaction.
- Melee combat with weapons, pitch bonuses, poise, stagger, healing, and difficulty settings.
- Five enemy archetypes and the Hollow Stag boss with a chime-order shell puzzle.
- Nissa as a persistent AI companion with follow/engage/wait, ranged support, weak-point marking, and barks.
- Two main quests and two side quests: Pip’s Bell and the north-dock repair.
- Chime Gate, Sluice, Echo Gallery, and Stag Window puzzles.
- Inventory, equipment, crafting, five buildable structures with persistence, skills, journal/lore/echoes, party, map, and settings.
- Field-notebook UI, character sheet, dialogue with choices, boss bar, and a complete ending screen.
- Atomic checksummed saves, backups, corruption quarantine, autosave, manual/new slots, explicit cross-device handoff, conflict preservation, and `.longnote` export/import.
- macOS universal release (ad-hoc signed), a 64-bit Windows release, and an unsigned iOS Xcode project.
- Procedural original audio: bells, reeds, strings, wind, ambience, generative music beds.
- Content validator, 47 logic/save/sync checks, 47 integration checks, and a 36-check end-to-end playthrough.

### Known limitations

- The full seven-chapter game is not included. Glasswood, the Quarry Door, the Vault of Voices, the Hush, and the Low Water are designed but not built.
- No signed IPA and no physical-iPhone run; iCloud on iOS requires signing and entitlements.
- No co-op networking.
- Bellhollow foreground art and camera clipping need another pass; draw calls exceed the mobile target.
- Audio has not been auditioned on external speakers or a phone.
- Full control remapping, haptics, localization, and voice acting are not shipped.

See `docs/PLAYTESTING.md` for the complete evidence and defect list.
