class_name TerrainBuilder
extends RefCounted
## Hand-authored heightfields. The valley is not noise with a story pasted on;
## each region has a shape that teaches traversal, sightlines, and water flow.

const SIZE := 120.0
const STEP := 2.0


static func height_at(region_id: String, x: float, z: float) -> float:
	match region_id:
		"bellhollow":
			return _bellhollow_height(x, z)
		"reedwater":
			return _reedwater_height(x, z)
		"kestrel_shelf":
			return _kestrel_height(x, z)
		"glasswood":
			return _glasswood_height(x, z)
		_:
			return 0.0


static func _bellhollow_height(x: float, z: float) -> float:
	var r := sqrt(x * x + z * z)
	var h := 0.0
	if r < 13.0:
		h = 0.0
	elif r < 19.0:
		h = 1.15
	elif r < 26.0:
		h = 2.55
	elif r < 33.0:
		h = 4.0
	elif r < 39.0:
		h = 5.3
	else:
		h = 5.3 + (r - 39.0) * 0.38
	h += sin(x * 0.31) * 0.09 + cos(z * 0.27) * 0.08
	# A broad southern approach, so the town is seen rather than entered through a trench.
	if z > -6.0:
		var t := clampf(z / 41.0, 0.0, 1.0)
		var ramp := lerpf(0.0, 5.2, t)
		var width_blend := 1.0 - clampf((absf(x) - 9.0) / 9.0, 0.0, 1.0)
		var approach := width_blend * clampf((z + 6.0) / 12.0, 0.0, 1.0)
		h = lerpf(h, ramp, approach)
	# The tower plaza is flat.
	if r < 6.0:
		h = 0.05
	return h


static func _reedwater_height(x: float, z: float) -> float:
	var base := -0.18 + sin(x * 0.08) * 0.14 + sin(z * 0.11) * 0.1
	var channel := absf(z - sin(x * 0.11) * 5.5)
	var river := -1.45
	if channel < 4.2:
		base = river + (channel / 4.2) * 0.25
	elif channel < 7.0:
		base = lerpf(base, -0.7, 1.0 - (channel - 4.2) / 2.8)
	# A wide, shallow pool near the shrine.
	var pool := sqrt(pow(x - 4.0, 2) + pow(z + 26.0, 2))
	if pool < 9.0:
		base = -1.3 + (pool / 9.0) * 0.5
	# Small reed islets.
	for i in 6:
		var ix := -40.0 + i * 16.0
		var iz := 12.0 + sin(i * 2.1) * 14.0
		var d := sqrt(pow(x - ix, 2) + pow(z - iz, 2))
		if d < 3.2:
			base = maxf(base, -0.2 - d * 0.1)
	return base


static func _kestrel_height(x: float, z: float) -> float:
	var h := 0.3 + (x + 60.0) * 0.035 + sin(z * 0.16) * 0.35 + cos(x * 0.21) * 0.22
	if x > 18.0:
		h += (x - 18.0) * 0.55
	return h


static func _glasswood_height(x: float, z: float) -> float:
	return 0.15 + sin(x * 0.12) * 0.18 + cos(z * 0.15) * 0.14


static func water_level(region_id: String) -> float:
	match region_id:
		"reedwater":
			return -0.72
		"sunken_choir":
			return -0.35
		_:
			return -999.0


static func is_in_water(region_id: String, x: float, z: float) -> bool:
	var wl := water_level(region_id)
	if wl < -100.0:
		return false
	return height_at(region_id, x, z) < wl - 0.05


static func terrain_color(region_id: String, x: float, z: float, h: float) -> Color:
	var slope := absf(height_at(region_id, x + 1.0, z) - h) + absf(height_at(region_id, x, z + 1.0) - h)
	match region_id:
		"bellhollow":
			if absf(x) < 5.0 and z > 4.0:
				return Color("#c49a5c")
			if slope > 0.65:
				return Palette.STONE_B
			if h > 4.8:
				return Color("#c8b99a")
			if h > 2.0:
				return Color("#8d8a56")
			return Color("#78824c")
		"reedwater":
			if h < -0.9:
				return Palette.MUD.darkened(0.15)
			if h < -0.45:
				return Palette.MUD
			if slope > 0.7:
				return Palette.STONE_B
			return Color("#78824c").lerp(Palette.REED_GOLD, 0.22)
		"kestrel_shelf":
			if slope > 0.8:
				return Palette.STONE_B
			return Palette.STONE_A.darkened(0.08)
		"glasswood":
			return Color("#8e9191").lerp(Color("#b8b2a0"), 0.35)
		_:
			return Palette.STONE_DARK


static func build(region_id: String) -> Dictionary:
	var steps := int(SIZE / STEP)
	var b := MeshBuilder.new()
	var half := SIZE * 0.5
	for iz in steps:
		for ix in steps:
			var x0 := -half + ix * STEP
			var z0 := -half + iz * STEP
			var x1 := x0 + STEP
			var z1 := z0 + STEP
			var h00 := height_at(region_id, x0, z0)
			var h10 := height_at(region_id, x1, z0)
			var h01 := height_at(region_id, x0, z1)
			var h11 := height_at(region_id, x1, z1)
			var a := Vector3(x0, h00, z0)
			var bb := Vector3(x1, h10, z0)
			var c := Vector3(x1, h11, z1)
			var d := Vector3(x0, h01, z1)
			var col := terrain_color(region_id, x0 + STEP * 0.5, z0 + STEP * 0.5, (h00 + h11) * 0.5)
			# Add a little facet variation so the ground reads as carved, not smooth.
			var v := sin(x0 * 0.37 + z0 * 0.23) * 0.018
			b.add_quad(a, d, c, bb, col.lightened(v))
	var mesh := b.commit(MeshFactory.world_material())
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	var cs := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape()
	# The heightfield is a thin surface, not a closed solid. Two-sided collision
	# prevents a body from falling through a back-facing triangle at a seam.
	shape.backface_collision = true
	cs.shape = shape
	body.add_child(cs)
	return {"mesh": mesh, "body": body, "size": SIZE}
