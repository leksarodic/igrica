extends Node
## Integration test: builds real regions, drives real dialogue, solves real
## puzzles, and verifies that the save/world flags survive. Run with:
##   godot --headless --path game res://tests/Integration.tscn

var passed := 0
var failed := 0
var failures: Array[String] = []
var world: WorldDirector
var dialogue: DialogueBox


func _ready() -> void:
	await get_tree().process_frame
	Game.new_game({"name": "Tester", "pronouns": "they", "palette": 2, "ear": "bell"})
	world = WorldDirector.new()
	add_child(world)
	world.build("bellhollow", "arrival")
	await get_tree().process_frame
	check(world.player != null, "player exists")
	check(world.region_id == "bellhollow", "bellhollow built")
	check(world.player.global_position.distance_to(Vector3.ZERO) < 80.0, "player has a sane spawn")
	check(world.region.lanterns.size() >= 4, "lanterns placed")
	var roost := _find_prompt(world.region, "Coax the bell")
	check(roost != null, "Pip's roost exists")
	if roost != null:
		roost.interact(world.player)
		await get_tree().process_frame
		check(Game.state.item_count("copper_bell") == 1, "Pip trades a copper bell for a hum-reed")
		check(Game.state.quest_stage("side_pip") == 2, "Pip's Bell advances")

	dialogue = DialogueBox.new()
	add_child(dialogue)
	await get_tree().process_frame
	Events.dialogue_started.emit("wren_arrival")
	await get_tree().process_frame
	check(dialogue.debug_is_open(), "Wren dialogue opens")
	dialogue.debug_advance() # start -> ask
	dialogue.debug_choose(0) # place
	dialogue.debug_advance() # place -> ask2
	dialogue.debug_choose(0) # returning
	dialogue.debug_advance() # returning -> start_point
	await get_tree().process_frame
	check(Game.state.quest_stage("main_01") == 1, "Wren advances main_01")
	dialogue.debug_close()

	# Pell's briefing and Sable's offer are data-driven.
	Events.dialogue_started.emit("pell_hub")
	await get_tree().process_frame
	check(dialogue.debug_is_open(), "Pell dialogue opens")
	dialogue.debug_advance() # start -> ask
	dialogue.debug_choose(0) # the Quarry Door
	await get_tree().process_frame
	check(Game.state.quest_stage("main_01") == 2, "Pell advances main_01")
	check(bool(Game.state.get_flag("met_pell", false)), "Pell sets met_pell")
	dialogue.debug_close()

	Game.state.set_quest("main_02", 0)
	Events.dialogue_started.emit("sable_hub")
	await get_tree().process_frame
	check(dialogue.debug_is_open(), "Sable dialogue opens")
	dialogue.debug_choose(0) # the north channel
	await get_tree().process_frame
	check(Game.state.quest_stage("main_02") == 0, "Sable offers the Sunken Choir")
	dialogue.debug_close()

	Events.dialogue_started.emit("nissa_ferry")
	await get_tree().process_frame
	dialogue.debug_choose(0) # choke
	await get_tree().process_frame
	check(Game.state.quest_stage("main_02") == 1, "Nissa advances to the fork")
	dialogue.debug_advance() # join node
	await get_tree().process_frame
	check(bool(Game.state.companion("nissa").get("active", false)), "Nissa becomes an active companion")
	check(Game.state.quest("main_01").get("state", "") == "done", "main_01 completes when Nissa joins")
	dialogue.debug_close()

	Events.dialogue_started.emit("brannoc_foundry")
	await get_tree().process_frame
	dialogue.debug_choose(0) # resonance fork
	await get_tree().process_frame
	check(bool(Game.state.get_flag("fork_recipe_known", false)), "Brannoc teaches the fork")
	dialogue.debug_close()
	Game.state.add_item("copper_scrap", 2)
	Game.state.add_item("humstone_shard", 1)
	Game.state.add_item("resin", 1)
	check(Game.content.can_craft(Game.state, "resonance_fork"), "fork is craftable with gathered materials")
	Game.state.remove_item("copper_scrap", 3)
	Game.state.remove_item("humstone_shard", 1)
	Game.state.remove_item("resin", 2)
	Game.state.add_item("resonance_fork", 1)
	Game.state.set_quest("main_02", 2)

	world.build("reedwater", "dock")
	await get_tree().process_frame
	check(world.region_id == "reedwater", "reedwater built")
	check(world.region.lanterns.size() >= 3, "reedwater lanterns")
	Game.state.add_item("hum_reed", 4)
	Game.state.add_item("resin", 2)
	var dock := _find_prompt(world.region, "Repair the north dock")
	check(dock != null, "the dock repair exists")
	if dock != null:
		dock.interact(world.player)
		await get_tree().process_frame
		check(bool(Game.state.world.get("ferry_repaired", false)), "the dock repair changes the world")
		check(Game.state.quest("side_ferry").get("state", "") == "done", "the ferry debt resolves")
	var gate := world.region.get_node_or_null("ChimeGate")
	check(gate != null, "chime gate exists")
	if gate != null:
		gate._cycle(1)
		gate._cycle(2)
		gate._cycle(2)
		check(gate.solved, "chime gate accepts the carving's chord")
		check(Game.state.quest_stage("main_02") >= 4, "gate advances the quest")
	Game.state.set_quest("main_02", 4)

	world.build("sunken_choir", "entrance")
	await get_tree().process_frame
	check(world.region_id == "sunken_choir", "dungeon built")
	var maze := world.region.get_node_or_null("EchoMaze")
	check(maze != null, "the echo gallery exists")
	if maze != null:
		maze._strike(0)
		maze._strike(2)
		maze._strike(1)
		check(maze.solved, "the echo gallery accepts low/high/mid")

	var boss := _find_boss(world.region)
	check(boss != null, "boss exists")
	if boss != null:
		check(boss.shell_intact, "boss starts shelled")
		boss.ring_chime(2)
		boss.ring_chime(3)
		boss.ring_chime(1)
		check(not boss.shell_intact, "boss shell breaks on the window order")
		boss.take_damage(9999.0, 999.0, "low", world.player)
		await get_tree().create_timer(1.5).timeout
		check(Game.state.puzzle_solved("hollow_stag"), "boss defeat is recorded")

	# The boss choice is data-driven too.
	Events.dialogue_started.emit("stag_choice")
	await get_tree().process_frame
	dialogue.debug_advance() # start -> ask
	await get_tree().process_frame
	dialogue.debug_choose(0) # tenders
	await get_tree().process_frame
	check(Game.state.world.get("chime_choice", "") == "tenders" or Game.state.quest("main_02").get("state", "") == "done", "the chime choice resolves")
	dialogue.debug_close()

	# Save and reload the full state.
	Game.state.set_quest("main_02", 8)
	var saved := Game.save_current("integration", false)
	check(saved.get("ok", false), "integration save writes: %s" % saved.get("reason", ""))
	if not saved.get("ok", false):
		_debug_save_diff()
	var loaded := Game.saves.load_slot("integration")
	check(loaded.get("ok", false), "integration save loads")
	if loaded.get("ok", false):
		check_eq(int(loaded["state"]["quests"]["main_02"]["stage"]), 8, "save keeps quest stage")
		check(bool(loaded["state"]["world"]["puzzles"].get("hollow_stag", false)), "save keeps boss flag")

	# Building persists and restores.
	Game.state.add_item("lantern_post_kit", 1)
	world.build("bellhollow", "arrival")
	await get_tree().process_frame
	world.build_system.begin("lantern_post")
	await get_tree().process_frame
	check(world.build_system.active, "build mode begins with a kit")
	world.build_system.confirm()
	await get_tree().process_frame
	check(Game.state.builds().size() >= 1, "a built structure is recorded")
	var built_count := Game.state.builds().size()
	world.build("bellhollow", "arrival")
	await get_tree().process_frame
	check(world.region.lanterns.size() >= 5, "built lanterns restore on region rebuild")
	check(Game.state.builds().size() == built_count, "restoring does not duplicate build records")

	# The workbench action itself (the UI path, not just the data check).
	var pause := PauseMenu.new()
	add_child(pause)
	await get_tree().process_frame
	Game.state.add_item("hum_reed", 1)
	Game.state.add_item("resin", 1)
	var tonics_before := Game.state.item_count("reed_tonic")
	pause._craft("reed_tonic")
	await get_tree().process_frame
	check(Game.state.item_count("reed_tonic") == tonics_before + 1, "workbench crafts a tonic through the UI path")
	pause.queue_free()

	# Cross-device save path writes a snapshot to a shared folder.
	Game.sync.set_root("user://test_transfer")
	var transfer := Game.save_and_continue_elsewhere()
	check(transfer.get("ok", false), "save and continue elsewhere succeeds")
	check(FileAccess.file_exists(Game.sync.snapshot_path(Game.current_slot, Game.saves.device_id)), "shared snapshot exists")

	# Input plumbing and movement.
	var before := world.player.global_position
	Input.action_press("move_forward")
	await get_tree().create_timer(0.8).timeout
	Input.action_release("move_forward")
	await get_tree().physics_frame
	var moved := world.player.global_position.distance_to(before)
	check(moved > 0.3, "player moves with input (%.2f m)" % moved)

	_report()
	get_tree().quit(0 if failed == 0 else 1)


