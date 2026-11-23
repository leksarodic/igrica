class_name Companion
extends CharacterBody3D
## Nissa walks, fights, comments, and never solves the puzzle for you.

var companion_id := "nissa"
var display_name := "Nissa"
var kind := "nissa"
var target: Player
var health := 120.0
var max_health := 120.0
var damage := 9.0
var attack_cooldown := 1.2
var ability_cooldown := 10.0

var _mesh: MeshInstance3D
var _anim := 0.0
var _shot_cd := 0.0
var _ability_cd := 4.0
var _bark_cd := 18.0
var _follow_side := 1.0
var _dead := false
var _waiting := false


func _ready() -> void:
	add_to_group("companion")
	collision_layer = 4
	collision_mask = 1
	floor_max_angle = deg_to_rad(52.0)
	floor_snap_length = 0.4
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.65
	var cs := CollisionShape3D.new()
	cs.shape = capsule
	cs.position.y = 0.82
	add_child(cs)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = MeshFactory.character_mesh(kind, 0)
	add_child(_mesh)
	_follow_side = -1.0 if randf() < 0.5 else 1.0
	Events.companion_command.connect(_on_command)


func configure(id: String) -> void:
	companion_id = id
	match id:
		"brannoc":
			display_name = "Brannoc"
			kind = "brannoc"
			health = 190.0
			damage = 14.0
			attack_cooldown = 1.8
		_:
			display_name = "Nissa"
			kind = "nissa"
			health = 110.0
			damage = 9.0
	max_health = health
	if _mesh != null:
		_mesh.mesh = MeshFactory.character_mesh(kind, 0)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Player
	if target == null:
		return
	_anim += delta
	_shot_cd = maxf(0.0, _shot_cd - delta)
	_ability_cd = maxf(0.0, _ability_cd - delta)
	_bark_cd = maxf(0.0, _bark_cd - delta)
	if _mesh != null:
		_mesh.position.y = sin(_anim * 7.0) * 0.02

	var dist := global_position.distance_to(target.global_position)
	if dist > 16.0:
		var behind := target.global_position - target.rig.forward() * 2.4 + target.rig.right() * _follow_side * 1.2
		global_position = behind + Vector3.UP * 0.5
		velocity = Vector3.ZERO

	var enemy := _nearest_enemy(14.0)
	if enemy != null and target.is_dead() == false:
		var to_enemy := enemy.global_position - global_position
		var dist_e := to_enemy.length()
		rotation.y = lerp_angle(rotation.y, atan2(to_enemy.x, to_enemy.z), delta * 8.0)
		if dist_e > 8.0:
			_move_toward(enemy.global_position + Vector3.UP * 0.0, delta, 4.8)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		if _shot_cd <= 0.0 and dist_e < 13.0:
			_shot_cd = attack_cooldown
			_shoot(enemy)
		if _ability_cd <= 0.0:
			_ability_cd = ability_cooldown
			_true_pitch(enemy)
	elif _waiting:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
	else:
		var desired := target.global_position - target.rig.forward() * 2.8 + target.rig.right() * _follow_side * 1.4
		var to := desired - global_position
		to.y = 0.0
		if to.length() > 1.6:
			_move_toward(desired, delta, 5.2)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			var face := target.global_position - global_position
			rotation.y = lerp_angle(rotation.y, atan2(face.x, face.z), delta * 3.0)
		if _bark_cd <= 0.0 and dist < 8.0 and not Game.in_combat:
			_bark_cd = randf_range(24.0, 40.0)
			_bark()

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	if health <= 0.0:
		_dead = true


func _move_toward(point: Vector3, delta: float, speed: float) -> void:
	var dir := point - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		return
	dir = dir.normalized()
	velocity.x = move_toward(velocity.x, dir.x * speed, 16.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, 16.0 * delta)


func _nearest_enemy(radius: float) -> Enemy:
	var best: Enemy = null
	var best_d := radius
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is Enemy and not node.is_dead():
			var d := global_position.distance_to((node as Enemy).global_position)
			if d < best_d:
				best_d = d
				best = node
	return best


func _shoot(enemy: Node3D) -> void:
	var tracer := MeshInstance3D.new()
	var b := MeshBuilder.new()
	b.add_box(Vector3(0.06, 0.06, 0.6), Palette.MINT)
	tracer.mesh = b.commit(MeshFactory.emissive_material(Palette.MINT, 2.5))
	tracer.global_position = global_position + Vector3.UP * 1.2
	get_parent().add_child(tracer)
	var to := enemy.global_position + Vector3.UP * 1.0
	tracer.look_at(to, Vector3.UP)
	var tween := tracer.create_tween()
	tween.tween_property(tracer, "global_position", to, 0.18)
	tween.tween_callback(func():
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(damage, 4.0, "high", self)
		tracer.queue_free()
	)
	AudioDirector.play_sfx("hit_light", global_position, -14.0, 1.4)


func _true_pitch(enemy: Enemy) -> void:
	enemy.mark(5.0)
	Events.companion_dialogue.emit(display_name, "%s — there, the third note. Hit it there." % enemy.display_name)
	AudioDirector.play_sfx("parry", enemy.global_position, -10.0, 1.2)


func _on_command(command: String) -> void:
	match command:
		"wait":
			_waiting = true
			Events.companion_dialogue.emit(display_name, "I'll hold here. Try not to need me.")
		"follow":
			_waiting = false
			Events.companion_dialogue.emit(display_name, "Right behind you.")
		"ability":
			var enemy := _nearest_enemy(16.0)
			if enemy != null:
				_true_pitch(enemy)


func _bark() -> void:
	var lines := [
		"The reeds are listening. That's either good or very bad.",
		"I've poled this channel in worse weather. Not much worse.",
		"If you find a jar with my mother's name on it, don't open it. Just tell me.",
		"You hold the pole like it owes you money. Try asking nicely.",
		"Wren hums when she's worried. She thinks no one notices.",
	]
	Events.companion_dialogue.emit(display_name, lines[randi() % lines.size()])


func take_damage(amount: float, _poise: float = 0.0, _pitch: String = "mid", _source: Node = null) -> void:
	if _dead:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		_dead = true
		Events.companion_dialogue.emit(display_name, "I'm all right. Go on. I'll catch up.")
		await get_tree().create_timer(6.0).timeout
		if is_inside_tree():
			_dead = false
			health = max_health
			global_position = target.global_position + Vector3(1.5, 0.5, 1.5) if target != null else global_position


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)


func is_dead() -> bool:
	return _dead


func health_fraction() -> float:
	return health / maxf(1.0, max_health)
