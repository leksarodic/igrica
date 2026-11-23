class_name Palette
extends RefCounted
## One palette, one mood. Colours are named by what they do, not by hue.

const PEWTER := Color("#2e3d42")
const REED_GOLD := Color("#d8b25c")
const OCHRE := Color("#b08a55")
const VERDIGRIS := Color("#4c8578")
const BONE := Color("#e6dfce")
const SLATE := Color("#3e5c67")
const EMBER := Color("#c9613c")
const PLUM := Color("#5b4a63")
const ASH := Color("#8e9191")
const MINT := Color("#9fd8b9")
const INK := Color("#1d2325")
const COPPER := Color("#a9764a")

const GRASS_A := Color("#6f7a45")
const GRASS_B := Color("#8a8a52")
const MUD := Color("#7a6a4c")
const STONE_A := Color("#b8a98c")
const STONE_B := Color("#9a9184")
const STONE_DARK := Color("#6d6b62")
const WATER := Color("#3e5c67")
const WOOD := Color("#6b5439")
const WOOD_DARK := Color("#4a3a29")
const ROOF := Color("#4c8578")
const ROOF_DARK := Color("#365f57")
const HUSH := Color("#8e9191")


static func pitch_color(pitch: String) -> Color:
	match pitch:
		"low":
			return Color("#c9613c")
		"high":
			return Color("#9fd8b9")
		_:
			return Color("#d8b25c")


static func pitch_marks(pitch: String) -> int:
	match pitch:
		"low":
			return 1
		"high":
			return 3
		_:
			return 2


static func variant(base: Color, amount: float) -> Color:
	var r := clampf(base.r + randf_range(-amount, amount), 0.0, 1.0)
	var g := clampf(base.g + randf_range(-amount, amount), 0.0, 1.0)
	var b := clampf(base.b + randf_range(-amount, amount), 0.0, 1.0)
	return Color(r, g, b, base.a)
