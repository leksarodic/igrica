# The Long Note — Working TODO

**Current release:** 0.1.2 vertical slice (macOS, Windows, iPhone Xcode project).
**Rule:** an item is only checked when it works in the running game and is tested.

Legend: `[x]` done and verified · `[~]` partial · `[ ]` not started · **P0** critical · **P1** next · **P2** full game · **P3** later.

---

## P0 — Correctness and first-session quality

- [x] Outdoor terrain collision is two-sided; the player cannot fall through a seam at spawn.
- [x] W/S direction is correct on keyboard, gamepad, and touch (forward = camera forward).
- [x] Camera follows the player; movement regression asserts distance **and** direction.
- [x] macOS release boots; DMG checksum valid; app exported from the mounted DMG moves ~5 m.
- [x] Windows release builds and smoke-tests Bellhollow, Reedwater, and the Sunken Choir on a Windows CI runner.
- [ ] Manual 30-minute first-session playtest on a physical Windows machine (D1b).
- [ ] Manual 30-minute first-session playtest on a physical iPhone (D1).
- [ ] Signed iPhone build + TestFlight (blocked on Apple team/provisioning).
- [ ] Signed/notarized macOS release (Developer ID + notarytool).
- [ ] Camera occlusion: raycast currently handles interiors by a shorter fixed distance; verify no clipping in every region and every twist.
- [ ] Add a visible “Return to title / continue” confirmation only if the player has unsaved progress; never overwrite a newer save.
- [ ] Check all save slots load into the correct region/spawn after a fresh launch.
- [ ] Verify 0.1.2 saves load after a simulated app kill during write (kill -9 loop).

## P1 — Vertical-slice polish

### Controls and accessibility
- [ ] Full keyboard/gamepad remapping UI with conflict detection.
- [ ] Gamepad glyphs in prompts and dialogue, switching by last input device.
- [ ] Haptics: light combat tick, heavy hit, interact confirm; off by default on iPhone.
- [ ] Touch left-handed mirror layout; verify one-handed reach on a 6.1" and 6.7" phone.
- [ ] Text scale applied to dialogue and HUD live, not only after rebuilding a screen.
- [ ] High-contrast theme pass; verify 4.5:1 body text and focus rings.
- [ ] Screen-reader labels for every menu control; verify VoiceOver navigation.
- [ ] Colour-blind simulation review of pitch marks and puzzle states.
- [ ] Reduced-motion review: ribbons, camera shake, weather, grade.
- [ ] Add a “hold vs toggle” option for sprint/listen/parry where applicable.

