class_name BellhollowRegion
extends RegionBase
## The hub. Warm, tired, lived-in, and small enough to learn by walking.

func build() -> void:
	add_environment()
	add_terrain()
	add_spawn("arrival", ground(0, 36), PI)
	add_spawn("listening_house", ground(-20, 14), PI * 0.5)
	add_spawn("ferry_dock", ground(-29, -8), 0.0)
	add_spawn("foundry", ground(27, 21), PI * 0.8)

	_build_tower()
	_build_path()
	_build_plaza()
	_build_town()
	_build_listening_house()
	_build_foundry()
	_build_dock()
	_build_props()
	_build_people()
	_build_lanterns()
	_build_pickups()
	_build_signs()
	_build_pip_roost()
	add_motes(Color("#ffd9a0"), 70)
	add_grass_field(4401, 140, 34.0, Palette.GRASS_A)
	_build_ambient_sound()


func _build_tower() -> void:
	add_prop(MeshFactory.tower_mesh(), Vector3(0, 0.05, -2))
	add_cylinder_collision(Vector3(0, 0.05, -2), 4.1, 13.0)
	# The cracked lip and a few fallen stones.
	add_prop(MeshFactory.rock_mesh(31), Vector3(4.8, ground(4.8, -2).y, -2))
	add_prop(MeshFactory.rock_mesh(32), Vector3(-4.5, ground(-4.5, -2).y, -1.2))
	var plaque := add_sign(Vector3(0, ground(0, 6).y, 6), "THE HOLLOW BELL — cracked in the year 600. It is not repaired. It is shored.")
	plaque.rotation.y = PI


func _build_town() -> void:
	var houses := [
		[-18.0, 22.0, 0.4], [18.0, 24.0, -0.5], [-27.0, 3.0, 1.2], [25.0, 3.0, -1.3],
		[-14.0, -17.0, 2.2], [16.0, -18.0, -2.4], [8.0, 27.0, 0.1], [-8.0, 27.0, -0.1],
		[33.0, 9.0, -1.5], [-33.0, 13.0, 1.8], [12.0, -8.0, -1.0], [-12.0, 8.0, 1.0],
	]
	for h in houses:
		var x: float = h[0]
		var z: float = h[1]
		var y := ground(x, z).y
		var yaw := atan2(-x, -z)
		add_house(Vector3(x, y, z), yaw, 4.6, 3.8, 3.0)
	# Market stalls around the plaza and along the approach.
	for i in 3:
		var angle := -0.7 + i * 0.7
		var pos := Vector3(cos(angle) * 9.0, ground(cos(angle) * 9.0, sin(angle) * 9.0 + 4.0).y, sin(angle) * 9.0 + 4.0)
		_stall(pos, angle + PI)
	for i in 3:
		var x := -9.5 + i * 9.5
		_stall(Vector3(x, ground(x, 12.0).y, 12.0), 0.0 if i != 1 else PI)
	for i in 4:
		_crate(Vector3(-7.5 + i * 5.0, ground(-7.5 + i * 5.0, 20.0).y, 20.0), 50 + i)
	# A few fences, crates, and banners.
	for i in 6:
		var angle := TAU * i / 6.0
		var x := cos(angle) * 14.5
		var z := sin(angle) * 14.5
		add_prop(MeshFactory.rock_mesh(100 + i), ground(x, z), angle)
	for i in 4:
		var a := -1.1 + i * 0.75
		_banner(Vector3(cos(a) * 12.0, ground(cos(a) * 12.0, sin(a) * 12.0 + 2.0).y, sin(a) * 12.0 + 2.0), Palette.REED_GOLD if i % 2 == 0 else Palette.EMBER)
	for i in 7:
		var a := TAU * i / 7.0
		var x := cos(a) * 11.0
		var z := sin(a) * 11.0 + 4.0
		_crate(Vector3(x, ground(x, z).y, z), i)
	# The Hush edge, west, is a visible grey ribbon beyond the terraces.
	var b := MeshBuilder.new()
	b.add_box(Vector3(70, 0.4, 10), Color("#8e9191"), Vector3(0, 0, 0))
	var hush_mesh := b.commit(MeshFactory.flat_material(Color("#8e9191"), 1.0))
	var hush := MeshInstance3D.new()
	hush.mesh = hush_mesh
	hush.position = Vector3(-72, 2.5, 0)
	add_child(hush)


