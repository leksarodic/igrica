class_name Player
extends CharacterBody3D
## The Listener. Movement, combat, interaction, and the Listen pulse.
## No class lock, no resource treadmill: every build can finish the story.

signal focus_changed(target: Node3D)

const WALK := 4.3
const SPRINT := 6.6
const DODGE_SPEED := 10.5
const GRAVITY := 18.0
const INTERACT_RANGE := 3.2

var state: GameState
var rig: CameraRig
var pivot: Node3D
var mesh_instance: MeshInstance3D
var weapon_pivot: Node3D
var health := 100.0
var max_health := 100.0
var breath := 100.0
var max_breath := 100.0
var ear_stat := 10.0

var _attack_cooldown := 0.0
var _heavy_cooldown := 0.0
var _dodge_time := 0.0
var _dodge_cooldown := 0.0
var _invuln := 0.0
var _control_lock := 0.0
var _step_timer := 0.0
var _walk_time := 0.0
var _focus: Node3D = null
var _interactable: Node3D = null
var _last_prompt := ""
var _listening := false
var _listen_cooldown := 0.0
var _ability_cooldowns := {"toll": 0.0, "lantern_song": 0.0, "echo_mark": 0.0, "quiet_passage": 0.0}
var _last_lantern: Node3D = null
var _dead := false
var _silenced := 0.0


func _ready() -> void:
	name = "Player"
	collision_layer = 1
	collision_mask = 1 | 4
	floor_max_angle = deg_to_rad(52.0)
	floor_snap_length = 0.45
	add_to_group("player")

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.7
	var cs := CollisionShape3D.new()
	cs.shape = capsule
	cs.position.y = 0.85
	add_child(cs)

	pivot = Node3D.new()
	pivot.name = "Body"
	add_child(pivot)

	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "CharacterMesh"
	mesh_instance.mesh = MeshFactory.character_mesh("listener", int(state.player.get("palette", 0)) if state != null else 0)
	mesh_instance.position.y = 0.0
	pivot.add_child(mesh_instance)

	weapon_pivot = Node3D.new()
	weapon_pivot.position = Vector3(0.4, 1.05, 0.1)
	pivot.add_child(weapon_pivot)
	_refresh_weapon()
	Events.equipment_changed.connect(_refresh_weapon)

	rig = CameraRig.new()
	rig.name = "CameraRig"
	add_child(rig)
	rig.set_target(self)
	rig.yaw = PI

	AudioDirector.set_music("working")


func _refresh_weapon() -> void:
	if weapon_pivot == null:
		return
	for child in weapon_pivot.get_children():
		child.queue_free()
	var weapon_id := String(Game.state.equipment().get("weapon", "reed_blade")) if Game.state != null else "reed_blade"
	var b := MeshBuilder.new()
	match weapon_id:
		"quarry_maul":
			b.add_cylinder(0.05, 1.0, 5, Palette.WOOD_DARK, Vector3(0, 0.5, 0))
			b.add_box(Vector3(0.34, 0.42, 0.22), Palette.STONE_B, Vector3(0, 1.02, 0))
			b.add_box(Vector3(0.36, 0.08, 0.24), Palette.COPPER, Vector3(0, 0.82, 0))
		"chime_staff":
			b.add_cylinder(0.045, 1.5, 5, Palette.WOOD, Vector3(0, 0.75, 0))
			b.add_ring(0.18, 0.05, 10, Palette.COPPER, Vector3(0, 1.55, 0), "z")
			b.add_sphere(0.05, 5, 3, Palette.REED_GOLD, Vector3(0, 1.55, 0))
		_:
			b.add_cylinder(0.035, 1.15, 5, Palette.STONE_A, Vector3(0, 0.57, 0))
			b.add_box(Vector3(0.10, 0.05, 0.05), Palette.COPPER, Vector3(0, 0.02, 0))
			b.add_cone(0.07, 0.22, 4, Palette.REED_GOLD, Vector3(0, 1.2, 0))
	var mi := MeshInstance3D.new()
	mi.name = "Weapon"
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.rotation_degrees = Vector3(-25, 0, 15)
	weapon_pivot.add_child(mi)
	if state != null:
		max_health = float(state.player.get("vitality", max_health))
		health = minf(health, max_health)
		max_breath = float(state.player.get("max_breath", max_breath))
		breath = minf(breath, max_breath)
		ear_stat = float(state.player.get("ear_stat", ear_stat))


