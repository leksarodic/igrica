extends Node
## Headless test suite. Run with:
##   godot --headless --path game res://tests/TestScene.tscn
## The suite exercises real autoloads and real file IO, not mocks.

var passed := 0
var failed := 0
var failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_test_content()
	_test_state()
	_test_save_roundtrip()
	_test_checksum_and_quarantine()
	_test_backup_recovery()
	_test_sync_conflict_and_recovery()
	_report()
	get_tree().quit(0 if failed == 0 else 1)


func _report() -> void:
	print("\n=== The Long Note — test report ===")
	print("passed: %d   failed: %d" % [passed, failed])
	for f in failures:
		print("FAIL: ", f)
	print("===================================\n")


func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		failures.append(message)
		push_error(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if str(actual) == str(expected):
		passed += 1
	else:
		failed += 1
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
		push_error(failures[-1])


func _wipe(path: String) -> void:
	var abs := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(abs):
		return
	var dir := DirAccess.open(path)
	if dir != null:
		var files: Array[String] = []
		var dirs: Array[String] = []
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if dir.current_is_dir():
				dirs.append(entry)
			else:
				files.append(entry)
			entry = dir.get_next()
		dir.list_dir_end()
		for f in files:
			dir.remove(f)
		for d in dirs:
			_wipe(path + "/" + d)
	DirAccess.remove_absolute(abs)


func _files(path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			out.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	return out


func _test_content() -> void:
	check(Game.content != null, "ContentDB loads")
	check(Game.content.errors.is_empty(), "ContentDB validation is clean: %s" % str(Game.content.errors))
	check(not Game.content.item("reed_blade").is_empty(), "items load")
	check(not Game.content.enemy("hollow_stag").is_empty(), "enemies load")
	check(Game.content.dialogue.has("wren_arrival"), "dialogue loads")


func _test_state() -> void:
	var s := GameState.new()
	s.new_character("Wren", "she", 2, "bell")
	check_eq(s.player["name"], "Wren", "character name")
	check_eq(s.player["ear"], "bell", "ear trait")
	check_eq(s.item_count("hum_reed"), 3, "starting inventory")
	s.add_item("resin", 2)
	check_eq(s.item_count("resin"), 4, "add item")
	check(s.remove_item("resin", 3), "remove item")
	check_eq(s.item_count("resin"), 1, "remove item count")
	check(!s.remove_item("resin", 99), "cannot remove more than held")
	s.set_quest("main_01", 3)
	check_eq(s.quest_stage("main_01"), 3, "quest stage")
	s.set_quest_choice("main_01", "route", "reeds")
	check_eq(s.quest("main_01")["choices"]["route"], "reeds", "quest choice")
	var att := int(s.player["attunement"])
	check(s.add_echo("echo_test"), "echo added")
	check_eq(int(s.player["attunement"]), att + 1, "echo raises attunement")
	check(!s.add_echo("echo_test"), "echo not duplicated")
	s.equip("weapon", "quarry_maul")
	s.recompute_stats(Game.content.items)
	check(float(s.player["vitality"]) > 100.0, "equipment affects vitality")
	var before := int(s.player["marks"])
	s.add_marks(5)
	check_eq(int(s.player["marks"]), before + 5, "marks added")
	check(s.spend_marks(3), "marks spent")
	check_eq(int(s.player["marks"]), before + 2, "marks spent count")


func _test_save_roundtrip() -> void:
	var dir := "user://test_saves_roundtrip"
	_wipe(dir)
	var sm := SaveManager.new(dir)
	var s := GameState.new()
	s.new_character("Wren", "she", 1, "reed")
	s.add_item("humstone_shard", 2)
	s.set_quest("main_02", 4)
	s.set_flag("met_pell", true)
	var result := sm.save_state("journey", s, false)
	check(result.get("ok", false), "save writes: %s" % result.get("reason", ""))
	var loaded := sm.load_slot("journey")
	check(loaded.get("ok", false), "save loads: %s" % loaded.get("reason", ""))
	if loaded.get("ok", false):
		var st = loaded["state"]
		check_eq(st.get("player", {}).get("name", ""), "Wren", "roundtrip name")
		check_eq(int(st.get("player", {}).get("inventory", {}).get("humstone_shard", 0)), 2, "roundtrip inventory")
		check_eq(int(st.get("quests", {}).get("main_02", {}).get("stage", -1)), 4, "roundtrip quest")
		check_eq(st.get("flags", {}).get("met_pell", false), true, "roundtrip flag")
	var listed := sm.list_slots()
	check(listed.size() == 1, "slot listing")
	if listed.size() == 1:
		check_eq(listed[0]["slot"], "journey", "listed slot id")
		check_eq(listed[0]["name"], "Wren", "listed player name")


func _test_checksum_and_quarantine() -> void:
	var dir := "user://test_saves_tamper"
	_wipe(dir)
	var sm := SaveManager.new(dir)
	var s := GameState.new()
	s.new_character("Tamer", "they", 0, "reed")
	sm.save_state("tamper", s, false)
	var path := sm.path_for("tamper")
	var text := FileAccess.get_file_as_string(path)
	text = text.replace("\"name\": \"Tamer\"", "\"name\": \"Tampered\"")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	var bad := sm.load_slot("tamper")
	check(!bad.get("ok", true), "tampered save is rejected")
	var found := false
	for name in _files(dir):
		if name.contains(".corrupt-"):
			found = true
	check(found, "tampered save is quarantined, not deleted")


func _test_backup_recovery() -> void:
	var dir := "user://test_saves_backup"
	_wipe(dir)
	var sm := SaveManager.new(dir)
	var a := GameState.new()
	a.new_character("First", "they", 0, "reed")
	sm.save_state("backup", a, false)
	var b := GameState.new()
	b.new_character("Second", "they", 0, "reed")
	sm.save_state("backup", b, false)
	var path := sm.path_for("backup")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("deliberately broken")
	f.close()
	var recovered := sm.load_slot("backup")
	check(recovered.get("ok", false), "backup recovery succeeds: %s" % recovered.get("reason", ""))
	check(bool(recovered.get("recovered_from_backup", false)), "recovery is marked as from backup")
	if recovered.get("ok", false):
		check_eq(recovered["state"].get("player", {}).get("name", ""), "First", "backup contains previous save")


func _test_sync_conflict_and_recovery() -> void:
	var root := "user://test_sync_root"
	var dir_a := "user://test_sync_a"
	var dir_b := "user://test_sync_b"
	var dir_c := "user://test_sync_c"
	_wipe(root)
	_wipe(dir_a)
	_wipe(dir_b)
	_wipe(dir_c)

	var sm_a := SaveManager.new(dir_a)
	sm_a.device_id = "device_mac"
	sm_a.device_name = "Aleksa's Mac"
	var sm_b := SaveManager.new(dir_b)
	sm_b.device_id = "device_phone"
	sm_b.device_name = "iPhone"
	var sm_c := SaveManager.new(dir_c)
	sm_c.device_id = "device_third"
	sm_c.device_name = "Other Mac"

	var sa := GameState.new()
	sa.new_character("Mac Wren", "she", 0, "reed")
	sa.add_item("copper_scrap", 3)
	sm_a.save_state("journey", sa, false)

	var sy_a := SyncService.new(sm_a)
	sy_a.set_root(root)
	sy_a.state_path = root + "/state_a.json"
	var push := sy_a.push("journey")
	check(push.get("ok", false), "sync push succeeds: %s" % push.get("reason", ""))
	check(FileAccess.file_exists(sy_a.snapshot_path("journey", "device_mac")), "snapshot exists")

	var sb := GameState.new()
	sb.new_character("Phone Wren", "she", 0, "bell")
	sb.add_item("hum_reed", 5)
	sm_b.save_state("journey", sb, false)

	var sy_b := SyncService.new(sm_b)
	sy_b.set_root(root)
	sy_b.state_path = root + "/state_b.json"
	var status := sy_b.status("journey")
	check_eq(status.get("state", ""), "conflict", "two diverged devices produce a conflict")
	check_eq(status.get("remote", {}).get("device_name", ""), "Aleksa's Mac", "remote device is identified")

	var both := sy_b.resolve("journey", "keep_both")
	check(both.get("ok", false), "keep both resolves without deleting: %s" % both.get("reason", ""))
	check(FileAccess.file_exists(sm_b.path_for(String(both.get("new_slot", "")))), "other version is preserved as a new slot")
	var still := sm_b.load_slot("journey")
	check(still.get("ok", false), "local save survives keep both")
	if still.get("ok", false):
		check_eq(still["state"].get("player", {}).get("name", ""), "Phone Wren", "local version is untouched")

	# A clean device can pull the remote snapshot.
	var sy_c := SyncService.new(sm_c)
	sy_c.set_root(root)
	sy_c.state_path = root + "/state_c.json"
	var status_c := sy_c.status("journey")
	check_eq(status_c.get("state", ""), "remote_only", "clean device sees a remote save")
	var pull := sy_c.pull("journey")
	check(pull.get("ok", false), "remote save pulls: %s" % pull.get("reason", ""))
	var pulled := sm_c.load_slot("journey")
	check(pulled.get("ok", false), "pulled save loads")
	if pulled.get("ok", false):
		check_eq(pulled["state"].get("player", {}).get("name", ""), "Mac Wren", "pulled progress is the remote progress")

	# Cleanup
	_wipe(root)
	_wipe(dir_a)
	_wipe(dir_b)
	_wipe(dir_c)
