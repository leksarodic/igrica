extends Node
## Application shell and the single owner of the journey's state.

var content: ContentDB
var state: GameState
var saves: SaveManager
var sync: SyncService
var current_slot := "autosave"
var running := false
var paused := false
var dialogue_active := false
var build_mode := false
var in_combat := false
var current_region := "bellhollow"
var session_started_utc := ""

var _autosave_guard := 0.0
var _pending_autosave := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	content = ContentDB.new()
	saves = SaveManager.new()
	sync = SyncService.new(saves)
	sync.events = Events
	session_started_utc = Time.get_datetime_string_from_system(true)
	connect_events()
	if DisplayServer.get_name() != "headless":
		sync.scan()


func connect_events() -> void:
	Events.region_entered.connect(_on_region_entered)
	Events.quest_stage_changed.connect(func(_id, _stage): request_autosave())
	Events.player_downed.connect(_on_player_downed)


func _process(delta: float) -> void:
	if not running:
		return
	if not paused:
		state.add_playtime(delta)
	_autosave_guard -= delta
	if _pending_autosave and _autosave_guard <= 0.0:
		_pending_autosave = false
		_autosave_guard = 2.0
		autosave()


func new_game(character: Dictionary) -> void:
	state = GameState.new()
	state.new_character(
		String(character.get("name", "Listener")),
		String(character.get("pronouns", "they")),
		int(character.get("palette", 0)),
		String(character.get("ear", "reed"))
	)
	state.recompute_stats(content.items)
	state.player["health"] = state.player["vitality"]
	state.player["breath"] = state.player.get("max_breath", 120.0)
	state.last_region = "bellhollow"
	state.last_spawn = "arrival"
	current_slot = "autosave"
	current_region = "bellhollow"
	running = true
	paused = false
	saves.save_state(current_slot, state, true)
	Events.game_started.emit(true)
	Events.region_entered.emit("bellhollow")


func load_game(slot: String) -> Dictionary:
	var result := saves.load_slot(slot)
	if not result.get("ok", false):
		return result
	state = GameState.new()
	state.from_dict(result["state"])
	state.recompute_stats(content.items)
	current_slot = slot
	current_region = state.last_region
	running = true
	paused = false
	Events.game_loaded.emit(slot)
	Events.region_entered.emit(current_region)
	return {"ok": true, "header": result["header"]}


func save_current(slot: String = "", automatic: bool = false) -> Dictionary:
	if not running or state == null:
		return {"ok": false, "reason": "No active journey."}
	var use_slot := slot if not slot.is_empty() else current_slot
	var result := saves.save_state(use_slot, state, automatic)
	if result.get("ok", false):
		Events.game_saved.emit(use_slot, automatic)
	else:
		Events.save_failed.emit(use_slot, String(result.get("reason", "unknown")))
	return result


func autosave() -> void:
	if not running:
		return
	save_current("autosave", true)


func request_autosave() -> void:
	_pending_autosave = true


func save_and_continue_elsewhere() -> Dictionary:
	var saved := save_current(current_slot, false)
	if not saved.get("ok", false):
		return saved
	var pushed := sync.push(current_slot)
	if pushed.get("ok", false):
		return {"ok": true, "message": "Saved and copied to %s" % sync.root, "path": sync.root, "header": saved.get("header", {})}
	return {
		"ok": true,
		"message": "Saved locally. The shared folder was not available; the save is safe on this device.",
		"header": saved.get("header", {}),
		"sync_error": pushed.get("reason", ""),
	}


func sync_now() -> Dictionary:
	if state == null:
		return {"ok": false, "reason": "No active journey."}
	save_current(current_slot, false)
	var pushed := sync.push(current_slot)
	var status := sync.status(current_slot)
	return {"ok": pushed.get("ok", false), "status": status, "push": pushed}


func set_paused(value: bool) -> void:
	paused = value
	get_tree().paused = value
	if value:
		save_current(current_slot, false)
		sync.push(current_slot)


func set_region(region_id: String, spawn_id: String) -> void:
	current_region = region_id
	if state != null:
		state.set_region(region_id, spawn_id)
	Events.region_entered.emit(region_id)


func _on_region_entered(region_id: String) -> void:
	current_region = region_id
	if running:
		request_autosave()


func _on_player_downed() -> void:
	if state != null:
		state.stats["deaths"] = int(state.stats.get("deaths", 0)) + 1
	request_autosave()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if running and state != null:
			save_current(current_slot, false)
			sync.push(current_slot)
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if running and state != null:
			save_current(current_slot, false)
			sync.push(current_slot)


func has_save() -> bool:
	return not saves.list_slots().is_empty()


func newest_save() -> Dictionary:
	var slots := saves.list_slots()
	for s in slots:
		if not s.get("corrupt", false):
			return s
	return {}


func describe_state() -> String:
	if state == null:
		return "No journey."
	return state.describe()
