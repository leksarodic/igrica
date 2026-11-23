class_name GameState
extends RefCounted
## The complete, serializable state of one journey. Nodes mutate this through
## commands and never write to disk directly. Keeping the model plain data is
## what makes saves portable, testable, and safe to migrate.

const SCHEMA := 1

var save_id := ""
var created_utc := ""
var modified_utc := ""
var playtime_seconds := 0.0
var revision := 1
var last_region := "bellhollow"
var last_spawn := "arrival"
var last_lantern := "bellhollow_listening"

var player := {}
var quests := {}
var flags := {}
var world := {}
var companions := {}
var journal := {}
var stats := {}


func _init() -> void:
	created_utc = Time.get_datetime_string_from_system(true)
	modified_utc = created_utc
	save_id = _make_id()
	player = {
		"name": "Listener",
		"pronouns": "they",
		"palette": 0,
		"ear": "reed",
		"attunement": 1,
		"skill_points": 1,
		"skills": ["hushstep"],
		"equipped": {
			"weapon": "reed_blade",
			"offhand": "lantern_offhand",
			"cloak": "traveller_cloak",
			"charm1": "",
			"charm2": "",
			"tool": "",
		},
		"inventory": {
			"reed_blade": 1,
			"lantern_offhand": 1,
			"traveller_cloak": 1,
			"reed_tonic": 2,
			"resin": 2,
			"hum_reed": 3,
			"copper_scrap": 1,
		},
		"marks": 12,
		"health": 100.0,
		"breath": 100.0,
		"vitality": 100.0,
		"ear_stat": 10.0,
		"stride": 1.0,
	}
	quests = {
		"main_01": {"stage": 0, "state": "active", "choices": {}},
	}
	flags = {}
	world = {
		"doors": {},
		"puzzles": {},
		"builds": [],
		"regions": {},
		"ferry_repaired": false,
		"bell_tower_repaired": false,
		"chime_choice": "",
	}
	companions = {
		"nissa": {"trust": 1, "active": false, "known": false},
		"brannoc": {"trust": 1, "active": false, "known": false},
	}
	journal = {
		"echoes": {},
		"lore": {},
		"people": {},
		"pins": [],
		"chimes": {},
	}
	stats = {
		"enemies_defeated": 0,
		"puzzles_solved": 0,
		"hints_used": 0,
		"distance": 0.0,
		"deaths": 0,
		"crafted": 0,
		"built": 0,
	}


static func _make_id() -> String:
	var crypto := Crypto.new()
	return crypto.generate_random_bytes(16).hex_encode()


func new_character(display_name: String, pronouns: String, palette: int, ear: String) -> void:
	player["name"] = display_name.strip_edges().substr(0, 24) if not display_name.strip_edges().is_empty() else "Listener"
	player["pronouns"] = pronouns
	player["palette"] = clampi(palette, 0, 5)
	player["ear"] = ear if ear in ["reed", "stone", "bell"] else "reed"
	match player["ear"]:
		"reed":
			player["breath"] = 120.0
		"stone":
			player["vitality"] = 120.0
		"bell":
			player["ear_stat"] = 14.0
	recompute_stats({})
	player["health"] = player["vitality"]
	player["breath"] = player.get("max_breath", 100.0)
	touch()


func touch() -> void:
	modified_utc = Time.get_datetime_string_from_system(true)
	revision += 1


func add_item(item_id: String, count: int = 1) -> void:
	if item_id.is_empty() or count <= 0:
		return
	var inv: Dictionary = player["inventory"]
	inv[item_id] = int(inv.get(item_id, 0)) + count
	touch()
	Events.item_gained.emit(item_id, count)


func remove_item(item_id: String, count: int = 1) -> bool:
	var inv: Dictionary = player["inventory"]
	var have := int(inv.get(item_id, 0))
	if have < count:
		return false
	if have == count:
		inv.erase(item_id)
	else:
		inv[item_id] = have - count
	touch()
	Events.item_removed.emit(item_id, count)
	return true


func has_item(item_id: String, count: int = 1) -> bool:
	return int(player["inventory"].get(item_id, 0)) >= count


func item_count(item_id: String) -> int:
	return int(player["inventory"].get(item_id, 0))


func inventory() -> Dictionary:
	return player["inventory"]


func equipment() -> Dictionary:
	return player["equipped"]


