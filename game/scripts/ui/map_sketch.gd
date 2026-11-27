class_name MapSketch
extends Control
## A hand-drawn survey of the valley. It marks what you have walked, not what
## you should do next.

var _paper := Color("#e2d9c4")
var _ink := Color("#2b3334")
var _soft := Color("#6f6a5c")
var _copper := Color("#a9764a")
var _ember := Color("#c9613c")


func _ready() -> void:
	custom_minimum_size = Vector2(660, 360)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, _paper, true)
	draw_rect(r, Color(_copper.r, _copper.g, _copper.b, 0.55), false, 1.0)
	for i in 7:
		var y := 24.0 + i * 44.0
		draw_line(Vector2(16, y), Vector2(size.x - 16, y + 3), Color(_soft.r, _soft.g, _soft.b, 0.12), 1.0)
	# Valley silhouette: three terraces around a central basin.
	var center := Vector2(size.x * 0.46, size.y * 0.52)
	for i in 3:
		var rad := 52.0 + i * 38.0
		var pts := PackedVector2Array()
		for s in 30:
			var a := TAU * s / 30.0
			var wobble := sin(a * 3.0 + i) * 7.0 + cos(a * 5.0) * 4.0
			pts.append(center + Vector2(cos(a), sin(a) * 0.72) * (rad + wobble))
		draw_polyline(pts, Color(_soft.r, _soft.g, _soft.b, 0.35), 1.0)
	# River braid.
	var river := PackedVector2Array()
	for s in 24:
		var t := float(s) / 23.0
		river.append(Vector2(center.x - 200 + t * 300, center.y + sin(t * 7.0) * 18 + 34))
	draw_polyline(river, Color(0.24, 0.36, 0.39, 0.55), 2.0)
	# Regions.
	_draw_region("Bellhollow", center, false)
	_draw_region("Reedwater", center + Vector2(-150, 30), false)
	_draw_region("Sunken Choir", center + Vector2(-55, -96), false)
	_draw_region("Kestrel Shelf", center + Vector2(150, -58), false)
	_draw_region("Glasswood", center + Vector2(78, 102), false)
	_draw_region("The Hush", center + Vector2(-246, -8), false)
	_draw_region("Low Water", center + Vector2(-300, 108), false)
	# The current place.
	var current := String(Game.current_region) if Game != null else "bellhollow"
	if current == "bellhollow":
		draw_circle(center, 5.0, _ember)
	# Compass tick.
	draw_line(Vector2(size.x - 42, 30), Vector2(size.x - 42, 54), _copper, 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(size.x - 42, 22), Vector2(size.x - 47, 32), Vector2(size.x - 37, 32)]), _ember)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x - 36, 30), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, _soft)


func _draw_region(label: String, pos: Vector2, visited: bool) -> void:
	var known := visited
	if Game.state != null:
		known = bool(Game.state.world.get("regions", {}).get(_region_key(label), false)) or visited
	var col := _ink if known else _soft
	draw_circle(pos, 3.0, _copper if known else Color(_soft.r, _soft.g, _soft.b, 0.4))
	var font := ThemeDB.fallback_font
	var text := label if known else label + " —"
	draw_string(font, pos + Vector2(8, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)


func _region_key(label: String) -> String:
	return label.to_lower().replace(" ", "_").replace("the_", "")
