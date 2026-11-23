# Technical Architecture

**Project:** *The Long Note*
**Status:** Phase 3 baseline, maintained through implementation
**Last revised:** November 2026

This document is the canonical technical decision record. Detailed subsystem notes live in `docs/architecture/`.

---

## 1. Engine decision

### Options considered

| Engine | Strengths | Problems for this project |
|---|---|---|
| **Godot 4.7** | MIT licensed, no royalties; one project exports macOS and iOS; mature 3D renderer with a mobile profile; fast GDScript iteration; small binary; editor runs natively on Apple Silicon; excellent headless mode for automated tests; scene/resource format is text and diff-friendly. | Smaller third-party asset ecosystem; iOS plugins need a small amount of Objective-C++; console exports are handled by third parties (not relevant here). |
| **Unity 6** | Huge ecosystem, mature mobile pipeline, strong tooling. | Licensing and runtime-fee uncertainty; heavy editor; a 3D open-world indie game of this size does not need the ecosystem; closed source makes long-term archival harder. |
| **Unreal 5** | Best-in-class rendering, world composition tools. | Massive runtime and binary size; overkill for a stylized low-poly game; iPhone thermal/battery budget is hostile to the default feature set; Blueprint/C++ split slows a tiny team; licensing complexity. |
| **Native (SwiftUI + SceneKit/RealityKit)** | Perfect platform integration, iCloud trivial, smallest binaries. | macOS and iOS would become two codebases for gameplay; SceneKit is effectively in maintenance; iterating on an action RPG in SwiftUI is slow; no desktop-first editor. |
| **Bevy / custom Rust** | Excellent performance, modern ECS, open source. | Immature editor and mobile pipeline; exporting a signed iOS app is manual; content authoring cost falls on programmers; too much risk for a small narrative game. |
| **Three.js / web** | Ubiquitous, fast iteration, easy sharing. | Not a native Mac or iPhone app; no App Store distribution story without a wrapper; weaker input/lifecycle integration; performance ceiling on iPhone Safari. |

### Decision

**Godot 4.7.2 stable**, GDScript-first, with a small Objective-C++ iOS plugin only for iCloud container discovery. The renderer is **Mobile** for both platforms (Vulkan on macOS through MoltenVK, Vulkan on iOS), with a **GL Compatibility** fallback available from settings for old devices. The game targets 60 fps on Apple Silicon Macs and 30–60 fps on iPhone 13 and newer.

**Why not 2D.** The game is about reading a three-dimensional landscape as an instrument: sightlines, elevation, water flow, and the shape of architecture. A 2.5D or HD-2D presentation would look beautiful but would make the spatial puzzles and the "see a place, wonder how to reach it" fantasy much weaker.

**Why not first-person.** Third-person keeps the character readable as a silhouette, supports touch camera control without a second thumbstick for aiming, and makes the companion visible and expressive. It also lets the player see the ground, which matters for building and puzzle placement.

**Godot version pinning.** `game/project.godot` declares `config/features=PackedStringArray("4.7", "Mobile")`. The version is pinned in `docs/TECHNICAL_ARCHITECTURE.md` and `README.md`; upgrades are treated as migrations with save-compatibility tests.

---

## 2. Language and code style

- **GDScript 2.0** for all gameplay, UI, tools, and tests. Static typing is used on public APIs and data models. `class_name` is used for globally referenced types.
- **Objective-C++** only in `game/ios/plugins/` for the iCloud ubiquity-container bridge. It is optional at runtime: if the plugin is absent (desktop, unsigned simulator build), the sync layer falls back to a folder adapter without failing.
- No third-party GDScript addons in the shipped game. Tests use a small in-repo runner so the project has zero supply-chain surface.
- Formatting: tabs for indentation (Godot convention), `snake_case` files and functions, `PascalCase` classes, `SCREAMING_SNAKE_CASE` constants. Public functions carry a short doc comment when behavior is non-obvious.
- Game logic never calls platform APIs directly. Platform behavior is behind `Platform`, `SaveStore`, `SyncAdapter`, `Haptics`, and `AudioBackend` interfaces.

---

