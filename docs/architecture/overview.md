# Architecture Overview

The canonical technical decision record is [`../TECHNICAL_ARCHITECTURE.md`](../TECHNICAL_ARCHITECTURE.md). This folder holds the subsystem notes that need more detail than the summary.

| Document | Contents |
|---|---|
| [`save_sync.md`](save_sync.md) | Save format, atomic writes, canonical checksum, backup/quarantine, sync folder, conflict matrix, adapters, platform lifecycle, verification |
| [`ios_build.md`](ios_build.md) | iPhone export, signing gap, simulator limitation, iCloud entitlements, safe area, remaining steps |
| [`ai_and_puzzles.md`](ai_and_puzzles.md) | Companion/enemy AI, boss state machine, puzzle models, solvability and hints |
| [`content_pipeline.md`](content_pipeline.md) | JSON content, id validation, dialogue conditions/effects, procedural cave rules, asset generation |

## Runtime shape

```
Main (Node3D)
├── WorldDirector
│   ├── active RegionBase (handcrafted or generated)
│   ├── Player (+ CameraRig, top-level)
│   ├── Companion (persistent across regions)
│   ├── BuildSystem (ghost, placement, restore)
│   └── CanvasLayer fade
├── PostProcess (CanvasLayer, grade shader)
├── DialogueBox (CanvasLayer 25)
├── HUD (CanvasLayer 10)
├── PauseMenu (CanvasLayer 30)
├── EndingScreen (CanvasLayer 35)
└── TouchControls (CanvasLayer 15, touch modes)
```

Autoloads: `Events` (signals), `Settings`, `InputRouter`, `Game` (state/save/sync/content/audio director), `AudioDirector`.

The `Game` autoload owns `GameState`, `SaveManager`, `SyncService`, and `ContentDB`. Nodes mutate the state model; they never write files directly. Scene-local communication is direct; cross-cutting concerns (quests, saves, region readiness, sync, UI screens) use the `Events` signal hub.

## Coordinate and design conventions

- 1 unit = 1 metre; +Y up; characters face −Z at yaw 0.
- Camera rig is `top_level`, follows the player but does not inherit the player's rotation. It uses a raycast against layers 1|4 to shorten in tight spaces; interiors also use a shorter base distance.
- Terrain is a 120×120 heightfield at 2 m steps with a trimesh collider. The height functions are hand-authored per region, not noise with a story pasted on.
- Water is a shader plane; `TerrainBuilder.is_in_water` is the gameplay query.
- One region is live at a time; thresholds fade and autosave. This is a deliberate memory/thermal decision, documented in the main architecture.
- Save data never contains scene node references, only ids, flags, positions, and numbers.

## Platform abstraction boundaries

| Concern | Where |
|---|---|
| Actions and analog input | `core/input_router.gd` |
| Touch presentation | `ui/touch_controls.gd`, `ui/touch_joystick.gd` |
| Safe area | `UITheme.safe_rect` |
| Audio buses/mix | `core/audio_director.gd` + `Settings` |
| iCloud root discovery | `core/sync_service.gd` |
| Lifecycle save | `core/game.gd::_notification` |
| Export presets | `game/export_presets.cfg` |
| Signing/entitlements | `docs/architecture/ios_build.md` |

## What is intentionally not built

- Seamless streaming open world.
- Runtime network multiplayer.
- CloudKit/account sync.
- A custom backend, Docker, or paid API.
- Telemetry/analytics.
- Asset downloads at runtime.