func _build_path() -> void:
	# A ribbon that follows the heightfield exactly. No z-fighting, no buried steps.
	var b := MeshBuilder.new()
	var z0 := 0.0
	while z0 < 38.0:
		var z1 := z0 + 2.0
		var y0 := ground(0, z0).y + 0.075
		var y1 := ground(0, z1).y + 0.075
		var color := Color("#b89a68") if int(z0) % 4 == 0 else Color("#ad8f60")
		b.add_quad(Vector3(-3.2, y0 + 0.12, z0), Vector3(-3.2, y1 + 0.12, z1), Vector3(3.2, y1 + 0.12, z1), Vector3(3.2, y0 + 0.12, z0), color)
		var side := Color("#a39a88")
		b.add_quad(Vector3(-3.55, y0, z0), Vector3(-3.55, y1, z1), Vector3(-3.15, y1, z1), Vector3(-3.15, y0, z0), side)
		b.add_quad(Vector3(3.15, y0, z0), Vector3(3.15, y1, z1), Vector3(3.55, y1, z1), Vector3(3.55, y0, z0), side)
		z0 = z1
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	add_child(mi)
	for i in 6:
		var zz := 30.0 - i * 6.0
		add_prop(MeshFactory.lantern_mesh(), ground(3.6, zz), 0.0)
	for i in 14:
		var zz := 2.0 + i * 2.4
		add_reed(Vector3(-4.2 + (i % 2) * 8.4, ground(-4.2, zz).y, zz), 3000 + i)

