extends Node3D
## Application shell. The title screen is a real view of the valley, and starting
## a journey swaps it for the playable world without a loading-screen theatre.

var _world: WorldDirector
var _hud: HUD
var _dialogue: DialogueBox
var _pause: PauseMenu
var _sheet: CharacterSheet
var _capture_path := ""
var _start_region := ""
var _start_spawn := "arrival"
var _start_slot := ""
var _started := false
var _overview := false
var _auto_dialogue := ""
var _auto_screen := ""
var _show_sheet := false
var _ending_choice := ""
var _give_kits := false
var _auto_build := ""
var _benchmark := false
var _selftest_move := false


func _ready() -> void:
	add_to_group("main")
	_parse_args()
	if not _start_region.is_empty():
		if _start_region == "continue":
			var newest := Game.newest_save()
			if not newest.is_empty():
				Game.load_game(String(newest["slot"]))
				_start_world(Game.state.last_region, Game.state.last_spawn)
			else:
				_build_diorama()
				_build_title()
		else:
			Game.new_game({"name": "Listener", "pronouns": "they", "palette": 0, "ear": "reed"})
			_start_world(_start_region, _start_spawn)
	else:
		_build_diorama()
		_build_title()
	if _show_sheet:
		_on_new()
	if not _capture_path.is_empty():
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(_capture_path)
		print("Captured ", _capture_path)
		get_tree().quit(0)


func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		match args[i]:
			"--capture":
				if i + 1 < args.size():
					_capture_path = args[i + 1]
			"--world":
				if i + 1 < args.size():
					_start_region = args[i + 1]
			"--spawn":
				if i + 1 < args.size():
					_start_spawn = args[i + 1]
			"--slot":
				if i + 1 < args.size():
					_start_slot = args[i + 1]
			"--overview":
				_overview = true
			"--touch":
				InputRouter.set_touch_forced(true)
			"--dialogue":
				if i + 1 < args.size():
					_auto_dialogue = args[i + 1]
			"--screen":
				if i + 1 < args.size():
					_auto_screen = args[i + 1]
			"--sheet":
				_show_sheet = true
			"--ending":
				if i + 1 < args.size():
					_ending_choice = args[i + 1]
			"--kits":
				_give_kits = true
			"--build":
				if i + 1 < args.size():
					_auto_build = args[i + 1]
			"--benchmark":
				_benchmark = true
			"--selftest-move":
				_selftest_move = true


