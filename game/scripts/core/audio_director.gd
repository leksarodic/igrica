extends Node
## Original procedural audio. No external music or sample packs: bells, reeds,
## wind, and the score are synthesized at startup and cached in memory.
## Audio is a layer of the world, never a nag.

const RATE := 22050
const SFX_VOICES := 16
const AMBIENT_VOICES := 4

var _streams: Dictionary = {}
var _music: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_3d: Array[AudioStreamPlayer3D] = []
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _music_mode := ""
var _rng := RandomNumberGenerator.new()
var _ready_done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 9127
	_ensure_buses()
	if DisplayServer.get_name() == "headless":
		_ready_done = true
		return
	_build_streams()
	_build_players()
	_ready_done = true
	Settings.apply_all()


func _ensure_buses() -> void:
	for bus_name in ["Music", "Ambience", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _build_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -80.0
	add_child(_music_player)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Ambience"
	_ambience_player.volume_db = -18.0
	add_child(_ambience_player)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	for i in 10:
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = "SFX"
		p3.max_distance = 26.0
		p3.unit_size = 4.0
		add_child(p3)
		_sfx_3d.append(p3)


func _build_streams() -> void:
	_streams["ui_click"] = _tone(880.0, 0.06, 0.25, 0.002, 0.04)
	_streams["ui_confirm"] = _chord([523.25, 659.25, 783.99], 0.5, 0.28)
	_streams["pickup"] = _bell(1318.5, 0.7, 0.24)
	_streams["save"] = _bell(659.25, 1.4, 0.3)
	_streams["hit_light"] = _hit(180.0, 0.18, 0.5)
	_streams["hit_heavy"] = _hit(95.0, 0.36, 0.75)
	_streams["parry"] = _bell(1760.0, 0.28, 0.4)
	_streams["dodge"] = _noise(0.18, 0.12, 0.0)
	_streams["listen"] = _bell(110.0, 1.8, 0.32)
	_streams["puzzle_good"] = _chord([261.63, 329.63, 392.0], 1.8, 0.3)
	_streams["puzzle_bad"] = _tone(196.0, 0.12, 0.12, 0.002, 0.1)
	_streams["step"] = _noise(0.08, 0.05, 0.0)
	_streams["build"] = _hit(140.0, 0.24, 0.4)
	_streams["heal"] = _chord([392.0, 523.25, 659.25], 1.2, 0.25)
	_streams["hurt"] = _hit(70.0, 0.3, 0.55)
	_streams["enemy_down"] = _chord([220.0, 277.18, 329.63], 1.4, 0.24)
	_streams["menu_open"] = _chord([329.63, 493.88], 0.7, 0.18)
	_streams["ui_back"] = _tone(392.0, 0.1, 0.2, 0.002, 0.08)
	_streams["companion"] = _chord([440.0, 554.37], 0.5, 0.2)

	_music["working"] = _music_bed([146.83, 220.0, 293.66], 18.0, 0.18)
	_music["surface"] = _music_bed([130.81, 196.0, 261.63], 22.0, 0.16)
	_music["water"] = _music_bed([123.47, 185.0, 246.94], 22.0, 0.15)
	_music["hollow"] = _music_bed([110.0, 164.81, 246.94], 26.0, 0.14)
	_music["tension"] = _music_bed([98.0, 146.83, 196.0], 16.0, 0.12)
	_music["hush"] = _music_bed([82.41, 123.47], 28.0, 0.1)
	_streams["ambience_wind"] = _wind(8.0, 0.16)


func _tone(freq: float, duration: float, amp: float, attack: float, release: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / RATE
		var env := _envelope(t, duration, attack, release)
		samples[i] = sin(TAU * freq * t) * env * amp
	return _to_wav(samples)


func _bell(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var partials := [1.0, 2.01, 3.0, 4.18, 5.43, 6.79]
	var gains := [1.0, 0.55, 0.32, 0.18, 0.11, 0.06]
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / RATE
		var env := exp(-t * 3.6) * minf(1.0, t * 60.0)
		var s := 0.0
		for p in partials.size():
			var f: float = freq * partials[p]
			s += sin(TAU * f * t) * gains[p]
		samples[i] = s * env * amp
	return _to_wav(samples)


func _chord(freqs: Array, duration: float, amp: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / RATE
		var env := minf(1.0, t * 20.0) * exp(-t * 1.4)
		var s := 0.0
		for f in freqs:
			s += sin(TAU * float(f) * t)
			s += sin(TAU * float(f) * 2.0 * t) * 0.18
		samples[i] = s / maxf(1.0, freqs.size()) * env * amp
	return _to_wav(samples)


func _hit(freq: float, duration: float, amp: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / RATE
		var env := exp(-t * 12.0)
		var body := sin(TAU * freq * t) * 0.7
		var click := _rng.randf_range(-1.0, 1.0) * exp(-t * 70.0) * 0.5
		samples[i] = (body + click) * env * amp
	return _to_wav(samples)


func _noise(duration: float, amp: float, low: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var last := 0.0
	for i in count:
		var t := float(i) / RATE
		var env := exp(-t * 18.0)
		var n := _rng.randf_range(-1.0, 1.0)
		last = lerpf(last, n, 0.25 + low)
		samples[i] = last * env * amp
	return _to_wav(samples)


func _wind(duration: float, amp: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var last := 0.0
	for i in count:
		var t := float(i) / RATE
		var n := _rng.randf_range(-1.0, 1.0)
		last = lerpf(last, n, 0.02)
		var lfo := 0.55 + 0.45 * sin(TAU * 0.09 * t)
		samples[i] = last * lfo * amp
	# Crossfade the seam so the loop does not click.
	var fade := int(RATE * 0.4)
	for i in fade:
		var k := float(i) / fade
		samples[i] = lerpf(samples[count - fade + i], samples[i], k)
	return _to_wav(samples)


func _music_bed(freqs: Array, duration: float, amp: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / RATE
		var swell := 0.5 + 0.5 * sin(TAU * t / duration)
		var s := 0.0
		for f in freqs.size():
			var base: float = freqs[f]
			s += sin(TAU * base * t + sin(TAU * 0.03 * t) * 0.2) * (0.6 + 0.4 * sin(TAU * (0.07 + f * 0.013) * t))
			s += sin(TAU * base * 0.5 * t) * 0.25
		samples[i] = s / maxf(1.0, freqs.size()) * (0.35 + 0.65 * swell) * amp
	var wav := _to_wav(samples)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = count
	return wav


func _envelope(t: float, duration: float, attack: float, release: float) -> float:
	var a := clampf(t / maxf(attack, 0.001), 0.0, 1.0)
	var r := clampf((duration - t) / maxf(release, 0.001), 0.0, 1.0)
	return a * r


func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


func play_sfx(id: String, position: Variant = null, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _ready_done or not _streams.has(id):
		return
	if DisplayServer.get_name() == "headless":
		return
	var stream: AudioStreamWAV = _streams[id]
	if position is Vector3:
		for p in _sfx_3d:
			if not p.playing:
				p.stream = stream
				p.global_position = position
				p.volume_db = volume_db
				p.pitch_scale = pitch
				p.play()
				return
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return


func play_ui(id: String) -> void:
	if _streams.has(id):
		play_sfx(id, null, -4.0)
		if _sfx_players.size() > 0:
			_sfx_players[0].bus = "UI"


func set_music(mode: String) -> void:
	if not _ready_done:
		return
	if mode == _music_mode:
		return
	_music_mode = mode
	if _music.is_empty() or not _music.has(mode):
		return
	var target: AudioStreamWAV = _music[mode]
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -34.0, 1.2)
	tween.tween_callback(func():
		_music_player.stream = target
		_music_player.play()
	)
	tween.tween_property(_music_player, "volume_db", -24.0, 1.6)
	if _ambience_player.stream == null:
		_ambience_player.stream = _streams["ambience_wind"]
		_ambience_player.play()


func set_music_intensity(value: float) -> void:
	if _music_player == null:
		return
	_music_player.volume_db = lerpf(-30.0, -18.0, clampf(value, 0.0, 1.0))


func stop_music() -> void:
	_music_mode = ""
	_music_player.stop()


func duck(amount_db: float = -8.0, duration: float = 1.0) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, amount_db)
		var tween := create_tween()
		tween.tween_interval(duration)
		tween.tween_callback(func():
			AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(Settings.music_volume, 0.001)))
		)


func play_ambient(id: String) -> void:
	if _streams.has(id) and _ambience_player != null:
		_ambience_player.stream = _streams[id]
		_ambience_player.play()
