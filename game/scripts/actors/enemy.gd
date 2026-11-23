class_name Enemy
extends CharacterBody3D
## Readable, non-gory opposition. Every archetype has a different reason to
## fight: territory, hunger, guarding, or a song it cannot finish.

signal defeated(enemy: Node)

var enemy_id := ""
var display_name := "Dissonant"
var max_health := 40.0
var health := 40.0
var damage := 8.0
var speed := 3.0
var pitch := "mid"
var max_poise := 10.0
var poise := 10.0
var aggro_range := 9.0
var attack_range := 2.2
var telegraph_time := 0.6
var recover_time := 0.8
var behavior := "ambusher"
var materials := {}
var level := 1

var _state := "idle"
var _timer := 0.0
var _cooldown := 0.0
var _stagger := 0.0
var _marked := 0.0
var _dead := false
var _player: Node3D = null
var _mesh: MeshInstance3D
var _base_color := Color.WHITE
var _spawn_position := Vector3.ZERO
var _patrol_target := Vector3.ZERO
var _last_known := Vector3.ZERO
var _flying := false
var _attack_visual: MeshInstance3D
var _marks: Array[MeshInstance3D] = []
var _anim := 0.0


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 2
	collision_mask = 1
	floor_max_angle = deg_to_rad(55.0)
	floor_snap_length = 0.4
	_spawn_position = global_position
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 1.6
	var cs := CollisionShape3D.new()
	cs.shape = capsule
	cs.position.y = 0.8
	add_child(cs)
	_mesh = MeshInstance3D.new()
	add_child(_mesh)
	_attack_visual = MeshInstance3D.new()
	_attack_visual.visible = false
	add_child(_attack_visual)


func configure(id: String, spawn_level: int = 1) -> void:
	enemy_id = id
	level = spawn_level
	var def: Dictionary = Game.content.enemy(id)
	display_name = String(def.get("name", id.capitalize()))
	max_health = float(def.get("health", 40.0)) * (1.0 + (level - 1) * 0.08)
	health = max_health
	damage = float(def.get("damage", 8.0)) * Settings.difficulty_multiplier("enemy_health")
	speed = float(def.get("speed", 3.0))
	pitch = String(def.get("pitch", "mid"))
	max_poise = float(def.get("poise", 10.0))
	poise = max_poise
	behavior = String(def.get("behavior", "ambusher"))
	aggro_range = float(def.get("aggro_range", 9.0))
	attack_range = float(def.get("attack_range", 2.2))
	telegraph_time = float(def.get("telegraph", 0.6)) * Settings.difficulty_multiplier("telegraph")
	recover_time = float(def.get("recover", 0.8))
	materials = def.get("materials", {})
	_flying = behavior in ["support", "harasser"]
	if _mesh != null:
		_mesh.mesh = MeshFactory.enemy_mesh(id)
		_mesh.position.y = 0.0
	_build_pitch_marks()
	_base_color = Color.WHITE
	_patrol_target = _spawn_position