func _start_world(region_id: String, spawn_id: String) -> void:
	if _started:
		return
	_started = true
	for child in get_children():
		child.free()
	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_hud = HUD.new()
	add_child(_hud)
	_world = WorldDirector.new()
	add_child(_world)
	_world.build(region_id, spawn_id)
	if _give_kits and Game.state != null:
		for kit in ["lantern_post_kit", "camp_kit", "resonator_kit", "reed_bridge_kit", "songbed_kit"]:
			Game.state.add_item(kit, 1)
	var grade := PostProcess.new()
	add_child(grade)
	_pause = PauseMenu.new()
	add_child(_pause)
	var ending := EndingScreen.new()
	add_child(ending)
	var touch := TouchControls.new()
	add_child(touch)
	AudioDirector.set_music(String(Game.content.region(region_id).get("music", "surface")))
	# Keep the cursor available for menus; the camera uses right-drag.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not _auto_build.is_empty():
		await get_tree().process_frame
		if _world.build_system != null:
			_world.build_system.begin(_auto_build)
		await get_tree().process_frame
	if not _auto_dialogue.is_empty():
		await get_tree().process_frame
		Events.dialogue_started.emit(_auto_dialogue)
	if not _auto_screen.is_empty():
		await get_tree().process_frame
		Events.open_screen.emit(_auto_screen, {})
	if not _ending_choice.is_empty():
		await get_tree().process_frame
		Game.state.set_quest_choice("main_02", "outcome", _ending_choice)
		Game.state.set_quest("main_02", 8, "done")
		Events.dialogue_finished.emit("stag_choice", "")
	if _selftest_move and _world != null and _world.player != null:
		await get_tree().create_timer(0.5).timeout
		var p0 := _world.player.global_position
		var c0 := _world.player.rig.camera.global_position
		print("PRETEST paused=", get_tree().paused, " mode=", InputRouter.mode, " action=", Input.is_action_pressed("move_forward"), " vec=", InputRouter.get_move_vector(), " pos=", p0, " vel=", _world.player.velocity, " floor=", _world.player.is_on_floor(), " dialogue=", Game.dialogue_active, " build=", Game.build_mode)
		var space := _world.get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(Vector3(p0.x, p0.y + 10.0, p0.z), Vector3(p0.x, p0.y - 10.0, p0.z), 1 | 4)
		q.exclude = [_world.player.get_rid()]
		var hit := space.intersect_ray(q)
		print("RAY ", hit)
		print("COLLISIONS ", _world.player.get_slide_collision_count())
		for ci in _world.player.get_slide_collision_count():
			var col := _world.player.get_slide_collision(ci)
			print("  COL ", ci, " ", col.get_collider(), " normal=", col.get_normal())
		Input.action_press("move_forward")
		await get_tree().create_timer(0.2).timeout
		print("MIDTEST action=", Input.is_action_pressed("move_forward"), " vec=", InputRouter.get_move_vector(), " vel=", _world.player.velocity, " pos=", _world.player.global_position)
		await get_tree().create_timer(1.0).timeout
		Input.action_release("move_forward")
		await get_tree().process_frame
		var p1 := _world.player.global_position
		var c1 := _world.player.rig.camera.global_position
		print("MOVETEST player_delta=", p1 - p0, " camera_delta=", c1 - c0, " fps=", Engine.get_frames_per_second())
		get_tree().quit(0)
	if _benchmark:
		await get_tree().create_timer(4.0).timeout
		print("BENCH fps=", Engine.get_frames_per_second(),
			" draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			" primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			" memory_mb=", Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
		get_tree().quit(0)
	if _overview:
		var cam := Camera3D.new()
		cam.fov = 60
		add_child(cam)
		cam.look_at_from_position(Vector3(0, 80, 70), Vector3(0, 0, -10), Vector3.UP)
		cam.current = true


func _build_diorama() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#2e3d42")
	sky_mat.sky_horizon_color = Color("#d8a45c")
	sky_mat.ground_bottom_color = Color("#1d2526")
	sky_mat.ground_horizon_color = Color("#6f8b8d")
	sky_mat.sky_energy_multiplier = 0.9
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color("#6f8b8d")
	env.fog_density = 0.012
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-24, -38, 0)
	sun.light_color = Color("#ffd9a0")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#7f8a5a")
	gm.roughness = 0.95
	gm.vertex_color_use_as_albedo = true
	ground.material_override = gm
	add_child(ground)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	shape.position.y = -0.5
	body.add_child(shape)
	add_child(body)

	var tower := MeshInstance3D.new()
	tower.mesh = MeshFactory.tower_mesh()
	tower.position = Vector3(-14, 0, -22)
	add_child(tower)

	# A small static diorama of the town, so the title is a view of the place.
	var houses := [
		[-2.0, -8.0, 0.4, 4.2, 3.4, 2.8], [-24.0, -10.0, 1.2, 5.0, 4.0, 3.2],
		[5.0, -17.0, -0.5, 4.0, 3.2, 2.6], [-9.0, -27.0, 0.2, 5.2, 4.2, 3.0],
		[13.0, -8.0, -1.1, 3.8, 3.0, 2.5],
	]
	for h in houses:
		var mi := MeshInstance3D.new()
		mi.mesh = MeshFactory.house(h[3], h[4], h[5], Palette.OCHRE.lightened(0.06), Palette.ROOF)
		mi.position = Vector3(h[0], 0, h[1])
		mi.rotation.y = h[2]
		add_child(mi)
	for i in 6:
		var t := MeshInstance3D.new()
		t.mesh = MeshFactory.tree_mesh(700 + i)
		var tx := -30.0 + i * 11.0
		var tz := 6.0 - (i % 3) * 14.0
		t.position = Vector3(tx, 0, tz)
		add_child(t)
	for i in 10:
		var r := MeshInstance3D.new()
		r.mesh = MeshFactory.reed_cluster_mesh(800 + i)
		r.position = Vector3(-6.0 + i * 1.4, 0, 4.0 + sin(i) * 1.2)
		add_child(r)
	var water := MeshInstance3D.new()
	var wp := PlaneMesh.new()
	wp.size = Vector2(70, 40)
	water.mesh = wp
	water.position = Vector3(0, 0.02, -42)
	var wshader := load("res://assets/shaders/water.gdshader") as Shader
	if wshader != null:
		var wm := ShaderMaterial.new()
		wm.shader = wshader
		water.material_override = wm
	add_child(water)

	for i in 9:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.28, 2.6, 0.28)
		post.mesh = pm
		post.position = Vector3(-26 + i * 3.4, 1.3, -6 + sin(i * 1.7) * 2.0)
		post.material_override = MeshFactory.flat_material(Color("#5d5b44"))
		add_child(post)

	for i in 5:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(-8 + i * 5, 2.4, -10 + i * 1.6)
		lamp.light_color = Color("#ffc36b")
		lamp.light_energy = 1.4
		lamp.omni_range = 7.0
		add_child(lamp)
		var bulb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.22
		sm.height = 0.44
		bulb.mesh = sm
		bulb.position = lamp.position
		bulb.material_override = MeshFactory.emissive_material(Color("#ffb45c"), 3.0)
		add_child(bulb)

	var camera := Camera3D.new()
	camera.fov = 55
	camera.current = true
	add_child(camera)
	camera.look_at_from_position(Vector3(13, 7.5, 17), Vector3(-4, 3, -6), Vector3.UP)


