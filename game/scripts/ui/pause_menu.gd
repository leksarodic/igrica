class_name PauseMenu
extends CanvasLayer
## The pause ring, rendered as a field-notebook spread. Every screen is reachable
## with mouse, keyboard, gamepad focus, or touch. Nothing has a badge.

var _root: Control
var _dim: ColorRect
var _panel: PanelContainer
var _sidebar: VBoxContainer
var _content: ScrollContainer
var _content_box: VBoxContainer
var _open := false
var _current := ""


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.03, 0.035, 0.72)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	var safe := UITheme.safe_rect(get_viewport())
	var panel_size := Vector2(minf(1120.0, safe.size.x - 80.0), minf(720.0, safe.size.y - 80.0))
	_panel.custom_minimum_size = panel_size
	_panel.position = -panel_size * 0.5
	_panel.add_theme_stylebox_override("panel", UITheme.paper_style(0.98, 24))
	_root.add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	_panel.add_child(row)
	_sidebar = VBoxContainer.new()
	_sidebar.custom_minimum_size = Vector2(220, 0)
	_sidebar.add_theme_constant_override("separation", 4)
	row.add_child(_sidebar)
	var divider := ColorRect.new()
	divider.color = Color(UITheme.COPPER.r, UITheme.COPPER.g, UITheme.COPPER.b, 0.35)
	divider.custom_minimum_size = Vector2(1, 0)
	row.add_child(divider)
	_content = ScrollContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_content)
	_content_box = VBoxContainer.new()
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 10)
	_content.add_child(_content_box)
	_build_sidebar()
	Events.open_screen.connect(_on_open_screen)
	Events.conflict_detected.connect(func(_info): if _open: _show_save_sync())


func _build_sidebar() -> void:
	var title := UITheme.heading("The Long Note", 24)
	_sidebar.add_child(title)
	_sidebar.add_child(UITheme.rule(160))
	_add_sidebar("Continue", func(): close())
	_add_sidebar("Journal", func(): _show_journal())
	_add_sidebar("Inventory", func(): _show_inventory())
	_add_sidebar("Craft", func(): _show_craft())
	_add_sidebar("Build", func(): _show_build())
	_add_sidebar("Skills", func(): _show_skills())
	_add_sidebar("Party", func(): _show_party())
	_add_sidebar("Map", func(): _show_map())
	_add_sidebar("Settings", func(): _show_settings())
	_add_sidebar("Save & Sync", func(): _show_save_sync())
	_add_sidebar("Leave to Title", func(): _leave_to_title())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sidebar.add_child(spacer)
	var hint := UITheme.body("Esc or Start closes. The valley will wait.", 12, UITheme.INK_SOFT)
	_sidebar.add_child(hint)


func _add_sidebar(text: String, callback: Callable) -> void:
	var b := UITheme.button(text)
	b.custom_minimum_size = Vector2(210, 36)
	b.pressed.connect(callback)
	_sidebar.add_child(b)


func _on_open_screen(screen_id: String, _context: Dictionary) -> void:
	if screen_id.is_empty():
		return
	open()
	match screen_id:
		"craft": _show_craft()
		"build": _show_build()
		"inventory": _show_inventory()
		"journal": _show_journal()
		"settings": _show_settings()
		"map": _show_map()
		"skills": _show_skills()
		"party": _show_party()
		"save": _show_save_sync()
		_: _show_journal()


func open() -> void:
	if _open:
		return
	_open = true
	_root.visible = true
	get_tree().paused = true
	Game.paused = true
	AudioDirector.play_ui("menu_open")
	_show_journal()
	if _sidebar.get_child_count() > 2:
		(_sidebar.get_child(2) as Button).grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	get_tree().paused = false
	Game.paused = false
	Game.save_current(Game.current_slot, false)
	AudioDirector.play_ui("ui_back")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_back"):
		if Game.dialogue_active:
			return
		if _open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func _clear() -> void:
	for child in _content_box.get_children():
		child.free()


func _screen_title(text: String, subtitle: String = "") -> void:
	_content_box.add_child(UITheme.eyebrow("FIELD NOTEBOOK"))
	_content_box.add_child(UITheme.heading(text, 30))
	if not subtitle.is_empty():
		_content_box.add_child(UITheme.body(subtitle, 15, UITheme.INK_SOFT))
	_content_box.add_child(UITheme.rule(240))
	_content.scroll_vertical = 0


