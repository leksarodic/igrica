# The Long Note — Game Design Document

**Version:** 1.0 (Phase 1, updated through implementation)
**Genre:** single-player open-valley action adventure RPG with crafting, building, and environmental logic puzzles
**Platforms:** macOS (Apple Silicon, universal) and iPhone, one shared Godot 4.7 project
**Audience:** ages 9+ and adults; co-play friendly
**Session shape:** 15–30 minutes typical, hours possible; save anywhere; no external pressure

---

## 1. Vision

*The Long Note* is a quiet, strange, beautiful game about a valley that is kept alive by a song — and about the people who have agreed not to ask who is singing it.

The player arrives in Carrow Vale as a Listener: someone who can hear the undertone beneath the world. They explore terraced cliffs, reed water, petrified woods, and the ruins of a vanished culture that tuned an entire landscape like an instrument. They fight not monsters but *dissonances*: knots of silence that used to be voices. They gather, craft, build, and solve problems of water, stone, sound, and memory. And they decide what to preserve, what to release, and what a community owes its dead.

The game is warm, not grim. Its horror is administrative: a town that has made an unbearable bargain and filed it under tradition. Its hope is practical: people can learn a different song.

**Design pillars**

1. **The world is legible.** No glowing trail of breadcrumbs. Landmarks, water flow, architecture, and sound teach the player how the valley works. Curiosity is the main progression currency.
2. **Every system is a way of listening.** Combat, crafting, building, and puzzles share one verb: tune. They are not four games stapled together.
3. **No one is a villain.** Antagonists have reasons, factions have valid fears, and the player's choices are disagreements about how to live, not good versus evil.
4. **Respect the player.** No timers, streaks, notifications, loot boxes, or manufactured urgency. Save anywhere. Stop anytime. Come back in six months and nothing has rotted.
5. **Small hands, deep roots.** A child can follow the adventure, fight with confidence, and solve the early puzzles. An adult can read the inscriptions, notice the contradictions, and argue about the ending.

---

## 2. The world

### 2.1 Carrow Vale

A glacial valley shaped like a bell, opening west onto a drowned lowland. The valley floor is a braid of channels and reed beds. Terraced cliffs rise in three steps, cut by waterfalls that no longer run in all the places they used to. At the center, the town of **Bellhollow** sits inside the dry basin of an ancient waterfall, its houses stacked on the terraces around a cracked stone tower called the **Hollow Bell**.

Four hundred years ago the valley was tuned by the **Cantors**, a culture of builders and listeners who discovered that the ground beneath the valley — the **Undersong** — resonates. They cut channels to specific lengths, raised stone chimes on ridgelines, and cast a great bell whose note holds the valley's shape. Their system, the **Chimeworks**, is still half-working, maintained by ritual by people who no longer understand it.

Where the Chimeworks fail, the **Hush** spreads: a grey country where sound dies, color drains, and memory thins. The Hush is not a place so much as a consequence. It is what remains when a voice is taken and not returned. It moves. It listens. It is patient.

**Geography**

| Region | Character | Role |
|---|---|---|
| **Bellhollow** | Terraced town, copper roofs, lantern-lit, ochre plaster, a bell-shaped dry basin, ferry dock | Hub: vendors, crafting, factions, companion, save lanterns, quest board |
| **Reedwater** | Shallow channels, floating reed islets, boardwalks, sunken shrines, heron-thin bridges | First open region; gathering, tutorial combat, ferry, the Sunken Choir |
| **Kestrel Crags** | Wind-cut limestone shelves, quarry terraces, rope bridges, hawk nests | Vertical exploration, quarry faction, wind puzzles, a procedural cave network |
| **Glasswood** | Petrified forest, silver trunks, glassgrass, frozen sound | Mystery region; Mira's trail; light-and-shadow puzzles; no map markers |
| **The Undersong** | Vast resonant caverns, water-carved halls, crystal chimes, the Vault of Voices | Main dungeon complex; logic grid puzzle; history; boss |
| **The Hush** | Desaturated grey field, silent architecture, drifting absence, thin returning color | Endgame region; navigation by memory; final choice |
| **The Low Water** | Drowned lowland beyond the valley mouth, boat wrecks, fog | Optional late region, Reedfolk home, high-risk exploration |

