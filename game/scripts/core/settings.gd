extends Node
## Player preferences. Settings are deliberately plain JSON, saved atomically,
## and applied immediately. Nothing here is a dark pattern: no engagement
## metrics, no experiment buckets, no behavioural tracking.

const PATH := "user://settings.json"
const SCHEMA := 1
const KEYS := [
	"master_volume", "music_volume", "ambience_volume", "sfx_volume", "ui_volume",
	"text_scale", "subtitles", "sound_captions", "high_contrast", "colorblind_marks",
	"reduced_motion", "camera_shake", "aim_assist", "invert_y", "sensitivity",
	"difficulty", "tutorial_prompts", "hint_frequency", "damage_numbers", "touch_scale",
	"left_handed_touch", "quality", "target_fps", "fullscreen", "mono_audio", "combat_flashes"
]

var master_volume := 0.7
var music_volume := 0.55
var ambience_volume := 0.7
var sfx_volume := 0.8
var ui_volume := 0.7

var text_scale := 1.0
var subtitles := true
var sound_captions := true
var high_contrast := false
var colorblind_marks := true
var reduced_motion := false
var camera_shake := 0.35
var aim_assist := 0.5
var invert_y := false
var sensitivity := 1.0
var difficulty := "standard"
var tutorial_prompts := true
var hint_frequency := "normal"
var damage_numbers := false
var touch_scale := 1.0
var left_handed_touch := false
var quality := "balanced"
var target_fps := 60
var fullscreen := false
var mono_audio := false
var combat_flashes := true

var _loaded := false


func _ready() -> void:
	load_settings()
	apply_all()


func load_settings() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PATH):
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	for key in data.keys():
		if KEYS.has(String(key)):
			set(String(key), data[key])
	# Guard against nonsense values from hand-edited files.
	text_scale = clampf(text_scale, 0.8, 1.6)
	sensitivity = clampf(sensitivity, 0.2, 3.0)
	master_volume = clampf(master_volume, 0.0, 1.0)
	music_volume = clampf(music_volume, 0.0, 1.0)
	ambience_volume = clampf(ambience_volume, 0.0, 1.0)
	sfx_volume = clampf(sfx_volume, 0.0, 1.0)
	ui_volume = clampf(ui_volume, 0.0, 1.0)
	target_fps = clampi(target_fps, 30, 120)
	if not ["story", "standard", "challenge"].has(difficulty):
		difficulty = "standard"
	if not ["low", "balanced", "high"].has(quality):
		quality = "balanced"


func save_settings() -> void:
	var data := {
		"schema": SCHEMA,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"ambience_volume": ambience_volume,
		"sfx_volume": sfx_volume,
		"ui_volume": ui_volume,
		"text_scale": text_scale,
		"subtitles": subtitles,
		"sound_captions": sound_captions,
		"high_contrast": high_contrast,
		"colorblind_marks": colorblind_marks,
		"reduced_motion": reduced_motion,
		"camera_shake": camera_shake,
		"aim_assist": aim_assist,
		"invert_y": invert_y,
		"sensitivity": sensitivity,
		"difficulty": difficulty,
		"tutorial_prompts": tutorial_prompts,
		"hint_frequency": hint_frequency,
		"damage_numbers": damage_numbers,
		"touch_scale": touch_scale,
		"left_handed_touch": left_handed_touch,
		"quality": quality,
		"target_fps": target_fps,
		"fullscreen": fullscreen,
		"mono_audio": mono_audio,
		"combat_flashes": combat_flashes,
	}
	var tmp := PATH + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t", true))
	file.flush()
	file.close()
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.rename(tmp.get_file(), PATH.get_file())


func apply_all() -> void:
	_apply_audio()
	_apply_display()
	_apply_quality()


func _apply_audio() -> void:
	var buses := {
		"Master": master_volume,
		"Music": music_volume,
		"Ambience": ambience_volume,
		"SFX": sfx_volume,
		"UI": ui_volume,
	}
	for bus_name in buses.keys():
		var idx := AudioServer.get_bus_index(String(bus_name))
		if idx >= 0:
			AudioServer.set_bus_mute(idx, float(buses[bus_name]) <= 0.001)
			AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(float(buses[bus_name]), 0.001)))
	if AudioServer.get_bus_index("Master") >= 0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), mono_audio and master_volume <= 0.001)


func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	Engine.max_fps = target_fps
	if OS.has_feature("macos") and not OS.has_feature("ios"):
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_quality() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	match quality:
		"low":
			vp.scaling_3d_scale = 0.7
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		"high":
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d = Viewport.MSAA_2X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		_:
			vp.scaling_3d_scale = 0.85 if is_mobile() else 1.0
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA


func set_value(key: String, value: Variant) -> void:
	if not KEYS.has(key):
		return
	set(key, value)
	apply_all()
	Events.settings_changed.emit(key, value)
	save_settings()


func is_mobile() -> bool:
	return OS.has_feature("ios") or OS.has_feature("android")


func is_touch() -> bool:
	return is_mobile() or DisplayServer.is_touchscreen_available()


func is_macos() -> bool:
	return OS.has_feature("macos") and not OS.has_feature("ios")


func is_ios() -> bool:
	return OS.has_feature("ios")


func difficulty_multiplier(stat: String) -> float:
	match difficulty:
		"story":
			return {"damage_taken": 0.6, "telegraph": 1.35, "enemy_health": 0.8, "aim_assist": 1.0}.get(stat, 1.0)
		"challenge":
			return {"damage_taken": 1.35, "telegraph": 0.85, "enemy_health": 1.15, "aim_assist": 0.0}.get(stat, 1.0)
		_:
			return {"damage_taken": 1.0, "telegraph": 1.0, "enemy_health": 1.0, "aim_assist": 0.5}.get(stat, 1.0)


func describe() -> Dictionary:
	return {
		"quality": quality,
		"difficulty": difficulty,
		"text_scale": text_scale,
		"subtitles": subtitles,
		"camera_shake": camera_shake,
	}
