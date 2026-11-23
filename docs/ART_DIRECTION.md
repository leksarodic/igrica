# Art Direction — *The Long Note*

**Direction:** *Carved paper and copper.*
A world built of confident flat shapes, low sun, and thin lines of resonance. It should look like a place someone made by hand, then left to weather.

---

## 1. Why this direction

A small team cannot out-detail a AAA open world, and an iPhone cannot render one. But a strong silhouette, a disciplined palette, and a consistent shape language can outperform polygons. Low-poly flat-shaded geometry is cheap, coherent, and expressive; vertex colouring removes texture memory pressure; a single low sun with long shadows creates drama without post-processing. The constraint is the style.

The reference points are not games. They are **woodblock prints, carved wooden toys, old survey maps, and copperplate engravings**: shapes that read at a glance, lines that carry information, colour used as punctuation. Nothing here imitates Diablo's gothic realism, Minecraft's voxel vocabulary, or any other game's distinctive design.

**Three rules**

1. **Silhouette first.** Every creature, building, and prop must be identifiable as a black shape at 100 metres.
2. **Colour is a sentence, not decoration.** Each hue has a job. Saturation is reserved for things you can hear or use.
3. **The world is drawn, not photographed.** Visible flat facets, visible construction, a human hand in the geometry. Perfection is not the goal; clarity and character are.

---

## 2. Palette

| Role | Name | Hex | Use |
|---|---|---|---|
| Sky base | Pewter | `#2E3D42` | dusk sky, deep shadow, cave walls |
| Sky light | Reed Gold | `#D8B25C` | low sun, lantern light, copper highlight |
| Ground | Ochre | `#B08A55` | paths, plaster, dry reed, timber |
| Foliage | Verdigris | `#4C8578` | reeds, moss, patinated copper |
| Stone | Bone | `#E6DFCE` | limestone, paper, bone, UI panels |
| Water | Slate Blue | `#3E5C67` | water, distance haze, cloth shadow |
| Accent | Ember | `#C9613C` | warmth, danger, important interaction |
| Mystery | Plum | `#5B4A63` | Hush edges, Cantor interiors, twilight |
| Silence | Ash | `#8E9191` | Hush grade, disabled states, grief |
| Alive | Clear Mint | `#9FD8B9` | healing, returning colour, solved states |

**Discipline:** a scene uses at most two saturated colours. Everything else lives in the muted family. Emissive accents are small (lanterns, resonance seams, eyes) and never fill the screen. UI uses bone, ink `#1D2325`, copper `#A9764A`, and ember only for destructive or urgent actions.

The Hush is rendered by a single grade: saturation −85%, contrast +10%, a slight blue lift, plus slow drifting grey motes. Returning colour enters as thin ribbons and patches, not a full-screen flash.

---

## 3. Shape language

| Motif | Belongs to | Geometry |
|---|---|---|
| **Bell curve** | Cantors, Chimeworks, Tenders | arches, bells, domes, tapered towers, hanging skirts |
| **Tuning fork** | Listeners, resonance, gates | split prongs, Y shapes, twin pillars, antlers |
| **Reed / lance** | Reedfolk, water, growth | thin verticals, clustered fans, sweeping curves |
| **Block / wedge** | Quarry Guild, labour, honesty | chunky cubes, cut steps, flat lintels, visible tool marks |
| **Ring / loop** | community, cycles, the Choir | round windows, circular plazas, coiled rope, wreath |

Characters are **tall and narrow** with **wide horizontal accents**: broad reed hats, bell-shaped cloaks, shoulder boards, copper ear-cuffs. This makes crowds readable and gives every NPC a distinct outline. Faces are simple planes with painted features suggested by geometry, not detailed textures — expressive at a distance, never uncanny.

**Architecture.** Bellhollow is stacked terraces of timber frames, ochre plaster, and copper roofs, with round windows and hanging lanterns. Cantor structures are pale limestone, precise, and too tall for the people who now live among them — arches whose tops are lost in mist, staircases with a riser too high for a child, channels cut to musical lengths. Quarry buildings are blunt and temporary. Reedfolk boats are long, low, and painted with wave-glyphs. The Hush has architecture with the colour and detail sucked out, but the shapes are the same — that is the point.