func configure(game_state: GameState) -> void:
	state = game_state
	if state == null:
		return
	max_health = float(state.player.get("vitality", 100.0))
	health = float(state.player.get("health", max_health))
	max_breath = float(state.player.get("max_breath", 120.0))
	breath = float(state.player.get("breath", max_breath))
	ear_stat = float(state.player.get("ear_stat", 10.0))
	if mesh_instance != null:
		mesh_instance.mesh = MeshFactory.character_mesh("listener", int(state.player.get("palette", 0)))
	Events.player_health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	_tick_timers(delta)
	if _control_lock > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
	else:
		_move(delta)
	_check_interaction()
	_update_focus()
	_apply_gravity(delta)
	move_and_slide()
	_update_animation(delta)
	_update_water(delta)


func _tick_timers(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_heavy_cooldown = maxf(0.0, _heavy_cooldown - delta)
	_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_control_lock = maxf(0.0, _control_lock - delta)
	_dodge_time = maxf(0.0, _dodge_time - delta)
	_listen_cooldown = maxf(0.0, _listen_cooldown - delta)
	_silenced = maxf(0.0, _silenced - delta)
	for key in _ability_cooldowns.keys():
		_ability_cooldowns[key] = maxf(0.0, float(_ability_cooldowns[key]) - delta)
	breath = minf(max_breath, breath + (18.0 if not Input.is_action_pressed("sprint") else 4.0) * delta)
	if state != null:
		state.player["breath"] = breath


func _move(delta: float) -> void:
	var input := InputRouter.get_move_vector()
	var dir := Vector3.ZERO
	if rig != null:
		dir = (rig.right() * input.x + rig.forward() * input.y)
	dir.y = 0.0
	dir = dir.normalized() * minf(input.length(), 1.0)
	var sprint := Input.is_action_pressed("sprint") and breath > 2.0
	var speed := SPRINT if sprint else WALK
	speed *= float(state.player.get("stride", 1.0)) if state != null else 1.0
	if sprint and dir.length() > 0.1:
		breath = maxf(0.0, breath - 12.0 * delta)
	if Input.is_action_just_pressed("dodge") and _dodge_cooldown <= 0.0 and breath > 12.0:
		_dodge_time = 0.24
		_dodge_cooldown = 0.65
		_invuln = maxf(_invuln, 0.3)
		breath -= 12.0
		var dodge_dir := dir if dir.length() > 0.1 else -global_transform.basis.z
		velocity.x = dodge_dir.x * DODGE_SPEED
		velocity.z = dodge_dir.z * DODGE_SPEED
		AudioDirector.play_sfx("dodge", global_position, -8.0)
	if _dodge_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, dir.x * speed, 26.0 * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, 26.0 * delta)
	if dir.length() > 0.1:
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 12.0, 0.0, 1.0))
	if Input.is_action_just_pressed("attack_light"):
		_attack(false)
	if Input.is_action_just_pressed("attack_heavy"):
		_attack(true)
	if Input.is_action_just_pressed("listen"):
		_listen()
	if Input.is_action_just_pressed("interact"):
		_interact()
	if Input.is_action_just_pressed("ability_1"):
		_use_ability("toll")
	if Input.is_action_just_pressed("ability_2"):
		_use_ability("echo_mark")
	if Input.is_action_just_pressed("use_tonic"):
		_use_tonic()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5


func _update_water(delta: float) -> void:
	if state == null:
		return
	var region := Game.current_region
	if TerrainBuilder.is_in_water(region, global_position.x, global_position.z):
		velocity.y -= GRAVITY * 0.25 * delta
		velocity *= 0.94
		if global_position.y < TerrainBuilder.water_level(region) + 0.5:
			global_position.y += 3.0 * delta
		if Input.is_action_pressed("sprint"):
			breath = maxf(0.0, breath - 18.0 * delta)