### Camera, movement, feel
- [ ] Camera collision with terrain/props using a proper spring probe; no wall clipping.
- [ ] Lock-on/focus camera for boss and companion targeting.
- [ ] Step-up and slope polish; no rubber-banding on the Bellhollow ramp.
- [ ] Water entry/exit transition, swim stamina feedback, and a safe return to bank.
- [ ] Ladder/climb animation and marked-ledge traversal (Climber's Hook item exists but is not used).
- [ ] Add coyote time and jump if playtests ask for it; keep traversal readable.

### Combat
- [ ] Make the Chime Staff a real ranged weapon (tracer/projectile, range falloff, pitch note).
- [ ] Add parry/counterpoint input and animation; currently only data exists.
- [ ] Add weapon-specific attack arcs and heavy variants; verify hit-once sets.
- [ ] Add poise bars/feedback for the Stone Sentinel and boss; no damage numbers by default.
- [ ] Add enemy group coordination: scout calls, flank slots, support protection.
- [ ] Give the companion a downed/revive loop that enemies can trigger.
- [ ] Balance pass: time-to-kill, Breath economy, tonic value, boss windows on Story/Standard/Challenge.

### Art and world
- [ ] Bellhollow foreground pass: visible path ribbon, stronger silhouettes, warmer lantern pools.
- [ ] Fix prop/terrain intersections in Bellhollow and Reedwater.
- [ ] Add remaining Cantor architecture details: carved interval marks, channel gates, bell ribs.
- [ ] Improve water: shoreline foam, reed reflections, subtle normal motion.
- [ ] Merge static props per region or use MultiMesh to bring draw calls from 336 toward 150.
- [ ] iPhone Low preset visual check; ensure no missing props or unreadable silhouettes.
- [ ] Replace the title diorama with a composed view of the real Bellhollow if performance allows.

### Audio
- [ ] Listening pass on Mac speakers, headphones, and iPhone speaker.
- [ ] Balance music/ambience/SFX under dialogue and combat.
- [ ] Verify every gameplay cue has a visual twin with audio muted.
- [ ] Add companion voice motifs and a distinct boss phase cue.
- [ ] Test audio-session interruption/resume on iPhone.

### UI
- [ ] Save & Sync conflict screen manual test with two real folders.
- [ ] Export/import `.longnote` round-trip on macOS + Windows + iOS Files.
- [ ] Add a readable “last saved / synced” line without badges.
- [ ] Inventory filters and equipment comparison; keep the notebook look.
- [x] Journal: per-lore entry reading view, not just counts.
- [x] Map: hand-drawn survey with explored labels and a player marker.
- [ ] Settings: quality changes apply live to shadows/grade/particles.
- [ ] Onboarding: verify a child can find Wren → Pell → Sable → Nissa without help.

### Story and side content in the slice
- [ ] Continue Wren's post-Choir dialogue and the “what now” thread.
- [ ] Add a short consequence scene in Bellhollow for each Chime choice.
- [ ] Pip's Bell: add a follow-up line from Brannoc and a Pip appearance at the roost.
- [ ] Ferry Debt: show the repaired dock, a Reedfolk thank-you, and a new crossing.
- [ ] Add 3–5 more Echoes in Bellhollow/Reedwater with authored vignettes.
- [ ] Add 2–3 optional lore inscriptions that teach the Chime Gate language earlier.

---

## P2 — Full game (designed, not shipped)

### Regions
- [ ] **Kestrel Crags**: quarry terraces, wind arches, Sundial Stair, rope bridges.
- [ ] **Quarry Door** dungeon: sealed Cantor reliquary, Keeper boss, faction choice.
- [ ] **Glasswood**: petrified forest, Listening Trees, Glass Observatory, Mira's camp.
- [ ] **Undersong Vault**: cathedral, Voice Lattice logic grid, Choir, First Bell.
- [ ] **The Hush**: navigation by memory, Returning, Choirmaster's hall, Mira's hollow.
- [ ] **Low Water**: drowned lowland, boat wrecks, Reedfolk anchorage, optional exploration.
- [ ] Full Bellhollow upper terraces and east dovecote district.
- [ ] Region streaming? Keep region thresholds; document the choice.

### Story chapters
- [ ] Chapter 3: The Quarry Door — open/study/seal choice; Keeper fight.
- [ ] Chapter 4: Mira's Letter — Glasswood trail; truth about the chord; Wren's grief.
- [ ] Chapter 5: The Vault of Voices — logic lattice; the Choir's offer; First Bell.
- [ ] Chapter 6: What the Silence Kept — Hush; Mira; the question of the dead.
- [ ] Chapter 7: The Long Note — three endings; epilogue variants.
- [ ] Write all dialogue with the same voice rules; no lore dumps.
- [ ] Three full endings: The Chord, The Note, The Silence.
- [ ] Epilogue variations by Tenders/Guild/Reedfolk trust, companions, side quests.

### Companions
- [ ] Brannoc as defender/engineer with Brace and repair.
- [ ] Pip as support/resource finder with hum captions.
- [ ] Companion trust scenes and disagreements.
- [ ] Companion commands: focus, hold, ability, revive, go home.
- [ ] Ensure companions never solve puzzles or steal boss last hits.

### Combat and progression
- [ ] Remaining weapons, cloaks, charms, skills, recipes, buildables.
- [ ] 18 skills with real behavior, free respec.
- [ ] More enemy archetypes: Hushbear, Reed Stalker, Hollow Wisp variants.
- [ ] Bosses: Keeper of the Quarry Door, the Choirmaster, the Hush finale.
- [ ] Full equipment silhouettes on the player.
- [ ] Balance the game for Story/Standard/Challenge without a loot treadmill.

### Puzzles
- [ ] Sundial Stair (shadow/light, two solutions).
- [ ] Chord Sockets (build resonators at correct distances).
- [ ] Voice Lattice (logic grid with three-stage hints).
- [ ] Hush Lanterns (multi-stage memory/navigation).
- [ ] Carving-language tutorial chain across regions.
- [ ] Solvability tests for every puzzle and reset path.

### World systems
- [ ] Full procedural Undersong cave network with handcrafted modules.
- [ ] Dynamic weather and wet-ground effects.
- [ ] Settlement repair stages visible across Bellhollow.
- [ ] Faction vendors, prices, and dialogue reacting to trust.
- [ ] More music modes and region ambience.

---

## P3 — Optional cooperative mode (design only)

- [ ] Host-authoritative 2–4 player sessions, invite-only.
- [ ] Shared quest state; per-player loot tokens; idempotent reward IDs.
- [ ] Disconnect snapshot to local solo save; no duplicate rewards.
- [ ] Preset pings/emotes only; no open voice/text chat by default.
- [ ] AI companions fill empty slots and are labeled AI.
- [ ] Keep offline single-player complete; never require networking.

---

## Infrastructure and quality

- [ ] CI for macOS export and headless tests.
- [ ] CI for iOS export (unsigned device build).
- [ ] Visual capture harness in CI for desktop and phone aspect ratios.
- [ ] Performance budgets enforced by a test (draw calls/triangles/memory).
- [ ] Save fuzz test: random state, 1000 round-trips, kill during write.
- [ ] Sync conflict matrix as an automated table.
- [ ] Content validator checks every dialogue/quest reference and every build item.
- [ ] Accessibility audit with VoiceOver and colour-blind simulation.
- [ ] Write `docs/RELEASE_CHECKLIST.md` and follow it for every build.
- [ ] Keep README feature matrix and `docs/PLAYTESTING.md` honest every release.

---

## Known blockers

- Apple Developer team/provisioning for a signed iPhone build and TestFlight.
- A physical Windows machine for a manual playtest.
- A physical iPhone for touch, safe-area, thermal, and lifecycle testing.
- Time for a proper art/audio polish pass.

*The valley will wait — but the TODO does not.*