func _debug_save_diff() -> void:
	var packed: Dictionary = Game.saves.make_save("dbg", Game.state)
	var text := JSON.stringify(packed, "\t", true, true)
	var parsed: Dictionary = JSON.parse_string(text)
	var a := JSON.stringify(Game.saves._canonical(packed["state"]), "", true, true)
	var b := JSON.stringify(Game.saves._canonical(parsed["state"]), "", true, true)
	if a == b:
		print("STATE CANONICAL MATCHES; header differs")
		var ha := JSON.stringify(Game.saves._canonical(packed["header"]), "", true, true)
		var hb := JSON.stringify(Game.saves._canonical(parsed["header"]), "", true, true)
		print("header equal: ", ha == hb)
		return
	for i in mini(a.length(), b.length()):
		if a[i] != b[i]:
			print("DIFF AT ", i)
			print("A: ", a.substr(maxi(0, i - 80), 200))
			print("B: ", b.substr(maxi(0, i - 80), 200))
			break
	print("len ", a.length(), " vs ", b.length())


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


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if str(actual) == str(expected):
		passed += 1
	else:
		failed += 1
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func _report() -> void:
	print("\n=== Integration report ===")
	print("passed: %d   failed: %d" % [passed, failed])
	for f in failures:
		print("FAIL: ", f)
	print("==========================\n")
