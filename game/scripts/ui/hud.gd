class_name HUD
extends CanvasLayer
## A pen sketch over the world. Health appears when it matters, prompts are
## verbs, and nothing pulses for attention.

var _region_label: Label
var _prompt: Label
var _notice: Label
var _health: ProgressBar
var _breath: ProgressBar
var _player: Player
var _notice_time := 0.0
var _prompt_time := 0.0
var _boss_panel: Control
var _boss_bar: ProgressBar
var _boss_label: Label


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Arial"])

	var safe := UITheme.safe_rect(get_viewport())
	_region_label = Label.new()
	_region_label.position = safe.position + Vector2(20, 18)
	_region_label.add_theme_font_override("font", font)
	_region_label.add_theme_font_size_override("font_size", 18)
	_region_label.add_theme_color_override("font_color", Color("#e6dfce"))
	_region_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_region_label.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(_region_label)

	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-180, -92)
	_prompt.custom_minimum_size = Vector2(360, 30)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_override("font", font)
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.add_theme_color_override("font_color", Color("#ffd9a0"))
	_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_prompt.add_theme_constant_override("shadow_offset_y", 1)
	_prompt.visible = false
	root.add_child(_prompt)

	_notice = Label.new()
	_notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notice.position = Vector2(-260, 92)
	_notice.custom_minimum_size = Vector2(520, 40)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.add_theme_font_override("font", font)
	_notice.add_theme_font_size_override("font_size", 17)
	_notice.add_theme_color_override("font_color", Color("#e6dfce"))
	_notice.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_notice.add_theme_constant_override("shadow_offset_y", 1)
	_notice.visible = false
	root.add_child(_notice)

	var safe2 := UITheme.safe_rect(get_viewport())
	_health = _make_bar(root, font, Color("#c9613c"), Vector2(safe2.position.x + 20, safe2.position.y + safe2.size.y - 86))
	_breath = _make_bar(root, font, Color("#9fd8b9"), Vector2(safe2.position.x + 20, safe2.position.y + safe2.size.y - 64))
	_health.visible = false
	_breath.visible = false
	_breath.value = 100

	Events.interaction_available.connect(_on_prompt)
	Events.notification.connect(_on_notice)
	Events.player_health_changed.connect(_on_health)
	Events.region_ready.connect(_on_region)
	Events.dialogue_started.connect(func(_id): _prompt.visible = false)
	_build_boss_bar(root, font)
	Events.boss_started.connect(_on_boss_started)
	Events.boss_health_changed.connect(_on_boss_health)
	Events.boss_ended.connect(_on_boss_ended)


func _build_boss_bar(root: Control, font: SystemFont) -> void:
	_boss_panel = Control.new()
	_boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_panel.position = Vector2(-300, 24)
	_boss_panel.custom_minimum_size = Vector2(600, 54)
	_boss_panel.visible = false
	root.add_child(_boss_panel)
	_boss_label = Label.new()
	_boss_label.position = Vector2(0, 0)
	_boss_label.custom_minimum_size = Vector2(600, 24)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.add_theme_font_override("font", font)
	_boss_label.add_theme_font_size_override("font_size", 16)
	_boss_label.add_theme_color_override("font_color", Color("#ffe0b0"))
	_boss_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_boss_label.add_theme_constant_override("shadow_offset_y", 1)
	_boss_panel.add_child(_boss_label)
	_boss_bar = ProgressBar.new()
	_boss_bar.position = Vector2(0, 28)
	_boss_bar.custom_minimum_size = Vector2(600, 7)
	_boss_bar.show_percentage = false
	_boss_bar.max_value = 100
	_boss_bar.value = 100
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.07, 0.08, 0.7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#c9613c")
	_boss_bar.add_theme_stylebox_override("background", bg)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	_boss_panel.add_child(_boss_bar)


func _on_boss_started(boss_name: String, maximum: float) -> void:
	_boss_panel.visible = true
	_boss_label.text = boss_name.to_upper()
	_boss_bar.max_value = maximum
	_boss_bar.value = maximum


func _on_boss_health(current: float, maximum: float) -> void:
	_boss_bar.max_value = maximum
	_boss_bar.value = current


func _on_boss_ended(_boss_name: String) -> void:
	_boss_panel.visible = false


func _make_bar(root: Control, font: SystemFont, color: Color, offset: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bar.position = offset
	bar.custom_minimum_size = Vector2(220, 8)
	bar.show_percentage = false
	bar.max_value = 100
	bar.value = 100
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.08, 0.09, 0.65)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	root.add_child(bar)
	return bar


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	if _player != null:
		_health.value = _player.health_fraction() * 100.0
		_breath.value = _player.breath_fraction() * 100.0
		_health.self_modulate.a = 1.0 if _player.health_fraction() < 0.999 else 0.0
		_breath.self_modulate.a = 1.0 if _player.breath_fraction() < 0.999 else 0.0
	if _notice_time > 0.0:
		_notice_time -= delta
		if _notice_time <= 0.0:
			_notice.visible = false
	if _prompt_time > 0.0:
		_prompt_time -= delta
		if _prompt_time <= 0.0:
			_prompt.visible = false


func _on_prompt(text: String, visible: bool) -> void:
	_prompt.text = text
	_prompt.visible = visible and not text.is_empty()
	if visible:
		_prompt_time = 3.0


func _on_notice(text: String) -> void:
	_notice.text = text
	_notice.visible = true
	_notice_time = 4.0


func _on_health(current: float, maximum: float) -> void:
	_health.value = (current / maxf(maximum, 1.0)) * 100.0


func _on_region(region_id: String) -> void:
	var data: Dictionary = Game.content.region(region_id)
	_region_label.text = String(data.get("name", region_id.capitalize()))
