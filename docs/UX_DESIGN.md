# UX and Interface Design — *The Long Note*

**Principle:** the world is the interface; the notebook is where you think.

The HUD is a pen sketch over the world. Screens are pages in a field notebook. Nothing shouts, nothing pulses for attention, and nothing is ever hidden behind a currency.

---

## 1. Design rules

1. **Contextual, not constant.** HUD elements appear when relevant and fade after 2.5 s of stillness. Health is visible only in danger or on demand; a subtle vignette and a tonal cue carry low health.
2. **One primary action.** The interact prompt always reads a verb in the player's language: *Listen, Read, Tune, Place, Speak, Climb, Repair.* Never "Press E to interact."
3. **No quest arrows.** The compass shows cardinal marks, discovered places, and player pins. The journal describes where a thing is in human terms ("upriver, where the reeds turn silver"). The map reveals by exploration.
4. **No red badges.** New journal entries are marked by a small ink dot that disappears when viewed. No counts, no exclamation marks, no badges on the app icon. Ever.
5. **Stop gracefully.** Pause → "Save & Stop" always available. On quit, a single quiet line: "The valley will wait." Autosave indicator is a small copper ring that fills once, then fades.
6. **Explain by doing.** Tutorials are one-line prompts attached to the action, with a "show me" option. No modal pop-ups in the first minute. The player can turn tutorials off.
7. **Readable over decorative.** Text never sits on busy foliage without a plate. Contrast ≥ 4.5:1 for body text, ≥ 3:1 for large text. Text scale 80–160%.
8. **Platform-native feel.** Mac uses hover, precise clicks, scroll, keyboard focus, and a windowed layout. iPhone uses large thumb targets, edge-safe layouts, swipe-to-dismiss for sheets, and haptic confirmation (optional).

---

## 2. Onboarding (first 10 minutes)

1. **Cold open, no menu wall.** Title → New Game → character sheet (name, pronouns, palette, one starting "ear" trait) → the ferry.
2. **Movement** taught by the road and a companion's line, not a popup. A prompt appears only if the player stands still for 8 s.
3. **Listen** taught at the first roadside carving: the pulse reveals a hidden path and a lore line. This is the game's thesis in one action.
4. **Combat** taught against a single Reed Crawler in a wide, safe arena with a companion callout. Dodging is taught by a telegraphed lunge, not a tutorial box.
5. **Crafting** taught by a broken ferry rope: gather two reeds and resin, craft a splice, watch the dock change. Building and crafting are introduced as care for a place.
6. **First save lantern** is a deliberate, warm moment: light it, the map opens a little, the game autosaves with a soft chime and a one-line confirmation. No "AUTOSAVE" banner.

---

## 3. HUD layout

### macOS (base 1600×900, scalable)

```
┌──────────────────────────────────────────────────────────────┐
│ [compass sliver]                                  [pause pill]│
│                                                              │
│                                                              │
│                     (world, unobstructed)                    │
│                                                              │
│ [vitals arc]                                   [ability pips]│
│                                     [context prompt]         │
└──────────────────────────────────────────────────────────────┘
```

- **Vitals arc:** a thin 120° arc, bottom-left, surrounding a small ink portrait mark. Health is a solid copper line; Breath is a finer mint line that appears only when spent. Numbers are off by default (option to show).
- **Compass sliver:** 220 px wide, top-center-left, showing N/E/S/W ticks, lantern marks, and pins. No quest markers.
- **Ability pips:** four small diamonds with cooldown rings, bottom-right. Keyboard labels appear for 3 s when the loadout changes.
- **Context prompt:** centered above the ability pips: a diamond glyph + verb. On gamepad, the button glyph is inline.
- **Pause pill:** a small copper bell glyph, top-right; also Esc/Start. Opens the pause ring.

### iPhone (landscape, 2556×1179 logical scaled)

```
┌──────────────────────────────────────────────────────────────┐
│ [compass]                                          [menu pill]│
│                                                              │
│  (floating stick zone)                    (camera drag zone) │
│                                                              │
│ [vitals arc]                     [context]   [abilities ▲]   │
│                                  [listen]     [attack ●]     │
│                                  [dodge]      [heavy ◐]      │
└──────────────────────────────────────────────────────────────┘
```

- **Left thumb:** floating virtual stick; a reed-ring appears where the thumb lands, with a 96 dp radius. No fixed stick to chase.
- **Right thumb:** the right 60% of the screen is camera drag. A small dead zone around buttons prevents accidental camera moves.
- **Action cluster:** arranged in a shallow arc for the right thumb. Attack 76 dp, heavy 68 dp, dodge 68 dp, listen 64 dp, context 72 dp. Minimum spacing 12 dp. The cluster is mirrored if the player is left-handed.
- **Menu pill:** top-right, 44 dp tall, safe-area aware.
- **Prompts:** text above the cluster, never under the thumb. All buttons have text labels that can be disabled once learned; icons are custom line drawings, not generic glyphs.
- **Safe areas:** HUD inset by `safe_area` + 12 dp. Notches and the home indicator never overlap a target.
- **Battery:** the game does not force 30 fps, but offers "Balanced (30 fps)" and "Smooth (60 fps)" presets with a plain explanation.