func _show_journal() -> void:
	_current = "journal"
	_clear()
	_screen_title("Journal", "What you know, not what to do next.")
	for qid in ["main_01", "main_02", "side_pip", "side_ferry"]:
		var q: Dictionary = Game.content.quest(qid)
		if q.is_empty():
			continue
		var qs: Dictionary = Game.state.quest(qid)
		var stage := int(qs.get("stage", -1))
		var state := String(qs.get("state", "active"))
		if stage < 0 and qid.begins_with("side"):
			continue
		_content_box.add_child(UITheme.heading(String(q.get("title", qid)), 21))
		var stages: Array = q.get("stages", [])
		var line := "Not begun."
		if stage >= 0 and stage < stages.size():
			line = String(stages[stage].get("text", ""))
		if state == "done":
			line = "Complete. " + line
		_content_box.add_child(UITheme.body(line, 16))
		_content_box.add_child(UITheme.rule(180))
	var lore_count: int = Game.state.journal.get("lore", {}).size()
	var echo_count: int = Game.state.journal.get("echoes", {}).size()
	_content_box.add_child(UITheme.body("Echoes: %d   ·   Lore: %d   ·   Attunement %d" % [echo_count, lore_count, int(Game.state.player.get("attunement", 1))], 15, UITheme.INK_SOFT))
	if lore_count > 0:
		_content_box.add_child(UITheme.rule(220))
		_content_box.add_child(UITheme.eyebrow("WHAT YOU HAVE LEARNED"))
		for lid in Game.state.journal.get("lore", {}).keys():
			var entry: Dictionary = Game.content.lore_entry(String(lid))
			if entry.is_empty():
				continue
			_content_box.add_child(UITheme.heading(String(entry.get("title", String(lid))), 19))
			_content_box.add_child(UITheme.body(String(entry.get("text", "")), 15))
			_content_box.add_child(UITheme.rule(160))
	var hints := UITheme.button("Ask for a nudge")
	hints.pressed.connect(func(): _show_hints())
	_content_box.add_child(hints)


func _show_hints() -> void:
	_content_box.add_child(UITheme.body(_hint_for_current_quest(), 16, UITheme.INK_SOFT))


func _hint_for_current_quest() -> String:
	var stage := Game.state.quest_stage("main_02")
	if Game.state.quest_stage("main_01") < 2:
		return "Walk to the Listening House on the third terrace and speak with Pell. Wren is waiting by the road."
	if stage < 0:
		return "Speak with Sable in the tower yard. She knows what the north channel needs."
	if stage <= 1:
		return "Brannoc can make a resonance fork. You need three copper, two resin, and one humstone shard. Use his bench."
	if stage == 2:
		return "Go to the north channel. Clear the choke with the fork, then read the survey stone."
	if stage == 3:
		return "Three stones stand before the shrine. Low, mid, high. The carving shows the chord."
	if stage == 4:
		return "The shrine mouth is under the reeds at the north end of the pool."
	if stage == 5:
		return "In the nave, three valves on the west wall: open, shut, open."
	if stage == 6:
		return "The echo gallery is on the east side of the nave. Low, high, mid. Listen first."
	if stage == 7:
		return "The window shows the chime order: mid, high, low. Ring them, then face the Stag."
	if stage == 8:
		return "Take the Choir Chime from the altar and choose where it belongs."
	return "The valley is listening. Try the place that feels wrong."


func _show_inventory() -> void:
	_current = "inventory"
	_clear()
	_screen_title("Inventory", "Everything you carry has a reason.")
	var inv: Dictionary = Game.state.inventory()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 4)
	_content_box.add_child(grid)
	for item_id in inv.keys():
		var count := int(inv[item_id])
		var def: Dictionary = Game.content.item(String(item_id))
		if def.is_empty():
			continue
		var label := "%s  ×%d" % [String(def.get("name", item_id)), count]
		var b := UITheme.button(label)
		b.custom_minimum_size = Vector2(360, 34)
		b.pressed.connect(func(): _show_item(String(item_id)))
		grid.add_child(b)
	_content_box.add_child(UITheme.rule(240))
	var eq := Game.state.equipment()
	var lines := "Weapon: %s\nOffhand: %s\nCloak: %s\nCharms: %s, %s" % [
		String(Game.content.item(String(eq.get("weapon", ""))).get("name", "—")),
		String(Game.content.item(String(eq.get("offhand", ""))).get("name", "—")),
		String(Game.content.item(String(eq.get("cloak", ""))).get("name", "—")),
		String(Game.content.item(String(eq.get("charm1", ""))).get("name", "—")),
		String(Game.content.item(String(eq.get("charm2", ""))).get("name", "—")),
	]
	_content_box.add_child(UITheme.body(lines, 16))


