# res://game_state.gd
extends Node

# Signal emitted when wave state changes
signal wave_state_changed(is_wave_active)

var is_wave_active: bool = false

func _ready():
	# Add to a group so we can be easily found
	add_to_group("game_state")
	print("GameState loaded! is_wave_active = ", is_wave_active)

func start_wave():
	is_wave_active = true
	print("GameState: Wave started, is_wave_active = ", is_wave_active)
	wave_state_changed.emit(true)

func end_wave():
	is_wave_active = false
	print("GameState: Wave ended, is_wave_active = ", is_wave_active)
	wave_state_changed.emit(false)

func can_modify_cards() -> bool:
	return not is_wave_active

# Static method to get the GameState instance
static func get_instance() -> Node:
	var tree = Engine.get_main_loop()
	if tree is SceneTree:
		var nodes = tree.get_nodes_in_group("game_state")
		if nodes.size() > 0:
			return nodes[0]
	print("GameState instance not found!")
	return null
