# Changelog

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
- macOS universal release (ad-hoc signed) and an unsigned iOS Xcode project.
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