---

## 4. The pause ring

Pause is a radial menu, not a grid of cards. Seven stations around a copper ring, with the world dimmed but visible:

```
                 Continue
        Settings          Journal
     Save & Sync          Map
            Party    Inventory
                 (Craft)
```

Keyboard/gamepad: left stick or arrows, A/Enter to select, B/Esc to close. Touch: tap a station; the center is Continue. Each station shows a one-word label and a small hand-drawn icon. No counts, no notification dots except the ink dot for new journal entries. `Save & Stop` is a persistent small line at the bottom of the ring: "Save and stop — the valley will wait."

---

## 5. Screens

### 5.1 Title
Full-screen painted view of Bellhollow at dusk (the in-engine world, not a separate asset), title in serif small caps, three options: **Continue**, **New Journal**, **Settings**. Continue shows the last save's place and playtime in human terms ("Reedwater, by the ferry — 2 h 14 m"). No news feed, no store, no social buttons, no daily reward.

### 5.2 Save select
A stack of journal spines, one per save, with name, place, playtime, device, and last played. Actions: Continue, Duplicate, Export, Delete (two-step confirmation, with "your autosave is safe"). Sync status is a small line: "Synced just now" / "Not synced — this device only" / "Another device has newer progress → Review". No auto-overwrite.

### 5.3 Character sheet
One page: silhouette preview, name field, pronoun choice (they/she/he/custom), skin/hair/cloak palette swatches, and a **starting ear** choice that grants a small initial affinity (not a class): *Reed Ear* (Breath), *Stone Ear* (Vigour), *Bell Ear* (Ear). The choice is explained in one sentence and can be respecced at any lantern. No min-max trap.

### 5.4 Journal (field notebook)
Tabs across the top edge: **Quests · Map · Lore · People · Echoes**. A pinned-paper aesthetic with a copper rule. Text is selectable on Mac; on iPhone it scrolls with large type. The journal records facts the player has learned, never solutions. Quest entries describe the problem in the character's voice and list known leads, not a checklist of waypoints.

### 5.5 Map
A hand-drawn survey of the valley, ink on bone, with contour hatching. Fog covers unexplored ground. Lanterns appear as small flames; pins are the player's own annotations (four symbols). The player can add a note to a pin. No fast-travel from the map: travel is physical, which keeps the valley legible. (Lanterns are save points, not teleporters.)

### 5.6 Inventory and equipment
A two-page spread. Left: carried items as drawn objects in a shallow grid, sorted by kind, with a weightless, searchable list. Right: the character silhouette with slots (weapon, offhand, cloak, charm ×2, tool) and a compact stat panel. Item detail slides in as a paper slip: name, one-line identity, stats, a short flavour line, actions (Equip, Upgrade, Drop). No rarity colours; a small copper corner mark for upgraded items.

### 5.7 Crafting
A workbench page: recipes on the left as annotated sketches; materials and outcome on the right. Known recipes only, with an option to "experiment" by combining two selected materials (discovery). Missing materials are shown in ink grey with their source hint. Craft is a single button with a short animation; no timers.

### 5.8 Skills
A small constellation of 18 nodes (8 in this build), grouped in three arcs: **Blade**, **Chime**, **Reed**. Each node is a line drawing with a two-line explanation and a "try it" preview. Free respec at any lantern with a single confirmation. No locked prestige layers.

### 5.9 Party
Companion portraits as ink sketches, with a one-line status, trust as a simple five-notch reed gauge, ability, and commands (Follow / Wait / Focus / Ability / Go home). Companions are labeled **AI companion**; no deception. A short bio is available on tap.

### 5.10 Build
A small radial of structures with costs, then a placement mode: ghost geometry, valid/invalid tint (mint/ash), a slope and clearance indicator, and confirm/cancel. Sockets glow faintly. On touch, drag to place, tap to confirm, a large cancel button at the thumb edge. Dismantle returns most materials and asks once.

### 5.11 Settings
Sections: **Display** (resolution/window, fullscreen, quality preset, brightness), **Audio** (master/music/ambience/SFX/UI, mono), **Controls** (keyboard/gamepad remap, sensitivity, invert Y, hold/toggle, touch layout handedness and button size), **Accessibility** (text scale, subtitles + size + background, sound captions, reduced motion, camera shake, aim assist, colour-blind pitch marks, high contrast, screen-reader labels), **Gameplay** (difficulty, tutorial prompts, hint frequency, damage numbers), **Saves & Sync** (sync folder, iCloud status, export/import, conflict history). Every option has a one-line plain-language description and applies immediately.

