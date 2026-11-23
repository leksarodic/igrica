class_name WorldDirector
extends Node3D
## Owns the active region, the player, and diegetic transitions. One region is
## live at a time; thresholds autosave on both sides.

var player: Player
var companion: Companion
var build_system: BuildSystem
var region: RegionBase
var region_id := ""
var spawn_id := "default"
var _transition: CanvasLayer
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	add_to_group("world_director")
	build_system = BuildSystem.new()
	add_child(build_system)
	build_system.setup(self)
	_transition = CanvasLayer.new()
	_transition.layer = 50
	add_child(_transition)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.04, 0.045, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition.add_child(_fade)


func build(start_region: String, start_spawn: String = "default", reset_player: bool = true) -> void:
	if _busy:
		return
	_busy = true
	if region != null:
		region.queue_free()
		region = null
	region_id = start_region
	spawn_id = start_spawn
	var fresh: RegionBase = RegionFactory.create(start_region)
	fresh.setup(self, start_region)
	add_child(fresh)
	fresh.build()
	region = fresh
	if player == null:
		player = Player.new()
		player.configure(Game.state)
		add_child(player)
	elif reset_player:
		player.configure(Game.state)
	var spawn := fresh.spawn_point(start_spawn)
	player.global_position = spawn["position"]
	player.rotation.y = float(spawn.get("yaw", PI))
	player.velocity = Vector3.ZERO
	if player.rig != null:
		var indoor := start_region in ["sunken_choir", "undercave"]
		player.rig.distance = 3.8 if indoor else 9.5
		player.rig.height = 1.8 if indoor else 2.5
		player.rig._current_distance = player.rig.distance
	if player.rig != null:
		player.rig.yaw = float(spawn.get("yaw", PI)) - PI
		player.rig.global_position = player.global_position + Vector3.UP * 1.55
	if build_system != null:
		build_system.restore(start_region)
	_ensure_companion()
	if Game.state != null:
		Game.state.world["regions"] = Game.state.world.get("regions", {})
		Game.state.world["regions"][start_region] = true
	Game.set_region(start_region, start_spawn)
	Events.region_ready.emit(start_region)
	_busy = false


func _ensure_companion() -> void:
	if Game.state == null or player == null:
		return
	var active := bool(Game.state.companion("nissa").get("active", false))
	if active:
		if companion == null or not is_instance_valid(companion):
			companion = Companion.new()
			companion.configure("nissa")
			add_child(companion)
		companion.target = player
		companion.global_position = player.global_position + Vector3(2.2, 0.6, 1.2)
	elif companion != null and is_instance_valid(companion):
		companion.queue_free()
		companion = null


func _process(_delta: float) -> void:
	if Game.state == null or player == null:
		return
	var active := bool(Game.state.companion("nissa").get("active", false))
	if active and (companion == null or not is_instance_valid(companion)):
		_ensure_companion()
	elif not active and companion != null and is_instance_valid(companion):
		_ensure_companion()


func go_to(next_region: String, next_spawn: String = "default") -> void:
	if _busy:
		return
	_busy = true
	if Game.state != null:
		Game.save_current(Game.current_slot, false)
	Game.autosave()
	await _fade_to(0.85)
	_busy = false
	build(next_region, next_spawn, false)
	_busy = true
	await get_tree().process_frame
	await _fade_to(0.0)
	_busy = false


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "color", Color(0.03, 0.04, 0.045, alpha), 0.35)
	await tween.finished


func respawn_point() -> Vector3:
	if region == null:
		return Vector3(0, 2, 0)
	for lantern in region.lanterns:
		if lantern.has_method("is_lit") and lantern.is_lit():
			return lantern.global_position + Vector3(0.8, 0.2, 0.8)
	return region.spawn_point(spawn_id)["position"]


func current_ground(x: float, z: float) -> float:
	if region == null:
		return 0.0
	return TerrainBuilder.height_at(region_id, x, z)


func transition_to(region_name: String, spawn_name: String) -> void:
	go_to(region_name, spawn_name)
