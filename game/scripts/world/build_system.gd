class_name BuildSystem
extends Node3D
## A small, purposeful building vocabulary. Placement is a ghost with clear
## validity, structures persist in the save, and nothing here is a survival sim.

var director: WorldDirector
var active := false
var selected := "lantern_post"
var ghost: Node3D
var _ghost_mesh: MeshInstance3D
var _valid := false
var _position := Vector3.ZERO
var _last_region := ""


func setup(world_director: WorldDirector) -> void:
	director = world_director
	name = "BuildSystem"


func _ready() -> void:
	add_to_group("build_system")


func begin(build_id: String = "") -> void:
	if director == null or Game.state == null:
		return
	if not build_id.is_empty():
		selected = build_id
	var def: Dictionary = Game.content.build(selected)
	if def.is_empty():
		return
	var kit := String(def.get("kit", ""))
	if not Game.state.has_item(kit):
		Events.notification.emit("You need a %s kit. Craft one at a workbench." % String(def.get("name", selected)))
		return
	if not (director.region_id in ["bellhollow", "reedwater", "kestrel_shelf", "undercave"]):
		Events.notification.emit("This place does not want to be built in.")
		return
	active = true
	Game.build_mode = true
	_rebuild_ghost()
	Events.notification.emit("Placing %s. Move, then press E or Strike. B cancels." % String(def.get("name", selected)))


func end() -> void:
	active = false
	Game.build_mode = false
	if ghost != null:
		ghost.queue_free()
		ghost = null
	Events.interaction_available.emit("", false)


func _rebuild_ghost() -> void:
	if ghost != null:
		ghost.queue_free()
	ghost = Node3D.new()
	add_child(ghost)
	_ghost_mesh = MeshInstance3D.new()
	_ghost_mesh.mesh = _mesh_for(selected)
	ghost.add_child(_ghost_mesh)
	_update_ghost_transform()


func _mesh_for(build_id: String) -> Mesh:
	match String(Game.content.build(build_id).get("kind", "lantern")):
		"camp":
			var b := MeshBuilder.new()
			b.add_prism(Vector3(2.4, 1.3, 2.0), Color("#7a6247"), Vector3(0, 0.65, 0))
			b.add_box(Vector3(0.5, 0.5, 0.5), Palette.STONE_DARK, Vector3(1.6, 0.25, 0.8))
			b.add_cone(0.25, 0.5, 6, Palette.EMBER, Vector3(1.6, 0.55, 0.8))
			return b.commit(MeshFactory.world_material())
		"resonator":
			return MeshFactory.chime_column_mesh(1.6)
		"bridge":
			return MeshFactory.boardwalk_mesh(4.0, 2.4)
		"songbed":
			var b := MeshBuilder.new()
			b.add_cylinder(1.2, 0.1, 12, Palette.GRASS_A, Vector3(0, 0.05, 0))
			b.add_ring(1.0, 0.08, 12, Palette.COPPER, Vector3(0, 0.12, 0))
			for i in 5:
				var a := TAU * i / 5.0
				b.add_cylinder(0.03, 0.8, 4, Palette.REED_GOLD, Vector3(cos(a) * 0.7, 0.4, sin(a) * 0.7))
			return b.commit(MeshFactory.world_material())
		_:
			return MeshFactory.lantern_mesh()


func _process(_delta: float) -> void:
	if not active:
		return
	if director == null or director.player == null:
		return
	_update_ghost_transform()
	var def: Dictionary = Game.content.build(selected)
	var kit := String(def.get("kit", ""))
	var has_kit := Game.state != null and Game.state.has_item(kit)
	_valid = has_kit and _can_place(selected, _position)
	Events.interaction_available.emit("Place %s" % String(def.get("name", selected)), _valid)


func _update_ghost_transform() -> void:
	if director == null or director.player == null or ghost == null:
		return
	var player := director.player
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.1:
		fwd = Vector3(0, 0, -1)
	fwd = fwd.normalized()
	_position = player.global_position + fwd * 4.0
	var ground := director.current_ground(_position.x, _position.z)
	_position.y = ground
	ghost.global_position = _position
	ghost.rotation.y = atan2(fwd.x, fwd.z)
	if _ghost_mesh != null:
		var tint := Palette.MINT if _valid else Palette.ASH
		_ghost_mesh.material_override = MeshFactory.flat_material(Color(tint.r, tint.g, tint.b, 0.55), 1.0)


