class_name TouchJoystick
extends Control
## Floating left stick: it appears where the thumb lands, so the player never
## chases a fixed circle.

var center := Vector2(140, 500)
var knob := Vector2(140, 500)
var radius := 78.0
var active := false
var touch_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(false)


func set_center(value: Vector2) -> void:
	center = value
	knob = value
	queue_redraw()


func _draw() -> void:
	draw_circle(center, radius, Color(0.07, 0.09, 0.10, 0.35))
	draw_arc(center, radius, 0, TAU, 40, Color(0.66, 0.72, 0.68, 0.55), 2.0)
	draw_circle(knob, 28.0, Color(0.90, 0.87, 0.80, 0.55))
	draw_arc(knob, 28.0, 0, TAU, 24, Color(0.66, 0.46, 0.29, 0.8), 2.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not active:
			active = true
			touch_index = event.index
			center = event.position
			knob = event.position
			InputRouter.set_touch_move(Vector2.ZERO)
			queue_redraw()
		elif not event.pressed and event.index == touch_index:
			_end_touch()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active = true
			center = event.position
			knob = event.position
			queue_redraw()
		else:
			_end_touch()
	elif event is InputEventMouseMotion and active:
		_update(event.position)


func _update(pos: Vector2) -> void:
	var delta := pos - center
	delta = delta.limit_length(radius)
	knob = center + delta
	var v := delta / radius
	InputRouter.set_touch_move(Vector2(v.x, -v.y))
	queue_redraw()


func _end_touch() -> void:
	active = false
	touch_index = -1
	InputRouter.set_touch_move(Vector2.ZERO)
	queue_redraw()
