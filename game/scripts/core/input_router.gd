extends Node
## One input vocabulary for keyboard/mouse, gamepad, and touch. Gameplay code
## reads actions and this router's analog values; it never checks the platform.

signal mode_changed(new_mode: int)

enum Mode { KEYBOARD_MOUSE, GAMEPAD, TOUCH }

var mode: int = Mode.KEYBOARD_MOUSE
var camera_delta := Vector2.ZERO
var touch_move := Vector2.ZERO
var touch_camera := Vector2.ZERO
var mouse_captured := false
var force_touch := false

var _actions := [
	"move_forward", "move_back", "move_left", "move_right", "sprint",
	"attack_light", "attack_heavy", "dodge", "interact", "ability_1",
	"ability_2", "listen", "pause", "build", "lock_on", "journal", "map",
	"camera_drag", "use_tonic", "companion_command", "ui_back",
]


func _ready() -> void:
	setup_actions()
	if Settings.is_touch() or force_touch:
		_set_mode(Mode.TOUCH)
	process_priority = -100


func setup_actions() -> void:
	_add("move_forward", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add("move_back", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_add("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_add("sprint", [_key(KEY_SHIFT), _button(JOY_BUTTON_LEFT_STICK)])
	_add("attack_light", [_mouse(MOUSE_BUTTON_LEFT), _key(KEY_J), _button(JOY_BUTTON_X)])
	_add("attack_heavy", [_mouse(MOUSE_BUTTON_RIGHT), _key(KEY_K), _button(JOY_BUTTON_Y)])
	_add("dodge", [_key(KEY_SPACE), _button(JOY_BUTTON_B)])
	_add("interact", [_key(KEY_E), _button(JOY_BUTTON_A)])
	_add("ability_1", [_key(KEY_Q), _button(JOY_BUTTON_LEFT_SHOULDER)])
	_add("ability_2", [_key(KEY_R), _button(JOY_BUTTON_RIGHT_SHOULDER)])
	_add("listen", [_key(KEY_F), _button(JOY_BUTTON_DPAD_DOWN)])
	_add("pause", [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)])
	_add("build", [_key(KEY_B), _button(JOY_BUTTON_DPAD_UP)])
	_add("lock_on", [_key(KEY_TAB), _button(JOY_BUTTON_RIGHT_STICK)])
	_add("journal", [_key(KEY_J)])
	_add("map", [_key(KEY_M)])
	_add("camera_drag", [_mouse(MOUSE_BUTTON_MIDDLE), _key(KEY_CTRL)])
	_add("use_tonic", [_key(KEY_1), _button(JOY_BUTTON_DPAD_LEFT)])
	_add("companion_command", [_key(KEY_C), _button(JOY_BUTTON_DPAD_RIGHT)])
	_add("ui_back", [_key(KEY_ESCAPE), _button(JOY_BUTTON_B)])


func _add(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.22)
	for ev in events:
		InputMap.action_add_event(action, ev)


func _key(code: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	return ev


func _mouse(button: int) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	return ev


func _button(index: int) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = index
	return ev


func _axis(axis: int, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	return ev


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_mode(Mode.TOUCH)
		return
	if event is InputEventMouseMotion:
		_set_mode(Mode.KEYBOARD_MOUSE)
		if mouse_captured or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			camera_delta += event.relative * Settings.sensitivity
		return
	if event is InputEventMouseButton:
		_set_mode(Mode.KEYBOARD_MOUSE)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_set_mode(Mode.KEYBOARD_MOUSE)
		return
	if event is InputEventJoypadButton and event.pressed:
		_set_mode(Mode.GAMEPAD)
		return
	if event is InputEventJoypadMotion and absf(event.axis_value) > 0.35:
		_set_mode(Mode.GAMEPAD)


func _process(_delta: float) -> void:
	if mode == Mode.GAMEPAD:
		var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		var ry := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		if absf(rx) > 0.18 or absf(ry) > 0.18:
			camera_delta += Vector2(rx, ry) * 14.0 * Settings.sensitivity
	if not Settings.is_touch() and mode != Mode.TOUCH:
		if Input.is_action_just_pressed("journal"):
			Events.notification.emit("Journal — open it from the pause ring.")
		if Input.is_action_just_pressed("map"):
			Events.notification.emit("Map — open it from the pause ring.")


func _set_mode(new_mode: int) -> void:
	if force_touch and new_mode != Mode.TOUCH:
		return
	if new_mode == mode:
		return
	mode = new_mode
	mode_changed.emit(mode)


func set_touch_forced(value: bool) -> void:
	force_touch = value
	if value:
		_set_mode(Mode.TOUCH)


func is_touch_mode() -> bool:
	return mode == Mode.TOUCH


func get_move_vector() -> Vector2:
	# Convention: +Y means forward, +X means right. Godot's get_vector gives
	# +Y for "move_back", so flip it once here for every input mode.
	if mode == Mode.TOUCH and touch_move.length() > 0.08:
		return touch_move.limit_length(1.0)
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return Vector2(v.x, -v.y)


func consume_camera_delta() -> Vector2:
	var out := camera_delta + touch_camera
	camera_delta = Vector2.ZERO
	touch_camera = Vector2.ZERO
	return out


func set_touch_move(value: Vector2) -> void:
	touch_move = value
	_set_mode(Mode.TOUCH)


func add_touch_camera(value: Vector2) -> void:
	touch_camera += value
	_set_mode(Mode.TOUCH)


func press_action(action: String, strength: float = 1.0) -> void:
	Input.action_press(action, strength)


func release_action(action: String) -> void:
	Input.action_release(action)


func rumble(weak: float = 0.4, strong: float = 0.2, duration: float = 0.15) -> void:
	if mode != Mode.GAMEPAD:
		return
	var devices := Input.get_connected_joypads()
	if devices.is_empty():
		return
	Input.start_joy_vibration(devices[0], weak, strong, duration)


func descriptor() -> String:
	match mode:
		Mode.GAMEPAD:
			return "Gamepad"
		Mode.TOUCH:
			return "Touch"
		_:
			return "Keyboard & mouse"
