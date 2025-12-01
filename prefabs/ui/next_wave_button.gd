# res://prefabs/ui/next_wave_button.gd
extends Button

@onready var arena = $".."

func _ready():
	# Connect the button pressed signal
	pressed.connect(_on_pressed)
	# Try to find the arena now (may not yet be available)
	arena = get_tree().get_first_node_in_group("arena")
	if not arena:
		# Fallback: maybe the button is a child of the arena or scene root has an Arena node
		if get_parent() and get_parent().has_method("start_wave"):
			arena = get_parent()
		else:
			var root_scene = get_tree().get_current_scene()
			if root_scene and root_scene.has_node("Arena"):
				var possible = root_scene.get_node("Arena")
				if possible and possible.has_method("start_wave"):
					arena = possible
	# Connect to arena signals if available
	update_button_text()

func _on_pressed():
	print("Next Wave button pressed!")
	arena.start_wave()
	if arena.has_method("update_monster"):
		arena.update_monster()
	disabled = true
	update_button_text()

func update_button_text():
	if arena and arena.has_method("get_current_wave") and arena.has_method("get_total_waves"):
		var next_wave = arena.get_current_wave() + 1
		if next_wave <= arena.get_total_waves():
			text = "Start Wave %d" % next_wave
		else:
			text = "All Waves Complete"
			disabled = true
	else:
		text = "Start Wave"

# Connect this to the arena's wave_ready signal (if present)
func _on_arena_wave_ready(next_wave_number):
	disabled = false
	update_button_text()