### 5.12 Save & Sync
A single page showing: local save (place, time, device), sync status (On/Off, folder or iCloud, last sync, pending changes), and the primary action **Save and continue on another device**. The action writes a snapshot, verifies its checksum, and shows a short confirmation with the folder path or "iCloud is syncing". No "success!" confetti. If offline, it says plainly that the save is safe locally and will sync when possible.

### 5.13 Conflict screen
Two journal pages side by side: this device and the other device, each with place, playtime, last played, Attunement, and the last quest stage. Three actions: **Keep this device** (the other is archived, not deleted), **Use the other device** (this save is archived first), **Keep both** (both appear in save select with device suffixes). A one-line explanation of why the conflict happened. No timers, no default destructive action.

---

## 6. Dialogue

- Letterbox-free, cinematic-adjacent: the camera gently frames the speakers; the world keeps moving. No freeze unless the scene needs it.
- A single subtitle line at a time, with speaker names, or a short two-line block at most. Tap/click/Space advances; a "history" button on the pause ring shows the last 30 lines.
- Choices are listed as full sentences with the player's intended tone in the authorial voice, never `[Lie]` tags. Conditions can grey out an option with a short reason ("You haven't read the inscription").
- No auto-advance. No timed choices. Ever.
- Sound captions in square brackets, e.g. `[the bell answers, a fifth below]`.
- Text is localized-ready: all strings in `data/` and UI tables, no concatenation of sentence fragments.

---

## 7. Feedback and juice (restrained)

- Soft hitstop, small directional camera push, tonal impact. Camera shake is 0 by default on iPhone, 0.3 on Mac, and fully adjustable.
- Interaction: a copper ring expands and fades; a single note plays. No coin sparkles, no "+1" floats unless the player opts into damage numbers.
- Pickup: the item flies to the notebook icon in one smooth arc; the notebook dot appears. No fanfare.
- Quest stage change: a single soft bell and a line in the journal; a small ink line animates in. No banner across the screen.
- Save: a copper ring fills, a quiet chime, nothing else.
- Low health: a thin ember edge and a slowed heartbeat-like tone; no red flashing. The effect can be disabled.

---

## 8. Accessibility commitments

| Need | Implementation |
|---|---|
| Low vision | 80–160% text scale, high-contrast UI theme, 4.5:1 minimum, scalable HUD, no text over clutter |
| Blind / low vision gameplay | All audio cues have visual twins; Listen pulse is core; no audio-only puzzle; nav assist option marks the next walkable ledge |
| Deaf / hard of hearing | Subtitles on by default, sound captions, pitch as shape marks, visual telegraphs; mono option |
| Colour vision | Pitch encoded by mark count and shape, not hue; palette tested with deuteranopia/protanopia/tritanopia simulation; high-contrast mode |
| Motor | Remap everything, hold/toggle, aim assist, generous parry on Story, no quick-time events, pause anywhere, touch targets ≥ 64 dp, no simultaneous multi-button requirements |
| Cognitive | One primary action, clear verbs, journal records facts, optional hints in three steps, no timers, no fail states in puzzles, difficulty change anytime |
| Motion sensitivity | Reduced motion disables camera bob, shake, ribbon shimmer, and weather intensity; FOV options |
| Photosensitivity | No flashing; all flashes ≤ 3 Hz and below threshold; can disable impact flashes |
| Session control | Pause/save/stop anywhere; no penalties for absence; clear ending |

Screen reader support: every menu control has an accessible name, role, and value; the HUD announces health/breath on demand, not continuously; gameplay is not fully screen-reader playable (documented honestly).

---

## 9. Content and tone rules for UI copy

- Plain, warm, specific. "The ferry rope has frayed through. Nissa has reeds enough for a splice, if you can find resin." Not "Quest: Repair Ferry (0/1)".
- No exclamation marks. No "Congratulations!" No "Awesome!" No fake urgency. No "Don't miss out!"
- Numbers only where they help a decision ("+12 Vigour", "2 of 3 chimes").
- Failure copy is kind and informative: "The stone settles back. The carving shows three notes, not two." Never "Wrong!"
- Confirmation copy names the consequence: "Give the chime to the Tenders. The north channel will run clear; the Reedfolk will lose their winter crossing."
- Save copy: "Saved. The valley will wait." Quit copy: "Your journal is closed at Reedwater. It will be here when you return."

---

## 10. Responsive behavior

- Base layout 1600×900; UI scales with `canvas_items` stretch and a `content_scale_factor` clamp. At aspect ratios wider than 21:9, the HUD pins to the safe area rather than stretching.
- Below 1024×640 logical, the HUD switches to "compact": smaller compass, vitals arc moves to the top-left, prompts shorten to verbs.
- Touch mode is selected by the last input device, not by platform: an iPad with a controller gets the desktop HUD with touch fallback available; a Mac with a touchscreen (none currently) would work too.
- Every screen is tested at 1024×640, 1280×800, 1600×900, 2560×1440, iPhone 15 landscape (2556×1179), and iPhone SE landscape (1334×750).
