class_name SaveManager
extends RefCounted
## Atomic, checksummed, versioned saves. The rules:
##   * never overwrite a good save in place;
##   * never delete a save to "fix" it;
##   * a corrupt file is quarantined, and the backup is offered;
##   * the header is enough to show a save in the UI without parsing the state.

const MAGIC := "longnote.save"
const SCHEMA := 1
const GAME_VERSION := "0.1.0"

var base_dir := "user://saves"
var device_id := ""
var device_name := "This device"
var game_version := GAME_VERSION

const _SAFE := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"


func _init(dir: String = "user://saves") -> void:
	base_dir = dir
	_ensure_dir()
	_load_identity()


func _ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_dir))


func _load_identity() -> void:
	var path := "user://device_id"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			device_id = f.get_as_text().strip_edges()
			f.close()
	if device_id.is_empty():
		var crypto := Crypto.new()
		device_id = crypto.generate_random_bytes(12).hex_encode()
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string(device_id)
			f.close()
	device_name = _detect_device_name()


func _detect_device_name() -> String:
	if OS.has_feature("ios"):
		return "iPhone"
	if OS.has_feature("macos"):
		var user := OS.get_environment("USER")
		if not user.is_empty():
			return "%s's Mac" % user.capitalize()
		return "Mac"
	return OS.get_name()


func sanitize_slot(slot: String) -> String:
	var out := ""
	for ch in slot:
		if _SAFE.contains(ch):
			out += ch
	out = out.strip_edges().substr(0, 40)
	return out if not out.is_empty() else "journey"


func path_for(slot: String) -> String:
	return "%s/%s.json" % [base_dir, sanitize_slot(slot)]


func _backup_path(slot: String) -> String:
	return "%s/%s.json.bak" % [base_dir, sanitize_slot(slot)]


func _tmp_path(slot: String) -> String:
	return "%s/%s.json.tmp" % [base_dir, sanitize_slot(slot)]


func make_save(slot: String, state: GameState, automatic: bool = false) -> Dictionary:
	state.touch()
	var header := {
		"magic": MAGIC,
		"schema": SCHEMA,
		"game_version": game_version,
		"slot": sanitize_slot(slot),
		"save_id": state.save_id,
		"created_utc": state.created_utc,
		"modified_utc": state.modified_utc,
		"device": {"id": device_id, "name": device_name, "platform": OS.get_name()},
		"revision": state.revision,
		"playtime_seconds": state.playtime_seconds,
		"automatic": automatic,
	}
	var payload := header.duplicate(true)
	payload["state"] = state.to_dict()
	header["checksum"] = _checksum(payload)
	return {"header": header, "state": payload["state"]}


func save_state(slot: String, state: GameState, automatic: bool = false) -> Dictionary:
	_ensure_dir()
	var packed := make_save(slot, state, automatic)
	var slot_name := sanitize_slot(slot)
	var dest := path_for(slot_name)
	var tmp := _tmp_path(slot_name)
	var bak := _backup_path(slot_name)

	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "reason": "Could not open save file for writing."}
	file.store_string(JSON.stringify(packed, "\t", true, true))
	file.flush()
	file.close()

	# Verify what actually landed on disk before replacing anything.
	var check := load_file(tmp, false)
	if not check.get("ok", false):
		return {"ok": false, "reason": "Save verification failed: %s" % check.get("reason", "unknown")}

	if FileAccess.file_exists(dest):
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(bak))
		DirAccess.copy_absolute(ProjectSettings.globalize_path(dest), ProjectSettings.globalize_path(bak))
	if FileAccess.file_exists(dest):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dest))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(dest))
	if err != OK:
		# Last resort: copy, then remove the temp.
		DirAccess.copy_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(dest))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	return {"ok": true, "header": packed["header"], "path": dest}


func load_slot(slot: String) -> Dictionary:
	var dest := path_for(slot)
	var result := load_file(dest, true)
	if result.get("ok", false):
		return result
	# If the main file is missing or corrupt, try the backup and be explicit.
	var bak := _backup_path(slot)
	if FileAccess.file_exists(bak):
		var recovered := load_file(bak, false)
		if recovered.get("ok", false):
			recovered["recovered_from_backup"] = true
			return recovered
	return result