func _update_animation(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > 0.2:
		_walk_time += delta * (7.0 + speed * 0.8)
		pivot.position.y = sin(_walk_time) * 0.045
		pivot.rotation.x = lerp_angle(pivot.rotation.x, -0.08 * (speed / SPRINT), delta * 8.0)
	else:
		_walk_time = 0.0
		pivot.position.y = lerpf(pivot.position.y, 0.0, delta * 10.0)
		pivot.rotation.x = lerp_angle(pivot.rotation.x, 0.0, delta * 8.0)
	if _dodge_time > 0.0:
		pivot.rotation.x = -0.35
	_step_timer -= delta
	if speed > 1.0 and _step_timer <= 0.0:
		_step_timer = 0.38 if speed < SPRINT else 0.3
		AudioDirector.play_sfx("step", global_position, -16.0, randf_range(0.9, 1.1))


func _attack(heavy: bool) -> void:
	if Game.build_mode:
		return
	if heavy and _heavy_cooldown > 0.0:
		return
	if not heavy and _attack_cooldown > 0.0:
		return
	if heavy:
		_heavy_cooldown = 0.95
	else:
		_attack_cooldown = 0.38
	var swing := 0.55 if heavy else 0.32
	_control_lock = swing * 0.55
	var weapon: Dictionary = Game.content.item(String(Game.state.equipment().get("weapon", "reed_blade"))) if Game.state != null else {}
	var weapon_pitch := String(weapon.get("pitch", "mid"))
	var weapon_damage := float(weapon.get("damage", 12.0))
	var upgrades: Dictionary = Game.state.player.get("upgrades", {}) if Game.state != null else {}
	var upgrade_bonus := 1.0 + int(upgrades.get("upgrade_weapon", 0)) * 0.15
	AudioDirector.play_sfx("hit_heavy" if heavy else "hit_light", global_position, -10.0, randf_range(0.95, 1.05))
	if rig != null:
		rig.shake(0.5 if heavy else 0.2)
	var tween := create_tween()
	tween.tween_property(weapon_pivot, "rotation_degrees", Vector3(-80 if heavy else -55, 0, 40), swing * 0.35)
	tween.tween_property(weapon_pivot, "rotation_degrees", Vector3(60 if heavy else 35, 0, -25), swing * 0.4)
	tween.tween_property(weapon_pivot, "rotation_degrees", Vector3(0, 0, 0), 0.25)
	await get_tree().create_timer(swing * 0.35).timeout
	var hits := _query_enemies(2.3 if heavy else 1.9)
	for enemy in hits:
		if enemy.has_method("take_damage"):
			var dmg := weapon_damage * (1.85 if heavy else 1.0) * upgrade_bonus
			enemy.take_damage(dmg, (14.0 + weapon_damage * 0.25) if heavy else 6.0, weapon_pitch, self)
	if not hits.is_empty():
		AudioDirector.play_sfx("enemy_down" if heavy else "hit_light", hits[0].global_position, -6.0)
		if rig != null:
			rig.shake(0.7 if heavy else 0.25)


func _query_enemies(radius: float) -> Array:
	var space := get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = sphere
	params.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * 0.9 + (-global_transform.basis.z) * 1.1)
	params.collision_mask = 2
	params.exclude = [get_rid()]
	var hits := space.intersect_shape(params, 8)
	var out: Array = []
	for h in hits:
		var node: Object = h.get("collider")
		if node != null and node.has_method("take_damage") and not out.has(node):
			out.append(node)
	return out


func _listen() -> void:
	if _listen_cooldown > 0.0:
		return
	_listen_cooldown = 1.2
	_listening = true
	AudioDirector.play_sfx("listen", global_position, -6.0)
	Events.listen_pulse.emit(global_position, 18.0)
	_spawn_listen_ring()
	for node in get_tree().get_nodes_in_group("resonance"):
		if node is Node3D and node.global_position.distance_to(global_position) < 18.0:
			if node.has_method("reveal"):
				node.reveal()
	for node in get_tree().get_nodes_in_group("climbable"):
		if node is Node3D and node.has_method("pulse"):
			node.pulse()
	await get_tree().create_timer(0.4).timeout
	_listening = false


func _spawn_listen_ring() -> void:
	var mi := MeshInstance3D.new()
	var b := MeshBuilder.new()
	b.add_ring(1.0, 0.08, 32, Palette.REED_GOLD, Vector3.ZERO, "y")
	mi.mesh = b.commit(MeshFactory.unshaded_material())
	mi.position = global_position + Vector3.UP * 0.15
	mi.scale = Vector3(0.4, 1, 0.4)
	get_parent().add_child(mi)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(mi, "scale", Vector3(18.0, 1, 18.0), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mi, "transparency", 1.0, 1.4)
	tween.chain().tween_callback(mi.queue_free)


