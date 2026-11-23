# Content Pipeline

All content is hand-authored JSON under `game/data/`, loaded once by `ContentDB`, validated at boot and by `tests/validate_content.py`. There is no runtime content generation for story, quests, dialogue, or items.

## Files

| File | Shape | Notes |
|---|---|---|
| `items.json` | id → name, kind, mark, pitch, damage, stats, value, description, effect/build | 31 items in this build |
| `recipes.json` | id → output, count, station, cost, known, description | outputs or upgrades |
| `quests.json` | id → title, giver, summary, stages[] | stage text is player-facing journal copy |
| `dialogue.json` | id → start, nodes{} | speaker, text, next, choices, effects, condition |
| `enemies.json` | id → health, damage, speed, pitch, poise, behavior, ranges, materials | combat data |
| `regions.json` | id → name, mood, music, sun/fog/sky colors, spawns | mood presets |
| `skills.json` | id → name, arc, cost, cooldown, description | 8 skills |
| `builds.json` | id → name, kit, kind, terrain, clearance, description | 5 structures |

## Dialogue model

A node has:

```json
{
  "speaker": "Wren",
  "text": "…",
  "next": "ask",
  "choices": [
    { "text": "What is this place?", "next": "place", "condition": "flag:met_pell",
      "effects": [{ "type": "flag", "key": "asked", "value": true }] }
  ],
  "effects": [{ "type": "quest", "id": "main_02", "stage": 2 }],
  "end": false
}
```

Conditions are a deliberately tiny, safe vocabulary:

- `flag:key` / `!flag:key`
- `quest:id>=n`
- `item:id`
- `trust:companion>=n`

Effects:

- `flag` (key/value), `quest` (id/stage), `quest_done` (id/outcome)
- `item` (id/count), `trust` (id/amount), `lore`/`echo` (id)
- `companion` (id/active), `choice` (id/value), `marks` (amount), `heal`

No `eval`, no scripts in data, no network, no localization markup yet. All speaker text is centralized for a future translation pass.

## Procedural generation

Only the optional `UndercaveRegion` uses generation, and only for layout and content placement:

- Seed = `abs(hash(save_id))`, stable for that journey.
- 4 rooms on a descending line with seeded widths/offsets; corridors connect them.
- One entrance/exit path, all rooms reachable, no soft-locks.
- Resources (copper, reed, echo glass, humstone, clay), 1–2 enemies, a lantern, and a three-note Chime Gate.
- No unique narrative items, no boss, no quest state. The generator cannot lock the main story.

Story locations (Bellhollow, Reedwater, the Sunken Choir) are handcrafted in `world/regions/`.

## Art pipeline

`MeshBuilder` accumulates triangles with per-face normals and vertex colors. `MeshFactory` provides silhouettes (characters, houses, tower, trees, reeds, rocks, boards, bells, chimes, jars, crystals). Materials are shared; flat shading; no textures. Terrain uses a hand-authored height function and vertex colors. Shaders are two small files: water and colour grade.

This keeps the repo small, avoids licensing risk, and makes the palette changeable in one place. A future artist can replace individual mesh builders without changing gameplay.

## Audio pipeline

`AudioDirector` synthesizes PCM buffers at startup (bells, plucks, wind, hits, chime chords) and generative music beds. No audio files are committed. The music director switches modes by region and boss state; it never uses stingers for quest pickups or engagement pressure.

## Validation

`tests/validate_content.py` checks:

- JSON parses; ids are unique.
- Recipe outputs/costs, build kits, enemy drops, dialogue targets, quest stages, region factory entries.
- Required docs and novella length.
- No banned notification/retention APIs or strings, no obvious secrets.

`ContentDB.validate()` repeats the id checks at runtime and logs errors in debug.