The map is one connected valley, but regions load at diegetic thresholds. Every threshold autosaves.

### 2.2 Time and weather

The valley has a fixed late-autumn mood: low amber sun, long shadows, mist in the low ground, occasional rain that changes footing and sound. There is a day/night tint for atmosphere, but **nothing is time-gated**. Shops do not close. NPCs do not disappear on a schedule. A "day" is roughly 40 real minutes of lighting change and exists purely for beauty. No quest requires waiting.

### 2.3 History in brief

- **c. −600 years:** Cantor surveyors discover the Undersong. They begin the Chimeworks: a valley-sized instrument.
- **c. −430:** The First Dissonance. A quake cracks the system; the Hush appears. The Cantors learn that a voice given to the great bell strengthens the Note.
- **c. −420 to −405:** The Harvests. Volunteers become conscripts. The Note holds; the Hush recedes. The valley is safe and complicit.
- **c. −400:** The Long Silence. The Cantors stop speaking, then vanish into the Undersong. Bellhollow is founded by those who refused to ask what the Note cost.
- **c. −60:** The spring that drives the Chimeworks begins to fail.
- **−19:** **Mira Alk**, a Listener, attempts a different solution — a chord of many willing voices — and disappears into the Hush. Officially, she died.
- **−12 (the novella):** Mira's daughter **Wren** returns, learns the truth, and leads the town to sing instead of sacrifice. The Note is released; the great bell cracks; the Hush breathes but does not vanish. Wren stays as Listener.
- **Present (the game):** The valley is changing. The released voices are not at rest. The quarry has breached a sealed Cantor chamber. Listeners are being called — including the player.

### 2.4 Factions

- **The Tenders** — bell-keepers and ritualists. Believe continuity is the only thing between the valley and silence. Led by **Warden Sable Voss** in the novella; in the game, by an aging Sable and a council. Values: duty, restraint, silence. Fear: chaos, exposure, the truth about the Note.
- **The Quarry Guild** — humstone miners and builders. Believe the valley should pay for its own upkeep and that secrecy is a luxury of the comfortable. Led by **Brannoc Kettle** (game: his daughter **Maud Kettle**). Values: work, openness, prosperity. Fear: being told to wait forever.
- **The Reedfolk** — boat families of Reedwater and the Low Water. Believe the Hush is a tide, not an enemy, and that the valley must be allowed to change. Led by **Nissa Quill** in the game. Values: movement, hospitality, listening. Fear: walls, permanence, being "saved" into a cage.
- **The Listeners** — not an organization. A scattered inheritance of people who hear the undertone. Their tradition is a set of notebooks, a handshake, and a warning: *never answer a voice you cannot see*.
- **The Choir** — what remains of the Cantors, now Hollow. Not a faction so much as a wound with a will. The **Choirmaster** collects voices because it believes it is preserving them.

Reputation with the three living factions ranges 0–5. It changes prices, dialogue, available side work, and which epilogue variations you see. **No main-story quest is ever gated by reputation.** Factions can disagree with the player without becoming enemies.

### 2.5 Ecology and creatures

Wildlife is musical and mostly harmless: **kettle-birds** that hum in fifths, **hush-hares** that make no sound at all, **glasswing moths**, **reed-eels**, **bellflowers** that close when spoken to. They exist for atmosphere and for the world to feel alive without being a resource pinata.

Hostile creatures are **dissonances**: animals and guardians whose inner note has been tangled by the Hush. They are not evil. They disperse into motes of light and a brief returning chord when defeated; the game never shows gore. Some can be calmed instead of fought (a designed alternative, not a checkbox).