func load_file(path: String, quarantine_on_failure: bool = true) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": "Save not found.", "path": path}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"ok": false, "reason": "Save could not be opened.", "path": path}
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		if quarantine_on_failure:
			_quarantine(path)
		return {"ok": false, "reason": "Save is not valid JSON: %s" % json.get_error_message(), "path": path}
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		if quarantine_on_failure:
			_quarantine(path)
		return {"ok": false, "reason": "Save is not a JSON object.", "path": path}
	var packed: Dictionary = parsed
	var header: Dictionary = packed.get("header", {})
	if String(header.get("magic", "")) != MAGIC:
		if quarantine_on_failure:
			_quarantine(path)
		return {"ok": false, "reason": "Not a Long Note save.", "path": path}
	var state_data: Dictionary = packed.get("state", {})
	var checksum := String(header.get("checksum", ""))
	var payload := header.duplicate(true)
	payload.erase("checksum")
	payload["state"] = state_data
	if checksum.is_empty() or _checksum(payload) != checksum:
		if quarantine_on_failure:
			_quarantine(path)
		return {"ok": false, "reason": "Save checksum does not match. The file was preserved.", "path": path}
	var schema := int(header.get("schema", 0))
	if schema > SCHEMA:
		return {"ok": false, "reason": "This save was made by a newer version of the game.", "path": path, "schema": schema}
	# Future schema migrations happen here, in order, before the state is used.
	return {
		"ok": true,
		"header": header,
		"state": state_data,
		"path": path,
		"schema": schema,
	}


func list_slots() -> Array:
	var out: Array = []
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.ends_with(".json") and not name.ends_with(".bak.json"):
			var result := load_file("%s/%s" % [base_dir, name], false)
			if result.get("ok", false):
				var h: Dictionary = result["header"]
				out.append({
					"slot": String(h.get("slot", name.get_basename())),
					"name": String(result["state"].get("player", {}).get("name", "Listener")),
					"region": String(result["state"].get("last_region", "bellhollow")).capitalize(),
					"attunement": int(result["state"].get("player", {}).get("attunement", 1)),
					"playtime_seconds": float(h.get("playtime_seconds", 0.0)),
					"modified_utc": String(h.get("modified_utc", "")),
					"device_name": String(h.get("device", {}).get("name", "")),
					"device_id": String(h.get("device", {}).get("id", "")),
					"revision": int(h.get("revision", 0)),
					"checksum": String(h.get("checksum", "")),
					"automatic": bool(h.get("automatic", false)),
					"path": result["path"],
				})
			else:
				out.append({"slot": name.get_basename(), "corrupt": true, "reason": result.get("reason", "")})
		name = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a, b): return String(a.get("modified_utc", "")) > String(b.get("modified_utc", "")))
	return out


func delete_slot(slot: String) -> bool:
	var removed := false
	for path in [path_for(slot), _backup_path(slot), _tmp_path(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			removed = true
	return removed


func export_package(slot: String, dest_path: String) -> Dictionary:
	var result := load_slot(slot)
	if not result.get("ok", false):
		return result
	var state := GameState.new()
	state.from_dict(result["state"])
	var packed := make_save(slot, state, bool(result["header"].get("automatic", false)))
	var f := FileAccess.open(dest_path, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "reason": "Could not write export file."}
	f.store_string(JSON.stringify(packed, "\t", true, true))
	f.flush()
	f.close()
	return {"ok": true, "path": dest_path}


func import_package(source_path: String, slot: String) -> Dictionary:
	var loaded := load_file(source_path, false)
	if not loaded.get("ok", false):
		return loaded
	var state := GameState.new()
	state.from_dict(loaded["state"])
	return save_state(slot, state, false)


func _canonical(value: Variant) -> Variant:
	# JSON parsing promotes every number to float in some Godot builds. Normalise
	# integral floats back to ints so the checksum survives a write/read cycle.
	match typeof(value):
		TYPE_DICTIONARY:
			var out := {}
			for k in (value as Dictionary).keys():
				out[str(k)] = _canonical((value as Dictionary)[k])
			return out
		TYPE_ARRAY:
			var arr := []
			for v in (value as Array):
				arr.append(_canonical(v))
			return arr
		TYPE_FLOAT:
			var f: float = value
			if not is_finite(f):
				return "f:nonfinite"
			if absf(f - roundf(f)) < 0.0000001:
				return int(roundf(f))
			# A fixed textual form survives JSON round-trips across platforms.
			return "f:%.6f" % f
		TYPE_INT:
			return int(value)
		_:
			return value


func _quarantine(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "-")
	var dest := "%s.corrupt-%s" % [path, stamp]
	DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(dest))


func _checksum(payload: Dictionary) -> String:
	var text := JSON.stringify(_canonical(payload), "", true, true)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()


func recovery_report() -> Dictionary:
	var report := {"missing_state": false, "quarantined": [], "backups": []}
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return report
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			if name.contains(".corrupt-"):
				report["quarantined"].append(name)
			elif name.ends_with(".json.bak"):
				report["backups"].append(name.replace(".json.bak", ""))
		name = dir.get_next()
	dir.list_dir_end()
	return report
