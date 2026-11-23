class_name ChimeGate
extends Node3D
## Three stones, three notes. The carving shows the chord; more than one voicing
## will open the gate, because the Cantors were many houses and none of them agreed.

var gate_id := "chime_gate"
var values := [1, 1, 1]
var target := [1, 2, 3]
var alternate := [3, 2, 1]
var solved := false
var barrier: Node3D
var _stones: Array[Node3D] = []
var _marks: Array[Node3D] = []
var _colors := {1: Palette.EMBER, 2: Palette.REED_GOLD, 3: Palette.MINT}
var _names := {1: "low", 2: "mid", 3: "high"}


func build(parent: Node3D, origin: Vector3, barrier_node: Node3D = null) -> void:
	position = origin
	barrier = barrier_node
	parent.add_child(self)
	for i in 3:
		var stone := Node3D.new()
		stone.position = Vector3(-3.0 + i * 3.0, 0, 0)
		add_child(stone)
		var mi := MeshInstance3D.new()
		mi.mesh = MeshFactory.chime_column_mesh(2.6)
		stone.add_child(mi)
		var it := Interactable.new()
		it.position = Vector3(0, 1.0, 0)
		it.configure("Tune the %s stone" % ["first", "second", "third"][i], func(_p, _n): _cycle(i))
		stone.add_child(it)
		_stones.append(stone)
		var mark_root := Node3D.new()
		mark_root.position = Vector3(0, 2.9, 0)
		stone.add_child(mark_root)
		_marks.append(mark_root)
	_refresh_marks()
	add_child(_make_carving())


func _make_carving() -> MeshInstance3D:
	var b := MeshBuilder.new()
	b.add_box(Vector3(2.2, 1.1, 0.18), Palette.STONE_B, Vector3(0, 1.2, -1.8))
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit(MeshFactory.world_material())
	mi.position = Vector3(0, 0, 0)
	var label := Label3D.new()
	label.text = "I   ·   II   ·   III"
	label.font_size = 48
	label.pixel_size = 0.006
	label.position = Vector3(0, 1.2, -1.69)
	label.modulate = Palette.REED_GOLD
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	mi.add_child(label)
	return mi


func _cycle(index: int) -> void:
	if solved:
		return
	values[index] = int(values[index]) % 3 + 1
	_refresh_marks()
	AudioDirector.play_sfx("ui_click", global_position, -6.0, 0.8 + values[index] * 0.15)
	_check()


func _refresh_marks() -> void:
	for i in _marks.size():
		var root := _marks[i]
		for child in root.get_children():
			child.queue_free()
		var value: int = values[i]
		for j in value:
			var mi := MeshInstance3D.new()
			var b := MeshBuilder.new()
			b.add_box(Vector3(0.14, 0.08, 0.14), _colors[value])
			mi.mesh = b.commit(MeshFactory.emissive_material(_colors[value], 2.4))
			mi.position = Vector3((j - (value - 1) * 0.5) * 0.22, 0, 0)
			root.add_child(mi)


func _check() -> void:
	if values == target or values == alternate:
		solved = true
		AudioDirector.play_sfx("puzzle_good", global_position, -2.0)
		if barrier != null and is_instance_valid(barrier):
			var tween := create_tween()
			tween.tween_property(barrier, "scale", Vector3(1.0, 0.01, 1.0), 0.8)
			tween.tween_callback(barrier.queue_free)
		if Game.state != null:
			Game.state.mark_puzzle(gate_id, true)
			Game.state.set_quest("main_02", 4)
		Events.notification.emit("The chord resolves. The reed gate opens.")
		Events.puzzle_solved.emit(gate_id)


func reset() -> void:
	values = [1, 1, 1]
	solved = false
	_refresh_marks()


func hint_text(level: int) -> String:
	if level <= 1:
		return "The carving shows three marks: one, two, three. The stones answer to low, mid, high."
	if level == 2:
		return "Set the first stone low, the second mid, the third high. Or the reverse — the gate accepts either voicing."
	return "First stone: low. Second: mid. Third: high. Or high, mid, low."
