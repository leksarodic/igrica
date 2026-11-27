class_name ContentDB
extends RefCounted
## Loads hand-authored content from res://data and fails loudly in debug when a
## referenced id is missing. Content is data, never generated at runtime.

const DATA_DIR := "res://data/"

var items: Dictionary = {}
var recipes: Dictionary = {}
var quests: Dictionary = {}
var enemies: Dictionary = {}
var regions: Dictionary = {}
var skills: Dictionary = {}
var dialogue: Dictionary = {}
var builds: Dictionary = {}
var lore: Dictionary = {}
var errors: Array[String] = []


func _init() -> void:
	load_all()


func load_all() -> void:
	items = _load("items.json")
	recipes = _load("recipes.json")
	quests = _load("quests.json")
	enemies = _load("enemies.json")
	regions = _load("regions.json")
	skills = _load("skills.json")
	dialogue = _load("dialogue.json")
	builds = _load("builds.json")
	lore = _load("lore.json")
	validate()


func _load(file_name: String) -> Dictionary:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		errors.append("Missing data file: %s" % path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		errors.append("Could not open data file: %s" % path)
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("Invalid JSON in %s" % path)
		return {}
	return parsed


func item(id: String) -> Dictionary:
	return items.get(id, {})


func recipe(id: String) -> Dictionary:
	return recipes.get(id, {})


func quest(id: String) -> Dictionary:
	return quests.get(id, {})


func enemy(id: String) -> Dictionary:
	return enemies.get(id, {})


func region(id: String) -> Dictionary:
	return regions.get(id, {})


func skill(id: String) -> Dictionary:
	return skills.get(id, {})


func lore_entry(id: String) -> Dictionary:
	return lore.get(id, {})


func build(id: String) -> Dictionary:
	return builds.get(id, {})


func dialogue_for(id: String) -> Dictionary:
	return dialogue.get(id, {})


func recipes_known(state: GameState) -> Array:
	var out: Array = []
	for id in recipes.keys():
		var r: Dictionary = recipes[id]
		if bool(r.get("known", false)) or state.get_flag("recipe_%s" % id):
			out.append(id)
	return out


func can_craft(state: GameState, recipe_id: String) -> bool:
	var r := recipe(recipe_id)
	if r.is_empty():
		return false
	var cost: Dictionary = r.get("cost", {})
	for item_id in cost.keys():
		if state.item_count(String(item_id)) < int(cost[item_id]):
			return false
	return true


func validate() -> void:
	errors.clear()
	for id in recipes.keys():
		var r: Dictionary = recipes[id]
		var out := String(r.get("output", ""))
		if out not in ["upgrade_weapon", "upgrade_cloak"] and not items.has(out):
			errors.append("Recipe %s outputs unknown item %s" % [id, out])
		for mat in r.get("cost", {}).keys():
			if not items.has(String(mat)):
				errors.append("Recipe %s costs unknown item %s" % [id, mat])
	for id in items.keys():
		var it: Dictionary = items[id]
		if not it.has("name") or not it.has("kind"):
			errors.append("Item %s is missing name/kind" % id)
	for id in enemies.keys():
		if not enemies[id].has("health"):
			errors.append("Enemy %s is missing health" % id)
	for id in quests.keys():
		if not quests[id].has("stages"):
			errors.append("Quest %s is missing stages" % id)
	for id in dialogue.keys():
		var d: Dictionary = dialogue[id]
		var nodes: Dictionary = d.get("nodes", {})
		if not nodes.has(String(d.get("start", ""))):
			errors.append("Dialogue %s has no valid start node" % id)
		for nid in nodes.keys():
			var node: Dictionary = nodes[nid]
			if node.has("next") and not nodes.has(String(node["next"])):
				errors.append("Dialogue %s node %s points to missing next %s" % [id, nid, node["next"]])
			for choice in node.get("choices", []):
				if not nodes.has(String(choice.get("next", ""))):
					errors.append("Dialogue %s node %s points to missing choice target" % [id, nid])
	if not errors.is_empty():
		for e in errors:
			push_error("[ContentDB] " + e)
