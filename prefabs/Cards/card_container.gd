# res://prefabs/card_container.gd
# Edit file: res://prefabs/card_container.gd
extends Control

@export var card_spacing: int = 20
@export var max_cards: int = 8
@export var starting_cards: int = 5
@export var card_size: Vector2 = Vector2(200,200)

var cards: Array = []
var card_scene = preload("res://prefabs/Cards/draggable_card.tscn")

var texture_ability_card_1 : Texture2D=load("res://images/card/Eye_beam.png")

var card_original_positions: Dictionary = {}
@onready var container = $HBoxContainer

func _ready():
	# Ensure proper container setup
	setup_container()
	
	# Create starting cards
	create_starting_cards()
	
	# Add border styling via a StyleBoxFlat
	add_theme_stylebox_override("panel", create_border_stylebox())
	
	# Enable drop detection so this container can accept dropped cards
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Track original positions of cards
	for child in container.get_children():
		if child is Control:
			card_original_positions[child] = child.global_position
	
func create_border_stylebox() -> StyleBoxFlat:
	var stylebox = StyleBoxFlat.new()
	# Background color (semi-transparent)
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	# Border widths
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	# Border color
	stylebox.border_color = Color(0.8, 0.8, 0.8)
	# Corner radii for rounded corners
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8
	# Content margins so children aren't flush with the border
	stylebox.content_margin_left = 5
	stylebox.content_margin_top = 5
	stylebox.content_margin_right = 5
	stylebox.content_margin_bottom = 5
	return stylebox

func setup_container():
	# Configure the HBoxContainer properly
	if container is HBoxContainer:
		container.add_theme_constant_override("separation", card_spacing)
		
		# Make sure the container expands properly
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Set container alignment
		container.alignment = BoxContainer.ALIGNMENT_CENTER

func create_starting_cards():
	var starting_card_data = [
		{"text": "Attack", "texture": texture_ability_card_1 },
		{"text": "Defend", "texture": texture_ability_card_1 },
		{"text": "Heal", "texture": texture_ability_card_1 },
		{"text": "Special", "texture":texture_ability_card_1 },
		{"text": "Boost", "texture":texture_ability_card_1 }
	]
	
	for i in range(min(starting_cards, starting_card_data.size())):
		var card_data = starting_card_data[i]
		add_card(card_data.text, card_data.texture)

#func _can_drop_data(position, data):
	# Accept any draggable card data
	#return data is Dictionary and data.has("card")

#func _drop_data(position, data):
	# Card was dropped on the container - update its original position
	#var card = null
	#if data is Dictionary and data.has("card"):
	#	card = data["card"]
	#if card != null and card_original_positions.has(card):
	#	card_original_positions[card] = card.global_position
#/
func get_drop_position_for_card(card):
	# Return the stored original position for this card, or container position as fallback
	return card_original_positions.get(card, global_position)
func add_card(text: String, texture: Texture2D = null) -> bool:
	if cards.size() >= max_cards:
		return false
	
	var new_card = card_scene.instantiate()
	new_card.card_text = text
	new_card.card_texture = texture
	# Set a fixed size for the card
	new_card.custom_minimum_size = card_size
	new_card.size = card_size
	
	new_card.card_dragged.connect(_on_card_dragged)
	new_card.card_dropped.connect(_on_card_dropped)
	
	container.add_child(new_card)
	card_original_positions[new_card] = new_card.global_position
	cards.append(new_card)
	update_card_indices()
	
	return true

func remove_card(card_index: int) -> bool:
	if card_index < 0 or card_index >= cards.size():
		return false
	
	var card = cards[card_index]
	card.queue_free()
	cards.remove_at(card_index)
	update_card_indices()
	
	return true

func _on_card_dragged(card: Control):
	# Visual feedback when dragging starts
	card.modulate = Color(0.8, 0.8, 1.0)
	card.z_index = 100  # Bring to front during drag

func _on_card_dropped(card: Control):
	card.modulate = Color(1, 1, 1)
	card.z_index = 0  # Reset z-index
	
	# Find the new position based on mouse position
	var mouse_pos = get_global_mouse_position()
	var new_index = find_new_card_position(mouse_pos)
	
	if new_index != card.get_card_index():
		reorder_card(card.get_card_index(), new_index)

func find_new_card_position(mouse_pos: Vector2) -> int:
	if cards.size() == 0:
		return 0
	
	# Find which card position the mouse is closest to
	for i in range(cards.size()):
		var card = cards[i]
		var card_center = card.global_position + card.size / 2
		
		# For horizontal layout, check X position
		if mouse_pos.x < card_center.x:
			return i
	
	return cards.size()

func reorder_card(old_index: int, new_index: int):
	if old_index == new_index or new_index < 0 or new_index > cards.size():
		return
	
	var card = cards[old_index]
	cards.remove_at(old_index)
	
	# Adjust new_index if we're removing from before it
	if new_index > old_index:
		new_index -= 1
	
	cards.insert(new_index, card)
	
	# Move the node in the container to maintain proper order
	container.move_child(card, new_index)
	update_card_indices()

func update_card_indices():
	for i in range(cards.size()):
		cards[i].set_card_index(i)

func get_cards() -> Array:
	return cards.duplicate()

func clear_cards():
	for card in cards:
		card.queue_free()
	cards.clear()
