class_name SyncService
extends RefCounted
## Offline-first cross-device saves.
##
## The local save is always authoritative for the running session. Sync copies
## immutable snapshots into a shared folder (iCloud Drive, a user folder, or a
## removable drive) and never replaces a newer save without an explicit choice.
## Conflicts preserve both versions.

const SCHEMA := 1
const STATE_FILE := "user://sync_state.json"

var saves: SaveManager
var root := "user://sync"
var events: Node = null
var enabled := true
var last_error := ""
var state_path := STATE_FILE

var _last_synced: Dictionary = {}
var _last_status: Dictionary = {}


func _init(save_manager: SaveManager) -> void:
	saves = save_manager
	_last_synced = _read_json(state_path)
	root = discover_root()


func discover_root() -> String:
	# Prefer iCloud Drive when the user actually has it mounted. This is a
	# document-folder adapter, not a custom account system.
	if Settings.is_macos() or Settings.is_ios():
		var home := OS.get_environment("HOME")
		if not home.is_empty() and Settings.is_ios():
			var ios_container := home + "/Library/Mobile Documents/iCloud~com~leksarodic~longnote/Documents"
			if DirAccess.dir_exists_absolute(ios_container):
				return ios_container
		if not home.is_empty():
			var candidate := home + "/Library/Mobile Documents/com~apple~CloudDocs/LongNote"
			if DirAccess.dir_exists_absolute(candidate):
				return candidate
			# Create it only when the iCloud Drive parent exists.
			var parent := home + "/Library/Mobile Documents/com~apple~CloudDocs"
			if DirAccess.dir_exists_absolute(parent):
				DirAccess.make_dir_recursive_absolute(candidate)
				if DirAccess.dir_exists_absolute(candidate):
					return candidate
	return "user://sync"


func set_root(path: String) -> void:
	if path.is_empty():
		return
	root = path
	_ensure_root()


func _ensure_root() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))


func index_path() -> String:
	return "%s/index.json" % root