func equip(slot: String, item_id: String) -> void:
	if not (slot in player["equipped"]):
		return
	player["equipped"][slot] = item_id
	touch()
	Events.equipment_changed.emit()


func add_marks(amount: int) -> void:
	player["marks"] = int(player["marks"]) + amount
	touch()
	Events.marks_changed.emit(int(player["marks"]))


func spend_marks(amount: int) -> bool:
	if int(player["marks"]) < amount:
		return false
	player["marks"] = int(player["marks"]) - amount
	touch()
	Events.marks_changed.emit(int(player["marks"]))
	return true


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	touch()


func get_flag(key: String, fallback: Variant = false) -> Variant:
	return flags.get(key, fallback)


func set_quest(quest_id: String, stage: int, state: String = "active") -> void:
	if not quests.has(quest_id):
		quests[quest_id] = {"stage": 0, "state": "active", "choices": {}}
	var q: Dictionary = quests[quest_id]
	if q["stage"] != stage:
		q["stage"] = stage
		Events.quest_stage_changed.emit(quest_id, stage)
	q["state"] = state
	if state == "done":
		Events.quest_completed.emit(quest_id, String(q.get("outcome", "")))
	touch()
	Events.journal_updated.emit()


func quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})


func quest_stage(quest_id: String) -> int:
	return int(quests.get(quest_id, {}).get("stage", -1))


func set_quest_choice(quest_id: String, key: String, value: String) -> void:
	if not quests.has(quest_id):
		quests[quest_id] = {"stage": 0, "state": "active", "choices": {}}
	quests[quest_id]["choices"][key] = value
	touch()


func add_echo(echo_id: String) -> bool:
	if journal["echoes"].has(echo_id):
		return false
	journal["echoes"][echo_id] = true
	player["attunement"] = int(player["attunement"]) + 1
	player["skill_points"] = int(player["skill_points"]) + 1
	touch()
	Events.journal_updated.emit()
	return true


func add_lore(lore_id: String) -> bool:
	if journal["lore"].has(lore_id):
		return false
	journal["lore"][lore_id] = true
	touch()
	Events.journal_updated.emit()
	return true


func add_person(person_id: String) -> void:
	journal["people"][person_id] = true
	touch()
	Events.journal_updated.emit()


func add_trust(companion_id: String, amount: int) -> void:
	if not companions.has(companion_id):
		companions[companion_id] = {"trust": 0, "active": false, "known": false}
	companions[companion_id]["trust"] = clampi(int(companions[companion_id]["trust"]) + amount, 0, 5)
	companions[companion_id]["known"] = true
	touch()
	Events.journal_updated.emit()


func companion(companion_id: String) -> Dictionary:
	return companions.get(companion_id, {"trust": 0, "active": false, "known": false})


func set_companion_active(companion_id: String, active: bool) -> void:
	if not companions.has(companion_id):
		companions[companion_id] = {"trust": 0, "active": false, "known": false}
	companions[companion_id]["active"] = active
	companions[companion_id]["known"] = true
	touch()


func set_world(key: String, value: Variant) -> void:
	world[key] = value
	touch()


func world_get(key: String, fallback: Variant = null) -> Variant:
	return world.get(key, fallback)


func mark_puzzle(puzzle_id: String, solved: bool) -> void:
	world["puzzles"][puzzle_id] = solved
	if solved:
		stats["puzzles_solved"] = int(stats["puzzles_solved"]) + 1
		Events.puzzle_solved.emit(puzzle_id)
	touch()


func puzzle_solved(puzzle_id: String) -> bool:
	return bool(world["puzzles"].get(puzzle_id, false))


func add_build(build_id: String, position: Vector3, region: String = "") -> void:
	world["builds"].append({"id": build_id, "region": region, "x": position.x, "y": position.y, "z": position.z})
	stats["built"] = int(stats["built"]) + 1
	touch()
	Events.build_placed.emit(build_id, position)


func remove_build(index: int) -> Dictionary:
	var builds: Array = world["builds"]
	if index < 0 or index >= builds.size():
		return {}
	var build: Dictionary = builds[index]
	builds.remove_at(index)
	touch()
	Events.build_removed.emit(String(build.get("id", "")))
	return build


func builds() -> Array:
	return world["builds"]


func set_region(region_id: String, spawn_id: String) -> void:
	last_region = region_id
	last_spawn = spawn_id
	touch()


func add_playtime(delta: float) -> void:
	playtime_seconds += delta