func _show_item(item_id: String) -> void:
	var def: Dictionary = Game.content.item(item_id)
	if def.is_empty():
		return
	_clear()
	_screen_title(String(def.get("name", item_id)), String(def.get("description", "")))
	var kind := String(def.get("kind", "material"))
	_content_box.add_child(UITheme.body("Kind: %s   ·   Value: %d marks" % [kind.capitalize(), int(def.get("value", 0))], 15, UITheme.INK_SOFT))
	if kind in ["weapon", "offhand", "cloak", "charm", "tool"]:
		var slot := _slot_for(kind)
		var b := UITheme.button("Equip")
		b.pressed.connect(func():
			Game.state.equip(slot, item_id)
			Game.state.recompute_stats(Game.content.items)
			AudioDirector.play_ui("ui_confirm")
			_show_inventory()
		)
		_content_box.add_child(b)
	elif kind == "consumable":
		var b := UITheme.button("Use")
		b.pressed.connect(func():
			if Game.state.remove_item(item_id, 1):
				var effect: Dictionary = def.get("effect", {})
				Game.state.heal(float(effect.get("heal", 0.0)))
				var player := get_tree().get_first_node_in_group("player")
				if player != null and player.has_method("heal"):
					player.heal(float(effect.get("heal", 0.0)))
				AudioDirector.play_ui("ui_confirm")
				_show_inventory()
		)
		_content_box.add_child(b)
	var back := UITheme.button("Back")
	back.pressed.connect(_show_inventory)
	_content_box.add_child(back)


func _slot_for(kind: String) -> String:
	match kind:
		"weapon": return "weapon"
		"offhand": return "offhand"
		"cloak": return "cloak"
		"charm":
			var eq := Game.state.equipment()
			return "charm1" if String(eq.get("charm1", "")).is_empty() else "charm2"
		"tool": return "tool"
	return "weapon"


func _show_craft() -> void:
	_current = "craft"
	_clear()
	_screen_title("Workbench", "Materials, a pattern, and a reason.")
	for rid in Game.content.recipes_known(Game.state):
		var r: Dictionary = Game.content.recipe(rid)
		var out := String(r.get("output", ""))
		var name := String(Game.content.item(out).get("name", out))
		if out == "upgrade_weapon":
			name = "Reinforce weapon"
		elif out == "upgrade_cloak":
			name = "Repair cloak"
		var cost_text := ""
		for mat in r.get("cost", {}).keys():
			var mat_name := String(Game.content.item(String(mat)).get("name", String(mat).replace("_", " ")))
			cost_text += "%s %d/%d   " % [mat_name, Game.state.item_count(String(mat)), int(r["cost"][mat])]
		var line := "%s — %s" % [name, cost_text.strip_edges()]
		var b := UITheme.button(line)
		var ok := Game.content.can_craft(Game.state, rid)
		b.disabled = not ok
		b.pressed.connect(func(): _craft(rid))
		_content_box.add_child(b)


func _craft(rid: String) -> void:
	if not Game.content.can_craft(Game.state, rid):
		return
	var r: Dictionary = Game.content.recipe(rid)
	for mat in r.get("cost", {}).keys():
		Game.state.remove_item(String(mat), int(r["cost"][mat]))
	var out := String(r.get("output", ""))
	if out == "resonance_fork":
		Game.state.add_item("resonance_fork", 1)
		Game.state.set_quest("main_02", 2)
		Events.notification.emit("The fork rings once and settles. It knows the chord.")
	elif out in ["upgrade_weapon", "upgrade_cloak"]:
		var key := out
		var upgrades: Dictionary = Game.state.player.get("upgrades", {})
		upgrades[key] = int(upgrades.get(key, 0)) + 1
		Game.state.player["upgrades"] = upgrades
		Events.notification.emit("The work is sound. It will hold longer now.")
	else:
		Game.state.add_item(out, int(r.get("count", 1)))
		if out == "resonator_kit":
			Game.state.set_flag("recipe_%s" % rid, true)
	Game.state.stats["crafted"] = int(Game.state.stats.get("crafted", 0)) + 1
	AudioDirector.play_sfx("build", null, -4.0)
	Game.state.touch()
	Game.autosave()
	_show_craft()