func snapshot_path(slot: String, device_id: String) -> String:
	return "%s/%s.%s.json" % [root, saves.sanitize_slot(slot), device_id]


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _write_json_atomic(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		last_error = "Could not write %s" % path
		return false
	f.store_string(JSON.stringify(data, "\t", true, true))
	f.flush()
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
	if err != OK:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	return true


func read_index() -> Dictionary:
	var idx := _read_json(index_path())
	if idx.is_empty():
		idx = {"schema": SCHEMA, "devices": {}, "slots": {}}
	if not idx.has("devices"):
		idx["devices"] = {}
	if not idx.has("slots"):
		idx["slots"] = {}
	return idx


func _write_index(idx: Dictionary) -> void:
	idx["schema"] = SCHEMA
	idx["updated_utc"] = Time.get_datetime_string_from_system(true)
	_write_json_atomic(index_path(), idx)


func _local_entries() -> Dictionary:
	var out := {}
	for entry in saves.list_slots():
		if entry.get("corrupt", false):
			continue
		out[String(entry["slot"])] = entry
	return out


func push(slot: String) -> Dictionary:
	if not enabled:
		return {"ok": false, "reason": "Sync is off."}
	_ensure_root()
	var result := saves.load_slot(slot)
	if not result.get("ok", false):
		return result
	var state := GameState.new()
	state.from_dict(result["state"])
	var packed := saves.make_save(slot, state, bool(result["header"].get("automatic", false)))
	var dest := snapshot_path(slot, saves.device_id)
	if not _write_json_atomic(dest, packed):
		return {"ok": false, "reason": last_error}
	var idx := read_index()
	var h: Dictionary = packed["header"]
	if not idx["slots"].has(slot):
		idx["slots"][slot] = {}
	idx["slots"][slot][saves.device_id] = {
		"device_id": saves.device_id,
		"device_name": saves.device_name,
		"platform": OS.get_name(),
		"checksum": h.get("checksum", ""),
		"revision": h.get("revision", 0),
		"modified_utc": h.get("modified_utc", ""),
		"playtime_seconds": h.get("playtime_seconds", 0.0),
		"file": dest.get_file(),
	}
	idx["devices"][saves.device_id] = {
		"name": saves.device_name,
		"platform": OS.get_name(),
		"last_seen": Time.get_datetime_string_from_system(true),
	}
	_write_index(idx)
	_mark_synced(slot, {
		"checksum": h.get("checksum", ""),
		"revision": h.get("revision", 0),
		"device_id": saves.device_id,
	})
	return {"ok": true, "header": h, "path": dest}


func remote_for(slot: String) -> Dictionary:
	var idx := read_index()
	var slots: Dictionary = idx.get("slots", {})
	if not slots.has(slot):
		return {}
	var best := {}
	for device_id in slots[slot].keys():
		if String(device_id) == saves.device_id:
			continue
		var entry: Dictionary = slots[slot][device_id]
		if best.is_empty() or int(entry.get("revision", 0)) > int(best.get("revision", 0)):
			best = entry
	return best


func status(slot: String) -> Dictionary:
	var local_result := saves.load_slot(slot)
	var local := {}
	if local_result.get("ok", false):
		var h: Dictionary = local_result["header"]
		local = {
			"slot": slot,
			"device_id": saves.device_id,
			"device_name": saves.device_name,
			"checksum": h.get("checksum", ""),
			"revision": h.get("revision", 0),
			"modified_utc": h.get("modified_utc", ""),
			"playtime_seconds": h.get("playtime_seconds", 0.0),
		}
	var remote := remote_for(slot)
	var last: Dictionary = _last_synced.get(slot, {})
	var state := "local_only"
	var reason := ""
	if remote.is_empty():
		state = "local_only" if not local.is_empty() else "no_data"
	elif local.is_empty():
		state = "remote_only"
	else:
		var local_clean: bool = String(local["checksum"]) == String(last.get("checksum", ""))
		var remote_clean: bool = String(remote["checksum"]) == String(last.get("checksum", ""))
		if String(local["checksum"]) == String(remote["checksum"]):
			state = "synced"
		elif local_clean and not remote_clean:
			state = "remote_newer"
		elif remote_clean and not local_clean:
			state = "local_newer"
		else:
			state = "conflict"
			reason = "Both devices have changes since the last shared version."
	var out := {
		"slot": slot,
		"state": state,
		"reason": reason,
		"local": local,
		"remote": remote,
		"last_synced": last,
		"root": root,
		"enabled": enabled,
	}
	_last_status = out
	if events != null:
		events.sync_status_changed.emit(out)
		if state == "conflict":
			events.conflict_detected.emit(out)
	return out


func scan() -> Array:
	var out: Array = []
	var seen := {}
	for slot in _local_entries().keys():
		out.append(status(slot))
		seen[slot] = true
	var idx := read_index()
	for slot in idx.get("slots", {}).keys():
		if not seen.has(slot):
			out.append(status(slot))
	return out


func pull(slot: String, device_id: String = "") -> Dictionary:
	var remote := remote_for(slot)
	if remote.is_empty():
		return {"ok": false, "reason": "No remote save for this slot."}
	if not device_id.is_empty() and String(remote.get("device_id", "")) != device_id:
		return {"ok": false, "reason": "That device has no snapshot for this slot."}
	var path := "%s/%s" % [root, String(remote.get("file", ""))]
	var loaded := saves.load_file(path, false)
	if not loaded.get("ok", false):
		return {"ok": false, "reason": "Remote save failed verification: %s" % loaded.get("reason", "")}
	# Archive the local version before replacing it. Nothing is deleted.
	var local_existed := FileAccess.file_exists(saves.path_for(slot))
	if local_existed:
		var stamp := Time.get_datetime_string_from_system(true).replace(":", "-")
		var archive := "%s.pre-sync-%s.json" % [saves.base_dir, stamp]
		DirAccess.copy_absolute(ProjectSettings.globalize_path(saves.path_for(slot)), ProjectSettings.globalize_path(archive))
	var state := GameState.new()
	state.from_dict(loaded["state"])
	var write := saves.save_state(slot, state, bool(loaded["header"].get("automatic", false)))
	if not write.get("ok", false):
		return write
	_mark_synced(slot, {
		"checksum": loaded["header"].get("checksum", ""),
		"revision": loaded["header"].get("revision", 0),
		"device_id": String(remote.get("device_id", "")),
	})
	return {"ok": true, "header": write.get("header", {}), "archived_local": local_existed}


func resolve(slot: String, resolution: String) -> Dictionary:
	match resolution:
		"keep_local":
			return push(slot)
		"use_remote":
			return pull(slot)
		"keep_both":
			var remote := remote_for(slot)
			if remote.is_empty():
				return {"ok": false, "reason": "No remote save to keep."}
			var path := "%s/%s" % [root, String(remote.get("file", ""))]
			var loaded := saves.load_file(path, false)
			if not loaded.get("ok", false):
				return loaded
			var state := GameState.new()
			state.from_dict(loaded["state"])
			var suffix := String(remote.get("device_name", "other")).to_lower().replace(" ", "_").replace("'", "")
			var new_slot := "%s_%s" % [saves.sanitize_slot(slot), suffix.substr(0, 16)]
			var write := saves.save_state(new_slot, state, false)
			if not write.get("ok", false):
				return write
			return {"ok": true, "new_slot": new_slot, "header": write.get("header", {})}
		_:
			return {"ok": false, "reason": "Unknown resolution."}


func push_all() -> Array:
	var results: Array = []
	for slot in _local_entries().keys():
		results.append(push(slot))
	return results


func _mark_synced(slot: String, data: Dictionary) -> void:
	_last_synced[slot] = data
	_write_json_atomic(state_path, _last_synced)


func summary() -> Dictionary:
	var statuses := scan()
	var conflicts := 0
	var pending := 0
	for s in statuses:
		if String(s.get("state", "")) == "conflict":
			conflicts += 1
		elif String(s.get("state", "")) in ["local_newer", "local_only"]:
			pending += 1
	return {
		"root": root,
		"device": saves.device_name,
		"enabled": enabled,
		"conflicts": conflicts,
		"pending": pending,
		"statuses": statuses,
		"last_error": last_error,
	}