---

## 4. Characters

- **Wren (novella; NPC/legend in game):** narrow, weathered, reed-cutter's hook at the belt, a coat the colour of wet slate, a wide hat with a torn brim. Her silhouette is a vertical line with one angled hook.
- **Sable Voss:** tall, straight, long slate coat with copper bell-buttons down the spine, hair pulled back, one ear covered by a copper listening plate. Reads as a closed door.
- **Nissa Quill:** compact, quick, layered reedcloth in verdigris and ochre, a short cape that flares when she turns, hair tied with river-glass beads, a sling of woven reed. Silhouette: a triangle in motion.
- **Brannoc Kettle:** huge, round-shouldered, dust veil, leather apron, one copper speaking-horn hanging at the chest. Reads as a boulder with a warm face.
- **Old Pell:** bent, layered paper coats, spectacles like two coins, always carrying three books. Reads as a walking stack.
- **The Choirmaster:** 3 metres tall, thin as a tuning fork, grey, robed in absence, a face made of a smooth bell-curve plate with no eyes, hands that end in chime prongs. Moves without footsteps. Never monstrous in a gory way; beautiful and wrong.
- **The Hollow Stag:** a great elk whose antlers are broken stone chimes, ribs open like a cage of silent bells, eyes like fogged glass. Moves in stops and starts, as if listening.

The player character is customizable in palette and silhouette accents (hat, cloak cut, ear-cuff, tool) but always belongs to the same shape family: a traveller, not a superhero. No giant shoulder pads, no glowing destiny armour.

---

## 5. Environment recipes

**Bellhollow (hub).** Ochre and copper, warm pools of lantern light, wet stone, hanging laundry, terraced gardens, a dry basin with a cracked tower at the center. Sightlines frame the tower from every street. Smoke. Birds. The town should feel *lived in and slightly tired*, with small signs of repair the player can add to.

**Reedwater.** Horizontal bands: pale sky, dark reed banks, silver water, gold light. Boardwalks and stilt platforms. Reeds are tall clustered quads that sway with a vertex shader. Floating islets of woven roots. Dead trees shaped like tuning forks. The Sunken Choir entrance is a half-drowned stone bell mouth under the waterline, visible only at the right angle.

**Kestrel Crags.** Verticality, wind, pale limestone shelves, rope bridges, hawk silhouettes, quarry cuts with visible strata. Sky occupies most of the frame. Grass is sparse. The palette cools with altitude.

**Glasswood.** Petrified trunks of silver-grey glass, canopy of shard leaves, light refracted into thin spectral lines on the ground. Everything is still; sound is muted in the mix. A beautiful, unsettling place.

**Undersong.** Dark limestone cathedrals, black water, chime columns, lantern moss in mint and plum. Echo is visual: rings of light expand from footsteps. The scale is too large for the player, deliberately.

**The Hush.** Ash-grey field, buildings stripped to shape, no birds, no wind sound, drifting motes. Colour returns in ribbons where the player restores something. The sky is a flat, luminous white-grey with no sun disc.

---

## 6. Lighting and rendering

- One directional sun, low (15–30°), warm `#FFD9A0`, energy 1.2; sky ambient cool `#7C98A0`, energy 0.35. Shadows: one cascade, 2048 px on Mac high, 1024 on iPhone.
- Lanterns: emissive spheres with an `OmniLight3D` (range 4–6 m), max 4 active near the player, pooled. Light is baked into vertex colour where possible for distant props.
- Fog: exponential depth fog matching the sky, denser at dawn and in the Hush. No volumetric fog on mobile.
- Sky: custom gradient shader with a low sun disc and slow-moving aurora bands shaped like sine waves. Stars appear only in the Undersong "sky" reflection.
- Post: colour grade + vignette + film grain (subtle, optional). No bloom on low-end iPhone; light bloom on Mac/High.
- **Renderer:** Mobile. Flat shading via `StandardMaterial3D` with `vertex_color_use_as_albedo`, roughness 0.9, specular 0.2. Copper trim uses metallic 0.5. No normal maps; geometry carries form.
- **Draw budget:** MultiMesh for reeds, grass, rocks, pebbles, lanterns, and crowd props. Target ≤ 150 draw calls, ≤ 120k triangles (Mac high) / 45k (iPhone low).

