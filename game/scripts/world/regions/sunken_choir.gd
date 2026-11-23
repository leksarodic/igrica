class_name SunkenChoirRegion
extends RegionBase
## A shrine built for listening, flooded by silence. The dungeon's one idea is
## that water, sound, and stone are the same system seen from different angles.

var boss: HollowStagBoss
var _water: MeshInstance3D
var _boss_barrier: Node3D
var _chime_item: Interactable
var _valves: Array[bool] = [false, false, false]
var _valve_nodes: Array[Node3D] = []


func build() -> void:
	add_environment()
	add_spawn("default", Vector3(0, 0.25, 0.5), PI)
	add_spawn("entrance", Vector3(0, 0.25, 0.5), PI)
	add_spawn("nave", Vector3(0, 0.25, -10), PI)
	add_spawn("boss", Vector3(0, 0.25, -38), PI)
	_build_rooms()
	_build_water()
	_build_sluice()
	_build_echo_maze()
	_build_boss_arena()
	_build_exit()
	_build_props()
	_build_enemies()
	_build_lanterns()
	_build_lights()
	_build_lore()


func _room(center: Vector3, w: float, d: float, h: float, doors: Array, color: Color) -> void:
	var floor_pos := center + Vector3(0, -0.25, 0)
	MeshFactory.static_box(self, Vector3(w, 0.5, d), floor_pos, color)
	var ceil := MeshInstance3D.new()
	var cb := MeshBuilder.new()
	cb.add_box(Vector3(w, 0.25, d), color.darkened(0.35), Vector3.ZERO)
	ceil.mesh = cb.commit(MeshFactory.world_material())
	ceil.position = center + Vector3(0, h, 0)
	add_child(ceil)
	var wall_color := color.darkened(0.08)
	for side in ["north", "south", "east", "west"]:
		var has_door: bool = side in doors
		if side in ["north", "south"]:
			var z := center.z + (-d * 0.5 if side == "north" else d * 0.5)
			if has_door:
				var seg := (w - 3.2) * 0.5
				MeshFactory.static_box(self, Vector3(maxf(seg, 0.5), h, 0.5), Vector3(center.x - (3.2 * 0.5 + seg * 0.5), h * 0.5, z), wall_color)
				MeshFactory.static_box(self, Vector3(maxf(seg, 0.5), h, 0.5), Vector3(center.x + (3.2 * 0.5 + seg * 0.5), h * 0.5, z), wall_color)
			else:
				MeshFactory.static_box(self, Vector3(w, h, 0.5), Vector3(center.x, h * 0.5, z), wall_color)
		else:
			var x := center.x + (-w * 0.5 if side == "west" else w * 0.5)
			if has_door:
				var seg := (d - 3.2) * 0.5
				MeshFactory.static_box(self, Vector3(0.5, h, maxf(seg, 0.5)), Vector3(x, h * 0.5, center.z - (3.2 * 0.5 + seg * 0.5)), wall_color)
				MeshFactory.static_box(self, Vector3(0.5, h, maxf(seg, 0.5)), Vector3(x, h * 0.5, center.z + (3.2 * 0.5 + seg * 0.5)), wall_color)
			else:
				MeshFactory.static_box(self, Vector3(0.5, h, d), Vector3(x, h * 0.5, center.z), wall_color)
	# Columns at the corners, Cantor-tall.
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var cp := center + Vector3(sx * (w * 0.5 - 1.2), 0, sz * (d * 0.5 - 1.2))
			var mi := MeshInstance3D.new()
			mi.mesh = MeshFactory.chime_column_mesh(h)
			mi.position = cp
			add_child(mi)


func _build_rooms() -> void:
	_room(Vector3(0, 0, 0), 12, 12, 6.0, ["north"], Palette.STONE_B)
	_room(Vector3(0, 0, -18), 22, 24, 9.0, ["south", "north", "west", "east"], Palette.STONE_B.darkened(0.06))
	_room(Vector3(0, 0, -44), 26, 24, 12.0, ["south", "north"], Palette.STONE_B.darkened(0.12))
	_room(Vector3(0, 0, -59), 12, 8, 6.0, ["south"], Palette.STONE_B)
	# Floor connectors between touching rooms.
	MeshFactory.static_box(self, Vector3(4, 0.5, 2.2), Vector3(0, -0.25, -31), Palette.STONE_B)
	MeshFactory.static_box(self, Vector3(4, 0.5, 1.4), Vector3(0, -0.25, -55.4), Palette.STONE_B)


func _build_water() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 22)
	plane.subdivide_width = 12
	plane.subdivide_depth = 12
	_water = MeshInstance3D.new()
	_water.mesh = plane
	_water.position = Vector3(0, 0.12, -18)
	var shader := load("res://assets/shaders/water.gdshader") as Shader
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		_water.material_override = mat
	add_child(_water)