func _build_title() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)

	var panel := PanelContainer.new()
	panel.position = Vector2(48, 40)
	panel.custom_minimum_size = Vector2(540, 520)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.12, 0.82)
	sb.border_color = Color("#a9764a")
	sb.set_border_width_all(1)
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 32
	sb.content_margin_bottom = 32
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 14)
	panel.add_child(stack)

	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Iowan Old Style", "Palatino", "Georgia", "Times New Roman"])
	font.font_weight = 500
	var display := SystemFont.new()
	display.font_names = font.font_names
	display.font_weight = 700

	var eyebrow := Label.new()
	eyebrow.text = "A CARROW VALE STORY"
	eyebrow.add_theme_font_override("font", font)
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.add_theme_color_override("font_color", Color("#a9764a"))
	stack.add_child(eyebrow)

	var title := Label.new()
	title.text = "The Long Note"
	title.add_theme_font_override("font", display)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("#e6dfce"))
	stack.add_child(title)

	var rule := ColorRect.new()
	rule.color = Color("#a9764a")
	rule.custom_minimum_size = Vector2(120, 1)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	stack.add_child(rule)

	var subtitle := Label.new()
	subtitle.text = "Some songs are kept. Some are let go."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(440, 0)
	subtitle.add_theme_font_override("font", font)
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color("#c9c2af"))
	stack.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	stack.add_child(spacer)

	_add_button(stack, "New Journey", _on_new)
	_add_button(stack, "Continue", _on_continue, Game.has_save())
	_add_button(stack, "Settings", _on_settings)
	_add_button(stack, "Leave", _on_quit)

	var version := Label.new()
	version.text = "Vertical slice 0.1.3   ·   offline, no notifications, no timers"
	version.add_theme_font_override("font", font)
	version.add_theme_font_size_override("font_size", 13)
	version.add_theme_color_override("font_color", Color("#8e9191"))
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.position = Vector2(50, -28)
	root.add_child(version)


func _add_button(parent: Control, text: String, callback: Callable, enabled: bool = true) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 46)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.disabled = not enabled
	btn.add_theme_font_override("font", SystemFont.new())
	btn.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.90, 0.87, 0.80, 0.06 if state == "normal" else 0.13)
		style.border_color = Color("#a9764a")
		style.set_border_width_all(1)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		btn.add_theme_stylebox_override(state, style)
	btn.add_theme_color_override("font_color", Color("#e6dfce"))
	btn.add_theme_color_override("font_hover_color", Color("#ffd9a0"))
	btn.add_theme_color_override("font_disabled_color", Color("#8e9191"))
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _on_new() -> void:
	AudioDirector.play_ui("ui_click")
	_sheet = CharacterSheet.new()
	add_child(_sheet)
	_sheet.begin(func(data):
		AudioDirector.play_ui("ui_confirm")
		Game.new_game(data)
		_start_world("bellhollow", "arrival")
	)


func start_from_save(slot: String) -> void:
	var result := Game.load_game(slot)
	if result.get("ok", false):
		_started = false
		_start_world(Game.state.last_region, Game.state.last_spawn)


func _on_continue() -> void:
	var newest := Game.newest_save()
	if newest.is_empty():
		return
	AudioDirector.play_ui("ui_confirm")
	var result := Game.load_game(String(newest.get("slot", "autosave")))
	if result.get("ok", false):
		_start_world(Game.state.last_region, Game.state.last_spawn)


func _on_settings() -> void:
	AudioDirector.play_ui("ui_click")
	Events.notification.emit("Settings — the full menu arrives in the next build step.")


func _on_quit() -> void:
	AudioDirector.play_ui("ui_back")
	if Game.state != null:
		Game.save_current(Game.current_slot, false)
	get_tree().quit()