### 2.6 Visual identity

"Carved paper and copper." Flat-shaded low-poly geometry, confident silhouettes, limited palette, strong low sun, long shadows, thin emissive ribbons for sound. Bell curves, arches, tuning-fork trees, wide reed hats, tall narrow figures, round lanterns. Read `docs/ART_DIRECTION.md` for the palette, shape language, and rendering rules. Nothing imitates Diablo, Minecraft, or any existing game's art.

---

## 3. Story

### 3.1 Premise

The player is a Listener drawn to Carrow Vale twelve years after the events of the novella. The great bell is cracked. The Hush has withdrawn from the town but has begun to move in new ways, and the voices released from the bell have not found rest. The Chimeworks are failing faster than the rituals can compensate.

### 3.2 Central mystery, in layers

- **Surface (child-readable):** Why is the valley going quiet, and how do we wake it up?
- **Middle (town secret):** The Long Note was sustained by taking people's voices. The Tenders have always known. The "Tending" is a euphemism.
- **Deep (family and world):** Mira Alk did not die. She went into the Hush to give the taken voices back, and she is still there, changing. The Choir is not an invader; it is the shape grief takes when no one will listen to it. The final question is not "how do we defeat the silence" but "what do we owe the dead, and who decides?"

### 3.3 Main arc (designed full game)

1. **The Cracked Bell** (Bellhollow) — Arrival, tutorial, the town's fragile peace, first companion. Learn to listen. A routine repair reveals a Cantor seal that should not be there.
2. **The Sunken Choir** (Reedwater) — Recover a chime that keeps the north channel clear. First dungeon, first boss, first faction choice. *(This is the vertical slice.)*
3. **The Quarry Door** (Kestrel Crags) — The Guild has opened a sealed shaft. Decide whether to close it, study it, or let the Guild keep it. Meet the first Hollow that speaks.
4. **Mira's Letter** (Glasswood) — Follow a trail of Listeners' notebooks. Learn the chord experiment. Learn that Mira chose to stay.
5. **The Vault of Voices** (Undersong) — Descend, solve the voice lattice, meet the Choirmaster, learn what the Cantors did and why. Recover the first willing chord.
6. **What the Silence Kept** (The Hush) — Navigate by memory, meet the echoes of the taken, find Mira. The final choice.
7. **Endings** — three, all bittersweet, none "good/bad": **The Chord** (plural, risky, alive), **The Note** (stable, costly, quiet), **The Silence** (let it pass, transform the town, wild). Epilogue variations per faction trust and side quests.

The main story is completable in roughly 12–18 hours for a first-time player who explores, 8–10 hours for a focused run. No ending requires grinding.

### 3.4 Quest design principles

