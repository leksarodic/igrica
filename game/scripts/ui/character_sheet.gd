class_name CharacterSheet
extends CanvasLayer
## A short, warm character page. No classes, no stat traps: choose an ear and a
## coat, and the valley will teach you the rest.

var _callback: Callable
var _root: Control
var _name: LineEdit
var _pronouns: OptionButton
var _ear: OptionButton
var _palette: OptionButton


func begin(callback: Callable) -> void:
	_callback = callback
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.035, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-330, -280)
	panel.custom_minimum_size = Vector2(660, 560)
	panel.add_theme_stylebox_override("panel", UITheme.paper_style(0.98, 30))
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UITheme.eyebrow("A NEW LISTENER"))
	box.add_child(UITheme.heading("Who came down the road?", 30))
	box.add_child(UITheme.body("The valley does not ask for a destiny. It asks for a name, a way to be addressed, and an ear.", 16, UITheme.INK_SOFT))
	box.add_child(UITheme.rule(220))
	box.add_child(UITheme.body("Name", 14, UITheme.INK_SOFT))
	_name = LineEdit.new()
	_name.text = "Listener"
	_name.max_length = 24
	_name.custom_minimum_size = Vector2(0, 38)
	_name.add_theme_font_override("font", UITheme.serif())
	_name.add_theme_font_size_override("font_size", 20)
	box.add_child(_name)
	UITheme.style_input(_name)
	box.add_child(UITheme.body("Pronouns", 14, UITheme.INK_SOFT))
	_pronouns = OptionButton.new()
	for p in ["they / them", "she / her", "he / him"]:
		_pronouns.add_item(p)
	box.add_child(_pronouns)
	UITheme.style_input(_pronouns)
	box.add_child(UITheme.body("Ear", 14, UITheme.INK_SOFT))
	_ear = OptionButton.new()
	_ear.add_item("Reed Ear — more breath")
	_ear.add_item("Stone Ear — more vigour")
	_ear.add_item("Bell Ear — stronger chords")
	box.add_child(_ear)
	UITheme.style_input(_ear)
	box.add_child(UITheme.body("Coat", 14, UITheme.INK_SOFT))
	_palette = OptionButton.new()
	for p in ["Slate and copper", "Reed green and gold", "Quarry brown and ember", "Bone and ink", "Plum and mint", "Ash and rust"]:
		_palette.add_item(p)
	box.add_child(_palette)
	UITheme.style_input(_palette)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var back := UITheme.button("Back")
	back.custom_minimum_size = Vector2(120, 42)
	back.pressed.connect(func(): queue_free())
	row.add_child(back)
	var start := UITheme.button("Come down the road")
	start.custom_minimum_size = Vector2(260, 42)
	start.pressed.connect(_on_start)
	row.add_child(start)
	start.grab_focus()


func _on_start() -> void:
	var ear: String = ["reed", "stone", "bell"][_ear.selected]
	var pronouns: String = ["they", "she", "he"][_pronouns.selected]
	var data := {
		"name": _name.text.strip_edges(),
		"pronouns": pronouns,
		"ear": ear,
		"palette": _palette.selected,
	}
	queue_free()
	if _callback.is_valid():
		_callback.call(data)
