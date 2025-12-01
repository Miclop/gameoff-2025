# res://prefabs/draggable_card.gd
extends Control
 
@export var card_text: String = "Card"
@export var card_texture: Texture2D

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var card_index: int = 0
var card_pindex: int = 0

var card_container: Control = null
@onready var texture_rect = $TextureRect
@onready var label = $Label

signal card_dragged(card)
signal card_dropped(card)

func _ready():
	# Set up the card appearance and mouse interaction
	setup_card_appearance()
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# Record initial position
	original_position = global_position
	# Try to find the card container (by group or common path)
	card_container = get_tree().get_first_node_in_group("card_container")
	if not card_container:
		if has_node("/root/Node2D/CardContainer"):
			card_container = get_node("/root/Node2D/CardContainer")

func setup_card_appearance():
	# Configure the texture rect to fill the card area
	if texture_rect:
		#texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		#texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		update_texture()

	# Configure the label
	if label:
		label.text = card_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 16)
func update_texture():
	if card_texture:
		texture_rect.texture = card_texture
	else:
		# If there's no texture, create a simple colored background
		# Remove any existing ColorRect
		for child in get_children():
			if child is ColorRect:
				child.queue_free()
		var color_rect = ColorRect.new()
		color_rect.color = Color(1, 0.3, 0.5)
		# Make sure it fills the control
		color_rect.anchor_left = 0
		color_rect.anchor_top = 0
		color_rect.anchor_right = 1
		color_rect.anchor_bottom = 1
		add_child(color_rect)
		move_child(color_rect, 0)

func _on_mouse_entered():
	# Slightly scale up on hover for visual feedback
	if not is_dragging:
		scale = Vector2(1.05, 1.05)

func _on_mouse_exited():
	if not is_dragging:
		scale = Vector2(1, 1)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_dragging()
			else:
				stop_dragging()

func start_dragging():
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	original_position = global_position
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100  # Bring to front
	scale = Vector2(1.1, 1.1)  # Slightly enlarge when dragging
	card_dragged.emit(self)
	get_viewport().set_input_as_handled()

func stop_dragging():
	if is_dragging:
		is_dragging = false
		mouse_filter = Control.MOUSE_FILTER_PASS
		z_index = 0
		scale = Vector2(1, 1)
		# Determine if the card was dropped over the card container; if not, restore position
		var mouse_pos = get_global_mouse_position()
		var dropped_inside = false
		if card_container and card_container is Control:
			if card_container.has_method("get_global_rect"):
				dropped_inside = card_container.get_global_rect().has_point(mouse_pos)
		# Fallback: search parent controls for a drop area
		if not dropped_inside:
			var p = get_parent()
			while p:
				if p is Control and p.has_method("_can_drop_data"):
					if p.has_method("get_global_rect"):
						dropped_inside = p.get_global_rect().has_point(mouse_pos)
					break
				p = p.get_parent()
		if not dropped_inside:
			global_position = original_position
		card_dropped.emit(self)
		get_viewport().set_input_as_handled()
func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func set_card_index(index: int):
	card_index = index

func get_card_index() -> int:
	return card_index