func _can_place(build_id: String, pos: Vector3) -> bool:
	var def: Dictionary = Game.content.build(build_id)
	if def.is_empty():
		return false
	if director == null or director.region == null:
		return false
	var clearance := float(def.get("clearance", 1.0))
	var water := TerrainBuilder.is_in_water(director.region_id, pos.x, pos.z)
	match String(def.get("terrain", "land")):
		"water":
			if not water:
				return false
		"land":
			if water:
				return false
	# Slope check: sample the ground around the footprint.
	var h := TerrainBuilder.height_at(director.region_id, pos.x, pos.z)
	for offset in [Vector3(clearance, 0, 0), Vector3(-clearance, 0, 0), Vector3(0, 0, clearance), Vector3(0, 0, -clearance)]:
		var dh := absf(TerrainBuilder.height_at(director.region_id, pos.x + offset.x, pos.z + offset.z) - h)
		if dh > 0.8:
			return false
	# Do not stack structures on top of each other or the player.
	for build in Game.state.builds():
		if String(build.get("region", "")) != director.region_id:
			continue
		var bp := Vector3(float(build.get("x", 0)), float(build.get("y", 0)), float(build.get("z", 0)))
		if bp.distance_to(pos) < clearance + 1.0:
			return false
	if director.player != null and director.player.global_position.distance_to(pos) < 1.0:
		return false
	return true


func confirm() -> void:
	if not active or not _valid:
		if active:
			Events.notification.emit("That spot will not hold it.")
		return
	var def: Dictionary = Game.content.build(selected)
	var kit := String(def.get("kit", ""))
	if not Game.state.remove_item(kit, 1):
		end()
		return
	Game.state.add_build(selected, _position, director.region_id)
	_spawn_for(selected, _position, false)
	AudioDirector.play_sfx("build", _position, -3.0)
	Events.notification.emit("%s placed. It will be here when you return." % String(def.get("name", selected)))
	Game.autosave()
	end()


func _spawn_for(build_id: String, pos: Vector3, restored: bool) -> Node3D:
	var def: Dictionary = Game.content.build(build_id)
	match String(def.get("kind", "lantern")):
		"camp":
			return _spawn_camp(pos)
		"resonator":
			return _spawn_resonator(pos)
		"bridge":
			return _spawn_bridge(pos)
		"songbed":
			return _spawn_songbed(pos)
		_:
			var lantern := Lantern.new()
			lantern.position = pos
			lantern.lantern_id = "built_lantern_%d" % Game.state.builds().size()
			lantern.prompt = "Rest at the lantern"
			director.region.add_child(lantern)
			director.region.lanterns.append(lantern)
			lantern.set_lit(true)
			return lantern


func _spawn_camp(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	director.region.add_child(root)
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh_for("camp")
	root.add_child(mi)
	var light := OmniLight3D.new()
	light.position = Vector3(1.6, 0.8, 0.8)
	light.light_color = Color("#ff9a5a")
	light.light_energy = 1.4
	light.omni_range = 6.0
	root.add_child(light)
	var it := Interactable.new()
	it.position = Vector3(0, 0.2, 0)
	it.configure("Rest at camp", func(_p, n):
		Game.state.heal(60.0)
		if director.player != null:
			director.player.heal(60.0)
			director.player.set_last_lantern(n)
		Game.save_current(Game.current_slot, false)
		AudioDirector.play_sfx("save", n.global_position, -3.0)
		Events.notification.emit("Rested. Saved. The valley will wait.")
	)
	root.add_child(it)
	return root


func _spawn_resonator(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	director.region.add_child(root)
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh_for("resonator")
	root.add_child(mi)
	var note := [1]
	var it := Interactable.new()
	it.position = Vector3(0, 1.0, 0)
	it.configure("Tune the resonator", func(_p, n):
		note[0] = int(note[0]) % 3 + 1
		AudioDirector.play_sfx("ui_click", n.global_position, -4.0, 0.8 + note[0] * 0.15)
		Events.notification.emit("The resonator holds the %s note." % ["low", "mid", "high"][note[0] - 1])
	)
	root.add_child(it)
	return root


func _spawn_bridge(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	director.region.add_child(root)
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh_for("bridge")
	root.add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 0.2, 4.0)
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)
	return root


func _spawn_songbed(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	director.region.add_child(root)
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh_for("songbed")
	root.add_child(mi)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.6, 0)
	light.light_color = Palette.MINT
	light.light_energy = 0.8
	light.omni_range = 4.0
	root.add_child(light)
	var it := Interactable.new()
	it.position = Vector3(0, 0.2, 0)
	it.configure("Listen to the songbed", func(_p, _n):
		AudioDirector.play_sfx("puzzle_good", pos, -4.0)
		Events.notification.emit("The reeds have taken the note. The ground sounds like itself again.")
	)
	root.add_child(it)
	return root


func restore(region_id: String) -> void:
	if Game.state == null or director == null or director.region == null:
		return
	end()
	for build in Game.state.builds():
		if String(build.get("region", "")) != region_id:
			continue
		var pos := Vector3(float(build.get("x", 0)), float(build.get("y", 0)), float(build.get("z", 0)))
		_spawn_for(String(build.get("id", "lantern_post")), pos, true)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("build"):
		if active:
			end()
		else:
			begin()
		get_viewport().set_input_as_handled()
		return
	if not active:
		return
	if event.is_action_pressed("ui_back"):
		end()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("attack_light"):
		confirm()
		get_viewport().set_input_as_handled()