func _build_sluice() -> void:
	# Three valves on the west wall of the nave.
	for i in 3:
		var pos := Vector3(-9.6, 0.2, -11.0 - i * 3.2)
		var root := Node3D.new()
		root.position = pos
		add_child(root)
		var b := MeshBuilder.new()
		b.add_cylinder(0.32, 0.5, 8, Palette.COPPER, Vector3(0, 0.8, 0), 0.3)
		b.add_box(Vector3(0.9, 0.1, 0.1), Palette.WOOD_DARK, Vector3(0.45, 0.8, 0))
		var mi := MeshInstance3D.new()
		mi.mesh = b.commit(MeshFactory.world_material())
		root.add_child(mi)
		var it := Interactable.new()
		it.position = Vector3(0.2, 0.8, 0)
		it.configure("Turn valve %d" % (i + 1), func(_p, _n): _toggle_valve(i))
		root.add_child(it)
		_valve_nodes.append(root)
	add_sign(Vector3(-9.4, 0.2, -20), "SLUICE — the old chant: open, shut, open. The water remembers the order.", PI * 0.5)
	# Barrier at the north door of the nave.
	_boss_barrier = Node3D.new()
	_boss_barrier.position = Vector3(0, 1.6, -30.0)
	add_child(_boss_barrier)
	var bb := MeshBuilder.new()
	bb.add_box(Vector3(7.0, 3.2, 0.6), Palette.STONE_DARK, Vector3.ZERO)
	bb.add_box(Vector3(5.0, 0.1, 0.7), Palette.COPPER, Vector3(0, 0.8, 0))
	bb.add_box(Vector3(5.0, 0.1, 0.7), Palette.COPPER, Vector3(0, -0.8, 0))
	var bmi := MeshInstance3D.new()
	bmi.mesh = bb.commit(MeshFactory.world_material())
	_boss_barrier.add_child(bmi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(7.0, 3.2, 0.6)
	cs.shape = shape
	body.add_child(cs)
	_boss_barrier.add_child(body)
	if Game.state != null and Game.state.puzzle_solved("sluice"):
		_boss_barrier.queue_free()


func _toggle_valve(index: int) -> void:
	_valves[index] = not _valves[index]
	var node := _valve_nodes[index]
	node.rotation_degrees.z = 55.0 if _valves[index] else 0.0
	AudioDirector.play_sfx("ui_click", node.global_position, -8.0, 0.7 + index * 0.12)
	if _valves == [true, false, true]:
		_solve_sluice()
	elif _valves.count(true) >= 2:
		Events.notification.emit("The water shifts, but the door does not open. Open, shut, open.")


func _solve_sluice() -> void:
	if Game.state == null or Game.state.puzzle_solved("sluice"):
		return
	Game.state.mark_puzzle("sluice", true)
	Game.state.set_quest("main_02", 5)
	AudioDirector.play_sfx("puzzle_good", Vector3(0, 1, -18), -2.0)
	Events.notification.emit("The sluice opens. The water gives up the stair.")
	var tween := create_tween()
	tween.tween_property(_water, "position:y", -1.2, 1.8)
	if _boss_barrier != null and is_instance_valid(_boss_barrier):
		var t2 := create_tween()
		t2.tween_property(_boss_barrier, "position:y", -3.0, 1.2)
		t2.tween_callback(_boss_barrier.queue_free)


func _build_echo_maze() -> void:
	var maze := EchoMaze.new()
	maze.build(self, Vector3(6.5, 0.2, -18), self)
	maze.name = "EchoMaze"


func _build_boss_arena() -> void:
	boss = HollowStagBoss.new()
	boss.position = Vector3(0, 0.2, -48)
	add_child(boss)
	boss.configure("hollow_stag")
	boss.defeated.connect(_on_boss_defeated)
	# The window: three notes, read left to right.
	var window := MeshInstance3D.new()
	var wb := MeshBuilder.new()
	wb.add_box(Vector3(10.0, 4.0, 0.3), Palette.INK, Vector3(0, 5.0, 0))
	wb.add_box(Vector3(9.0, 3.0, 0.1), Palette.PLUM, Vector3(0, 5.0, 0.2))
	window.mesh = wb.commit(MeshFactory.world_material())
	window.position = Vector3(0, 0, -56.0)
	add_child(window)
	var label := Label3D.new()
	label.text = "II   ·   III   ·   I"
	label.font_size = 96
	label.pixel_size = 0.012
	label.position = Vector3(0, 5.2, -55.7)
	label.modulate = Palette.REED_GOLD
	add_child(label)
	# Three chimes.
	var notes := [2, 3, 1]
	var positions := [Vector3(-8, 0.2, -36), Vector3(0, 0.2, -34), Vector3(8, 0.2, -36)]
	for i in 3:
		var root := Node3D.new()
		root.position = positions[i]
		add_child(root)
		var mi := MeshInstance3D.new()
		mi.mesh = MeshFactory.chime_column_mesh(3.2)
		root.add_child(mi)
		var note: int = notes[i]
		var it := Interactable.new()
		it.position = Vector3(0, 1.2, 0)
		it.configure("Ring the %s chime" % ["low", "mid", "high"][note - 1], func(_p, _n): _ring(note, _n))
		root.add_child(it)
	# The altar and the Chime.
	var altar := MeshFactory.static_box(self, Vector3(3.0, 1.0, 1.6), Vector3(0, 0.5, -60), Palette.STONE_A)
	_chime_item = Interactable.new()
	_chime_item.position = Vector3(0, 0.75, -60)
	var cb := MeshBuilder.new()
	cb.add_cylinder(0.35, 0.7, 10, Palette.COPPER, Vector3(0, 0.35, 0), 0.25)
	cb.add_ring(0.36, 0.08, 10, Palette.REED_GOLD, Vector3(0, 0.02, 0))
	var cmi := MeshInstance3D.new()
	cmi.mesh = cb.commit(MeshFactory.world_material())
	_chime_item.add_child(cmi)
	_chime_item.configure("Take the Choir Chime", func(_p, _n):
		Events.dialogue_started.emit("stag_choice")
	)
	_chime_item.enabled = false
	add_child(_chime_item)


func _ring(note: int, node: Node) -> void:
	if boss == null or not is_instance_valid(boss) or boss.is_dead():
		return
	boss.ring_chime(note)
	AudioDirector.play_sfx("listen", node.global_position, -4.0, 0.85 + note * 0.1)


func _on_boss_defeated(_enemy: Node) -> void:
	_chime_item.enabled = true
	AudioDirector.set_music("hollow")
	Events.notification.emit("The altar is open. Take the Choir Chime when you are ready.")


func _build_exit() -> void:
	add_interactable("Climb back to Reedwater", Vector3(0, 0.3, 5.2), func(_p, _n):
		var d := get_tree().get_first_node_in_group("world_director")
		if d != null:
			d.go_to("reedwater", "choir_entrance")
	)


func _build_props() -> void:
	for i in 8:
		var a := TAU * i / 8.0
		add_prop(MeshFactory.crystal_mesh(2200 + i, Palette.MINT if i % 2 else Palette.PLUM), Vector3(cos(a) * 9.0, 0.2, -18 + sin(a) * 11.0))
	for i in 6:
		var a := TAU * i / 6.0
		add_prop(MeshFactory.rock_mesh(2400 + i), Vector3(cos(a) * 11.0, 0.2, -44 + sin(a) * 10.0))
	for i in 5:
		add_prop(MeshFactory.jar_shelf_mesh(2.2, 1.2), Vector3(-8.0 + i * 4.0, 3.0, -55.0))
	add_prop(MeshFactory.bell_mesh(1.6, Palette.COPPER), Vector3(6.0, 0.2, -40.0))


func _build_enemies() -> void:
	add_enemy("reed_crawler", Vector3(-8, 0.2, -14), 2)
	add_enemy("reed_crawler", Vector3(8, 0.2, -24), 2)
	add_enemy("choir_moth", Vector3(0, 1.2, -24), 2)
	add_enemy("stone_sentinel", Vector3(0, 0.2, -33), 3)


func _build_lanterns() -> void:
	add_lantern("choir_entrance", Vector3(3.2, 0.2, 0.5), true)
	add_lantern("choir_nave", Vector3(0, 0.2, -10.0), true)
	add_lantern("choir_door", Vector3(4.5, 0.2, -33.0), true)


func _build_lights() -> void:
	for p in [Vector3(0, 4.5, 0.0), Vector3(0, 5.0, -18.0), Vector3(-6, 5.0, -44.0), Vector3(6, 5.0, -48.0), Vector3(0, 4.5, -59.0)]:
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color("#ffc36b") if p.z > -40 else Color("#9fd8b9")
		light.light_energy = 1.6
		light.omni_range = 14.0
		light.shadow_enabled = false
		add_child(light)


func _build_lore() -> void:
	add_sign(Vector3(4.5, 0.2, 2.5), "THE SUNKEN CHOIR — built to hold a note, flooded to hold a silence. The water is not the enemy.")
	add_sign(Vector3(-4.5, 0.2, -10.0), "THE SLUICE — open, shut, open. The Cantors did not trust memory; they trusted repetition.")
	add_sign(Vector3(9.0, 0.2, -26.0), "THE ECHO GALLERY — low, high, mid. Listen, then answer in order.")
