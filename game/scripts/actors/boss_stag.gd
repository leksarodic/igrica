class_name HollowStagBoss
extends Enemy
## The Hollow Stag is not a damage sponge. Its shell is held by three notes.
## Read the window, ring the chimes in order, then fight what is underneath.

var shell_intact := true
var chime_target := [2, 3, 1]
var chimes_rung: Array[int] = []
var boss_name := "The Hollow Stag"
var _silence_cd := 12.0
var _roar_cd := 7.0
var _announced := false


func _ready() -> void:
	super._ready()
	behavior = "charger"
	speed = 3.6
	telegraph_time = 0.95
	recover_time = 1.1
	if _mesh != null:
		_mesh.mesh = MeshFactory.enemy_mesh("hollow_stag")
		_mesh.scale = Vector3(1.15, 1.15, 1.15)


func configure(id: String, spawn_level: int = 1) -> void:
	super.configure(id, spawn_level)
	behavior = "charger"
	display_name = "The Hollow Stag"


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _dead:
		return
	if not _announced and _player != null and global_position.distance_to(_player.global_position) < 22.0:
		_announced = true
		Events.boss_started.emit(boss_name, max_health)
		AudioDirector.set_music("tension")
		Events.notification.emit("THE HOLLOW STAG — its shell is a chord. Read the window.")
	_silence_cd -= delta
	_roar_cd -= delta
	if _silence_cd <= 0.0:
		_silence_cd = 16.0
		_silence()
	if _roar_cd <= 0.0 and not shell_intact:
		_roar_cd = 11.0
		_antler_sweep()
	Events.boss_health_changed.emit(health, max_health)


func take_damage(amount: float, poise_damage: float = 0.0, attack_pitch: String = "mid", source: Node = null) -> void:
	if shell_intact:
		if _mesh != null:
			_mesh.scale = Vector3(1.25, 1.05, 1.25)
			var t := create_tween()
			t.tween_property(_mesh, "scale", Vector3(1.15, 1.15, 1.15), 0.2)
		AudioDirector.play_sfx("parry", global_position, -10.0, 0.6)
		return
	super.take_damage(amount, poise_damage, attack_pitch, source)


func ring_chime(note: int) -> void:
	if not shell_intact:
		return
	chimes_rung.append(note)
	var idx := chimes_rung.size() - 1
	if idx >= chime_target.size():
		chimes_rung.clear()
		return
	if chimes_rung[idx] != chime_target[idx]:
		chimes_rung.clear()
		Events.notification.emit("The chime falls out of the chord. The window shows three notes again.")
		AudioDirector.play_sfx("puzzle_bad", global_position, -8.0)
		return
	AudioDirector.play_sfx("ui_click", global_position, -6.0, 0.9 + note * 0.12)
	if chimes_rung.size() == chime_target.size():
		break_shell()


func break_shell() -> void:
	if not shell_intact:
		return
	shell_intact = false
	chimes_rung.clear()
	AudioDirector.play_sfx("puzzle_good", global_position, -1.0)
	Events.notification.emit("The shell splits. The Stag is listening now.")
	Events.boss_phase_changed.emit("hollow_stag", 2)
	if _mesh != null:
		var t := create_tween()
		t.tween_property(_mesh, "scale", Vector3(1.0, 1.25, 1.0), 0.4)
		t.tween_property(_mesh, "scale", Vector3(1.15, 1.15, 1.15), 0.4)
	for i in 10:
		var mote := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.05
		sm.height = 0.1
		mote.mesh = sm
		mote.material_override = MeshFactory.emissive_material(Palette.MINT, 2.5)
		mote.position = Vector3(randf_range(-1, 1), randf_range(1.5, 3.5), randf_range(-1, 1))
		add_child(mote)
		var tween := mote.create_tween()
		tween.tween_property(mote, "position", mote.position + Vector3(0, 2, 0), 1.0)
		tween.tween_callback(mote.queue_free)


func _silence() -> void:
	if _player == null:
		return
	var d := global_position.distance_to(_player.global_position)
	if d < 9.0:
		Events.companion_dialogue.emit("Nissa", "It's drawing the sound out of the air. Move!")
		AudioDirector.play_sfx("puzzle_bad", global_position, -4.0, 0.5)
		if _player.has_method("silence"):
			_player.silence(3.0)


func _antler_sweep() -> void:
	if _player == null:
		return
	var to := _player.global_position - global_position
	if to.length() < 6.0:
		_player.take_damage(damage * 0.9, 18.0, "low", self)
		AudioDirector.play_sfx("hit_heavy", _player.global_position, -4.0)
		Events.notification.emit("The antlers sweep wide. Stay behind it.")


func _die(source: Node) -> void:
	if _dead:
		return
	_dead = true
	collision_layer = 0
	AudioDirector.play_sfx("enemy_down", global_position, 0.0)
	AudioDirector.set_music("hollow")
	Events.boss_ended.emit(boss_name)
	Events.notification.emit("The Stag kneels. The Choir Chime is on the altar.")
	if Game.state != null:
		Game.state.mark_puzzle("hollow_stag", true)
		Game.state.set_quest("main_02", 8)
		Game.state.add_item("stag_charm", 1)
		Game.state.add_marks(40)
	_spawn_motes()
	defeated.emit(self)
	await get_tree().create_timer(1.2).timeout
	queue_free()
