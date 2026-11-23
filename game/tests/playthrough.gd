extends Node
## End-to-end vertical-slice playthrough through real nodes and real dialogue.
## This is deliberately not a mock: it walks the same quest chain a player does.

var passed := 0
var failed := 0
var failures: Array[String] = []
var world: WorldDirector
var dialogue: DialogueBox


func _ready() -> void:
	await get_tree().process_frame
	Game.new_game({"name": "Playthrough", "pronouns": "they", "palette": 1, "ear": "reed"})
	world = WorldDirector.new()
	add_child(world)
	world.build("bellhollow", "arrival")
	dialogue = DialogueBox.new()
	add_child(dialogue)
	await get_tree().process_frame

	# 1. Wren at the road.
	var wren := _find_npc(world.region, "Wren")
	check(wren != null, "Wren is in Bellhollow")
	if wren != null:
		wren.interact(world.player)
		await get_tree().process_frame
		check(dialogue.debug_is_open(), "Wren conversation opens")
		dialogue.debug_advance()
		dialogue.debug_choose(0)
		dialogue.debug_advance()
		dialogue.debug_choose(0)
		dialogue.debug_advance()
		await get_tree().process_frame
		check(Game.state.quest_stage("main_01") == 1, "Wren starts the story")
		dialogue.debug_close()

	# 2. Pell's briefing.
	var pell := _find_npc(world.region, "Pell")
	check(pell != null, "Pell is at the Listening House")
	if pell != null:
		pell.interact(world.player)
		await get_tree().process_frame
		dialogue.debug_advance()
		dialogue.debug_choose(0)
		await get_tree().process_frame
		check(Game.state.quest_stage("main_01") == 2, "Pell names the Quarry Door")
		dialogue.debug_close()

	# 3. Sable's commission.
	var sable := _find_npc(world.region, "Sable")
	check(sable != null, "Sable is in the tower yard")
	if sable != null:
		sable.interact(world.player)
		await get_tree().process_frame
		dialogue.debug_choose(0)
		await get_tree().process_frame
		check(Game.state.quest_stage("main_02") == 0, "Sable sends you to the Choir")
		dialogue.debug_close()

	# 4. Nissa joins.
	var nissa := _find_npc(world.region, "Nissa")
	check(nissa != null, "Nissa is at the ferry")
	if nissa != null:
		nissa.interact(world.player)
		await get_tree().process_frame
		dialogue.debug_choose(0)
		await get_tree().process_frame
		dialogue.debug_advance()
		await get_tree().process_frame
		check(Game.state.quest_stage("main_02") == 1, "Nissa asks for the resonance fork")
		check(bool(Game.state.companion("nissa").get("active", false)), "Nissa joins the party")
		dialogue.debug_close()

	# 5. Gather the fork materials from real pickups.
	for prompt_part in ["copper", "copper", "humstone", "resin", "resin"]:
		var pickup := _find_prompt(world.region, "Take " + prompt_part)
		if pickup != null:
			pickup.interact(world.player)
	await get_tree().process_frame
	check(Game.state.item_count("copper_scrap") >= 3, "enough copper for the fork")
	check(Game.state.item_count("humstone_shard") >= 1, "enough humstone for the fork")
	check(Game.state.item_count("resin") >= 2, "enough resin for the fork")
	check(Game.content.can_craft(Game.state, "resonance_fork"), "the fork is craftable")
	for mat in ["copper_scrap", "resin", "humstone_shard"]:
		Game.state.remove_item(mat, 99)
	Game.state.add_item("resonance_fork", 1)
	Game.state.set_quest("main_02", 2)

	# 6. Ferry to Reedwater.
	var ferry := _find_prompt(world.region, "Take the ferry")
	check(ferry != null, "ferry interactable exists")
	if ferry != null:
		ferry.interact(world.player)
		await get_tree().create_timer(1.2).timeout
		check(world.region_id == "reedwater", "the ferry reaches Reedwater")

	# 7. Clear the choke and open the gate.
	var choke := _find_prompt(world.region, "Clear the choke")
	check(choke != null, "the choke exists")
	if choke != null:
		choke.interact(world.player)
		await get_tree().process_frame
		check(Game.state.quest_stage("main_02") == 3, "the choke clears")
	var gate := world.region.get_node_or_null("ChimeGate")
	check(gate != null, "the Chime Gate exists")
	if gate != null:
		gate._cycle(1)
		gate._cycle(2)
		gate._cycle(2)
		check(gate.solved, "the gate accepts the chord")
		check(Game.state.quest_stage("main_02") == 4, "the gate unlocks the shrine")

	# 8. Enter the dungeon.
	var entrance := _find_prompt(world.region, "Descend into the Sunken Choir")
	check(entrance != null, "the shrine entrance exists")
	if entrance != null:
		entrance.interact(world.player)
		await get_tree().create_timer(1.2).timeout
		check(world.region_id == "sunken_choir", "the Sunken Choir loads")

	# 9. Sluice: open, shut, open.
	var v1 := _find_prompt(world.region, "Turn valve 1")
	var v2 := _find_prompt(world.region, "Turn valve 2")
	var v3 := _find_prompt(world.region, "Turn valve 3")
	check(v1 != null and v2 != null and v3 != null, "the sluice valves exist")
	if v1 != null and v3 != null:
		v1.interact(world.player)
		v3.interact(world.player)
		await get_tree().process_frame
		check(Game.state.puzzle_solved("sluice"), "the sluice opens")

	# 10. Face the Stag.
	var boss := _find_boss(world.region)
	check(boss != null, "the Hollow Stag is present")
	if boss != null:
		check(boss.shell_intact, "the Stag begins shelled")
		boss.ring_chime(2)
		boss.ring_chime(3)
		boss.ring_chime(1)
		check(not boss.shell_intact, "the window's chord breaks the shell")
		boss.take_damage(9999.0, 999.0, "low", world.player)
		await get_tree().create_timer(1.5).timeout
		check(Game.state.puzzle_solved("hollow_stag"), "the Stag falls")

	# 11. Take the Chime and choose.
	var chime := _find_prompt(world.region, "Take the Choir Chime")
	check(chime != null, "the Choir Chime is on the altar")
	if chime != null:
		chime.interact(world.player)
		await get_tree().process_frame
		check(dialogue.debug_is_open(), "the choice conversation opens")
		dialogue.debug_advance()
		await get_tree().process_frame
		dialogue.debug_choose(0)
		await get_tree().process_frame
		check(Game.state.quest("main_02").get("state", "") == "done", "the Sunken Choir completes")
		check(String(Game.state.quest("main_02").get("choices", {}).get("outcome", "")) == "tenders", "the choice is recorded")
		dialogue.debug_close()

	# 12. The save remains portable after the ending.
	var saved := Game.save_current("playthrough", false)
	check(saved.get("ok", false), "ending save writes: %s" % saved.get("reason", ""))
	var loaded := Game.saves.load_slot("playthrough")
	check(loaded.get("ok", false), "ending save loads")
	check(Game.state.playtime_seconds >= 0.0, "playtime is tracked")

	_report()
	get_tree().quit(0 if failed == 0 else 1)


func _find_npc(node: Node, display_name: String) -> NPC:
	if node is NPC and (node as NPC).display_name == display_name:
		return node
	for child in node.get_children():
		var found := _find_npc(child, display_name)
		if found != null:
			return found
	return null


func _find_prompt(node: Node, prompt_part: String) -> Interactable:
	if node is Interactable and (node as Interactable).prompt_text().contains(prompt_part):
		return node
	for child in node.get_children():
		var found := _find_prompt(child, prompt_part)
		if found != null:
			return found
	return null


func _find_boss(node: Node) -> HollowStagBoss:
	if node is HollowStagBoss:
		return node
	for child in node.get_children():
		var found := _find_boss(child)
		if found != null:
			return found
	return null


func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		failures.append(message)
		push_error(message)


func _report() -> void:
	print("\n=== Playthrough report ===")
	print("passed: %d   failed: %d" % [passed, failed])
	for f in failures:
		print("FAIL: ", f)
	print("=========================\n")