func _show_build() -> void:
	_current = "build"
	_clear()
	_screen_title("Build", "A small vocabulary with a purpose. Structures persist.")
	var any := false
	for bid in Game.content.builds.keys():
		var def: Dictionary = Game.content.build(bid)
		var kit := String(def.get("kit", ""))
		if not Game.state.has_item(kit):
			continue
		any = true
		_content_box.add_child(UITheme.body(String(def.get("name", bid)), 18))
		_content_box.add_child(UITheme.body(String(def.get("description", "")), 14, UITheme.INK_SOFT))
		var b := UITheme.button("Place %s" % String(def.get("name", bid)))
		b.pressed.connect(func():
			var director := get_tree().get_first_node_in_group("world_director")
			if director != null and director.build_system != null:
				close()
				director.build_system.begin(bid)
		)
		_content_box.add_child(b)
		_content_box.add_child(UITheme.rule(180))
	if not any:
		_content_box.add_child(UITheme.body("No build kits yet. Craft one at Brannoc's workbench: lantern post, camp, resonator, reed bridge, or songbed.", 16, UITheme.INK_SOFT))


func _show_skills() -> void:
	_current = "skills"
	_clear()
	_screen_title("Skills", "No build traps. Respec at any lantern.")
	var pts := int(Game.state.player.get("skill_points", 0))
	_content_box.add_child(UITheme.body("Skill points: %d" % pts, 16, UITheme.INK_SOFT))
	for sid in ["hushstep", "toll", "echo_mark"]:
		var s: Dictionary = Game.content.skill(sid)
		var learned: bool = sid in Game.state.player.get("skills", [])
		var b := UITheme.button("%s — %s" % [String(s.get("name", sid)), String(s.get("description", ""))])
		if learned:
			b.text = "✓ " + b.text
		else:
			b.disabled = pts <= 0
			b.pressed.connect(func():
				Game.state.player["skills"].append(sid)
				Game.state.player["skill_points"] = pts - 1
				Game.state.touch()
				Game.autosave()
				_show_skills()
			)
		_content_box.add_child(b)
	_content_box.add_child(UITheme.body("Lantern Song and Quiet Passage exist as effects but are not bound to quick slots in this slice. Counterpoint, Reed Bind, and Second Verse are designed for the full game but are not implemented.", 13, UITheme.INK_SOFT))


func _show_party() -> void:
	_current = "party"
	_clear()
	_screen_title("Party", "Nissa is a person, not a tool. She is also very good with a sling.")
	for cid in ["nissa", "brannoc"]:
		var c: Dictionary = Game.state.companion(cid)
		if not bool(c.get("known", false)):
			continue
		_content_box.add_child(UITheme.heading(cid.capitalize(), 22))
		_content_box.add_child(UITheme.body("Trust %d / 5   ·   %s" % [int(c.get("trust", 0)), "travelling with you" if bool(c.get("active", false)) else "at home"], 15, UITheme.INK_SOFT))
		var follow := UITheme.button("Ask to follow")
		follow.pressed.connect(func():
			Game.state.set_companion_active(cid, true)
			Events.companion_command.emit("follow")
			Game.autosave()
			_show_party()
		)
		_content_box.add_child(follow)
		var wait := UITheme.button("Wait here")
		wait.pressed.connect(func():
			Events.companion_command.emit("wait")
			_show_party()
		)
		_content_box.add_child(wait)
		_content_box.add_child(UITheme.rule(200))


func _show_map() -> void:
	_current = "map"
	_clear()
	_screen_title("Map", "A survey, not a quest arrow.")
	var sketch := MapSketch.new()
	_content_box.add_child(sketch)
	_content_box.add_child(UITheme.body("A survey, not a quest arrow. Lanterns are save points, not teleporters.", 14, UITheme.INK_SOFT))
	_content_box.add_child(UITheme.rule(240))
	for rid in Game.content.regions.keys():
		if rid in ["undercave"]:
			continue
		var r: Dictionary = Game.content.region(rid)
		var visited: bool = bool(Game.state.world.get("regions", {}).get(rid, false))
		var name := String(r.get("name", rid))
		_content_box.add_child(UITheme.body("%s%s" % [name, "" if visited else " — unexplored"], 17, UITheme.INK if visited else UITheme.INK_SOFT))
	_content_box.add_child(UITheme.body("Walk, and the valley becomes legible. No road appears until you have found it.", 14, UITheme.INK_SOFT))