func _build_pitch_marks() -> void:
	for m in _marks:
		m.queue_free()
	_marks.clear()
	var count := Palette.pitch_marks(pitch)
	for i in count:
		var mi := MeshInstance3D.new()
		var b := MeshBuilder.new()
		b.add_box(Vector3(0.16, 0.035, 0.035), Palette.pitch_color(pitch))
		mi.mesh = b.commit(MeshFactory.emissive_material(Palette.pitch_color(pitch), 2.0))
		mi.position = Vector3((i - (count - 1) * 0.5) * 0.22, 2.2, 0)
		add_child(mi)
		_marks.append(mi)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_anim += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	_timer = maxf(0.0, _timer - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	_stagger = maxf(0.0, _stagger - delta)
	_marked = maxf(0.0, _marked - delta)
	if _mesh != null:
		_mesh.position.y = sin(_anim * 3.0 + position.x) * 0.03
		_mesh.scale = _mesh.scale.lerp(Vector3.ONE * (1.1 if _stagger > 0.0 else 1.0), delta * 8.0)
	if _stagger > 0.0:
		_state = "stagger"
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity(delta)
		move_and_slide()
		return
	if _player == null:
		_apply_gravity(delta)
		move_and_slide()
		return
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	var sees := _can_see_player()
	match behavior:
		"support":
			_support_behavior(delta, dist, sees)
		"guard":
			_guard_behavior(delta, to_player, dist, sees)
		"charger":
			_charger_behavior(delta, to_player, dist, sees)
		"harasser":
			_harasser_behavior(delta, to_player, dist, sees)
		_:
			_ambusher_behavior(delta, to_player, dist, sees)
	_face(to_player)
	_apply_gravity(delta)
	move_and_slide()
	_tick_world_ui()


func _apply_gravity(delta: float) -> void:
	if _flying:
		var target_y := _spawn_position.y + 1.2 + sin(_anim * 1.4) * 0.25
		global_position.y = lerpf(global_position.y, target_y, clampf(delta * 2.0, 0.0, 1.0))
		velocity.y = 0.0
		return
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.5


func _ambusher_behavior(delta: float, to_player: Vector3, dist: float, sees: bool) -> void:
	if _state == "idle":
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		if sees and dist < aggro_range:
			_state = "chase"
			_last_known = _player.global_position
			AudioDirector.play_sfx("enemy_down", global_position, -18.0, 1.6)
		return
	if _state == "chase":
		_move_toward(_player.global_position, delta)
		if dist < attack_range and _cooldown <= 0.0:
			_begin_attack()
		if dist > aggro_range * 1.6 and not sees:
			_state = "return"
		return
	if _state == "telegraph":
		velocity.x = 0.0
		velocity.z = 0.0
		if _timer <= 0.0:
			_resolve_attack(dist)
		return
	if _state == "recover":
		velocity.x = 0.0
		velocity.z = 0.0
		if _timer <= 0.0:
			_state = "chase"
		return
	if _state == "return":
		_move_toward(_spawn_position, delta)
		if global_position.distance_to(_spawn_position) < 1.2:
			_state = "idle"
			health = minf(max_health, health + max_health * 0.25)


func _charger_behavior(delta: float, to_player: Vector3, dist: float, sees: bool) -> void:
	if _state == "idle":
		velocity.x = 0.0
		velocity.z = 0.0
		if sees and dist < aggro_range:
			_state = "chase"
		return
	if _state == "chase":
		_move_toward(_player.global_position, delta, speed * 0.85)
		if dist < attack_range + 3.0 and _cooldown <= 0.0:
			_begin_attack()
		return
	if _state == "telegraph":
		velocity.x = 0.0
		velocity.z = 0.0
		if _timer <= 0.0:
			# Charge in a straight line; if it hits terrain, it is stunned.
			var dir := (_player.global_position - global_position).normalized()
			velocity = dir * speed * 2.4
			_timer = 0.55
			_state = "charge"
			_attack_visual.visible = true
		return
	if _state == "charge":
		if _timer <= 0.0 or is_on_wall():
			_state = "recover"
			_timer = recover_time * 1.4
			_attack_visual.visible = false
			if is_on_wall():
				stagger(1.5)
				AudioDirector.play_sfx("hit_heavy", global_position, -6.0)
		elif global_position.distance_to(_player.global_position) < 2.2:
			_player.take_damage(damage, 10.0, pitch, self)
			_state = "recover"
			_timer = recover_time
			_attack_visual.visible = false
		return
	if _state == "recover":
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
		if _timer <= 0.0:
			_state = "chase"
		return


func _guard_behavior(delta: float, to_player: Vector3, dist: float, sees: bool) -> void:
	if not sees and _state == "idle":
		if _patrol_target.distance_to(global_position) < 1.0:
			var angle := randf() * TAU
			_patrol_target = _spawn_position + Vector3(cos(angle), 0, sin(angle)) * 4.0
		_move_toward(_patrol_target, delta, speed * 0.4)
		return
	if dist > 2.6:
		_move_toward(_player.global_position, delta, speed)
	elif _cooldown <= 0.0:
		_begin_attack()
	if _state == "telegraph":
		velocity.x = 0.0
		velocity.z = 0.0
		if _timer <= 0.0:
			_resolve_attack(dist)
	elif _state == "recover" and _timer <= 0.0:
		_state = "chase"


func _support_behavior(delta: float, dist: float, sees: bool) -> void:
	var target := _lowest_ally()
	if target != null and target != self:
		var to := target.global_position - global_position
		if to.length() > 7.0:
			_move_toward(target.global_position, delta, speed)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)
			if _cooldown <= 0.0:
				_cooldown = 3.5
				if target.has_method("heal"):
					target.heal(8.0)
				AudioDirector.play_sfx("heal", global_position, -12.0, 1.4)
		return
	if sees and dist < aggro_range:
		_move_toward(_player.global_position, delta, speed * 0.7)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)


func _harasser_behavior(delta: float, to_player: Vector3, dist: float, sees: bool) -> void:
	if sees and dist < aggro_range:
		if dist < 5.0:
			_move_toward(global_position * 2.0 - _player.global_position, delta, speed)
		elif dist > 9.0:
			_move_toward(_player.global_position, delta, speed)
		else:
			velocity.x = cos(_anim) * speed * 0.5
			velocity.z = sin(_anim) * speed * 0.5
		if _cooldown <= 0.0:
			_cooldown = 2.4
			_player.take_damage(damage, 2.0, pitch, self)
			AudioDirector.play_sfx("hit_light", _player.global_position, -12.0, 1.3)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)


