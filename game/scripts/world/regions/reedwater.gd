class_name ReedwaterRegion
extends RegionBase
## The first open region: water, reeds, a choked channel, and a shrine that
## keeps its own counsel.

func build() -> void:
	add_environment()
	add_terrain()
	add_water(TerrainBuilder.water_level("reedwater"))
	add_spawn("default", ground(-42, 14), PI)
	add_spawn("dock", ground(-42, 14), PI)
	add_spawn("north_channel", ground(0, 14), PI)
	add_spawn("choir_entrance", ground(4, -18), PI)
	add_spawn("reed_camp", ground(-34, 4), 0.2)

	_build_dock()
	_build_channels()
	_build_choke()
	_build_chime_gate()
	_build_shrine()
	_build_props()
	_build_enemies()
	_build_lanterns()
	_build_people()
	_build_optional()
	add_motes(Color("#9fd8b9"), 55)
	add_grass_field(5510, 90, 44.0, Palette.GRASS_A)


func _build_dock() -> void:
	var pos := ground(-42, 14)
	add_boardwalk(pos, 14.0, 0.0)
	add_prop(MeshFactory.boat_mesh(), Vector3(-44.0, -0.55, 6.0), 0.6)
	add_prop(MeshFactory.boat_mesh(), Vector3(-39.0, -0.65, 7.5), -0.3)
	var come_back := add_interactable("Ferry back to Bellhollow", pos + Vector3(0, 0.3, -2.0), func(_p, _n):
		var d := get_tree().get_first_node_in_group("world_director")
		if d != null:
			d.go_to("bellhollow", "ferry_dock")
	)
	come_back.name = "FerryBack"
	add_sign(pos + Vector3(3.0, 0.0, 2.5), "REEDWATER — mind the current. The reed is not a fence; it is a neighbour.")
	var repair_prompt := "Repair the north dock"
	if Game.state != null and bool(Game.state.world.get("ferry_repaired", false)):
		repair_prompt = "The dock is sound"
	var repair := add_interactable(repair_prompt, pos + Vector3(2.2, 0.2, -4.0), _repair_dock)
	repair.name = "DockRepair"
	for i in 8:
		add_reed(Vector3(-48.0 + i * 1.8, ground(-48.0 + i * 1.8, 5.0).y + 0.3, 5.0 + sin(i) * 1.2), 4100 + i)


func _repair_dock(_player: Node, node: Node) -> void:
	if Game.state == null:
		return
	if bool(Game.state.world.get("ferry_repaired", false)):
		Events.notification.emit("The dock will hold through the winter crossing.")
		return
	if not (Game.state.has_item("hum_reed", 4) and Game.state.has_item("resin", 2)):
		Events.notification.emit("Four hum-reed and two pots of resin. Nissa was specific.")
		return
	Game.state.remove_item("hum_reed", 4)
	Game.state.remove_item("resin", 2)
	Game.state.set_world("ferry_repaired", true)
	Game.state.set_quest("side_ferry", 3, "done")
	Game.state.add_trust("nissa", 1)
	var b := MeshBuilder.new()
	b.add_box(Vector3(4.0, 0.15, 3.0), Palette.WOOD, Vector3(0, 0.08, 0))
	for s in [-1, 1]:
		b.add_box(Vector3(0.12, 2.0, 0.12), Palette.WOOD_DARK, Vector3(s * 1.8, 1.0, -1.2))
	b.add_prism(Vector3(4.4, 0.8, 3.2), Palette.ROOF, Vector3(0, 2.0, -1.2))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = node.global_position
	add_child(mi)
	AudioDirector.play_sfx("build", node.global_position, -2.0)
	Events.notification.emit("The dock is rebuilt. The Reedfolk will remember.")