## 7. VFX

- **Resonance:** thin translucent ribbons with a sine displacement, additive, fading over 1.2 s. Pitch is encoded by ribbon count (1/2/3) and wave speed, not colour alone.
- **Hits:** a flat white-gold spark burst, a short freeze-frame (30–60 ms), and a ring that expands along the ground. No blood, no decals.
- **Enemy defeat:** the silhouette breaks into 12–20 motes that drift upward and resolve into a single soft chord; the body is gone. This is both a moral choice and a performance win.
- **Healing:** mint ribbons spiral inward, a soft bell tone, a brief warm rim light. 
- **Listen pulse:** a transparent ring expands from the player, outlining resonance seams in gold and climbable ledges in chalk white. This is the signature visual.
- **Hush:** saturation drain at the screen edges, motes moving against the wind, sound captions go grey.
- **Weather:** rain as streaked quads with a wet-darkened ground shader; mist as layered billboards; falling leaves in autumn. All toggleable for performance.

## 8. UI visual language

Bone paper, ink, copper hairlines, small caps, a serif display face, generous margins. No gradients, no glass, no floating cards, no emoji. The HUD is drawn as if with a fine pen: thin arcs, small diamond markers, tick marks. Menus look like a naturalist's field notebook: a map pinned to a page, a pressed reed, a note in the margin. The world stays visible behind translucent parchment; no full-screen opaque dashboards except the map and journal, which are meant to be read.

Read `docs/UX_DESIGN.md` for layout, type scale, and interaction rules.

## 9. Typography

- **Display / headings:** a humanist serif available on Apple platforms (`Iowan Old Style`, fallback `Palatino`, then Godot's default serif). Small caps, 1.15 line height, letter-spacing +2%.
- **Body:** `Avenir Next` / `Helvetica Neue` fallback, 16–18 px at 1×, 1.45 line height.
- **Numbers / data:** tabular figures, same body face, lighter weight.
- **Never:** all-caps paragraphs, centered body text longer than two lines, text over busy foliage without a backing plate.
- Text scale 80–160% with reflow, not clipping. Minimum readable size on iPhone: 15 pt effective in landscape.

## 10. Sound-shaped visuals (accessibility)

Every audio signal has a visual twin:

| Audio | Visual |
|---|---|
| Pitch Low / Mid / High | 1 / 2 / 3 short horizontal marks above the target; low = thick, high = thin |
| Enemy telegraph | A shaped flash on the attacking limb + ground arc; direction is unambiguous |
| Hidden resonance | Gold seam + a slow pulse on the Listen ring |
| Puzzle correct chord | Mint ribbon bloom + a held ring |
| Puzzle wrong | Short ash-grey flicker, no punishment sound |
| Hush proximity | Desaturation + motes; captions note "[sound fades]" |
| Companion call | Portrait mark + caption, never audio-only |

## 11. Asset production rules

1. All shipped art is original and generated in-repo (`MeshFactory`, shaders, UI) or created by the team. Any external asset must be licensed for commercial use, credited in `docs/ASSET_LICENSES.md`, and reviewed for style fit.
2. No AI-generated imagery is shipped as-is without art direction and licensing review; the procedural art system is the primary source.
3. File naming: `snake_case`, prefixed by category (`prop_`, `env_`, `char_`, `vfx_`, `ui_`).
4. Every mesh under 1,500 triangles unless it is a hero asset; hero assets under 6,000.
5. Vertex colours, not textures, for environment surfaces. Textures only for UI paper grain, noise, and the sky.
6. Test every new prop on iPhone Low before adding it to a region.

## 12. Review checklist

- Does it read as a silhouette at distance?
- Is it within the palette and shape language?
- Does it tell the player something true about the world?
- Is it distinguishable from every other interactable?
- Does it survive colour-blind simulation and muted audio?
- Is it under budget, and does the scene still hold 60 fps on the target Mac / 30 on iPhone Low?
- Would a child understand what it is, and an adult find something more in it?
