class_name TouchControls
extends CanvasLayer
## Touch is a first-class input, not a shrunken mouse. A floating left stick,
## a right-side camera drag, and a thumb-arc action cluster sized for landscape.

var _left: TouchJoystick
var _camera: Control
var _buttons: Array[Control] = []
var _joy_center := Vector2.ZERO
var _joy_knob := Vector2.ZERO
var _joy_active := false
var _joy_touch := -1
var _joy_radius := 78.0
var _visible := false


class TouchButton:
	extends Control
	signal pressed
	signal released
	var label := ""
	var action := ""
	var index := -1
	var held := false
	var radius := 42.0
	var accent := Color("#c9613c")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(radius * 2, radius * 2)
		size = custom_minimum_size
		pivot_offset = size * 0.5

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, radius, Color(0.07, 0.09, 0.10, 0.62 if not held else 0.85))
		draw_arc(c, radius, 0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.9), 2.0)
		var font := ThemeDB.fallback_font
		var fs := 14
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, c + Vector2(-text_size.x * 0.5, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#e6dfce"))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and not held:
				index = event.index
				_press()
			elif not event.pressed and event.index == index:
				_release()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not held:
				_press()
			elif not event.pressed:
				_release()

	func _press() -> void:
		held = true
		InputRouter.press_action(action, 1.0)
		pressed.emit()
		queue_redraw()

	func _release() -> void:
		if not held:
			return
		held = false
		index = -1
		InputRouter.release_action(action)
		released.emit()
		queue_redraw()


func _ready() -> void:
	layer = 15
	_visible = InputRouter.is_touch_mode()
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()
	InputRouter.mode_changed.connect(func(m): _visible = m == InputRouter.Mode.TOUCH; _update_visible())


func _build() -> void:
	_camera = Control.new()
	_camera.name = "CameraDrag"
	_camera.mouse_filter = Control.MOUSE_FILTER_STOP
	_camera.gui_input.connect(_on_camera_input)
	add_child(_camera)

	_left = TouchJoystick.new()
	_left.name = "LeftStick"
	add_child(_left)

	var specs := [
		["Strike", "attack_light", 52.0, Color("#c9613c"), Vector2(-170, -200)],
		["Heavy", "attack_heavy", 42.0, Color("#c9613c"), Vector2(-280, -160)],
		["Dodge", "dodge", 40.0, Color("#9fd8b9"), Vector2(-120, -320)],
		["Use", "interact", 46.0, Color("#d8b25c"), Vector2(-300, -270)],
		["Listen", "listen", 36.0, Color("#9fd8b9"), Vector2(-390, -200)],
		["Toll", "ability_1", 34.0, Color("#d8b25c"), Vector2(-90, -430)],
		["Mark", "ability_2", 34.0, Color("#d8b25c"), Vector2(-180, -420)],
	]
	for spec in specs:
		var b := TouchButton.new()
		b.label = spec[0]
		b.action = spec[1]
		b.radius = spec[2]
		b.accent = spec[3]
		b.position = spec[4]
		add_child(b)
		_buttons.append(b)
	var menu := TouchButton.new()
	menu.label = "Menu"
	menu.action = "pause"
	menu.radius = 26.0
	menu.accent = Color("#a9764a")
	menu.position = Vector2(-80, 20)
	menu.pressed.connect(func(): Events.open_screen.emit("journal", {}))
	add_child(menu)
	_buttons.append(menu)


func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	var safe := UITheme.safe_rect(get_viewport())
	_camera.position = Vector2(safe.position.x + safe.size.x * 0.42, safe.position.y)
	_camera.size = Vector2(safe.size.x * 0.58, safe.size.y)
	_left.position = Vector2(safe.position.x, safe.position.y)
	_left.size = Vector2(safe.size.x * 0.45, safe.size.y)
	_left.set_center(Vector2(safe.position.x + 150, safe.position.y + safe.size.y - 170))
	for b in _buttons:
		if b == null:
			continue
		var rel: Vector2 = b.position
		if b.label == "Menu":
			b.position = Vector2(safe.position.x + safe.size.x - 76, safe.position.y + 26)
		else:
			b.position = Vector2(safe.position.x + safe.size.x + rel.x, safe.position.y + safe.size.y + rel.y)
	_update_visible()


func _update_visible() -> void:
	var show := _visible and not Game.dialogue_active
	for c in get_children():
		if c is Control:
			c.visible = show


func _process(_delta: float) -> void:
	var show := _visible and not Game.dialogue_active
	for c in get_children():
		if c is Control and c.visible != show:
			c.visible = show


func _on_camera_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		InputRouter.add_touch_camera(event.relative)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		InputRouter.add_touch_camera(event.relative)
