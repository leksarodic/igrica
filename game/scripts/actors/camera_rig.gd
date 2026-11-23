class_name CameraRig
extends Node3D
## Comfortable third-person orbit. The camera is a plain offset rig, not a
## spring arm: on a wide ramp a colliding spring arm collapses onto the player's
## head, which is worse than a rare clip. A light raycast keeps it out of walls.

@export var distance := 9.5
@export var height := 2.5
@export var min_pitch := -1.0
@export var max_pitch := 0.15

var target: Node3D
var yaw := 0.0
var pitch := -0.33
var camera: Camera3D
var _holder: Node3D
var _shake := 0.0
var _shake_time := 0.0
var _current_distance := 8.5


func _ready() -> void:
	top_level = true
	_holder = Node3D.new()
	_holder.position = Vector3(0, 0, distance)
	add_child(_holder)
	camera = Camera3D.new()
	camera.fov = 55.0
	camera.current = true
	_holder.add_child(camera)
	process_priority = 10


func set_target(node: Node3D) -> void:
	target = node
	if target != null:
		global_position = target.global_position + Vector3.UP * height
		rotation = Vector3(pitch, yaw, 0)


func _process(delta: float) -> void:
	if target == null:
		return
	var look := InputRouter.consume_camera_delta()
	if look.length_squared() > 0.0:
		yaw -= look.x * 0.0028
		pitch = clampf(pitch - look.y * 0.0022, min_pitch, max_pitch)
	rotation = Vector3(pitch, yaw, 0)
	var desired := target.global_position + Vector3.UP * height
	global_position = global_position.lerp(desired, clampf(delta * 12.0, 0.0, 1.0))
	var want := distance
	var space := get_world_3d().direct_space_state
	var origin := global_position
	var cam_desired := global_transform * Vector3(0, 0, distance)
	var query := PhysicsRayQueryParameters3D.create(origin, cam_desired, 1 | 4)
	if target is CollisionObject3D:
		query.exclude = [(target as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		want = maxf(1.6, origin.distance_to(hit.get("position", cam_desired)) - 0.25)
	_current_distance = lerpf(_current_distance, want, clampf(delta * 10.0, 0.0, 1.0))
	_holder.position.z = _current_distance
	if _shake > 0.0:
		_shake_time += delta * 42.0
		camera.h_offset = sin(_shake_time) * _shake * 0.06
		camera.v_offset = cos(_shake_time * 1.3) * _shake * 0.045
		_shake = maxf(0.0, _shake - delta * 2.4)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func shake(amount: float) -> void:
	if Settings.reduced_motion:
		return
	_shake = minf(_shake + amount * Settings.camera_shake, 1.0)


func forward() -> Vector3:
	return -global_transform.basis.z


func right() -> Vector3:
	return global_transform.basis.x
