class_name NPC
extends StaticBody3D
## A person with a shape, a voice, and somewhere else to be.

var display_name := "Someone"
var dialogue_id := ""
var kind := "villager"
var facing := 0.0
var idle_seed := 0.0
var _mesh: MeshInstance3D
var _player: Node3D
var _base_y := 0.0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0
	idle_seed = randf() * 10.0
	_base_y = position.y
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.7
	var cs := CollisionShape3D.new()
	cs.shape = capsule
	cs.position.y = 0.85
	add_child(cs)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = MeshFactory.character_mesh(kind, 0)
	add_child(_mesh)


func configure(person_name: String, dialogue: String, appearance: String = "villager", yaw: float = 0.0) -> void:
	display_name = person_name
	dialogue_id = dialogue
	kind = appearance
	facing = yaw
	rotation.y = yaw
	if _mesh != null:
		_mesh.mesh = MeshFactory.character_mesh(kind, 0)


func prompt_text() -> String:
	return "Speak with %s" % display_name


func interact(player: Node) -> void:
	_player = player
	if dialogue_id.is_empty():
		Events.notification.emit("%s nods." % display_name)
		return
	var resolved := dialogue_id
	if display_name == "Wren" and Game.state != null and Game.state.quest_stage("main_01") >= 1:
		resolved = "wren_hub"
	if display_name == "Sable" and Game.state != null and bool(Game.state.get_flag("chime_chosen", false)):
		resolved = "sable_after"
	AudioDirector.play_sfx("companion", global_position, -10.0)
	Events.dialogue_started.emit(resolved)
	if player is Node3D:
		var to := (player as Node3D).global_position - global_position
		rotation.y = atan2(to.x, to.z)


func _process(delta: float) -> void:
	if _mesh != null:
		_mesh.position.y = sin(Time.get_ticks_msec() * 0.0018 + idle_seed) * 0.012
	if _player != null and is_instance_valid(_player):
		var to := _player.global_position - global_position
		if to.length() < 5.0:
			var target_yaw := atan2(to.x, to.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, delta * 2.0)
		else:
			rotation.y = lerp_angle(rotation.y, facing, delta * 0.6)
