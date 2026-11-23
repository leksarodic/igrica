extends Node
## Cross-cutting signals. Nothing here mutates state; listeners decide what to do.
## Gameplay nodes talk to each other directly inside a scene; this hub is only for
## concerns that genuinely span systems (saves, quests, settings, sync, UI).

signal game_started(is_new_game: bool)
signal game_loaded(slot: String)
signal game_saved(slot: String, automatic: bool)
signal save_failed(slot: String, reason: String)

signal region_entered(region_id: String)
signal region_exiting(region_id: String)
signal region_ready(region_id: String)

signal item_gained(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal inventory_changed
signal equipment_changed
signal marks_changed(amount: int)

signal quest_stage_changed(quest_id: String, stage: int)
signal quest_completed(quest_id: String, outcome: String)
signal journal_updated

signal dialogue_started(dialogue_id: String)
signal dialogue_finished(dialogue_id: String, choice_id: String)
signal dialogue_line(speaker: String, text: String, caption: String)

signal puzzle_solved(puzzle_id: String)
signal puzzle_reset(puzzle_id: String)
signal puzzle_hint(puzzle_id: String, level: int, text: String)

signal player_downed
signal player_respawned
signal player_health_changed(current: float, maximum: float)
signal companion_command(command: String)
signal companion_dialogue(speaker: String, text: String)

signal listen_pulse(origin: Vector3, radius: float)
signal noise_made(origin: Vector3, radius: float)

signal interaction_available(text: String, visible: bool)
signal open_screen(screen_id: String, context: Dictionary)
signal hint_requested
signal notification(text: String)

signal build_placed(build_id: String, position: Vector3)
signal build_removed(build_id: String)

signal sync_status_changed(status: Dictionary)
signal conflict_detected(info: Dictionary)
signal settings_changed(key: String, value: Variant)

signal boss_phase_changed(boss_id: String, phase: int)
signal boss_started(boss_name: String, maximum: float)
signal boss_health_changed(current: float, maximum: float)
signal boss_ended(boss_name: String)
signal ending_reached(ending_id: String)

signal region_transition_requested(region_id: String, spawn_id: String)
signal scene_capture_requested(path: String)