func _show_settings() -> void:
	_current = "settings"
	_clear()
	_screen_title("Settings", "Everything applies immediately. Nothing is hidden.")
	_add_slider("Master volume", Settings.master_volume, func(v): Settings.set_value("master_volume", v))
	_add_slider("Music", Settings.music_volume, func(v): Settings.set_value("music_volume", v))
	_add_slider("Ambience", Settings.ambience_volume, func(v): Settings.set_value("ambience_volume", v))
	_add_slider("Effects", Settings.sfx_volume, func(v): Settings.set_value("sfx_volume", v))
	_add_slider("Text scale", Settings.text_scale * 100.0, func(v):
		Settings.set_value("text_scale", v / 100.0)
		_settings_rebuild()
	, 80.0, 160.0)
	_add_slider("Camera sensitivity", Settings.sensitivity, func(v): Settings.set_value("sensitivity", v), 0.2, 3.0)
	_add_slider("Camera shake", Settings.camera_shake, func(v): Settings.set_value("camera_shake", v), 0.0, 1.0)
	var diff := OptionButton.new()
	diff.add_item("Story")
	diff.add_item("Standard")
	diff.add_item("Challenge")
	diff.selected = ["story", "standard", "challenge"].find(Settings.difficulty)
	diff.item_selected.connect(func(i): Settings.set_value("difficulty", ["story", "standard", "challenge"][i]))
	_content_box.add_child(UITheme.body("Difficulty", 15, UITheme.INK_SOFT))
	_content_box.add_child(diff)
	var quality := OptionButton.new()
	quality.add_item("Low (battery)")
	quality.add_item("Balanced")
	quality.add_item("High")
	quality.selected = ["low", "balanced", "high"].find(Settings.quality)
	quality.item_selected.connect(func(i): Settings.set_value("quality", ["low", "balanced", "high"][i]))
	_content_box.add_child(UITheme.body("Graphics", 15, UITheme.INK_SOFT))
	_content_box.add_child(quality)
	_add_toggle("Subtitles", Settings.subtitles, func(v): Settings.set_value("subtitles", v))
	_add_toggle("Sound captions", Settings.sound_captions, func(v): Settings.set_value("sound_captions", v))
	_add_toggle("Reduced motion", Settings.reduced_motion, func(v): Settings.set_value("reduced_motion", v))
	_add_toggle("Colour-blind pitch marks", Settings.colorblind_marks, func(v): Settings.set_value("colorblind_marks", v))


func _add_slider(label: String, value: float, callback: Callable, minv: float = 0.0, maxv: float = 1.0) -> void:
	_content_box.add_child(UITheme.body(label, 15, UITheme.INK_SOFT))
	var slider := HSlider.new()
	slider.min_value = minv
	slider.max_value = maxv
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size = Vector2(420, 28)
	slider.value_changed.connect(callback)
	_content_box.add_child(slider)


func _add_toggle(label: String, value: bool, callback: Callable) -> void:
	var check := CheckButton.new()
	check.text = label
	check.button_pressed = value
	check.add_theme_font_override("font", UITheme.sans())
	check.toggled.connect(callback)
	_content_box.add_child(check)


func _settings_rebuild() -> void:
	_clear()
	_show_settings()