func add_distance(delta: float) -> void:
	stats["distance"] = float(stats.get("distance", 0.0)) + delta


func recompute_stats(item_table: Dictionary) -> void:
	var base_vitality := 100.0
	var base_ear := 10.0
	var base_stride := 1.0
	var base_breath := 100.0
	match String(player.get("ear", "reed")):
		"reed":
			base_breath = 120.0
		"stone":
			base_vitality = 120.0
		"bell":
			base_ear = 14.0
	var att := int(player.get("attunement", 1))
	base_vitality += (att - 1) * 6.0
	base_ear += (att - 1) * 1.5
	base_breath += (att - 1) * 4.0
	var equipped: Dictionary = player.get("equipped", {})
	for slot in equipped.keys():
		var item_id := String(equipped[slot])
		if item_id.is_empty():
			continue
		var def: Dictionary = item_table.get(item_id, {})
		var mods: Dictionary = def.get("stats", {})
		base_vitality += float(mods.get("vitality", 0.0))
		base_ear += float(mods.get("ear", 0.0))
		base_stride += float(mods.get("stride", 0.0))
		base_breath += float(mods.get("breath", 0.0))
	player["vitality"] = base_vitality
	player["ear_stat"] = base_ear
	player["stride"] = base_stride
	player["max_breath"] = base_breath
	player["health"] = minf(float(player.get("health", base_vitality)), base_vitality)
	player["breath"] = minf(float(player.get("breath", base_breath)), base_breath)


func heal(amount: float) -> void:
	player["health"] = minf(float(player["health"]) + amount, float(player["vitality"]))
	Events.player_health_changed.emit(float(player["health"]), float(player["vitality"]))


func damage(amount: float) -> void:
	player["health"] = maxf(0.0, float(player["health"]) - amount)
	Events.player_health_changed.emit(float(player["health"]), float(player["vitality"]))
	if float(player["health"]) <= 0.0:
		Events.player_downed.emit()


func to_dict() -> Dictionary:
	return {
		"schema": SCHEMA,
		"save_id": save_id,
		"created_utc": created_utc,
		"modified_utc": modified_utc,
		"playtime_seconds": playtime_seconds,
		"revision": revision,
		"last_region": last_region,
		"last_spawn": last_spawn,
		"last_lantern": last_lantern,
		"player": player.duplicate(true),
		"quests": quests.duplicate(true),
		"flags": flags.duplicate(true),
		"world": world.duplicate(true),
		"companions": companions.duplicate(true),
		"journal": journal.duplicate(true),
		"stats": stats.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	save_id = String(data.get("save_id", _make_id()))
	created_utc = String(data.get("created_utc", Time.get_datetime_string_from_system(true)))
	modified_utc = String(data.get("modified_utc", created_utc))
	playtime_seconds = float(data.get("playtime_seconds", 0.0))
	revision = int(data.get("revision", 1))
	last_region = String(data.get("last_region", "bellhollow"))
	last_spawn = String(data.get("last_spawn", "arrival"))
	last_lantern = String(data.get("last_lantern", "bellhollow_listening"))
	player = data.get("player", player).duplicate(true)
	for key in ["attunement", "skill_points", "marks", "palette"]:
		if player.has(key):
			player[key] = int(player[key])
	quests = data.get("quests", quests).duplicate(true)
	for qid in quests.keys():
		if quests[qid] is Dictionary:
			quests[qid]["stage"] = int(quests[qid].get("stage", 0))
			if not quests[qid].has("choices"):
				quests[qid]["choices"] = {}
	flags = data.get("flags", flags).duplicate(true)
	world = data.get("world", world).duplicate(true)
	companions = data.get("companions", companions).duplicate(true)
	journal = data.get("journal", journal).duplicate(true)
	stats = data.get("stats", stats).duplicate(true)
	# Fill defaults for fields added in later builds.
	if not player.has("inventory"):
		player["inventory"] = {}
	if not world.has("puzzles"):
		world["puzzles"] = {}
	if not world.has("builds"):
		world["builds"] = []


func describe() -> String:
	var inv_count := 0
	for v in player.get("inventory", {}).values():
		inv_count += int(v)
	return "%s · %s · Attunement %d · %d plays" % [
		String(player.get("name", "Listener")),
		last_region.capitalize(),
		int(player.get("attunement", 1)),
		int(playtime_seconds / 60.0),
	]
