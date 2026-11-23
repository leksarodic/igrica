class_name Interactable
extends StaticBody3D
## A thing the player can address. Distance-based, verb-first, no floating icon soup.

var prompt := "Look"
var action := Callable()
var enabled := true
var context := {}


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0


func configure(text: String, callback: Callable, extra: Dictionary = {}) -> void:
	prompt = text
	action = callback
	context = extra


func prompt_text() -> String:
	return prompt if enabled else ""


func interact(player: Node) -> void:
	if not enabled:
		return
	if action.is_valid():
		action.call(player, self)
	else:
		Events.notification.emit(prompt)


func set_enabled(value: bool) -> void:
	enabled = value
