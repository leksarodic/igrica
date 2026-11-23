class_name UndercaveRegion
extends RegionBase
## A small generated side-cave. Seeded from the save, stable forever for that
## journey, with handcrafted modules and no story-critical items.

var _seed := 0
var _rooms: Array[Dictionary] = []


func build() -> void:
	_seed = absi(hash(Game.state.save_id if Game.state != null else "longnote"))
	add_environment()
	add_spawn("default", Vector3(0, 0.25, 2.0), PI)
	add_spawn("entrance", Vector3(0, 0.25, 2.0), PI)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var z := 0.0
	for i in 4:
		var w := rng.randf_range(8.0, 13.0)
		var d := rng.randf_range(8.0, 12.0)
		var x := 0.0 if i == 0 else rng.randf_range(-8.0, 8.0)
		var room := {"center": Vector3(x, 0, z), "w": w, "d": d}
		_rooms.append(room)
		_room(Vector3(x, 0, z), w, d, 5.5)
		if i > 0:
			var prev: Dictionary = _rooms[i - 1]
			var pz: float = float(prev["center"].z) - float(prev["d"]) * 0.5
			var nz: float = z + d * 0.5
			var corridor_len := absf(pz - nz) + 1.0
			MeshFactory.static_box(self, Vector3(3.2, 0.5, corridor_len), Vector3(x, -0.25, (pz + nz) * 0.5), Palette.STONE_DARK)
		z -= d * 0.5 + 7.0 + d * 0.5
	_build_contents(rng)
	_build_exit()


func _room(center: Vector3, w: float, d: float, h: float) -> void:
	MeshFactory.static_box(self, Vector3(w, 0.5, d), center + Vector3(0, -0.25, 0), Palette.STONE_DARK.lightened(0.12))
	var ceil := MeshInstance3D.new()
	var cb := MeshBuilder.new()
	cb.add_box(Vector3(w, 0.3, d), Palette.STONE_DARK.darkened(0.2), Vector3.ZERO)
	ceil.mesh = cb.commit(MeshFactory.world_material())
	ceil.position = center + Vector3(0, h, 0)
	add_child(ceil)
	for side in ["north", "south", "east", "west"]:
		var is_axis_z: bool = side in ["north", "south"]
		var door: bool = side in ["north", "south"]
		if is_axis_z:
			var z := center.z + (-d * 0.5 if side == "north" else d * 0.5)
			if door:
				var seg := (w - 3.4) * 0.5
				MeshFactory.static_box(self, Vector3(maxf(seg, 0.4), h, 0.5), Vector3(center.x - (1.7 + seg * 0.5), h * 0.5, z), Palette.STONE_DARK)
				MeshFactory.static_box(self, Vector3(maxf(seg, 0.4), h, 0.5), Vector3(center.x + (1.7 + seg * 0.5), h * 0.5, z), Palette.STONE_DARK)
			else:
				MeshFactory.static_box(self, Vector3(w, h, 0.5), Vector3(center.x, h * 0.5, z), Palette.STONE_DARK)
		else:
			var x := center.x + (-w * 0.5 if side == "west" else w * 0.5)
			MeshFactory.static_box(self, Vector3(0.5, h, d), Vector3(x, h * 0.5, center.z), Palette.STONE_DARK)


func _build_contents(rng: RandomNumberGenerator) -> void:
	for i in _rooms.size():
		var room: Dictionary = _rooms[i]
		var c: Vector3 = room["center"]
		var w: float = room["w"]
		var d: float = room["d"]
		for j in 3:
			var pos := c + Vector3(rng.randf_range(-w * 0.35, w * 0.35), 0.1, rng.randf_range(-d * 0.35, d * 0.35))
			add_prop(MeshFactory.crystal_mesh(_seed + i * 10 + j, Palette.MINT if j % 2 else Palette.PLUM), pos)
		if i == 0:
			add_pickup("copper_scrap", 2, c + Vector3(2, 0.1, 0))
			add_pickup("hum_reed", 2, c + Vector3(-2, 0.1, 1))
		elif i == 1:
			add_enemy("reed_crawler", c + Vector3(2, 0.1, 0), 2)
		elif i == 2:
			add_enemy("returning_wisp", c + Vector3(-2, 1.5, 0), 2)
			add_pickup("echo_glass", 1, c + Vector3(0, 0.1, 2))
		else:
			add_pickup("humstone_shard", 2, c + Vector3(0, 0.1, 0))
			add_pickup("river_clay", 2, c + Vector3(2, 0.1, 1))
			add_lantern("undercave_deep", c + Vector3(-2, 0.1, -2))
	# A generated mini-puzzle: three chime stones, target shown on a carving.
	var last: Dictionary = _rooms[_rooms.size() - 1]
	var center: Vector3 = last["center"]
	var gate := ChimeGate.new()
	gate.gate_id = "undercave_gate"
	gate.target = [1, 2, 3]
	gate.build(self, center + Vector3(0, 0.1, -float(last["d"]) * 0.25), null)


func _build_exit() -> void:
	add_interactable("Climb back to Reedwater", Vector3(0, 0.3, 5.2), func(_p, _n):
		var d := get_tree().get_first_node_in_group("world_director")
		if d != null:
			d.go_to("reedwater", "reed_camp")
	)
