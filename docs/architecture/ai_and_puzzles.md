# AI and Puzzle Systems

## Companion AI

`actors/companion.gd`. Nissa is a utility-weighted state machine, not a follower script:

- **Follow**: a formation offset behind/right of the player, with a teleport catch-up beyond 16 m.
- **Engage**: nearest living enemy within 14 m. Closes to 8 m, then holds and fires a tracer every 1.2 s.
- **True Pitch**: every 10 s, marks an enemy's weak point for 5 s and calls it out.
- **Wait / Follow**: responds to party commands; waiting sets velocity to zero but keeps perception.
- **Downed**: six-second recovery, then rejoins.
- **Barks**: at most one ambient line every 24–40 s, only out of combat, from a small hand-written pool. It never repeats quest-critical information.

Companions never activate a puzzle, read a clue, or solve a lock. They can hold a light, indicate a rule, or mark a weak point.

The companion persists across regions: `WorldDirector` owns the node and repositions it after each region build. It is always labeled as AI in the party UI.

## Enemy AI

`actors/enemy.gd` implements shared perception and archetype behaviors:

- **Perception:** distance + a raycast line of sight. No omniscient tracking. Hearing is represented by noise events for future use.
- **Ambusher (Reed Crawler):** idles, wakes on sight/range, chases, telegraphed lunge, retreats when far and heals at its spawn.
- **Charger (Bramble Ram):** scrapes, telegraphs, charges in a straight line, stuns on a wall, recovers.
- **Support (Choir Moth):** stays near hurt allies, heals them, flees if focused.
- **Harasser (Returning Wisp):** keeps range, strafes, silences, flees through geometry.
- **Guard (Stone Sentinel):** patrols its territory, closes, telegraphed shield-forward attack, reacts to sound.
- **Boss (Hollow Stag):** a separate script with a shell gate, charge behavior, antler sweep, and a silence field.

Shared combat: poise/stagger, pitch match bonus, hit flash/scale, non-gory defeat motes, deterministic material drops, and marks. Difficulty modifies damage taken, telegraph duration, and enemy health — never removes mechanics.

## Boss: the Hollow Stag

`actors/boss_stag.gd`. The fight is a two-layer test:

1. **Observation puzzle.** The ruined window shows `II · III · I` (mid, high, low). Three chimes in the arena ring notes. Ringing them in order breaks the shell; a wrong note resets the sequence with a neutral click, not a punishment.
2. **Execution.** While shelled, damage is ignored. After the shell breaks, the Stag uses charges, a wide antler sweep at close range, and a silence field that disables chords for three seconds. The counter is to move out of the field and punish the recovery.

No adds treadmill, no invulnerability sponge, no random one-shot. The HUD shows a boss bar once the player enters the arena.

## Puzzle models

| Puzzle | File | Rule | Solutions | Hints |
|---|---|---|---|---|
| Chime Gate | `puzzles/chime_gate.gd` | Three stones cycle low/mid/high. The carving shows 1-2-3. | `[1,2,3]` or `[3,2,1]` | Carving; journal nudge; explicit sequence |
| Sluice | `world/regions/sunken_choir.gd` | Three valves; open, shut, open. Water lowers and the door opens. | `[true,false,true]` | Sign; wrong pattern feedback; journal |
| Echo Gallery | `puzzles/echo_maze.gd` | Three hidden stones; strike low/high/mid in order. `Listen` reveals them briefly. | `[1,3,2]` | Carving; pulse; journal |
| Stag Window | boss + arena | Ring chimes in the window order. | `[2,3,1]` | Window, Nissa callout, boss prompt |

General rules:

- Every rule is demonstrated before it is tested.
- Failure is reversible, quiet, and informative.
- No timer, no death, no consumable cost.
- The journal records facts and offers escalating hints; it does not give the solution by default.
- Multiple valid solutions where the fiction allows it (the Chime Gate accepts two voicings).
- Puzzles reset to a known state on re-entry; progress is stored by id, not by transient scene nodes.

## Verification

- `Chime Gate` and boss shell are solved through real interactions in `tests/Playthrough.tscn`.
- The Sluice is solved through the real valve interactables.
- `tests/Integration.tscn` rebuilds regions and verifies persistence flags.
- Puzzle state is part of the save and survives a reload.
- No puzzle depends on audio alone; pitch is encoded by mark count and colour, and `Listen` has a visual pulse.
