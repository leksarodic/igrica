class_name MeshFactory
extends RefCounted
## Reusable silhouettes. Characters are tall, narrow, and wide-hatted; creatures
## are readable as black shapes at distance; architecture is built from bell
## curves, wedges, and thin verticals.

static var _world_mat: StandardMaterial3D
static var _unshaded_mat: StandardMaterial3D
static var _emissive_cache: Dictionary = {}


static func world_material() -> StandardMaterial3D:
	if _world_mat == null:
		_world_mat = StandardMaterial3D.new()
		_world_mat.vertex_color_use_as_albedo = true
		_world_mat.roughness = 0.93
		_world_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_world_mat.metallic = 0.02
	return _world_mat


static func unshaded_material() -> StandardMaterial3D:
	if _unshaded_mat == null:
		_unshaded_mat = StandardMaterial3D.new()
		_unshaded_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_unshaded_mat.vertex_color_use_as_albedo = true
		_unshaded_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _unshaded_mat


static func emissive_material(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var key := "%s_%.2f" % [color.to_html(), energy]
	if _emissive_cache.has(key):
		return _emissive_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_emissive_cache[key] = m
	return m


static func flat_material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


static func add_mesh(parent: Node3D, mesh: Mesh, position: Vector3 = Vector3.ZERO, rotation_y: float = 0.0, name: String = "Mesh") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = position
	mi.rotation.y = rotation_y
	parent.add_child(mi)
	return mi


static func static_box(parent: Node3D, size: Vector3, position: Vector3, color: Color, rotation_y: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	body.rotation.y = rotation_y
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var b := MeshBuilder.new()
	b.add_box(size, color, Vector3.ZERO)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(world_material())
	body.add_child(mi)
	parent.add_child(body)
	return body


# --- Characters -----------------------------------------------------------

static func character_mesh(kind: String, palette_index: int = 0) -> ArrayMesh:
	var b := MeshBuilder.new()
	var skin: Color = [Color("#c99d7b"), Color("#8d5d43"), Color("#e0b894"), Color("#6f4632"), Color("#b98462"), Color("#d8b08a")][palette_index % 6]
	var cloak: Color = Palette.SLATE
	var accent: Color = Palette.COPPER
	var height := 1.0
	var width := 1.0
	match kind:
		"wren":
			cloak = Color("#41525a")
			accent = Palette.REED_GOLD
			height = 1.03
			width = 0.92
		"sable":
			cloak = Color("#39464d")
			accent = Palette.COPPER
			height = 1.12
			width = 0.95
		"nissa":
			cloak = Color("#4c8578")
			accent = Color("#d8b25c")
			height = 0.94
			width = 0.9
		"brannoc":
			cloak = Color("#6b5439")
			accent = Color("#a9764a")
			height = 1.04
			width = 1.3
		"pell":
			cloak = Color("#8a7a63")
			accent = Color("#e6dfce")
			height = 0.9
			width = 1.0
		"maud":
			cloak = Color("#7a6247")
			accent = Color("#c9613c")
			height = 1.0
			width = 1.12
		"tender":
			cloak = Color("#4b5a60")
			accent = Palette.COPPER
		_:
			cloak = Color("#41525a")
			accent = Palette.MINT
	# legs
	b.add_cylinder(0.085 * width, 0.62 * height, 6, Palette.WOOD_DARK, Vector3(-0.13 * width, 0.31 * height, 0))
	b.add_cylinder(0.085 * width, 0.62 * height, 6, Palette.WOOD_DARK, Vector3(0.13 * width, 0.31 * height, 0))
	# body / cloak
	b.add_cylinder(0.30 * width, 0.85 * height, 8, cloak, Vector3(0, 0.95 * height, 0), 0.22 * width)
	b.add_cone(0.52 * width, 1.05 * height, 8, cloak.darkened(0.08), Vector3(0, 0.58 * height, 0))
	# belt
	b.add_cylinder(0.26 * width, 0.07, 8, accent, Vector3(0, 0.86 * height, 0))
	# arms
	b.add_cylinder(0.07 * width, 0.62 * height, 5, cloak.darkened(0.12), Vector3(-0.36 * width, 1.05 * height, 0))
	b.add_cylinder(0.07 * width, 0.62 * height, 5, cloak.darkened(0.12), Vector3(0.36 * width, 1.05 * height, 0))
	# hands
	b.add_sphere(0.075 * width, 5, 3, skin, Vector3(-0.36 * width, 0.73 * height, 0))
	b.add_sphere(0.075 * width, 5, 3, skin, Vector3(0.36 * width, 0.73 * height, 0))
	# head
	b.add_sphere(0.20 * width, 8, 5, skin, Vector3(0, 1.55 * height, 0))
	# hat / hood
	if kind == "pell":
		b.add_cylinder(0.26 * width, 0.14, 8, cloak.lightened(0.1), Vector3(0, 1.72 * height, 0))
	elif kind == "nissa":
		b.add_cylinder(0.42 * width, 0.055, 10, Color("#c9a45c"), Vector3(0, 1.72 * height, 0))
		b.add_cylinder(0.2 * width, 0.18, 8, Color("#4c8578"), Vector3(0, 1.65 * height, 0), 0.14)
	else:
		b.add_cylinder(0.5 * width, 0.06, 10, cloak.darkened(0.18), Vector3(0, 1.72 * height, 0))
		b.add_cylinder(0.2 * width, 0.22, 8, cloak, Vector3(0, 1.66 * height, 0), 0.15)
	# copper ear cuff
	b.add_cylinder(0.06, 0.03, 6, accent, Vector3(0.18 * width, 1.58 * height, 0.02))
	if kind == "sable":
		b.add_cylinder(0.13, 0.02, 8, Palette.COPPER, Vector3(-0.19 * width, 1.58 * height, 0))
	return b.commit(world_material())


static func enemy_mesh(kind: String) -> ArrayMesh:
	var b := MeshBuilder.new()
	match kind:
		"reed_crawler":
			b.add_cylinder(0.34, 0.3, 7, Color("#5d6b46"), Vector3(0, 0.32, 0), 0.22)
			b.add_sphere(0.22, 7, 4, Color("#6f7a4c"), Vector3(0, 0.42, 0.55))
			for s in [-1, 1]:
				for i in 3:
					b.add_cylinder(0.035, 0.45, 4, Color("#3f4a33"), Vector3(s * 0.3, 0.2, -0.3 + i * 0.32))
			b.add_cylinder(0.02, 0.35, 4, Palette.REED_GOLD, Vector3(0, 0.62, 0.62))
			b.add_sphere(0.06, 5, 3, Palette.MINT, Vector3(0, 0.68, 0.64))
		"bramble_ram":
			b.add_box(Vector3(0.8, 0.65, 1.25), Color("#6b5c42"), Vector3(0, 0.75, 0))
			b.add_sphere(0.32, 7, 4, Color("#7a6a4c"), Vector3(0, 0.9, 0.72))
			for s in [-1, 1]:
				b.add_cone(0.09, 0.65, 5, Palette.REED_GOLD, Vector3(s * 0.28, 1.08, 0.72))
				b.add_cylinder(0.07, 0.5, 5, Color("#4a3a29"), Vector3(s * 0.28, 0.3, 0.4))
				b.add_cylinder(0.07, 0.5, 5, Color("#4a3a29"), Vector3(s * 0.28, 0.3, -0.4))
			b.add_box(Vector3(0.5, 0.35, 0.2), Color("#4c8578"), Vector3(0, 1.2, -0.2))
		"choir_moth":
			b.add_sphere(0.14, 6, 4, Color("#d8d2c0"), Vector3(0, 1.1, 0))
			for s in [-1, 1]:
				b.add_triangle(Vector3(0, 1.1, 0), Vector3(s * 0.75, 1.55, -0.1), Vector3(s * 0.5, 0.95, 0.25), Color("#c9c2af"))
				b.add_triangle(Vector3(0, 1.1, 0), Vector3(s * 0.7, 1.1, 0.35), Vector3(s * 0.45, 0.8, 0.1), Color("#b8b2a0"))
			b.add_cylinder(0.012, 0.3, 4, Palette.PLUM, Vector3(0, 1.3, 0))
			b.add_sphere(0.035, 4, 3, Palette.MINT, Vector3(0, 1.45, 0))
		"stone_sentinel":
			b.add_box(Vector3(0.9, 1.5, 0.55), Color("#a9a696"), Vector3(0, 1.05, 0))
			b.add_box(Vector3(0.55, 0.45, 0.45), Color("#b7b5a6"), Vector3(0, 1.95, 0))
			b.add_box(Vector3(0.2, 0.08, 0.08), Palette.REED_GOLD, Vector3(0, 1.98, 0.24))
			b.add_box(Vector3(0.14, 1.1, 0.14), Color("#8f8c7c"), Vector3(-0.58, 1.0, 0))
			b.add_box(Vector3(0.14, 1.1, 0.14), Color("#8f8c7c"), Vector3(0.58, 1.0, 0))
			b.add_box(Vector3(0.7, 0.9, 0.08), Color("#8f8c7c"), Vector3(0, 1.0, 0.38))
			for i in 3:
				b.add_box(Vector3(0.12, 0.35, 0.12), Color("#7c796b"), Vector3(-0.3 + i * 0.3, 0.18, 0))
		"returning_wisp":
			for i in 5:
				var a := TAU * i / 5.0
				b.add_sphere(0.12, 5, 3, Color("#9fd8b9"), Vector3(cos(a) * 0.25, 1.1 + sin(a) * 0.18, sin(a) * 0.1))
			b.add_sphere(0.2, 6, 4, Color("#d8d2c0"), Vector3(0, 1.1, 0))
		"hollow_stag":
			b.add_box(Vector3(1.05, 1.0, 1.8), Color("#8a8578"), Vector3(0, 1.75, 0))
			b.add_cylinder(0.32, 1.2, 6, Color("#9a9587"), Vector3(0, 2.3, 0.9))
			b.add_sphere(0.28, 7, 4, Color("#b0aa9a"), Vector3(0, 2.35, 1.35))
			for s in [-1, 1]:
				for i in 3:
					b.add_cylinder(0.09, 1.3, 5, Color("#57544c"), Vector3(s * 0.45, 0.65, -0.55 + i * 0.55))
				b.add_cone(0.08, 0.9, 5, Color("#c9c2af"), Vector3(s * 0.35, 2.75, 1.2))
				b.add_cone(0.06, 0.65, 5, Color("#c9c2af"), Vector3(s * 0.5, 2.95, 1.05))
				b.add_cone(0.05, 0.5, 5, Color("#c9c2af"), Vector3(s * 0.62, 3.05, 1.18))
			b.add_box(Vector3(0.8, 0.5, 0.6), Color("#6f6a5e"), Vector3(0, 1.45, -0.9))
	return b.commit(world_material())


# --- Props ----------------------------------------------------------------

static func house(width: float, depth: float, height: float, wall: Color, roof: Color) -> ArrayMesh:
	var b := MeshBuilder.new()
	# Stone footing, plaster body, timber frame, overhanging roof.
	b.add_box(Vector3(width + 0.15, 0.45, depth + 0.15), Palette.STONE_B.darkened(0.12), Vector3(0, 0.22, 0))
	b.add_box(Vector3(width, height, depth), wall, Vector3(0, height * 0.5, 0))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			b.add_box(Vector3(0.14, height, 0.14), Palette.WOOD_DARK, Vector3(sx * width * 0.5, height * 0.5, sz * depth * 0.5))
	for y in [height * 0.32, height * 0.68]:
		b.add_box(Vector3(width + 0.04, 0.10, 0.10), Palette.WOOD_DARK, Vector3(0, y, depth * 0.5))
		b.add_box(Vector3(width + 0.04, 0.10, 0.10), Palette.WOOD_DARK, Vector3(0, y, -depth * 0.5))
	b.add_prism(Vector3(depth + 0.8, 1.3, width + 0.8), roof, Vector3(0, height + 0.7, 0))
	b.add_box(Vector3(width + 0.8, 0.12, depth + 0.8), roof.darkened(0.15), Vector3(0, height + 0.04, 0))
	b.add_box(Vector3(0.55, 1.0, 0.10), Palette.WOOD_DARK, Vector3(0, 0.5, depth * 0.5 + 0.03))
	b.add_box(Vector3(0.68, 0.12, 0.14), Palette.COPPER, Vector3(0, 1.02, depth * 0.5 + 0.04))
	for wx in [-width * 0.30, width * 0.30]:
		b.add_box(Vector3(0.40, 0.42, 0.06), Palette.INK, Vector3(wx, height * 0.62, depth * 0.5 + 0.03))
		b.add_box(Vector3(0.30, 0.32, 0.02), Palette.REED_GOLD, Vector3(wx, height * 0.62, depth * 0.5 + 0.06))
	b.add_box(Vector3(0.14, 0.7, 0.14), Color("#6d6b62"), Vector3(width * 0.28, height + 1.15, depth * 0.18))
	b.add_box(Vector3(0.24, 0.12, 0.24), Palette.STONE_DARK, Vector3(width * 0.28, height + 1.5, depth * 0.18))
	return b.commit(world_material())


static func tower_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add_cylinder(4.2, 13.0, 16, Palette.STONE_A, Vector3(0, 6.5, 0), 2.7)
	for i in 8:
		var a := TAU * i / 8.0
		b.add_box(Vector3(0.32, 12.4, 0.32), Palette.STONE_B, Vector3(cos(a) * 3.75, 6.4, sin(a) * 3.75))
	for y in [3.2, 7.8, 11.8]:
		b.add_ring(4.05 - (y - 3.2) * 0.04, 0.22, 16, Palette.COPPER.darkened(0.1), Vector3(0, y, 0))
	b.add_ring(4.35, 0.7, 16, Palette.STONE_B, Vector3(0, 13.1, 0))
	b.add_cone(3.3, 2.2, 16, Palette.ROOF_DARK, Vector3(0, 14.3, 0))
	# The crack and a bell-mouth doorway.
	b.add_box(Vector3(0.5, 9.0, 0.28), Palette.INK, Vector3(1.95, 6.2, 2.95))
	b.add_box(Vector3(1.5, 2.6, 0.3), Palette.INK, Vector3(0, 1.3, 3.7))
	b.add_box(Vector3(1.9, 0.25, 0.4), Palette.STONE_B, Vector3(0, 2.7, 3.7))
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		b.add_box(Vector3(0.3, 1.1, 0.3), Palette.WOOD, Vector3(cos(a) * 4.6, 13.6, sin(a) * 4.6))
	return b.commit(world_material())


static func lantern_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add_cylinder(0.07, 2.2, 5, Palette.WOOD_DARK, Vector3(0, 1.1, 0))
	b.add_box(Vector3(0.35, 0.04, 0.35), Palette.COPPER, Vector3(0, 2.18, 0))
	b.add_box(Vector3(0.28, 0.38, 0.28), Color("#ffd9a0"), Vector3(0, 2.0, 0))
	b.add_cone(0.24, 0.28, 4, Palette.COPPER, Vector3(0, 2.32, 0))
	return b.commit(world_material())


static func tree_mesh(seed: int, kind: String = "pine") -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var b := MeshBuilder.new()
	var h := rng.randf_range(2.4, 4.8)
	if kind == "petrified":
		b.add_cylinder(0.16, h, 5, Color("#8e9191"), Vector3(0, h * 0.5, 0), 0.09)
		for i in 3:
			var a := rng.randf_range(0, TAU)
			b.add_cylinder(0.05, h * 0.55, 4, Color("#b8b2a0"), Vector3(cos(a) * 0.25, h * 0.7, sin(a) * 0.25))
		b.add_cone(0.5, 0.9, 5, Color("#c9c2af"), Vector3(0, h * 0.9, 0))
	else:
		b.add_cylinder(0.14, h, 6, Palette.WOOD_DARK, Vector3(0, h * 0.5, 0), 0.09)
		for i in 3:
			var y := h * (0.55 + i * 0.14)
			var r := 1.1 - i * 0.22
			b.add_cone(r, 1.0, 7, Palette.VERDIGRIS.darkened(0.1 + i * 0.05), Vector3(0, y, 0))
	return b.commit(world_material())


static func reed_cluster_mesh(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var b := MeshBuilder.new()
	for i in 7:
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(0.0, 0.45)
		var h := rng.randf_range(0.7, 1.8)
		b.add_cylinder(0.018, h, 3, Palette.GRASS_A.lerp(Palette.REED_GOLD, rng.randf()), Vector3(cos(a) * r, h * 0.5, sin(a) * r))
		b.add_box(Vector3(0.08, 0.16, 0.02), Palette.REED_GOLD.darkened(0.15), Vector3(cos(a) * r, h + 0.06, sin(a) * r))
	return b.commit(world_material())


static func rock_mesh(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var b := MeshBuilder.new()
	var size := Vector3(rng.randf_range(0.6, 1.8), rng.randf_range(0.3, 0.9), rng.randf_range(0.6, 1.6))
	b.add_box(size, Palette.STONE_B.darkened(rng.randf_range(0.0, 0.15)), Vector3(0, size.y * 0.4, 0))
	b.add_box(size * 0.6, Palette.STONE_A, Vector3(size.x * 0.2, size.y * 0.7, 0))
	return b.commit(world_material())


static func boardwalk_mesh(length: float, width: float = 2.2) -> ArrayMesh:
	var b := MeshBuilder.new()
	var planks := int(length / 0.55)
	for i in planks:
		var z := -length * 0.5 + i * 0.55
		b.add_box(Vector3(width, 0.1, 0.48), Palette.WOOD if i % 2 == 0 else Palette.WOOD.darkened(0.08), Vector3(0, 0.1, z))
	for s in [-1, 1]:
		b.add_cylinder(0.08, 1.2, 4, Palette.WOOD_DARK, Vector3(s * width * 0.42, 0.5, -length * 0.4))
		b.add_cylinder(0.08, 1.2, 4, Palette.WOOD_DARK, Vector3(s * width * 0.42, 0.5, length * 0.4))
	return b.commit(world_material())


static func boat_mesh() -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add_box(Vector3(1.4, 0.5, 4.2), Color("#4c8578"), Vector3(0, 0.25, 0))
	b.add_prism(Vector3(4.2, 0.45, 1.4), Color("#3a6b60"), Vector3(0, 0.45, 0))
	b.add_box(Vector3(0.18, 1.1, 0.18), Palette.WOOD_DARK, Vector3(0, 1.0, 1.6))
	b.add_box(Vector3(0.9, 0.06, 0.06), Palette.REED_GOLD, Vector3(0, 1.5, 1.6))
	return b.commit(world_material())


static func bell_mesh(scale: float = 1.0, color: Color = Palette.COPPER) -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add_cylinder(0.9 * scale, 1.6 * scale, 12, color, Vector3(0, 1.7 * scale, 0), 0.55 * scale)
	b.add_ring(0.92 * scale, 0.12 * scale, 12, color.darkened(0.2), Vector3(0, 0.92 * scale, 0))
	b.add_cylinder(0.18 * scale, 0.35 * scale, 8, color.darkened(0.25), Vector3(0, 2.65 * scale, 0))
	b.add_sphere(0.12 * scale, 6, 3, color.darkened(0.3), Vector3(0, 0.95 * scale, 0))
	return b.commit(world_material())


static func chime_column_mesh(height: float = 4.0) -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add_cylinder(0.32, height, 6, Palette.STONE_A, Vector3(0, height * 0.5, 0), 0.28)
	b.add_ring(0.4, 0.1, 6, Palette.COPPER, Vector3(0, height * 0.82, 0))
	b.add_box(Vector3(0.5, 0.35, 0.5), Palette.STONE_B, Vector3(0, height + 0.15, 0))
	return b.commit(world_material())


static func jar_shelf_mesh(width: float, height: float) -> ArrayMesh:
	var b := MeshBuilder.new()
	b.add_box(Vector3(width, 0.12, 0.55), Palette.STONE_B, Vector3(0, 0, 0))
	for i in int(width / 0.35):
		var x := -width * 0.5 + 0.2 + i * 0.35
		b.add_cylinder(0.09, 0.28, 6, Palette.STONE_A, Vector3(x, 0.22, 0))
		b.add_cylinder(0.06, 0.06, 6, Palette.COPPER, Vector3(x, 0.38, 0))
	b.add_box(Vector3(width, 0.1, 0.55), Palette.STONE_B, Vector3(0, height * 0.5, 0))
	return b.commit(world_material())


static func crystal_mesh(seed: int, color: Color = Palette.MINT) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var b := MeshBuilder.new()
	for i in 3:
		var a := rng.randf_range(0, TAU)
		var h := rng.randf_range(0.8, 2.4)
		b.add_cone(0.18, h, 5, color, Vector3(cos(a) * 0.3, h * 0.5, sin(a) * 0.3))
	return b.commit(world_material())