func _move_toward(target: Vector3, delta: float, move_speed: float = -1.0) -> void:
	var dir := target - global_position
	dir.y = 0.0
	if dir.length() < 0.1:
		return
	dir = dir.normalized()
	var s := speed if move_speed < 0.0 else move_speed
	velocity.x = move_toward(velocity.x, dir.x * s, 16.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * s, 16.0 * delta)


func _face(to_player: Vector3) -> void:
	if to_player.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(to_player.x, to_player.z), 0.12)


func _begin_attack() -> void:
	_state = "telegraph"
	_timer = telegraph_time
	_cooldown = telegraph_time + recover_time + 1.2
	_attack_visual.visible = true
	var b := MeshBuilder.new()
	b.add_ring(1.0 + attack_range * 0.25, 0.05, 24, Palette.EMBER, Vector3.ZERO, "y")
	_attack_visual.mesh = b.commit(MeshFactory.emissive_material(Palette.EMBER, 2.0))
	_attack_visual.position = Vector3(0, 0.1, 0)
	AudioDirector.play_sfx("puzzle_bad", global_position, -8.0, 0.6)


func _resolve_attack(dist: float) -> void:
	_attack_visual.visible = false
	_state = "recover"
	_timer = recover_time
	if dist <= attack_range + 0.8 and _player != null:
		_player.take_damage(damage, poise * 0.2, pitch, self)
		AudioDirector.play_sfx("hit_heavy", _player.global_position, -6.0)


func _can_see_player() -> bool:
	if _player == null:
		return false
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 1.4
	var to := _player.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := space.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == _player


func _lowest_ally() -> Node3D:
	var best: Node3D = null
	var frac := 0.95
	for node in get_tree().get_nodes_in_group("enemy"):
		if node == self or not node is Node3D:
			continue
		if node.has_method("health_fraction"):
			var f: float = node.health_fraction()
			if f < frac:
				frac = f
				best = node
	return best


func take_damage(amount: float, poise_damage: float = 0.0, attack_pitch: String = "mid", source: Node = null) -> void:
	if _dead:
		return
	var pitch_bonus := 1.2 if attack_pitch == pitch else 1.0
	var final := amount * pitch_bonus
	health -= final
	poise -= poise_damage
	if poise <= 0.0:
		stagger(1.0)
		poise = max_poise
	if _mesh != null:
		_mesh.scale = Vector3(1.18, 0.9, 1.18)
		var tween := create_tween()
		tween.tween_property(_mesh, "scale", Vector3.ONE, 0.18)
	if health <= 0.0:
		_die(source)
	else:
		AudioDirector.play_sfx("hit_light", global_position, -8.0, randf_range(0.9, 1.1))
		if _state == "idle":
			_state = "chase"


func heal(amount: float) -> void:
	if _dead:
		return
	health = minf(max_health, health + amount)


func stagger(seconds: float) -> void:
	_stagger = maxf(_stagger, seconds)
	_timer = 0.0
	_state = "stagger"


func mark(seconds: float) -> void:
	_marked = seconds
	if _marks.size() > 0:
		for m in _marks:
			m.scale = Vector3.ONE * 1.6


func _die(source: Node) -> void:
	if _dead:
		return
	_dead = true
	collision_layer = 0
	_attack_visual.visible = false
	AudioDirector.play_sfx("enemy_down", global_position, -3.0)
	if Game.state != null:
		Game.state.stats["enemies_defeated"] = int(Game.state.stats.get("enemies_defeated", 0)) + 1
		for mat in materials.keys():
			Game.state.add_item(String(mat), int(materials[mat]))
		Game.state.add_marks(2)
	_spawn_motes()
	defeated.emit(self)
	if source != null and source.has_method("heal"):
		pass
	await get_tree().create_timer(0.5).timeout
	queue_free()


func _spawn_motes() -> void:
	var host := get_parent()
	if host == null:
		return
	for i in 12:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.06
		sm.height = 0.12
		mi.mesh = sm
		mi.material_override = MeshFactory.emissive_material(Palette.MINT.lerp(Palette.REED_GOLD, randf()), 2.5)
		mi.position = global_position + Vector3(randf_range(-0.5, 0.5), randf_range(0.5, 1.5), randf_range(-0.5, 0.5))
		host.add_child(mi)
		var tween := mi.create_tween()
		tween.set_parallel(true)
		tween.tween_property(mi, "position", mi.position + Vector3(randf_range(-0.4, 0.4), randf_range(1.2, 2.6), randf_range(-0.4, 0.4)), 0.9)
		tween.tween_property(mi, "scale", Vector3.ZERO, 0.9)
		tween.chain().tween_callback(mi.queue_free)


func _tick_world_ui() -> void:
	pass


func is_dead() -> bool:
	return _dead


func health_fraction() -> float:
	return health / maxf(1.0, max_health)


func pitch_marks() -> int:
	return Palette.pitch_marks(pitch)
