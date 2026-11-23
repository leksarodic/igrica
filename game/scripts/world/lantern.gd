class_name Lantern
extends Interactable
## A safe point. Light it, the map opens a little, the game saves, and nobody
## is told they should come back tomorrow.

var lantern_id := ""
var _light: OmniLight3D
var _flame: MeshInstance3D
var _lit := false


func _ready() -> void:
	super._ready()
	add_to_group("lantern")
	collision_layer = 4
	var post := MeshInstance3D.new()
	post.mesh = MeshFactory.lantern_mesh()
	add_child(post)
	_flame = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	_flame.mesh = sphere
	_flame.position = Vector3(0, 2.0, 0)
	_flame.material_override = MeshFactory.emissive_material(Color("#ffd9a0"), 3.0)
	add_child(_flame)
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 2.05, 0)
	_light.light_color = Color("#ffc36b")
	_light.light_energy = 1.5
	_light.omni_range = 7.5
	_light.shadow_enabled = false
	add_child(_light)
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 2.4, 0.6)
	var cs := CollisionShape3D.new()
	cs.shape = box
	cs.position.y = 1.2
	add_child(cs)
	_lit = false
	_refresh_visual()


func set_lit(value: bool) -> void:
	_lit = value
	_refresh_visual()


func prompt_text() -> String:
	return "Light the lantern" if not _lit else "Rest at the lantern"


func interact(player: Node) -> void:
	_lit = true
	_refresh_visual()
	AudioDirector.play_sfx("save", global_position, -3.0)
	AudioDirector.play_sfx("ui_confirm", null, -12.0)
	if player is Player:
		(player as Player).heal(25.0)
		(player as Player).set_last_lantern(self)
	if Game.state != null:
		Game.state.last_lantern = lantern_id
		Game.state.heal(25.0)
		Game.state.world["lanterns"] = Game.state.world.get("lanterns", {})
		Game.state.world["lanterns"][lantern_id] = true
	Game.save_current(Game.current_slot, false)
	Events.notification.emit("Saved. The valley will wait.")
	Events.open_screen.emit("", {})


func _refresh_visual() -> void:
	if _flame == null or _light == null:
		return
	_flame.visible = _lit
	_light.visible = _lit
	_light.light_energy = 1.8 if _lit else 0.0


func is_lit() -> bool:
	return _lit


func _process(delta: float) -> void:
	if _lit and _flame != null:
		var s := 1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.08
		_flame.scale = Vector3(s, s, s)
		_light.light_energy = 1.7 + sin(Time.get_ticks_msec() * 0.003) * 0.15
