class_name RegionBase
extends Node3D
## Base for handcrafted regions. Subclasses place the things that matter;
## this class owns shared atmosphere, terrain, props, and spawn bookkeeping.

var director: Node = null
var region_id := ""
var spawn_points: Dictionary = {}
var lanterns: Array[Node3D] = []
var data: Dictionary = {}
var _sun: DirectionalLight3D
var _env: WorldEnvironment


func setup(world_director: Node, id: String) -> void:
	director = world_director
	region_id = id
	data = Game.content.region(id)
	name = "Region_" + id


func build() -> void:
	pass


func add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(String(data.get("sky_top", "#2e3d42")))
	sky_mat.sky_horizon_color = Color(String(data.get("sky_horizon", "#d8b25c")))
	sky_mat.ground_bottom_color = Color("#141b1c")
	sky_mat.ground_horizon_color = Color(String(data.get("fog_color", "#6f8b8d")))
	sky_mat.sky_energy_multiplier = 0.9
	sky_mat.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.15
	env.ambient_light_color = Color("#7c98a0")
	env.fog_enabled = true
	env.fog_light_color = Color(String(data.get("fog_color", "#6f8b8d")))
	env.fog_density = float(data.get("fog_density", 0.012)) * 0.8
	env.fog_sky_affect = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.3
	env.glow_enabled = Settings.quality == "high"
	env.glow_intensity = 0.5
	_env = WorldEnvironment.new()
	_env.environment = env
	add_child(_env)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-22, -42, 0)
	_sun.light_color = Color(String(data.get("sun_color", "#ffd9a0")))
	_sun.light_energy = float(data.get("sun_energy", 1.2)) * 1.15
	_sun.shadow_enabled = Settings.quality != "low"
	_sun.directional_shadow_max_distance = 55.0
	add_child(_sun)

	# A cool fill from the opposite side keeps silhouettes readable without
	# flattening the low sun. No shadows: it is a stage light, not a second sun.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-32, 145, 0)
	fill.light_color = Color("#d0b080")
	fill.light_energy = 0.65
	fill.shadow_enabled = false
	add_child(fill)

	AudioDirector.set_music(String(data.get("music", "surface")))


func add_terrain() -> void:
	var built := TerrainBuilder.build(region_id)
	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = built["mesh"]
	add_child(mi)
	var body: StaticBody3D = built["body"]
	body.collision_layer = 1
	add_child(body)
	add_spawn("default", Vector3(0, TerrainBuilder.height_at(region_id, 0, 38), 38))


func add_motes(color: Color = Color("#ffd9a0"), amount: int = 70) -> void:
	if Settings.quality == "low":
		return
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 12.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 34.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 0.03
	p.initial_velocity_max = 0.18
	p.gravity = Vector3(0, 0.006, 0)
	p.scale_amount_min = 0.35
	p.scale_amount_max = 1.0
	p.color = color
	var sm := SphereMesh.new()
	sm.radius = 0.035
	sm.height = 0.07
	sm.radial_segments = 4
	sm.rings = 2
	p.mesh = sm
	p.material_override = MeshFactory.emissive_material(color, 1.3)
	p.position = Vector3(0, 3.0, 0)
	add_child(p)


func add_grass_field(seed: int, count: int, radius: float, color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var b := MeshBuilder.new()
	for i in count:
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(4.0, radius)
		var x := cos(a) * r
		var z := sin(a) * r
		var y := TerrainBuilder.height_at(region_id, x, z)
		var h := rng.randf_range(0.18, 0.5)
		b.add_cone(0.045, h, 4, color.darkened(rng.randf_range(0.0, 0.15)), Vector3(x, y + h * 0.5, z))
	for i in 18:
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(2.5, 6.0)
		var x := cos(a) * r
		var z := sin(a) * r
		var y := TerrainBuilder.height_at(region_id, x, z)
		var h := rng.randf_range(0.2, 0.6)
		b.add_cone(0.05, h, 4, color.lightened(0.08), Vector3(x, y + h * 0.5, z))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	add_child(mi)


func add_water(level: float, size: float = 120.0) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = 40
	plane.subdivide_depth = 40
	var mi := MeshInstance3D.new()
	mi.name = "Water"
	mi.mesh = plane
	mi.position = Vector3(0, level, 0)
	var shader := load("res://assets/shaders/water.gdshader") as Shader
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mi.material_override = mat
	add_child(mi)


func add_spawn(id: String, position: Vector3, yaw: float = PI) -> void:
	spawn_points[id] = {"position": position, "yaw": yaw}


func spawn_point(id: String) -> Dictionary:
	if spawn_points.has(id):
		return spawn_points[id]
	if spawn_points.has("default"):
		return spawn_points["default"]
	return {"position": Vector3(0, 1, 0), "yaw": PI}


func ground(x: float, z: float) -> Vector3:
	return Vector3(x, TerrainBuilder.height_at(region_id, x, z), z)


func add_prop(mesh: Mesh, position: Vector3, yaw: float = 0.0, parent: Node3D = null) -> MeshInstance3D:
	var host := parent if parent != null else self
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = position
	mi.rotation.y = yaw
	host.add_child(mi)
	return mi


func add_house(position: Vector3, yaw: float = 0.0, width: float = 5.0, depth: float = 4.0, height: float = 3.2) -> void:
	var mi := add_prop(MeshFactory.house(width, depth, height, Palette.OCHRE.lightened(0.06), Palette.ROOF.lightened(0.05)), position, yaw)
	for wx in [-width * 0.28, width * 0.28]:
		var glow := MeshInstance3D.new()
		var gb := MeshBuilder.new()
		gb.add_box(Vector3(0.26, 0.30, 0.04), Palette.REED_GOLD)
		glow.mesh = gb.commit(MeshFactory.emissive_material(Color("#ffb45c"), 1.6))
		glow.position = Vector3(wx, height * 0.62, depth * 0.5 + 0.03)
		mi.add_child(glow)
	var body := StaticBody3D.new()
	body.position = position
	body.rotation.y = yaw
	body.collision_layer = 1 | 4
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height + 1.2, depth)
	cs.shape = shape
	cs.position.y = (height + 1.2) * 0.5
	body.add_child(cs)
	add_child(body)


