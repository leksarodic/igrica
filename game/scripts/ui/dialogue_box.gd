class_name DialogueBox
extends CanvasLayer
## Dialogue is a conversation, not a cutscene. The world keeps moving, choices
## are full sentences, and nothing is ever timed.

var _root: Control
var _panel: PanelContainer
var _speaker: Label
var _text: Label
var _choices: VBoxContainer
var _continue: Button
var _dialogue_id := ""
var _node: Dictionary = {}
var _nodes: Dictionary = {}
var _active := false
var _choice_buttons: Array[Button] = []


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.position = Vector2(-470, -300)
	_panel.custom_minimum_size = Vector2(940, 250)
	_panel.add_theme_stylebox_override("panel", UITheme.paper_style(0.97))
	_panel.visible = false
	_root.add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	_panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	_speaker = Label.new()
	_speaker.add_theme_font_override("font", UITheme.serif_bold())
	_speaker.add_theme_font_size_override("font_size", UITheme.ts(20))
	_speaker.add_theme_color_override("font_color", UITheme.COPPER)
	stack.add_child(_speaker)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(880, 90)
	_text.add_theme_font_override("font", UITheme.serif())
	_text.add_theme_font_size_override("font_size", UITheme.ts(21))
	_text.add_theme_color_override("font_color", UITheme.INK)
	_text.add_theme_constant_override("line_spacing", 5)
	stack.add_child(_text)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 4)
	stack.add_child(_choices)
	_continue = UITheme.button("Continue")
	_continue.pressed.connect(_advance)
	stack.add_child(_continue)
	Events.dialogue_started.connect(_on_start)


func _on_start(dialogue_id: String) -> void:
	if _active:
		return
	var data: Dictionary = Game.content.dialogue_for(dialogue_id)
	if data.is_empty():
		Events.notification.emit("That conversation is not written yet.")
		return
	_dialogue_id = dialogue_id
	_nodes = data.get("nodes", {})
	_active = true
	Game.dialogue_active = true
	Game.set_paused(false)
	_panel.visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_show_node(String(data.get("start", "")))


func _show_node(node_id: String) -> void:
	if not _nodes.has(node_id):
		_end()
		return
	_node = _nodes[node_id]
	_apply_effects(_node.get("effects", []))
	_speaker.text = String(_node.get("speaker", ""))
	_text.text = String(_node.get("text", ""))
	_clear_choices()
	var choices: Array = _node.get("choices", [])
	var visible_choices: Array = []
	for c in choices:
		if _condition_ok(String(c.get("condition", ""))):
			visible_choices.append(c)
	if not visible_choices.is_empty():
		_continue.visible = false
		for i in visible_choices.size():
			var c: Dictionary = visible_choices[i]
			var b := UITheme.button("%d. %s" % [i + 1, String(c.get("text", ""))])
			b.pressed.connect(func(): _choose(c))
			_choices.add_child(b)
			_choice_buttons.append(b)
		if _choice_buttons.size() > 0:
			_choice_buttons[0].grab_focus()
	elif not bool(_node.get("end", false)) and not String(_node.get("next", "")).is_empty():
		_continue.visible = true
		_continue.text = "Continue"
		_continue.grab_focus()
	else:
		_continue.visible = true
		_continue.text = "Close"
		_continue.grab_focus()
	AudioDirector.play_ui("ui_click")


func _choose(choice: Dictionary) -> void:
	_apply_effects(choice.get("effects", []))
	if Game.state != null:
		Game.state.touch()
	Game.autosave()
	var next := String(choice.get("next", ""))
	if next.is_empty():
		_end()
	else:
		_show_node(next)


func _advance() -> void:
	if not _active:
		return
	if not _node.get("choices", []).is_empty():
		return
	var next := String(_node.get("next", ""))
	if next.is_empty() or bool(_node.get("end", false)):
		_end()
	else:
		_show_node(next)


func _end() -> void:
	_panel.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_active = false
	Game.dialogue_active = false
	Events.dialogue_finished.emit(_dialogue_id, "")
	if Game.state != null:
		Game.state.touch()
	Game.save_current(Game.current_slot, false)


func _clear_choices() -> void:
	for b in _choice_buttons:
		b.queue_free()
	_choice_buttons.clear()


func _condition_ok(condition: String) -> bool:
	if condition.is_empty():
		return true
	if condition.begins_with("!"):
		return not _condition_ok(condition.substr(1))
	if condition.begins_with("flag:"):
		return bool(Game.state.get_flag(condition.substr(5), false))
	if condition.begins_with("quest:"):
		var rest := condition.substr(6)
		var parts := rest.split(">=")
		if parts.size() == 2:
			return Game.state.quest_stage(parts[0]) >= int(parts[1])
		return Game.state.quest_stage(rest) >= 0
	if condition.begins_with("item:"):
		return Game.state.has_item(condition.substr(5))
	if condition.begins_with("trust:"):
		var parts := condition.substr(6).split(">=")
		if parts.size() == 2:
			return int(Game.state.companion(parts[0]).get("trust", 0)) >= int(parts[1])
	return true


func _apply_effects(effects: Array) -> void:
	for e in effects:
		if not (e is Dictionary):
			continue
		match String(e.get("type", "")):
			"flag":
				Game.state.set_flag(String(e.get("key", "")), e.get("value", true))
			"quest":
				Game.state.set_quest(String(e.get("id", "")), int(e.get("stage", 0)))
			"quest_done":
				var qid := String(e.get("id", ""))
				Game.state.set_quest_choice(qid, "outcome", String(e.get("outcome", "")))
				Game.state.set_quest(qid, int(Game.state.quest(qid).get("stage", 0)), "done")
			"item":
				Game.state.add_item(String(e.get("id", "")), int(e.get("count", 1)))
			"trust":
				Game.state.add_trust(String(e.get("id", "")), int(e.get("amount", 1)))
			"lore":
				Game.state.add_lore(String(e.get("id", "")))
			"echo":
				Game.state.add_echo(String(e.get("id", "")))
			"companion":
				Game.state.set_companion_active(String(e.get("id", "")), true)
			"choice":
				Game.state.set_quest_choice(String(e.get("id", "")), "choice", String(e.get("value", "")))
			"marks":
				Game.state.add_marks(int(e.get("amount", 0)))
			"heal":
				Game.state.heal(30.0)
	if not effects.is_empty():
		Events.journal_updated.emit()


func debug_choose(index: int) -> void:
	if index >= 0 and index < _choice_buttons.size():
		_choice_buttons[index].pressed.emit()


func debug_advance() -> void:
	_advance()


func debug_is_open() -> bool:
	return _active


func debug_close() -> void:
	_end()


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx: int = int(event.keycode) - int(KEY_1)
			if idx < _choice_buttons.size():
				_choice_buttons[idx].pressed.emit()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_end()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			if _continue.visible:
				_advance()
				get_viewport().set_input_as_handled()