func _use_ability(id: String) -> void:
	if state != null and not (id in state.player.get("skills", [])):
		Events.notification.emit("You have not learned that chord yet. Open Skills at a lantern.")
		return
	if _silenced > 0.0:
		Events.notification.emit("The silence holds your chords. Move out of it.")
		return
	if float(_ability_cooldowns.get(id, 0.0)) > 0.0:
		return
	match id:
		"toll":
			_ability_cooldowns[id] = 9.0
			AudioDirector.play_sfx("listen", global_position, -4.0, 0.8)
			for enemy in _query_enemies(5.0):
				if enemy.has_method("stagger"):
					enemy.stagger(1.4)
				if enemy.has_method("take_damage"):
					enemy.take_damage(8.0 + ear_stat * 0.4, 20.0, "low", self)
			Events.notification.emit("Toll — the low note breaks the guard.")
		"echo_mark":
			_ability_cooldowns[id] = 7.0
			var target := _nearest_enemy(16.0)
			if target != null:
				_focus = target
				if target.has_method("mark"):
					target.mark(6.0)
				AudioDirector.play_sfx("parry", target.global_position, -6.0, 1.3)
		"lantern_song":
			_ability_cooldowns[id] = 16.0
			heal(22.0 + ear_stat)
			AudioDirector.play_sfx("heal", global_position, -4.0)
		"quiet_passage":
			_ability_cooldowns[id] = 20.0
			_invuln = maxf(_invuln, 2.0)
			AudioDirector.play_sfx("dodge", global_position, -10.0)


func silence(seconds: float) -> void:
	_silenced = maxf(_silenced, seconds)


func _use_tonic() -> void:
	if state == null:
		return
	if state.remove_item("reed_tonic", 1):
		heal(35.0)
		AudioDirector.play_sfx("heal", global_position, -4.0)
		Events.item_gained.emit("reed_tonic_used", 1)


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	if state != null:
		state.player["health"] = health
	Events.player_health_changed.emit(health, max_health)


func take_damage(amount: float, _poise: float = 0.0, _pitch: String = "mid", _source: Node = null) -> void:
	if _invuln > 0.0 or _dead:
		return
	var scaled := amount * Settings.difficulty_multiplier("damage_taken")
	health = maxf(0.0, health - scaled)
	if state != null:
		state.player["health"] = health
	Events.player_health_changed.emit(health, max_health)
	if rig != null:
		rig.shake(0.9)
	AudioDirector.play_sfx("hurt", global_position, -6.0)
	if health <= 0.0:
		_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	_control_lock = 999.0
	Events.player_downed.emit()
	AudioDirector.play_sfx("enemy_down", global_position, -2.0, 0.6)
	await get_tree().create_timer(1.4).timeout
	_respawn()


func _respawn() -> void:
	_dead = false
	_control_lock = 0.0
	health = max_health
	breath = max_breath
	if state != null:
		state.player["health"] = health
	var point := _respawn_point()
	global_position = point
	velocity = Vector3.ZERO
	Events.player_respawned.emit()
	Events.player_health_changed.emit(health, max_health)
	AudioDirector.play_sfx("save", global_position, -4.0)


func _respawn_point() -> Vector3:
	var director := get_tree().get_first_node_in_group("world_director")
	if director != null and director.has_method("respawn_point"):
		return director.respawn_point()
	return global_position + Vector3.UP * 2.0


func set_last_lantern(lantern: Node3D) -> void:
	_last_lantern = lantern


func _check_interaction() -> void:
	var best: Node3D = null
	var best_d := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactable"):
		if not (node is Node3D):
			continue
		var d := global_position.distance_to((node as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = node
	_interactable = best
	var prompt := ""
	if best != null and best.has_method("prompt_text"):
		prompt = String(best.prompt_text())
	if prompt != _last_prompt:
		_last_prompt = prompt
		Events.interaction_available.emit(prompt, not prompt.is_empty())


func _interact() -> void:
	if Game.build_mode:
		return
	if _interactable != null and _interactable.has_method("interact"):
		_control_lock = 0.1
		_interactable.interact(self)


func _update_focus() -> void:
	if _focus != null and (not is_instance_valid(_focus) or (_focus.has_method("is_dead") and _focus.is_dead())):
		_focus = null
		focus_changed.emit(null)


func _nearest_enemy(max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_distance
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is Node3D and not (node.has_method("is_dead") and node.is_dead()):
			var d := global_position.distance_to((node as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = node
	return best


func is_dead() -> bool:
	return _dead


func health_fraction() -> float:
	return health / maxf(1.0, max_health)


func breath_fraction() -> float:
	return breath / maxf(1.0, max_breath)


func current_focus() -> Node3D:
	return _focus