- Quests are **problems with people attached**, not errands. Every main quest changes the world state visibly.
- Multiple solutions are authored where the fiction supports them: talk, build, sneak, fight, or solve.
- Consequences are legible in advance whenever possible, and shown afterward in the hub (repaired ferry, reopened channel, new stall, a faction's banner).
- NPCs pursue their own goals. Some quests continue without the player; a few can be missed and are acknowledged, not punished.
- No quest asks the player to collect 20 rat tails. Gathering is for crafting, and quests ask for a handful of specific things with alternate sources.

### 3.5 Side content (selected)

- **Pip's Bell** — Find Brannoc's escaped kettle-bird and the small bell it stole. Teaches listen-pulse. No combat.
- **The Ferryman's Debt** — Nissa owes a Reedfolk family a boat. Repair it (build) or pay (craft/sell) or mediate (dialogue). Teaches building.
- **The Cartographer's Widow** — A map that lies; a light-and-shadow puzzle in Glasswood.
- **A Quiet Argument** — Two Tenders disagree about the Tending. The player can take sides or refuse; both are respected.
- **The Humstone Thief** — A Quarry Guild mystery with three suspects and a physical clue in the stone dust.
- **Names in the Water** — Reedfolk funeral rite; a gentle exploration quest about memory.
- **The Unfinished Chime** — Optional dungeon puzzle requiring a resonator built in a specific place. Multiple valid chords.
- **What Pell Heard** — An archive mystery spanning three regions; rewards a unique charm and a lore revelation.

---

## 4. Core loop

**Minute to minute:** move through readable terrain → observe (listen pulse reveals resonance, tracks, hidden geometry) → interact, gather, or fight → learn something about the place → make a small choice.

**Fifteen to thirty minutes:** one location or one quest stage → a puzzle or fight → a discovery → return to a lantern, autosave, stop cleanly.

**A session of hours:** a region arc → a dungeon → a faction decision → visible change in Bellhollow.

There is no energy, no cooldown on exploration, no daily content, and no reason to log in. The world waits.

---

## 5. Exploration

### 5.1 Movement

Third-person, camera-relative movement. Walk, sprint (Breath), dodge with i-frames (Breath), jump, climb ladders and marked ledges, wade, swim (Breath), ride the ferry, and use ziplines/reedslides later. Movement is tuned to feel grounded: acceleration, a small coyote window, step-up, slope limits, and a camera that does not fight the player.

Traversal abilities are earned, not gated by keys: **Reedstep** (cross shallow water without slowing), **Climber's Hook** (marked cliff ledges), **Hushlantern** (see in the Hush), **Resonator** (built, opens harmonic gates). Returning to old places with new tools is a designed pleasure, with optional shortcuts that open permanently.

### 5.2 Discovery

- **Echoes** — memory fragments (a carving, a song, an object) that raise Attunement. There are ~40 in the full game, hand-placed, each with a short readable/listenable vignette. They are not collectible trivia; each teaches something about the valley or a puzzle language.
- **Lanterns** — safe points that light the map, autosave, and let companions talk. Not fast-travel spam: about one per region sub-area, plus the hub.
- **Hidden places** — behind waterfalls, under boardwalks, inside hollow trees, up marked climbs, through harmonic gates. Rewards are practical (materials, charms, recipes) or narrative (a letter, a room, a view).
- **No meaningless collectibles.** No feathers, no flags, no "500 seeds". If it glitters, it does something.

### 5.3 The Listen pulse

Hold **Listen** to send a soft pulse: nearby resonance sources glow, climbable ledges show a chalk mark, hidden doors reveal a seam, enemies within range show their pitch marks, and (in darkness) geometry is outlined briefly. It has a short cooldown and a visual/audio cost so it is a tool, not a wallhack. It is the game's signature verb and the accessibility bridge for players who can't rely on audio.

---

## 6. Combat

### 6.1 Feel

Readable, weighty, non-gory. Attacks have wind-up, contact, and recovery; hits produce a brief freeze-frame, a directional spark, a tonal ping, and a poise reaction. Enemies disperse into light. The camera shakes are small and can be disabled. The player can pause at any time.

### 6.2 Vocabulary

- **Light attack** — fast chain, low commitment, builds Cadence.
- **Heavy attack** — slow, high poise damage, can break guards; a held variant for a wider arc.
- **Dodge** — i-frames, cancels recovery, costs Breath.
- **Parry / Counterpoint** — a short window; a successful parry staggers and opens a free heavy. Forgiving on Story, tight on Challenge.
- **Chords (abilities)** — cooldown-based, no mana potions. Four equipped at once.
- **Listen in combat** — reveals the next telegraph's pitch and weak point for a moment; costs Breath.
- **Companion command** — focus target, hold ground, use ability, revive.

### 6.3 Pitch and poise (not colour-matching)

Every enemy has a **pitch** (Low, Mid, High) shown as one, two, or three marks plus a distinct audio timbre. Weapons and chords carry a pitch. Hitting an enemy with a *matching* pitch deals bonus poise damage and produces a resolving chord; *opposing* pitch is resisted. This is a soft advantage, never a lock: any weapon can kill any enemy, and the basic combo is always viable. Pitch is used to make fights *readable* and to reward observation, not to force loadout juggling. The colour-blind/audio-off player sees the marks and the resolve animation; nothing depends on colour or hearing alone.

### 6.4 Player stats and progression

- **Vigour** — health.
- **Breath** — stamina for sprint, dodge, heavy attacks, Listen.
- **Ear** — resonance power: chord damage/radius, healing, pitch-match bonus.
- **Stride** — movement and dodge distance.

Progression is **Attunement**, earned by Echoes and major discoveries (not enemy grind). Each Attunement grants one skill point and a small stat choice. Enemies drop materials and marks, not XP. A player who avoids most combat can still reach the stats needed for the main story because Echoes are the primary source. There is no level cap treadmill and no infinite scaling.

**Skills (18 in the full game; 8 in the slice):** each is a meaningful behavior change, not +5% damage. Examples: *Hushstep* (dodge leaves a decoy tone), *Toll* (cone stagger wave), *Lantern Song* (healing aura that also lights the Hush), *Echo Mark* (reveals a weak point and raises pitch match), *Reed Bind* (roots a target), *Counterpoint* (parry riposte), *Second Verse* (companion revive), *Quiet Passage* (enemies lose track of you briefly). Respec is free at any lantern. No builds are traps.

### 6.5 Equipment and crafting

- Slots: **weapon**, **offhand** (chime, buckler, lantern), **cloak**, **charm ×2**, **tool**.
- ~18 weapons, ~12 cloaks, ~20 charms in the full game; 3 weapons, 4 cloaks, 5 charms in the slice. Every item has a hand-authored identity and a visible silhouette change on the character.
- Upgrades at a bench: +1/+2 with materials found in the world, never random. No rarity colours, no affixes, no loot beams.
- Set-like synergies are explicit and small ("Reedfolk weaves: +Breath regen while wading"), discoverable from the item text.
- **No random drops.** Enemies drop a fixed material list with a guaranteed amount. Chests are hand-placed and contain authored rewards. The player can plan.

### 6.6 Difficulty and failure

Three authored difficulties: **Story** (generous windows, lower damage, aim assist, more puzzle hints offered), **Standard**, **Challenge** (tighter windows, smarter packs, no aim assist). All are changeable at any time without penalty. Death is soft: the player returns at the last lantern, keeps all items and quest progress, and enemies reset. There is no corpse run, no lost currency, no durability tax.

### 6.7 Enemies (roster excerpt)

| Enemy | Behavior | Counterplay |
|---|---|---|
| **Reed Crawler** | Burrows in reeds, ambushes, retreats when hurt, calls one ally | Listen reveals its burrow; dodge the lunge; punish the retreat |
| **Bramble Ram** | Territorial charger; telegraphs with a hoof-scrape; stunned if it hits stone | Bait into walls/arches; sidestep; heavy punishes the stun |
| **Choir Moth** | Floats at range, harmonizes to buff/heal others, flees if focused | Prioritize, use ranged/chord, cut line of sight |
| **Stone Sentinel** | Cantor guardian; patrols, raises a shield against frontal attacks, reacts to sound | Break its stance with a heavy or a pitch match, attack from flank, or sneak past |
| **Hollow Wisp** | Keeps distance, silences abilities in a small field, phases through walls | Close fast, use weapon basics, force it into light |
| **Reed Stalker** | Pack hunter; flanks, waits for the player to commit | Watch the reeds, use Toll to break the pincer |
| **Hushbear** | Slow, enormous, guards paths; not aggressive unless approached | Avoid, distract with a thrown tone, or fight for a shortcut |

Enemy groups use a shared alert board: one scout calls, others take flank slots, support stays behind. Enemies investigate sounds, guard territory, protect healers, retreat to allies, and give up a chase at a territory line. They are not all "run at the player".

### 6.8 Bosses

- **The Hollow Stag** (slice, Sunken Choir) — a guardian whose antlers are broken chimes. Three chimes in the arena must be rung in the order shown in the ruined glass window while the Stag charges, stamps, and calls Hollow echoes. Ringing them in order breaks its shell; then it fights with readable charge/antler sweeps and a "silence field" that disables chords until you step out. No adds treadmill, no invulnerability sponge: the puzzle is the phase gate, the fight is the execution.
- Later bosses: **The Keeper of the Quarry Door** (a stone choir that must be conducted), **The Choirmaster** (a duel of echoes and listening), **The Hush** (a navigation/choice finale, not a damage sponge).

---

## 7. Crafting and building

### 7.1 Resources

Hum-reed, pine resin, copper scrap, humstone shard, glassgrass fibre, river clay, and rare **echo-glass**. Each has 2–3 uses; none is a filler. Nodes are hand-placed and respawn slowly on region re-entry (a convenience, not a grind loop), and vendors sell small amounts so the player is never stuck.

### 7.2 Crafting

At the hub bench or a portable camp: weapons, cloak repairs/upgrades, charms, tonics, tools, and **build kits**. Recipes are learned by discovery (a carving, a book, a companion's suggestion, experimentation) as well as bought. ~24 recipes in the full game; 10 in the slice. Crafting is instant (no timers), with a short, satisfying bench animation. No crafting queues, no real-time waits.

### 7.3 Building

A small, purposeful vocabulary placed in the world, not a voxel sandbox:

- **Lantern Post** — light, a safe point, and a small map reveal.
- **Resonator** — emits a chosen pitch; used in harmonic gates, to calm creatures, and to purify Hush patches.
- **Reed Bridge** — spans marked gaps; permanent.
- **Camp** — rest (heal, companion banter, save), portable crafting.
- **Songbed** — planted reeds that slowly restore a patch of Hush and attract wildlife.
- **Repair scaffolds** — restore authored structures (ferry dock, bell ropes, channel gates, the town well).

Placement uses a ghost preview with slope/clearance/overlap rules and a short list of **sockets** for puzzle-critical structures. Free placement is allowed for camps and lanterns. Structures persist in the save and change the world visibly. Costs are modest; the point is expression and problem-solving, not resource grinding. Dismantling returns most materials.

### 7.4 Integration

- The ferry cannot run until its dock is repaired (build).
- A harmonic gate needs two resonators at specific distances (build + spatial reasoning).
- A Hush patch blocks a shortcut; a songbed clears it over one region visit (not real time).
- A camp lets a companion open up about their past (narrative reward).
- The town visibly improves as you repair it; vendors add stock, children appear, lanterns light.

---

## 8. Puzzles

Puzzles are the spine, not a side dish. Every region teaches a language, then asks the player to speak it. Rules are introduced safely, then combined. Hints escalate in three steps (nudge → specific → solution) and are always optional; solving without hints is recorded only in the player's own journal.

### 8.1 Puzzle families

1. **Harmonic tuning** — set stones/chimes to a target chord. Clues are in carvings, songs, bird calls, or architecture. Multiple valid chords where the fiction allows (any chord in the same mode opens the gate, but a "true" chord yields a bonus).
2. **Water and flow** — sluices, mill wheels, cisterns, tide gates. Route water to raise/lower, turn, or reveal. Simulated visually; the player can experiment without drowning.
3. **Echo navigation** — dark spaces where Listen reveals geometry for a moment. Build a mental map; multiple routes; no instant death. Nissa holds a light and comments, but does not solve it.
4. **Spatial alignment** — mirrors, prisms, shadow-casting arches, and the sun. Strong in Glasswood.
5. **Mechanical sequences** — bell order, lever timing without twitch requirement, counterweights, pulley systems.
6. **Logic lattices** — the Vault of Voices: assign names/voices to resonators under constraints derived from inscriptions. A genuine logic grid, with a paper-and-pencil feel and an in-world notepad.
7. **Multi-stage mysteries** — a clue in one region unlocks an interpretation in another. The Cartographer's Widow, What Pell Heard, and the main "who fed the Note" thread.
8. **Build puzzles** — place structures to satisfy a spatial/harmonic condition. Multiple solutions; dismantle freely.

### 8.2 Rules

- Every rule is demonstrated before it is tested.
- Failure is reversible, quiet, and informative. No punishment, no timer, no "you died to a puzzle".
- No pixel hunts. Interactables have a consistent affordance; Listen highlights clues; the journal records discovered facts, not solutions.
- Hints are diegetic where possible (a companion notices, a book falls open) and always available from the pause menu.
- Younger players can finish the critical path with hints; adults get optional harder variants and "true" solutions that reward observation.

### 8.3 Puzzle catalogue (full game)

| # | Name | Region | Skills | Solutions |
|---|---|---|---|---|
| P1 | The Chime Gate | Reedwater | Tuning, pattern from a carving | 1 true + 2 modal alternatives |
| P2 | The Sluice | Sunken Choir | Flow, spatial | 2 routes |
| P3 | The Echo Maze | Sunken Choir | Memory, orientation | 3 routes, one secret |
| P4 | The Stag's Window | Sunken Choir boss | Pattern, observation under pressure | 1 order, readable from glass |
| P5 | Chord Sockets | Reedwater optional | Build, distance, harmony | Many valid layouts |
| P6 | The Sundial Stair | Kestrel Crags | Shadow, time-of-light (not real time) | 2 |
| P7 | The Voice Lattice | Undersong | Logic grid | 1, with 3-stage hints |
| P8 | The Hush Lanterns | The Hush | Memory, navigation, multi-stage | 2 |

---

## 9. Companions

Companions are people with opinions, not tools. They walk, fight, comment, disagree, and occasionally refuse. They never solve a puzzle for the player; they notice things, hold lights, demonstrate a rule, or offer a hint if asked. They can be told to wait, follow, focus a target, use an ability, or go home. Their trust rises through shared discovery and respectful choices, never through gift spam.

**Nissa Quill** (Reedfolk, 30s in the game; 19 in the novella) — reed-reader, ferry keeper, ranged specialist. Dry, quick, kind under the teasing. Ability **True Pitch**: reveals an enemy's pitch/weak point and hums the reference note for a puzzle. She has her own stake in the Reedwater choice and will say so. She is not romanceable; the relationship is a friendship between adults (or a mentor friendship for younger players), written with warmth and no fan service.

**Brannoc Kettle** (Quarry Guild, 70s) — defender/engineer. Deaf in one ear, speaks through a copper horn, laughs like a door. Ability **Brace**: taunts, shields, and repairs a structure instantly once per rest. He argues with Nissa and likes the player more if they ask questions.

**Pip** — a kettle-bird. Support/comic. Finds a resource once per region, distracts an enemy, sits on things. Never speaks in words; captions translate its hums ("[a satisfied fifth]").

**Companion AI principles:** stay out of the player's line of fire; do not steal the last hit on a boss phase; revive the player if safe; retreat and heal instead of dying heroically; path around hazards; comment at most once per beat; never repeat a line in the same session; be quiet during puzzles unless asked. AI companions are always labeled as AI in the party UI.

Co-op (designed, not shipped): 2–4 players, invite-only, AI fills gaps, no open chat, preset pings/emotes, host-authoritative state, safe disconnect. See `TECHNICAL_ARCHITECTURE.md` §9.4.

---

## 10. Interface

The world is the interface. HUD elements appear contextually and fade:

- Top-left: a thin health/breath arc around the character portrait mark (no giant bars).
- Bottom-right: contextual action prompts; ability pips with cooldown rings.
- Top-right: a compass sliver that shows cardinal marks and player-placed pins, **not** quest arrows.
- Interaction: a small in-world diamond and a verb ("Listen", "Read", "Tune", "Place"), never a wall of floating icons.
- Subtitles: on by default, speaker-named, with sound captions.
- Damage: a subtle edge tint and a tonal cue; no red vignette strobing.

Screens: Title/Continue, Save select, Character creation (name, pronouns, palette, starting ear — no class lock), Field Notebook (Journal / Quests / Map / Lore / People), Inventory, Equipment, Crafting, Skills, Party, Build, Settings, Save & Sync, Pause. All reachable from a single pause ring, all navigable by keyboard, gamepad, touch, and screen reader labels. Design language: bone-paper panels, ink type, copper hairlines, small caps, one accent colour. Read `docs/UX_DESIGN.md`.

Accessibility: text scale 80–160%, full remap, hold/toggle options, aim assist, reduced motion, reduced camera shake, colour-blind-safe pitch encoding, subtitle size/background, mono audio, no audio-only puzzles, pause-anywhere, difficulty change anytime. No flashing content.

---

## 11. Multiplayer (designed, not shipped)

Optional 2–4 player cooperative exploration and combat, invite-only private sessions, host-authoritative world state, shared quest progress with per-player loot tokens, AI companions filling empty slots, no public matchmaking, no open voice or text chat (preset emotes and pings), disconnect-safe snapshots, and duplicate-reward prevention via idempotent reward IDs. Offline single-player remains the primary, complete experience. **This build does not include networking.** The README says so plainly.

---

## 12. Audio

Generative modal music, procedural bells/reeds/strings, rich ambience, clear combat tones, every cue visualised. Music responds to region and danger but never nags. There are natural silences; the Hush is partly defined by the absence of the score. Volume buses and a mono option. See `docs/AUDIO_DIRECTION.md`.

---

## 13. Non-addictive design charter

This is a hard product constraint, enforced by tests that scan for banned APIs/strings.

**Never ship:** push/local notifications, daily login rewards, streaks, energy, timers that gate content, limited-time events, battle passes, loot boxes, gacha, randomized paid or free rewards, artificial waiting, FOMO, loss-aversion mechanics (decaying resources, "your town is under attack"), red badges, retention analytics, A/B-tested reward schedules, dark-pattern consent.

**Always ship:** pause/save anywhere, offline-first, a clear ending, a complete arc, natural stopping points, no punishment for absence, progression by curiosity/creativity/mastery, transparent systems, free respec, difficulty changes, and a "you can stop now" courtesy: when the player quits, the game says where they are and that the valley will wait.

The game has no external notifications of any kind. It never asks the player to come back.

---

## 14. Scope and delivery

| Area | Designed | This build |
|---|---|---|
| Regions | 7 | Bellhollow, Reedwater, Sunken Choir, one procedural Undersong side-cave, a Kestrel shelf |
| Main quests | 7 chapters | Chapter 1 + Chapter 2 (complete arc with choice and consequence) |
| Side quests | 8 | 2 (Pip's Bell, The Ferryman's Debt) |
| Dungeons | 4 handcrafted + procedural caves | 1 handcrafted (Sunken Choir) + procedural caves |
| Bosses | 4 | 1 (Hollow Stag) |
| Enemies | 7 | 4 (Crawler, Ram, Moth, Sentinel) + boss |
| Companions | 3 | 1 (Nissa) + Pip as ambient pet |
| Weapons | 18 | 3 |
| Cloaks/charms | 32 | 4 cloaks, 5 charms |
| Skills | 18 | 8 |
| Recipes | 24 | 10 |
| Buildables | 6 | 5 |
| Puzzles | 8 families, ~20 instances | 4 instances across 3 families |
| Platforms | macOS, iPhone | macOS shipped; iPhone export configured and export-validated as far as signing allows |
| Co-op | designed | not shipped |

The build is an honest, polished vertical slice plus the shared architecture the rest of the game needs. Nothing in this table is claimed as complete unless it works and is tested; see `README.md` and `docs/PLAYTESTING.md`.
