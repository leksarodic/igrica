# Project Plan — *The Long Note*

**Studio:** independent, small team (creative direction, narrative, design, engineering, art, audio, QA)
**Engine:** Godot 4.7.2
**Targets:** macOS 13+ (Apple Silicon and Intel via universal build), iOS 16+ (iPhone 11 and newer recommended)
**Repository:** `github.com/leksarodic/igrica`

---

## 1. Delivery strategy

An open-world RPG is too large to build safely in one pass. The plan is a **production vertical slice** with the architecture and content pipeline of the full game: one hub, one outdoor region, one handcrafted dungeon, one boss, one companion, two quests, four puzzles, a complete save/sync system, and a polished cross-platform UI. Everything in the slice is real, tested, and playable. Content beyond the slice is designed but explicitly marked not shipped.

The ordering is deliberate: narrative and systems are specified before code; pure logic is tested before it is wired to scenes; the world is built with procedural art so visual quality scales with iteration rather than asset production; platform work is integrated from the first week, not bolted on at the end.

**Definition of done for any feature:** it works in the running game, has an automated test where the logic allows it, has been manually exercised on macOS, has a documented iPhone path, and is listed accurately in the README. A script or a screen that only looks functional does not count.

---

## 2. Phases and milestones

### Phase 1 — Creative direction (complete)

- Three original concepts with worlds, mysteries, loops, emotional atmospheres, and platform fit.
- Comparative decision and justification.
- Game design document, art direction, audio direction, UX design, technical architecture.
- Character, faction, region, and story outlines that the novella will test.
- **Exit criteria:** a reader can explain the game, its hook, and how the systems connect, without seeing code.

### Phase 2 — Narrative foundation (complete)

- A complete standalone novella (~7,500–9,000 words) set twelve years before the game.
- Lore, characters, factions, locations, timeline, and story-structure documents.
- Continuity check across all documents; no contradictions with the game's premise.
- **Exit criteria:** the novella reads as a story, not a synopsis; every named place and faction in the game appears consistently in the lore.

### Phase 3 — Technical foundation (complete)

- Godot project boots on macOS; headless mode works; test runner works.
- Core autoloads: `Game`, `Events`, `Settings`, `GameState`, `SaveManager`, `SyncService`, `Platform`, `ContentDB`, `AudioDirector`.
- Input abstraction with keyboard/mouse, gamepad, and touch modes; camera; player controller; interaction; terrain and region loading; pause.
- Save format v1 with checksum, atomic write, backup, migration hook; sync adapter interface + local folder adapter + conflict logic.
- Basic UI shell and theme.
- **Exit criteria:** move around a test region, open the pause ring, save, quit, relaunch, continue in the same place.

### Phase 4 — Playable vertical slice (complete)

- Bellhollow hub with NPCs, vendors, bench, lantern, quest board, visible repairs.
- Reedwater outdoor region with gathering, combat, secrets, ferry, and the dungeon entrance.
- The Sunken Choir dungeon with the Sluice and Echo Maze puzzles, the Stone Sentinel, and the Hollow Stag boss with the Stag's Window puzzle.
- The Chime Gate overworld puzzle with multiple valid solutions.
- Two enemy types minimum (four implemented), one companion (Nissa), one quest with a consequential choice, two side quests.
- Inventory, equipment, crafting, building, skills, journal, quest log, map, party screen.
- Full save/load including world state and built structures.
- **Exit criteria:** a new player can start, learn, explore, solve, fight, choose, save, and stop, without a developer explaining anything.

### Phase 5 — Cross-platform experience (complete, with a documented signing gap)

- macOS: keyboard/mouse, controller, resizable window, native menus, correct scaling.
- iPhone: touch HUD, floating stick, camera drag, safe areas, landscape, quality presets, lifecycle save, haptics (optional).
- Shared gameplay and UI logic; no fork in the codebase.
- Save portability via folder/iCloud adapter; explicit "Save and continue on another device"; conflict screen.
- iOS export preset and Xcode project generation; build validation as far as the environment permits.
- **Exit criteria:** macOS build runs and passes the smoke test; iOS export produces a valid Xcode project; the sync path is tested with two simulated devices; remaining signing steps are documented precisely.

### Phase 6 — Expand the world (out of scope for this build)

- Kestrel Crags, Glasswood, Undersong, the Hush, the Low Water.
- Chapters 3–7, eight side quests, three more bosses, three companions, the remaining items/skills/recipes/puzzles.
- Full ending set and epilogue.
- Co-op prototype (host-authoritative, invite-only).
- **This phase is designed in the GDD but not shipped.** The repository contains hooks (region registry, content data, session interface) but no fake content.

### Phase 7 — Polish and testing (ongoing, complete for the slice)

- Performance pass on Mac and iPhone-class settings.
- Save corruption, conflict, termination, background/foreground, input, scaling, memory, progression, puzzle correctness, AI behaviour tests.
- Accessibility pass, playtest protocol, defect log.
- **Exit criteria:** no known progression blocker; no data-loss path; all tests green; documented limitations.