## 3. Project layout

```
game/
  project.godot
  main.tscn                    # single root scene
  export_presets.cfg
  addons/                      # none at runtime (test runner is in tests/)
  assets/                      # generated/curated art, audio, fonts (see licensing)
  data/                        # content as JSON: items, recipes, quests, dialogue, puzzles
  scripts/
    core/                      # Game, Events, Settings, SaveManager, SyncService, Platform
    world/                     # WorldDirector, regions, terrain, props, weather, nav
    actors/                    # Player, Companion, Enemy, Boss, shared actor logic
    combat/                    # Damage, weapons, abilities, status effects
    systems/                   # Inventory, Crafting, Building, QuestLog, Dialogue, Journal
    puzzles/                   # pure-logic puzzle models + scene controllers
    ui/                        # theme, HUD, screens, touch controls
    art/                       # mesh factory, palette, shaders, VFX, procedural audio
  tests/                       # headless unit + integration tests
  ios/                         # Xcode-side assets and the optional iCloud plugin
assets/                        # source art and licensed third-party assets (documented)
docs/
tests/                         # repo-level content validation, docs checks, export checks
```

---

## 4. Runtime architecture

### 4.1 Process and scenes

One `Main.tscn` scene owns the application shell:

```
Main (Node)
├── Game (autoload-free root controller)
├── WorldHost (Node3D)          # loads/unloads region scenes
├── UILayer (CanvasLayer)       # HUD, screens, touch controls
├── AudioDirector (Node)       # procedural music + SFX
└── TransitionLayer (CanvasLayer)
```

The game uses **one active region scene at a time**, with a short authored transition (fade + title card). Regions are handcrafted `.tscn` scenes or code-built scenes under `scripts/world/regions/`. Streaming a seamless open world is deliberately avoided: it multiplies memory, collision, and persistence complexity for a game whose tension is local and whose map is a valley, not a continent. Region boundaries are diegetic (a ferry, a cave mouth, a gate) and autosave on both sides, so players never lose progress at a seam.

**Why not a single open scene.** iPhone memory and thermal headroom. A valley of this density in one scene would require aggressive LOD and streaming, which is a multi-month engineering project with little player-visible benefit. The design promise is "a world that feels open and rewards wandering", not "no loading screens". Documented honestly in the README.

### 4.2 Game state ownership

`GameState` is a single serializable object (dictionary-backed model with typed accessors) that holds:

