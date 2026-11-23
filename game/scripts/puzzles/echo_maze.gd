class_name EchoMaze
extends Node3D
## Three hidden echo stones in a dark gallery. The carving shows the order;
## the Listen pulse reveals which stone is which. No guessing, no timers.

var values: Array[int] = []
var target := [1, 3, 2]
var solved := false
var _stones: Array[Node3D] = []
var _marks: Array[Node3D] = []


func build(parent: Node3D, origin: Vector3, reward_parent: Node3D) -> void:
	position = origin
	parent.add_child(self)
	for i in 3:
		var root := Node3D.new()
		root.position = Vector3(-3.0 + i * 3.0, 0, 0)
		add_child(root)
		var mi := MeshInstance3D.new()
		mi.mesh = MeshFactory.chime_column_mesh(1.8)
		mi.visible = false
		root.add_child(mi)
		var it := Interactable.new()
		it.position = Vector3(0, 0.9, 0)
		it.configure("Strike the echo stone", func(_p, _n): _strike(i))
		root.add_child(it)
		_stones.append(root)
		add_child(_marker(root.position + Vector3(0, 2.1, 0)))
	# A reward appears when the sequence resolves.
	var reward := Interactable.new()
	reward.position = Vector3(0, 0.3, -4.0)
	var b := MeshBuilder.new()
	b.add_box(Vector3(0.6, 0.4, 0.5), Palette.WOOD_DARK, Vector3(0, 0.2, 0))
	b.add_box(Vector3(0.5, 0.06, 0.4), Palette.COPPER, Vector3(0, 0.43, 0))
	reward.add_child(_mesh_from(b))
	reward.configure("Open the cache", func(_p, n):
		Game.state.add_item("echo_glass", 2)
		Game.state.add_item("humstone_shard", 1)
		Game.state.add_lore("echo_maze")
		AudioDirector.play_sfx("pickup", n.global_position, -3.0)
		Events.notification.emit("A Cantor cache: echo glass and a humstone shard.")
		n.queue_free()
	)
	reward.visible = false
	reward.name = "Cache"
	add_child(reward)


func _marker(pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := MeshBuilder.new()
	b.add_sphere(0.06, 5, 3, Palette.MINT)
	mi.mesh = b.commit(MeshFactory.emissive_material(Palette.MINT, 2.0))
	mi.position = pos
	mi.visible = false
	_marks.append(mi)
	return mi


func _strike(index: int) -> void:
	if solved:
		return
	values.append(index + 1)
	var idx := values.size() - 1
	if idx >= target.size():
		values.clear()
		return
	if values[idx] != target[idx]:
		values.clear()
		AudioDirector.play_sfx("puzzle_bad", global_position, -8.0)
		Events.notification.emit("The echo breaks. The carving shows: low, high, mid.")
		return
	AudioDirector.play_sfx("ui_click", global_position, -6.0, 0.9 + index * 0.15)
	if values.size() == target.size():
		solved = true
		Game.state.mark_puzzle("echo_maze", true)
		Game.state.set_quest("main_02", 6)
		var cache := get_node_or_null("Cache")
		if cache != null:
			cache.visible = true
		AudioDirector.play_sfx("puzzle_good", global_position, -2.0)
		Events.notification.emit("The echo resolves. A cache opens in the dark.")
		Events.puzzle_solved.emit("echo_maze")


func reveal() -> void:
	for i in _stones.size():
		var stone := _stones[i]
		for child in stone.get_children():
			if child is MeshInstance3D:
				child.visible = true
		if i < _marks.size():
			_marks[i].visible = true
			var tween := create_tween()
			tween.tween_interval(4.0)
			tween.tween_callback(func():
				if is_instance_valid(_marks[i]):
					_marks[i].visible = false
					for child in stone.get_children():
						if child is MeshInstance3D:
							child.visible = false
			)


func _mesh_from(builder: MeshBuilder) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = builder.commit(MeshFactory.world_material())
	return mi