---

## 3. Work breakdown (this build)

| Workstream | Items | Owner role |
|---|---|---|
| Narrative | Novella, lore, characters, factions, locations, timeline, dialogue, quest text | Narrative designer / world author |
| Systems | State, inventory, crafting, building, quests, dialogue, puzzles, progression | Systems designer |
| Combat | Player, weapons, abilities, enemies, companion, boss, damage, status | Gameplay designer / engineer |
| World | Terrain, regions, props, lighting, weather, nav, streaming, secrets | World builder / artist |
| UI/UX | Theme, HUD, screens, touch, accessibility, onboarding | UX designer |
| Audio | Synth, music director, ambience, SFX, mixing | Audio engineer |
| Platform | macOS export, iOS export, iCloud bridge, lifecycle, input | Technical architect |
| QA | Unit, integration, content validation, visual smoke, playtest | QA / all |

---

## 4. Technical milestones and gates

1. **Boot gate:** project opens without errors; headless test runner exits 0.
2. **Movement gate:** player moves, camera orbits, collisions hold, 60 fps in a test scene.
3. **Save gate:** 100 save/load round-trips with random state, checksum verified, no corruption; kill -9 during write recovers from backup.
4. **Sync gate:** two simulated devices produce a conflict; all three resolution paths preserve data.
5. **Slice gate:** scripted end-to-end test completes the quest and boss; manual playthrough on macOS.
6. **Platform gate:** macOS export launches; iOS export produces an Xcode project; simulator build attempted and documented.
7. **Polish gate:** UI at six resolutions, touch at two iPhone sizes, accessibility options verified, no placeholder art or dead interactions.

---

## 5. Risks and responses

| Risk | Likelihood | Impact | Response |
|---|---|---|---|
| Scope exceeds one cycle | High | High | Slice-first; region loading; procedural art; explicit non-shipped list |
| iPhone performance | Medium | High | Mobile renderer, strict budgets, MultiMesh, quality presets, early profiling |
| iOS signing unavailable | Certain in this environment | Medium | Implement everything; validate export; document exact remaining steps; never claim a signed build |
| Puzzle or quest soft-lock | Medium | High | State-machine puzzles with reset; progression tests; hints; no required consumables |
| Save corruption | Low | Critical | Atomic writes, checksums, backups, quarantine, migration tests, kill tests |
| Tone drift | Medium | High | Style bible, naming rules, review checklist, no generic fantasy vocabulary |
| Audio synthesis cost on iPhone | Medium | Medium | Pre-bake with budget, cache, degrade to ambience only, fail silent |
| Companion AI feels generic | Medium | Medium | Distinct voice, opinions, refusal, puzzle etiquette, limited chatter, tests for non-annoyance |
| Content pipeline slows | Medium | Medium | JSON + validation; hot-reload in debug; content IDs checked at boot |

---

## 6. Testing plan (detail in `PLAYTESTING.md`)

- **Automated:** GDScript headless suite (logic + scene integration), Python content/docs validator, export smoke script.
- **Manual:** a structured 90-minute first-session protocol, a 30-minute "return after absence" protocol, a touch-only protocol, a keyboard-only protocol, a gamepad protocol, an accessibility protocol, and an adversarial save/sync protocol.
- **Visual:** capture harness for hub, region, dungeon, boss, and each screen at desktop and phone aspect ratios; reviewed against the art direction checklist.
- **Performance:** frame-time capture on the target Mac; iPhone simulator is not a performance proxy, so budgets are enforced statically and the limitation is documented.

---

## 7. Repository and release discipline

- Logical commits at phase and subsystem milestones; commit messages describe player-visible or architectural change.
- No credentials, keys, or personal data in the repo. iCloud container IDs are configuration, not secrets.
- `README.md` is the single source of truth for how to run, build, test, and what is implemented.
- No push to remotes other than the project repository; no force-push over history.
- Versioning: `0.1.0` for the vertical slice; `1.0.0` reserved for the full game.
- Licenses: engine (MIT), fonts (system, not redistributed), all art/audio original. Third-party assets, if any, are documented before merge.

---

## 8. Status ledger

| Phase | Status | Evidence |
|---|---|---|
| 1 Creative direction | Complete | `docs/GAME_CONCEPTS.md`, GDD, art/audio/UX, architecture |
| 2 Narrative | Complete | `docs/story/*`, word count verified |
| 3 Technical foundation | Complete | project boots, tests pass, save round-trip |
| 4 Vertical slice | Complete | playable build; end-to-end test |
| 5 Cross-platform | Complete with signing gap | macOS app; iOS Xcode project; sync tested with simulated devices |
| 6 Expansion | Designed, not shipped | GDD scope table |
| 7 Polish | Complete for slice | test report, playtest log, known issues |

This ledger is updated only with evidence. Where something is partial, it says so.