- player identity, stats, level/attunement, skills, equipment, inventory, currency
- quest states and dialogue flags
- world flags (doors, puzzles solved, structures built, NPC positions, region states)
- companion states and trust
- discovered lore, map markers, fast-travel lanterns
- statistics (playtime, distance, puzzles solved without hints — used only for the player's own journal, never for scoring others)

Nodes never write directly to disk. They mutate `GameState` through commands and emit `Events`. `SaveManager` serializes `GameState` plus a small set of scene-independent world records. This makes saves deterministic, testable, and portable.

### 4.3 Event bus

`Events` (autoload) is a typed signal hub: `item_gained`, `quest_stage_changed`, `dialogue_finished`, `puzzle_solved`, `region_entered`, `player_downed`, `companion_command`, `save_requested`, `sync_status_changed`, `settings_changed`. Direct node references are used inside a scene; the bus is only for cross-cutting concerns. No global string-based message passing beyond the declared signals.

### 4.4 Update and physics

- Fixed physics at 60 Hz; rendering uncapped with V-Sync; a frame-budget guard degrades VFX before gameplay.
- Characters are `CharacterBody3D`. Projectiles are pooled `Area3D` scenes. Hit detection uses short `ShapeCast3D` sweeps with a hit-once set per swing, avoiding frame-rate-dependent overlap bugs.
- All gameplay timers use `delta`; no `Timer` node is trusted for combat windows.
- Pause is a real `get_tree().paused` state with a UI-only pause mode; audio buses duck. The game pauses on focus loss and on iOS backgrounding, then autosaves.

### 4.5 Coordinate and world conventions

- 1 Godot unit = 1 metre. Player height ≈ 1.8 m. Camera distance 7–10 m.
- +Y up, characters face −Z. Region origins are at the region's arrival point; world-space positions are converted to region-local when persisting.
- Terrain is a heightfield mesh with a trimesh collider for walkable ground and separate collision for cliffs. Water is a shader plane plus an `Area3D` for swim/foot transitions.
- Navigation uses `NavigationRegion3D` baked at build time per region; dynamic obstacles use avoidance. Enemies also use direct steering for local behavior so they never look like they are following a grid.

---

## 5. Rendering and art pipeline

- **Renderer:** Mobile. HDR off on iPhone low preset. MSAA off; FXAA on Mac, off on low-end iPhone. Shadow atlas limited to one directional light with a tight cascade; no SSAO on mobile. Fog is a custom depth fog in the sky/terrain shader, not volumetric.
- **Geometry:** low-poly, flat-shaded, vertex-colored meshes generated by `MeshFactory` (`scripts/art/`) at load time and cached in `user://cache/` as `.res` for faster subsequent boots. This gives a coherent art style without an asset farm, keeps the repository small, and lets the palette be tuned in one place.
- **Materials:** `StandardMaterial3D` with vertex color, roughness 0.85, no metallic except copper trim (metallic 0.6). Emissive accents use an unshaded additive material. A custom `sound_ribbon.gdshader` renders translucent ribbons with a scrolling wave for resonance visualization.
- **Vegetation/props:** `MultiMeshInstance3D` per prop type per region chunk. Grass/reeds are billboard quads with alpha-scissor, disabled on the lowest iPhone preset.
- **Lighting:** one directional sun (warm, low angle), sky gradient with a custom `sky.gdshader` (pewter-to-amber), ambient from sky, plus emissive lanterns. Region mood is a `MoodPreset` resource (sun color/energy, fog color/density, ambient, music mode).
- **Post:** minimal. A single full-screen color-grade shader provides the Hush desaturation and subtle vignette; it can be disabled for accessibility and low-end devices.
- **Performance budget:** ≤ 45k visible triangles per frame on iPhone low, ≤ 120k on Mac high; ≤ 2 shadow-casting lights visible; ≤ 150 draw calls after MultiMesh batching; 512 MB texture budget (mostly UI and a few noise textures); no runtime texture generation above 512×512.
- **Asset sources:** all shipped meshes, textures, shaders, fonts, and audio are generated in-repo or system fonts. Third-party assets, if ever added, must be listed in `docs/ASSET_LICENSES.md` with source, license, and modification notes. No copyrighted game assets are used.

## 6. Audio

Procedural audio, all original:

- `Synth` builds `AudioStreamWAV` buffers at startup from additive synthesis + noise + envelopes (bell partials, reed flute, plucked string, footstep noise, water, wind).
- `MusicDirector` plays a generative modal score: a slow harmonic bed, sparse bell/pluck motifs drawn from a seeded pattern, and layer changes driven by region mood and combat intensity. It never loops audibly on a short timescale and never uses stingers to manufacture urgency.
- Ambience is layered loops with randomized one-shots (birds, reed rustle, distant bell, water).
- Every gameplay-critical sound has a visual counterpart: attack telegraph flashes, pitch shown as three shape marks, subtitle captions for non-speech sounds (`[bell tolls twice]`).
- Buses: Master, Music, Ambience, SFX, UI, Voice-less dialogue. Settings expose each; a "Mono audio" toggle downmixes.

No external audio files are required; if curated recordings are added, they are licensed and documented.

## 7. Input abstraction

`InputRouter` maps physical input to **actions**, and `InputMode` (`KEYBOARD_MOUSE`, `GAMEPAD`, `TOUCH`) drives UI presentation. Gameplay code reads actions only.

| Action | Keyboard/mouse | Gamepad | Touch |
|---|---|---|---|
| Move | WASD | Left stick | Left virtual stick (floating origin, 96 dp) |
| Camera | Mouse (hold RMB or always) | Right stick | Drag anywhere on right 60% |
| Light attack | LMB / J | West face | Primary button |
| Heavy attack | RMB / K | North face | Heavy button |
| Dodge | Space | East face | Dodge button |
| Interact | E | South face | Context button, large |
| Ability 1/2 | Q / R | LB / RB | Two ability buttons |
| Listen (pulse) | F | D-pad down | Listen button |
| Build | B | D-pad up | Build via pause ring |
| Pause | Esc | Start | Menu pill, top-right |

Touch buttons are ≥ 64 dp, primary action ≥ 76 dp, positioned inside thumb arcs in landscape. The left stick is floating (appears where the thumb lands) to avoid the "chasing a fixed stick" problem. Camera drag has sensitivity and invert options. All touch controls are optional overlays that fade when not touched. On iPhone, the game runs landscape-only and respects safe areas via `DisplayServer.get_display_safe_area()`.

Remapping is stored in settings for keyboard and gamepad; touch layout is fixed but sizes and handedness (left/right stick swap) are configurable.

## 8. Save format

Saves are **JSON**, schema-versioned, checksummed, atomic, and human-inspectable for support.

```json
{
  "magic": "longnote.save",
  "schema": 1,
  "game_version": "0.1.0",
  "save_id": "uuid",
  "slot": "wren",
  "created_utc": "2026-11-23T10:00:00Z",
  "modified_utc": "2026-11-23T18:12:03Z",
  "device": {"id": "uuid", "name": "Aleksa's Mac", "platform": "macOS"},
  "revision": 42,
  "playtime_seconds": 5412,
  "checksum": "sha256:…",
  "state": { "...": "GameState" }
}
```

- Written to `user://saves/<slot>.json.tmp`, flushed, fsynced where available, then renamed over `<slot>.json`. The previous file is rotated to `<slot>.json.bak`. A `.journal` marker exists during a write so an interrupted write is repaired on next boot from the `.bak`.
- Checksum is SHA-256 over canonical JSON of `state` + header fields except `checksum`. A mismatch does not delete anything: the save is quarantined as `<slot>.corrupt-<timestamp>.json` and the backup is offered.
- Schema migrations live in `SaveMigrations` as an ordered list; every migration has a fixture in `tests/fixtures/`.
- Autosave at region transitions, lantern rests, quest stage changes, and app backgrounding. Autosaves use a separate `autosave` slot and never overwrite manual slots.
- **The game never punishes absence.** No timestamps gate content, resources do not decay, and there is no offline progress to lose.

## 9. Cross-device synchronization

### 9.1 Model

Offline-first. The local save is authoritative for the session; sync is a background copy/merge of immutable save snapshots plus a small metadata index. There is exactly one file per save slot per device; the sync folder holds the newest snapshot per device and a small `index.json` describing them.

```
syncRoot/
  index.json                  # device id -> {slot, modified_utc, revision, playtime, checksum, device_name}
  <slot>.<device_id>.json     # full save snapshots, never mutated in place
```

Each snapshot carries `device.id`, `device.name`, `revision` (monotonic per device), `modified_utc`, and `playtime_seconds`. Conflict is defined as **both this device and another device having revisions newer than the last common sync point for the same logical save**. Timestamps are not trusted for ordering (clocks lie); revision + device id + explicit last-synced digest are.

### 9.2 Adapters

| Adapter | Use | Status |
|---|---|---|
| `LocalFolderAdapter` | Default; a user-chosen folder (iCloud Drive, external drive, network share, Files app on iOS). | Implemented |
| `ICloudDriveAdapter` | Detects the app's iCloud ubiquity container on macOS/iOS and uses it as the sync root. | macOS iCloud Drive path verified; iOS container path implemented with local fallback, requires signed build + iCloud capability (unverified) |
| `DeviceTransferAdapter` | Explicit export/import of a `.longnote` package for AirDrop or cable. | Implemented |

iCloud Drive (document-based, ubiquity container) is preferred over CloudKit for this game: saves are a handful of files, the conflict semantics we need are file-level and explicit, and CloudKit's record-level sync and account requirement add complexity without improving the player experience. iCloud Drive also works with the Files app on iPhone, which gives players a transparent recovery path. The game does **not** require an account, a login, or a network connection.

On iOS, the app must be signed with the iCloud capability and an ubiquity container (e.g. `iCloud.com.longnote.game`), and `NSUbiquitousContainers` must be set in Info.plist. The native bridge `ICloudBridge.mm` asks `FileManager` for `URLForUbiquityContainerIdentifier` and returns its path. Without entitlements the call returns nil, and the game silently falls back to local + user-folder sync. **This is the only iOS-specific code in the project.** Exact steps are in `docs/architecture/ios_build.md`.

### 9.3 Conflict handling

- On app foreground and on demand, `SyncService` scans the index. If a newer remote snapshot exists and local has no unsynced changes, it offers "Continue from other device". If both changed, it presents a **conflict screen** with both versions (device, time, playtime, last quest, level) and three actions: **Keep this device**, **Use other device** (local is archived first), **Keep both** (both slots preserved with device suffixes). Nothing is overwritten without an explicit choice.
- A newer save is never replaced by an older one. The only automatic action is *copying* snapshots into the sync folder; all replacement is explicit or based on "local is clean and remote is strictly newer".
- If a save fails checksum, it is quarantined and the player is told where it is. The game never deletes a save to "fix" a problem.

### 9.4 Cooperative sessions (design)

Optional 2–4 player co-op is designed but not shipped in this build (see GDD §11). The architecture reserves a `SessionService` and authoritative-host model: the host's `GameState` is canonical, clients send intents, rewards are issued once by the host with idempotency keys, and a disconnect snapshots the client into a local "solo continuation" of its own save rather than corrupting the shared one. No public matchmaking, no open voice/text chat; invites only, with preset emotes and pings. AI companions fill empty slots and are always labeled as AI.

## 10. AI architecture

- **Companions** use a utility-based state machine: `Follow`, `Engage`, `Reposition`, `Revive`, `Interact`, `Wait`, `Comment`. A small utility scorer weighs distance, threat, player health, line of sight, and cooldowns. Companions navigate with the navmesh, avoid the player's line of fire, and never take a puzzle action that would solve it for the player (they can *indicate*, not *activate*, except where explicitly designed).
- **Enemies** use perception (vision cone + hearing radius + last-known-position memory) and behavior trees expressed as data (`data/ai/*.json`) compiled into lightweight nodes. Archetypes: territorial ambusher, pack charger, ranged harasser, support/healer, guard, and boss. Group coordination is a shared `PackBlackboard` (alert level, target, flank slots) limited to nearby members.
- **Bosses** are scripted state machines with observation phases; no bullet-sponge scaling. Telegraphs are readable, audio+visual, and difficulty settings widen windows rather than removing mechanics.
- **Navigation:** baked navmesh per region; companions and enemies use `NavigationAgent3D` with avoidance; flying enemies use simple steering with obstacle probes.
- **Dialogue/quests** are deterministic data; the "AI" never invents content at runtime. This guarantees tone, safety, and localizability.

## 11. Procedural generation

Used only where it serves replayability without diluting authorship:

- **Undersong side-caves:** seeded room-and-corridor generator over handcrafted modules. Guarantees: one entrance/exit path, every room reachable, at least one resource cluster, one of three puzzle archetypes, no soft-locks, no unique narrative items. Seed is stored per save; the same cave is stable for that save (no "daily" content).
- **Resource scatter:** deterministic Poisson-disc placement per region seed, with authored exclusion zones around story beats.
- **Reed islets / rock fields:** decorative, non-blocking, deterministic.
- Important story locations, dungeons, bosses, and puzzles are always handcrafted. The generator never creates quests, dialogue, or boss arenas.

## 12. Data-driven content

Items, recipes, quests, dialogue, puzzles, enemies, and region metadata are JSON under `game/data/`, validated by `tests/validate_content.py` and by a runtime `ContentDB` that fails loudly in debug if a referenced id is missing. JSON is chosen over Godot `.tres` for reviewability, diff quality, and tooling with standard editors. Large binary assets stay out of JSON.

Dialogue format: nodes with `id`, `speaker`, `text`, optional `choices` (text, condition, effects), `next`, and `once`. Conditions are a small safe expression vocabulary (`flag:`, `quest:`, `item:`, `trust:`), never `eval`.

## 13. Platform integration

### macOS
- Windowed by default, resizable, minimum 1024×640 logical; fullscreen toggle; `content_scale_mode=canvas_items` with a 1600×900 base and per-axis stretch. Native menu bar with About, Settings, Quit. Cmd+Q saves to autosave first. Trackpad-friendly camera sensitivity; mouse capture only while orbiting.
- Export: universal (arm64 + x86_64) app bundle, hardened runtime, notarization documented (requires an Apple Developer account; the repo ships an unsigned local build script).

### iPhone
- Landscape only. Safe-area insets applied to HUD. Touch overlay generated at runtime based on `InputMode`. 30/60 fps toggle, quality preset, reduced effects, battery-conscious defaults (30 fps cap when unplugged is *not* forced; the player chooses).
- Lifecycle: on `NOTIFICATION_APPLICATION_PAUSED` / `WM_WINDOW_FOCUS_OUT`, pause, duck audio, autosave atomically, and flush sync if enabled. On resume, verify save integrity and rebuild touch state.
- Export: iOS preset generates an Xcode project; signing requires the developer's team ID and provisioning profile. Documented precisely in `docs/architecture/ios_build.md`.

### Shared
- 100% of gameplay, content, UI logic, save logic, and art generation is shared. Only input presentation, lifecycle hooks, haptics, and iCloud path discovery are platform-specific.

## 14. Testing strategy

**Current results (23 November 2026):** 47 logic/save/sync checks, 45 integration checks, 36 end-to-end playthrough checks, content validation OK, macOS export booted, iOS Xcode project generated with an unsigned device build succeeding. Full details and open defects are in `docs/PLAYTESTING.md`.

1. **Pure logic tests (headless, fast):** save serialization/checksum/atomicity, migrations, sync conflict matrix, inventory/equipment rules, crafting, quest state machines, puzzle solvers, dialogue conditions, procedural cave invariants, damage math, AI utility scoring.
2. **Scene integration tests (headless):** boot world, simulate player input via `Input.action_press`, complete the quest chain with scripted interactions, verify save/load round-trip including world flags, run the boss arena with an invulnerable test player to validate phase transitions.
3. **Content validation (Python, stdlib):** all JSON parses; every referenced id exists; no dead quest references; puzzles have a verified solution; docs required files exist; novella word count in range; no banned dark-pattern strings/APIs (notifications, daily rewards, timers gating).
4. **Visual smoke tests:** a capture harness renders the hub, region, dungeon, boss, and each major UI screen to PNG for review; run on macOS with a real GPU. iPhone simulator screenshots are produced when the Xcode project builds.
5. **Manual playtest protocol:** `docs/PLAYTESTING.md` with tasks, observation notes, and a defect log. Results are recorded honestly, including what was not tested.

## 15. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Scope: an open-world RPG is large | Vertical slice first; region-based loading; procedural only for optional caves; content authored in JSON for fast iteration; explicit "not shipped" list in README. |
| iPhone performance | Mobile renderer, low-poly, MultiMesh, strict triangle/draw budgets, quality presets tested on device; no SSAO/volumetrics. |
| iOS signing/iCloud entitlement unavailable in this environment | Ship the iCloud bridge with a folder fallback; document exact provisioning steps; test conflict logic headlessly and via a simulated sync folder. |
| Save corruption | Atomic write + checksum + backup + quarantine + migration fixtures + tests. |
| Puzzle soft-locks | Puzzles are state machines with reset; solvability tests; hints; no one-shot consumables required. |
| Audio synthesis cost | Pre-bake short SFX buffers at startup with time budget; stream music layers; graceful silence if audio init fails. |
| Tone drift toward generic fantasy | Palette, naming, and faction rules in `ART_DIRECTION.md`; art/UX review checklist; no elves, no prophecies, no loot boxes. |

## 16. Explicit non-goals for this build

- Seamless streaming open world.
- Online multiplayer (architecture and design only).
- Voice acting.
- Localization beyond English (all strings centralized; structure ready).
- Console exports.
- CloudKit account sync.
- Any telemetry or analytics.