func _build_plaza() -> void:
	var b := MeshBuilder.new()
	b.add_cylinder(9.0, 0.12, 28, Color("#b8a98c"), Vector3(0, 0.02, 0))
	b.add_ring(8.6, 0.35, 28, Color("#8e8271"), Vector3(0, 0.12, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	add_child(mi)
	# A well and two benches make the square a place, not a stage.
	_well(Vector3(7.5, ground(7.5, 4.0).y, 4.0))
	_bench(Vector3(-6.0, ground(-6.0, 6.0).y, 6.0), 1.2)
	_bench(Vector3(6.0, ground(6.0, 10.0).y, 10.0), -1.2)


func _banner(position: Vector3, color: Color) -> void:
	var b := MeshBuilder.new()
	b.add_cylinder(0.06, 3.0, 4, Palette.WOOD_DARK, Vector3(0, 1.5, 0))
	b.add_box(Vector3(1.1, 1.5, 0.04), color, Vector3(0.55, 2.2, 0))
	b.add_box(Vector3(1.1, 0.08, 0.06), Palette.COPPER, Vector3(0.55, 2.98, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = position
	add_child(mi)


func _crate(position: Vector3, seed: int) -> void:
	var b := MeshBuilder.new()
	b.add_box(Vector3(0.8, 0.8, 0.8), Palette.WOOD, Vector3(0, 0.4, 0))
	b.add_box(Vector3(0.84, 0.08, 0.84), Palette.WOOD_DARK, Vector3(0, 0.85, 0))
	if seed % 2 == 0:
		b.add_cylinder(0.35, 0.55, 8, Palette.WOOD_DARK, Vector3(0, 0.28, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = position
	mi.rotation.y = seed * 0.7
	add_child(mi)


func _well(position: Vector3) -> void:
	var b := MeshBuilder.new()
	b.add_cylinder(1.5, 0.9, 12, Color("#a99a82"), Vector3(0, 0.45, 0))
	b.add_cylinder(1.3, 0.2, 12, Palette.INK, Vector3(0, 0.85, 0))
	b.add_box(Vector3(0.18, 2.2, 0.18), Palette.WOOD_DARK, Vector3(-0.9, 1.1, 0))
	b.add_box(Vector3(0.18, 2.2, 0.18), Palette.WOOD_DARK, Vector3(0.9, 1.1, 0))
	b.add_box(Vector3(2.0, 0.15, 0.15), Palette.WOOD, Vector3(0, 2.2, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = position
	add_child(mi)


func _bench(position: Vector3, yaw: float) -> void:
	var b := MeshBuilder.new()
	b.add_box(Vector3(1.6, 0.12, 0.45), Palette.WOOD, Vector3(0, 0.5, 0))
	b.add_box(Vector3(0.12, 0.5, 0.35), Palette.WOOD_DARK, Vector3(-0.6, 0.25, 0))
	b.add_box(Vector3(0.12, 0.5, 0.35), Palette.WOOD_DARK, Vector3(0.6, 0.25, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = position
	mi.rotation.y = yaw
	add_child(mi)


func _stall(position: Vector3, yaw: float) -> void:
	var b := MeshBuilder.new()
	b.add_box(Vector3(2.4, 0.9, 1.4), Palette.WOOD, Vector3(0, 0.45, 0))
	b.add_box(Vector3(2.8, 0.08, 1.8), Palette.ROOF, Vector3(0, 2.0, 0))
	for s in [-1, 1]:
		b.add_box(Vector3(0.08, 2.0, 0.08), Palette.WOOD_DARK, Vector3(s * 1.2, 1.0, s * 0.6))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = position
	mi.rotation.y = yaw
	add_child(mi)
	var body := StaticBody3D.new()
	body.position = position
	body.rotation.y = yaw
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 1.0, 1.4)
	cs.shape = shape
	cs.position.y = 0.5
	body.add_child(cs)
	add_child(body)


func _build_listening_house() -> void:
	var pos := Vector3(-22, ground(-22, 12).y, 12)
	var b := MeshBuilder.new()
	b.add_cylinder(4.2, 4.0, 12, Palette.STONE_A, Vector3(0, 2.0, 0))
	b.add_cone(4.6, 2.0, 12, Palette.ROOF, Vector3(0, 5.0, 0))
	b.add_box(Vector3(1.2, 2.2, 0.3), Palette.WOOD_DARK, Vector3(0, 1.1, 4.1))
	b.add_box(Vector3(0.5, 0.5, 0.16), Palette.REED_GOLD, Vector3(0, 2.8, 4.2))
	for i in 5:
		var a := TAU * i / 5.0
		b.add_box(Vector3(0.18, 1.2, 0.18), Palette.COPPER, Vector3(cos(a) * 3.2, 4.4, sin(a) * 3.2))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = pos
	add_child(mi)
	add_cylinder_collision(pos, 4.0, 4.0)
	add_sign(Vector3(-22, ground(-22, 17).y, 17), "THE LISTENING HOUSE — records, tea, and the occasional argument. Mind the step.")


func _build_foundry() -> void:
	var pos := Vector3(30, ground(30, 22).y, 22)
	var b := MeshBuilder.new()
	b.add_box(Vector3(9.0, 3.4, 7.0), Color("#3b3a36"), Vector3(0, 1.7, 0))
	b.add_prism(Vector3(7.2, 1.4, 9.2), Palette.ROOF_DARK, Vector3(0, 3.4, 0))
	b.add_box(Vector3(1.2, 2.2, 0.2), Palette.WOOD_DARK, Vector3(0, 1.1, 3.55))
	b.add_cylinder(0.55, 3.2, 6, Color("#5b5246"), Vector3(3.0, 4.6, -1.8))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = pos
	add_child(mi)
	add_cylinder_collision(pos, 5.2, 3.4)
	# Outdoor forge glow.
	var light := OmniLight3D.new()
	light.position = pos + Vector3(1.5, 1.2, 4.0)
	light.light_color = Color("#ff8a4a")
	light.light_energy = 1.2
	light.omni_range = 5.0
	add_child(light)
	add_bench(Vector3(27.5, ground(27.5, 19.0).y, 19.0))


func _build_dock() -> void:
	var pos := Vector3(-30, ground(-30, -10).y, -10)
	add_boardwalk(pos, 6.0, PI * 0.5)
	add_prop(MeshFactory.boat_mesh(), pos + Vector3(-4, -1.6, 1.5), 0.5)
	add_prop(MeshFactory.boat_mesh(), pos + Vector3(-6, -1.9, -2.5), -0.4)
	var b := MeshBuilder.new()
	b.add_cylinder(0.22, 1.6, 6, Palette.WOOD_DARK, Vector3(0, 0.8, 0))
	b.add_box(Vector3(1.4, 0.08, 0.08), Palette.WOOD, Vector3(0, 1.6, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = pos + Vector3(0, 0, 0)
	add_child(mi)
	var ferry := add_interactable("Take the ferry down to Reedwater", pos + Vector3(-2, 0.3, 0), _on_ferry)
	ferry.name = "Ferry"
	add_sign(pos + Vector3(2, 0, 2), "NORTH DOCK — Reedwater ferry. The channel is choked; the ferry runs when the water does.")


func _on_ferry(_player: Node, _node: Node) -> void:
	if Game.state == null:
		return
	if Game.state.quest_stage("main_02") < 1:
		Events.notification.emit("Nissa is at the dock. The ferry will not run through a choked channel.")
		return
	var director := get_tree().get_first_node_in_group("world_director")
	if director != null:
		director.go_to("reedwater", "dock")


func _build_people() -> void:
	add_npc("Wren", "wren_arrival", "wren", ground(1.4, 30.5), 0.0)
	add_npc("Sable", "sable_hub", "sable", ground(6.0, 1.0), 0.5)
	add_npc("Pell", "pell_hub", "pell", ground(-19.0, 15.5), 1.2)
	add_npc("Brannoc", "brannoc_foundry", "brannoc", ground(27.0, 17.0), 2.5)
	if Game.state == null or not bool(Game.state.companion("nissa").get("active", false)):
		add_npc("Nissa", "nissa_ferry", "nissa", ground(-28.5, -8.0), 0.2)
	add_npc("Maud", "", "maud", ground(24.0, 8.0), 1.0)
	add_npc("Vess", "", "tender", ground(-6.0, 8.0), 0.6)
	add_npc("Iset", "", "tender", ground(10.0, 12.0), -0.8)


func _build_lanterns() -> void:
	add_lantern("bellhollow_square", Vector3(0, ground(0, 18).y, 18), true)
	add_lantern("bellhollow_listening", Vector3(-20, ground(-20, 10).y, 10), true)
	add_lantern("bellhollow_foundry", Vector3(27, ground(27, 21).y, 21), true)
	add_lantern("bellhollow_ferry", Vector3(-30, ground(-30, -7).y, -7), true)


func _build_pickups() -> void:
	add_pickup("copper_scrap", 2, ground(20.0, 16.0))
	add_pickup("humstone_shard", 1, ground(33.0, 24.0))
	add_pickup("resin", 2, ground(-16.0, 24.0))
	add_pickup("hum_reed", 2, ground(-30.0, -4.0))
	add_pickup("river_stone", 1, ground(-33.0, 16.0))


func _build_signs() -> void:
	add_sign(Vector3(2.5, ground(2.5, 34).y, 34), "BELLHOLLOW — population 300, opinions 900. The valley will wait.", PI)
	add_sign(Vector3(-36, ground(-36, 2).y, 2), "WEST ROAD CLOSED — Hush. Do not answer it.", 1.2)


func _build_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 712
	for i in 36:
		var angle := rng.randf_range(0, TAU)
		var radius := rng.randf_range(16.0, 42.0)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		if absf(x) < 5.0 and z > 0.0:
			continue
		var y := ground(x, z).y
		add_reed(Vector3(x, y, z), 900 + i)
	for i in 18:
		var angle := rng.randf_range(0, TAU)
		var radius := rng.randf_range(36.0, 50.0)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		add_tree(Vector3(x, ground(x, z).y, z), 500 + i)
	for i in 10:
		var angle := rng.randf_range(0, TAU)
		var radius := rng.randf_range(8.0, 34.0)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		add_rock(Vector3(x, ground(x, z).y, z), 300 + i)


func _build_pip_roost() -> void:
	var pos := Vector3(32, ground(32, 28).y, 28)
	var b := MeshBuilder.new()
	b.add_cylinder(1.4, 2.4, 8, Palette.WOOD, Vector3(0, 1.2, 0))
	b.add_cone(1.8, 1.2, 8, Palette.ROOF_DARK, Vector3(0, 3.0, 0))
	for i in 5:
		var a := TAU * i / 5.0
		b.add_box(Vector3(0.22, 0.28, 0.1), Palette.INK, Vector3(cos(a) * 1.25, 1.7, sin(a) * 1.25))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = pos
	add_child(mi)
	add_cylinder_collision(pos, 1.4, 2.4)
	var it := add_interactable("Coax the bell from Pip", pos + Vector3(0, 0.4, 1.4), _pip_bell)
	it.name = "PipRoost"
	add_sign(pos + Vector3(1.8, 0, 1.8), "THE KETTLE-BIRD ROOST — do not leave shiny things. Pip is a professional.")


func _pip_bell(_player: Node, node: Node) -> void:
	if Game.state == null:
		return
	if bool(Game.state.get_flag("pip_bell_done", false)):
		Events.notification.emit("Pip is asleep in her nest, hoarding three spoons and a button.")
		return
	if not Game.state.has_item("hum_reed", 1):
		Events.notification.emit("Pip wants a hum-reed. She is very clear about this.")
		return
	Game.state.remove_item("hum_reed", 1)
	Game.state.add_item("copper_bell", 1)
	Game.state.set_flag("pip_bell_done", true)
	Game.state.set_quest("side_pip", 2)
	AudioDirector.play_sfx("pickup", node.global_position, -3.0)
	Events.notification.emit("Pip trades the bell for a reed. She is not sorry.")


func _build_ambient_sound() -> void:
	AudioDirector.play_ambient("ambience_wind")