func _build_channels() -> void:
	# Boardwalks across the main channel and toward the shrine.
	add_boardwalk(ground(-8, 20), 8.0, PI * 0.5)
	add_boardwalk(ground(12, 2), 10.0, 0.0)
	add_boardwalk(ground(-12, -6), 7.0, PI * 0.5)
	for i in 8:
		var x := -36.0 + i * 9.0
		var z := -2.0 + sin(i * 1.7) * 4.0
		add_rock(ground(x, z), 400 + i)
	for i in 10:
		var x := -44.0 + i * 10.0
		var z := 22.0 + sin(i * 2.3) * 6.0
		add_reed(ground(x, z), 600 + i)


func _build_choke() -> void:
	var pos := ground(0, 14)
	# A physical wall of drowned reed. It is removed when the fork clears it.
	var barrier := Node3D.new()
	barrier.name = "ChokeBarrier"
	barrier.position = pos
	add_child(barrier)
	var b := MeshBuilder.new()
	for i in 12:
		var x := -3.2 + (i % 6) * 1.1
		var y := 0.3 + (i / 6) * 1.2
		b.add_cylinder(0.09, 1.8, 4, Palette.MUD.darkened(0.1), Vector3(x, y, 0))
		b.add_box(Vector3(1.0, 0.5, 0.4), Palette.GRASS_A.darkened(0.2), Vector3(x, y + 0.5, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	barrier.add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.5, 3.0, 1.2)
	cs.shape = shape
	cs.position.y = 1.5
	body.add_child(cs)
	barrier.add_child(body)

	var stone := add_interactable("Read the Cantor survey stone", ground(-2.4, 12.5), _read_stone)
	stone.name = "SurveyStone"
	var b2 := MeshBuilder.new()
	b2.add_box(Vector3(1.8, 1.4, 0.4), Palette.STONE_A, Vector3(0, 0.7, 0))
	b2.add_box(Vector3(0.8, 0.08, 0.1), Palette.REED_GOLD, Vector3(0, 1.0, 0.22))
	stone.add_child(_mesh_from(b2))

	var clear := add_interactable("Clear the choke with the resonance fork", pos + Vector3(0, 0.4, 0.5), func(_p, node): _clear_choke(barrier, node))
	clear.name = "Choke"
	if Game.state != null and Game.state.puzzle_solved("reed_choke"):
		barrier.queue_free()


func _read_stone(_player: Node, node: Node) -> void:
	Game.state.add_lore("cantor_survey")
	Game.state.add_echo("echo_channel_chord")
	AudioDirector.play_sfx("listen", node.global_position, -4.0)
	Events.notification.emit("THREE NOTES: low, mid, high. The third is flattened. The carving says: A CHORD, NOT A NOTE.")


func _clear_choke(barrier: Node3D, node: Node) -> void:
	if Game.state == null:
		return
	if not Game.state.has_item("resonance_fork"):
		Events.notification.emit("The reeds are packed too tight. Brannoc's fork would find the note in them.")
		return
	Game.state.mark_puzzle("reed_choke", true)
	Game.state.set_quest("main_02", 3)
	AudioDirector.play_sfx("puzzle_good", node.global_position, -2.0)
	Events.notification.emit("The fork finds the note. The choke lets go.")
	var tween := create_tween()
	tween.tween_property(barrier, "scale", Vector3(1.4, 0.01, 1.4), 0.6)
	tween.tween_callback(barrier.queue_free)


func _build_chime_gate() -> void:
	# The gate sits on the approach to the shrine. Its barrier is separate.
	var pos := ground(4, -8)
	var barrier := Node3D.new()
	barrier.name = "ChimeBarrier"
	barrier.position = pos + Vector3(0, 1.5, -2.8)
	add_child(barrier)
	var b := MeshBuilder.new()
	b.add_box(Vector3(9.0, 3.0, 0.6), Palette.GRASS_A.darkened(0.25), Vector3(0, 0, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	barrier.add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(9.0, 3.0, 0.6)
	cs.shape = shape
	body.add_child(cs)
	barrier.add_child(body)
	var gate := ChimeGate.new()
	gate.build(self, pos, barrier)
	gate.name = "ChimeGate"
	add_sign(pos + Vector3(0, 0, -4.2), "THE GATE OF THE THREE NOTES — ring what the carving shows. Two voicings are honest.", 0.0)


func _build_shrine() -> void:
	var pos := ground(4, -18)
	var b := MeshBuilder.new()
	b.add_cylinder(3.6, 2.2, 12, Palette.STONE_A, Vector3(0, 1.1, 0), 3.0)
	b.add_ring(3.7, 0.5, 12, Palette.STONE_B, Vector3(0, 2.3, 0))
	b.add_box(Vector3(2.2, 2.6, 0.4), Palette.INK, Vector3(0, 1.3, 3.0))
	b.add_box(Vector3(1.1, 0.9, 0.2), Palette.GRASS_A.darkened(0.2), Vector3(0, 2.8, 3.1))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = pos
	add_child(mi)
	add_cylinder_collision(pos, 3.6, 2.4)
	var entrance := add_interactable("Descend into the Sunken Choir", pos + Vector3(0, 0.4, 3.4), func(_p, _n):
		if Game.state != null and Game.state.quest_stage("main_02") < 4:
			Events.notification.emit("The gate is holding the path shut. Read the three stones first.")
			return
		var d := get_tree().get_first_node_in_group("world_director")
		if d != null:
			d.go_to("sunken_choir", "entrance")
	)
	entrance.name = "ChoirEntrance"


func _build_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1123
	for i in 60:
		var x := rng.randf_range(-48, 48)
		var z := rng.randf_range(-44, 45)
		if absf(x) < 8 and z > -24:
			continue
		add_reed(ground(x, z), 1200 + i)
	for i in 16:
		var x := rng.randf_range(-52, 52)
		var z := rng.randf_range(-50, 46)
		add_tree(ground(x, z), 1400 + i, "pine" if i % 3 else "petrified")
	for i in 8:
		var x := rng.randf_range(-44, 44)
		var z := rng.randf_range(-40, 40)
		add_rock(ground(x, z), 1600 + i)


func _build_enemies() -> void:
	add_enemy("reed_crawler", ground(-14, 26), 1)
	add_enemy("reed_crawler", ground(14, 18), 1)
	add_enemy("reed_crawler", ground(-6, -2), 1)
	add_enemy("bramble_ram", ground(18, 28), 1)
	add_enemy("bramble_ram", ground(-20, 4), 1)
	add_enemy("choir_moth", ground(10, -4), 1)
	if Game.state != null and Game.state.puzzle_solved("reed_choke"):
		pass


func _build_lanterns() -> void:
	add_lantern("reedwater_dock", ground(-40, 16), true)
	add_lantern("reedwater_choke", ground(-4, 18))
	add_lantern("reedwater_gate", ground(8, -6))


func _build_people() -> void:
	add_npc("Orrin", "", "reedfolk", ground(-38, 16), 0.6)
	add_npc("Hask", "", "reedfolk", ground(-30, 8), 1.0)
	if Game.state == null or not bool(Game.state.companion("nissa").get("active", false)):
		add_npc("Nissa", "nissa_ferry", "nissa", ground(-40.5, 11.5), 0.2)


func _build_optional() -> void:
	# A climbable shelf and cave mouth; the cave is a generated side area.
	var pos := ground(36, -30)
	add_prop(MeshFactory.rock_mesh(77), pos)
	add_sign(pos + Vector3(0, 0, 2), "KESTREL SHELF — the cave goes down. The Guild says it is empty. The Guild says a lot of things.")
	var entrance := add_interactable("Enter the Undersong side-cave", pos + Vector3(0, 0.5, 0), func(_p, _n):
		var d := get_tree().get_first_node_in_group("world_director")
		if d != null:
			d.go_to("undercave", "entrance")
	)
	entrance.name = "CaveEntrance"