func add_tree(position: Vector3, seed: int, kind: String = "pine") -> void:
	add_prop(MeshFactory.tree_mesh(seed, kind), position)
	var body := StaticBody3D.new()
	body.position = position
	body.collision_layer = 1 | 4
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.25
	shape.height = 2.0
	cs.shape = shape
	cs.position.y = 1.0
	body.add_child(cs)
	add_child(body)


func add_reed(position: Vector3, seed: int) -> void:
	add_prop(MeshFactory.reed_cluster_mesh(seed), position)


func add_rock(position: Vector3, seed: int) -> void:
	add_prop(MeshFactory.rock_mesh(seed), position)


func add_boardwalk(position: Vector3, length: float, yaw: float = 0.0) -> void:
	var mi := add_prop(MeshFactory.boardwalk_mesh(length), position, yaw)
	var body := StaticBody3D.new()
	body.position = position
	body.rotation.y = yaw
	body.collision_layer = 1 | 4
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.2, 0.2, length)
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


func add_lantern(id: String, position: Vector3, lit: bool = false) -> Lantern:
	var lantern := Lantern.new()
	lantern.position = position
	lantern.lantern_id = id
	lantern.prompt = "Light the lantern"
	add_child(lantern)
	lantern.set_lit(lit)
	lanterns.append(lantern)
	return lantern


func add_npc(name: String, dialogue_id: String, appearance: String, position: Vector3, yaw: float = PI) -> NPC:
	var npc := NPC.new()
	npc.position = position
	npc.configure(name, dialogue_id, appearance, yaw)
	add_child(npc)
	return npc


func add_interactable(prompt: String, position: Vector3, callback: Callable, extra: Dictionary = {}) -> Interactable:
	var it := Interactable.new()
	it.position = position
	it.configure(prompt, callback, extra)
	add_child(it)
	return it


func add_pickup(item_id: String, amount: int, position: Vector3, glow: bool = true) -> Interactable:
	var it := Interactable.new()
	it.position = position
	var b := MeshBuilder.new()
	b.add_box(Vector3(0.32, 0.32, 0.32), Palette.COPPER if item_id.contains("copper") else Palette.REED_GOLD, Vector3(0, 0.35, 0))
	b.add_sphere(0.12, 5, 3, Palette.MINT, Vector3(0, 0.62, 0))
	it.add_child(_mesh_from(b))
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.5, 0)
	light.light_color = Palette.MINT
	light.light_energy = 0.7
	light.omni_range = 2.2
	it.add_child(light)
	it.configure("Take %s" % item_id.replace("_", " "), func(_p, node): _take_pickup(node, item_id, amount))
	add_child(it)
	return it


func _take_pickup(node: Node, item_id: String, amount: int) -> void:
	Game.state.add_item(item_id, amount)
	AudioDirector.play_sfx("pickup", node.global_position, -4.0)
	Events.notification.emit("+%d %s" % [amount, item_id.replace("_", " ").capitalize()])
	node.queue_free()


func _mesh_from(builder: MeshBuilder) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = builder.commit(MeshFactory.world_material())
	return mi


func add_bench(position: Vector3) -> Interactable:
	var b := MeshBuilder.new()
	b.add_box(Vector3(2.4, 0.15, 0.9), Palette.WOOD, Vector3(0, 1.0, 0))
	for s in [-1, 1]:
		b.add_box(Vector3(0.15, 1.0, 0.7), Palette.WOOD_DARK, Vector3(s * 0.9, 0.5, 0))
	b.add_box(Vector3(0.5, 0.2, 0.3), Palette.COPPER, Vector3(0.6, 1.15, 0))
	var it := Interactable.new()
	it.position = position
	it.add_child(_mesh_from(b))
	it.configure("Use the workbench", func(_p, _n): Events.open_screen.emit("craft", {}))
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 1.1, 0.9)
	cs.shape = shape
	cs.position.y = 0.55
	body.add_child(cs)
	it.add_child(body)
	add_child(it)
	return it


func add_sign(position: Vector3, text: String, yaw: float = 0.0) -> Interactable:
	var b := MeshBuilder.new()
	b.add_box(Vector3(0.12, 1.4, 0.12), Palette.WOOD_DARK, Vector3(0, 0.7, 0))
	b.add_box(Vector3(1.1, 0.7, 0.08), Palette.WOOD, Vector3(0, 1.45, 0))
	var it := Interactable.new()
	it.position = position
	it.rotation.y = yaw
	it.add_child(_mesh_from(b))
	it.configure("Read the sign", func(_p, _n): Events.notification.emit(text))
	add_child(it)
	return it


func add_cylinder_collision(position: Vector3, radius: float, height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	body.collision_layer = 1 | 4
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	cs.position.y = height * 0.5
	body.add_child(cs)
	add_child(body)
	return body


func add_enemy(enemy_id: String, position: Vector3, level: int = 1) -> Node3D:
	var enemy := Enemy.new()
	enemy.position = position
	enemy.configure(enemy_id, level)
	add_child(enemy)
	return enemy
