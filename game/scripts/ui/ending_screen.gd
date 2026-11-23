class_name EndingScreen
extends CanvasLayer
## A clear ending, not a retention loop. It names what you chose, shows the
## journey's small statistics, and lets you stop or keep exploring.

var _root: Control
var _shown := false


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	Events.dialogue_finished.connect(_on_dialogue_finished)
	Events.ending_reached.connect(func(_id): pass)


func _on_dialogue_finished(_id: String, _choice: String) -> void:
	if _shown:
		return
	if Game.state == null:
		return
	if String(Game.state.quest("main_02").get("state", "")) != "done":
		return
	_shown = true
	_show()


func _show() -> void:
	_root.visible = true
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.035, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-380, -300)
	panel.custom_minimum_size = Vector2(760, 600)
	panel.add_theme_stylebox_override("panel", UITheme.paper_style(0.98, 34))
	_root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var choice := String(Game.state.quest("main_02").get("choices", {}).get("outcome", Game.state.world.get("chime_choice", "keep")))
	var title := "The Chord, Carried"
	var body := "You kept the Choir Chime. It will travel with you, and the channel will have to find another way. The Tenders are disappointed. Nissa is not. The valley is a little less certain and a little more yours."
	match choice:
		"tenders":
			title = "The Note, Kept"
			body = "The Chime returns to the tower. The north channel runs clear by morning, the market fills, and the Reedfolk lose their winter crossing. Sable writes the debt in her slate book. You have bought the valley another season. The question of who pays for the next one is still open."
		"reedfolk":
			title = "The Silence, Welcomed"
			body = "The Chime goes to the Reedfolk, and the water goes where it wants. The market thins, the ferry thrives, and the channels remember how to move. Sable does not congratulate you. Nissa does, and then she makes tea, which is more useful."
		_:
			pass
	box.add_child(UITheme.eyebrow("THE FIRST CHORD"))
	box.add_child(UITheme.heading(title, 34))
	box.add_child(UITheme.rule(220))
	box.add_child(UITheme.body(body, 18))
	box.add_child(UITheme.rule(220))
	var echoes: int = Game.state.journal.get("echoes", {}).size()
	var lore: int = Game.state.journal.get("lore", {}).size()
	var minutes := int(Game.state.playtime_seconds / 60.0)
	box.add_child(UITheme.body("Attunement %d   ·   Echoes %d   ·   Lore %d   ·   %d minutes in the valley" % [int(Game.state.player.get("attunement", 1)), echoes, lore, minutes], 15, UITheme.INK_SOFT))
	box.add_child(UITheme.body("This is the end of the vertical slice. The Quarry Door, Glasswood, the Vault, and the three full endings are designed but not shipped in this build.", 14, UITheme.INK_SOFT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var keep := UITheme.button("Keep exploring")
	keep.pressed.connect(func():
		_root.visible = false
		get_tree().paused = false
		Game.paused = false
	)
	row.add_child(keep)
	var title_btn := UITheme.button("Return to the title")
	title_btn.pressed.connect(func():
		_root.visible = false
		get_tree().paused = false
		Game.paused = false
		Game.running = false
		get_tree().reload_current_scene()
	)
	row.add_child(title_btn)
	AudioDirector.play_sfx("save", null, -4.0)
	Events.ending_reached.emit(choice)