func _show_save_sync() -> void:
	_current = "save"
	_clear()
	_screen_title("Save & Sync", "The local save is always available. Sync is a copy, never a replacement.")
	var status: Dictionary = Game.sync.status(Game.current_slot)
	_content_box.add_child(UITheme.body("This device: %s" % Game.saves.device_name, 16))
	_content_box.add_child(UITheme.body("Shared folder: %s" % String(status.get("root", "—")), 14, UITheme.INK_SOFT))
	var state_text := String(status.get("state", "local_only")).replace("_", " ")
	_content_box.add_child(UITheme.body("Status: %s" % state_text, 16))
	if String(status.get("state", "")) == "conflict":
		_content_box.add_child(UITheme.body("Another device has newer progress. Nothing has been overwritten.", 15, UITheme.EMBER))
		var keep := UITheme.button("Keep this device's progress")
		keep.pressed.connect(func():
			Game.sync.resolve(Game.current_slot, "keep_local")
			_show_save_sync()
		)
		_content_box.add_child(keep)
		var use := UITheme.button("Use the other device's progress")
		use.pressed.connect(func():
			var r := Game.sync.resolve(Game.current_slot, "use_remote")
			if r.get("ok", false):
				Game.load_game(Game.current_slot)
				_show_save_sync()
		)
		_content_box.add_child(use)
		var both := UITheme.button("Keep both")
		both.pressed.connect(func():
			Game.sync.resolve(Game.current_slot, "keep_both")
			_show_save_sync()
		)
		_content_box.add_child(both)
	var slot_row := HBoxContainer.new()
	var slot_name := LineEdit.new()
	slot_name.text = "journey_%d" % int(Time.get_unix_time_from_system())
	slot_name.custom_minimum_size = Vector2(260, 36)
	UITheme.style_input(slot_name)
	slot_row.add_child(slot_name)
	var save_as := UITheme.button("Save as new journey")
	save_as.pressed.connect(func():
		var slot := Game.saves.sanitize_slot(slot_name.text)
		var r := Game.save_current(slot, false)
		if r.get("ok", false):
			Game.current_slot = slot
			Events.notification.emit("Saved as %s. The valley will wait." % slot)
			_show_save_sync()
	)
	slot_row.add_child(save_as)
	_content_box.add_child(slot_row)
	var save := UITheme.button("Save now")
	save.pressed.connect(func():
		Game.save_current(Game.current_slot, false)
		Events.notification.emit("Saved. The valley will wait.")
		_show_save_sync()
	)
	_content_box.add_child(save)
	var elsewhere := UITheme.button("Save and continue on another device")
	elsewhere.pressed.connect(func():
		var result := Game.save_and_continue_elsewhere()
		var msg := String(result.get("message", "Saved."))
		if not result.get("ok", true):
			msg = String(result.get("reason", "Save failed."))
		Events.notification.emit(msg)
		_show_save_sync()
	)
	_content_box.add_child(elsewhere)
	var export_btn := UITheme.button("Export journey…")
	export_btn.pressed.connect(func(): _file_dialog(true))
	_content_box.add_child(export_btn)
	var import_btn := UITheme.button("Import journey…")
	import_btn.pressed.connect(func(): _file_dialog(false))
	_content_box.add_child(import_btn)
	var sync_now := UITheme.button("Sync now")
	sync_now.pressed.connect(func():
		var r := Game.sync_now()
		Events.notification.emit("Sync checked." if r.get("ok", false) else "No shared folder available; the local save is safe.")
		_show_save_sync()
	)
	_content_box.add_child(sync_now)
	_content_box.add_child(UITheme.rule(240))
	_content_box.add_child(UITheme.heading("Journeys", 22))
	for entry in Game.saves.list_slots():
		if entry.get("corrupt", false):
			_content_box.add_child(UITheme.body("A damaged save was preserved: %s" % String(entry.get("slot", "?")), 14, UITheme.EMBER))
			continue
		var slot := String(entry.get("slot", ""))
		var line := "%s — %s · %d min · %s" % [String(entry.get("name", "Listener")), String(entry.get("region", "")), int(float(entry.get("playtime_seconds", 0.0)) / 60.0), String(entry.get("modified_utc", ""))]
		_content_box.add_child(UITheme.body(line, 15))
		if slot != Game.current_slot:
			var load := UITheme.button("Load this journey")
			load.pressed.connect(func():
				var main := get_tree().get_first_node_in_group("main")
				if main != null and main.has_method("start_from_save"):
					close()
					main.call_deferred("start_from_save", slot)
			)
			_content_box.add_child(load)


func _file_dialog(save_mode: bool) -> void:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save_mode else FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = PackedStringArray(["*.longnote ; Long Note journey"])
	dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	dialog.current_file = "longnote_%s.longnote" % Game.current_slot
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)
	dialog.file_selected.connect(func(path):
		if save_mode:
			var result := Game.saves.export_package(Game.current_slot, path)
			Events.notification.emit("Journey exported." if result.get("ok", false) else String(result.get("reason", "Export failed.")))
		else:
			var slot := "imported_%d" % int(Time.get_unix_time_from_system())
			var result := Game.saves.import_package(path, slot)
			if result.get("ok", false):
				Events.notification.emit("Journey imported as %s." % slot)
				_show_save_sync()
			else:
				Events.notification.emit(String(result.get("reason", "Import failed.")))
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())


func _leave_to_title() -> void:
	close()
	get_tree().paused = false
	Game.running = false
	get_tree().reload_current_scene()
