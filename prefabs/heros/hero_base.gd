# res://prefabs/hero_base.gd
extends Node2D

@export var hero_name: String = "Hero"
@export var reaction_time: float = 0.5  # seconds
@export var max_health: int = 100
@export var movement_speed: float = 200.0  # pixels per second
@export var attack_speed: float = 1.0  # attacks per second
@export var hero_texture: Texture2D  # Optional: set a texture per-hero in the inspector
var current_health: int

@onready var sprite = get_node_or_null("Sprite2D")
@onready var health_bar = get_node_or_null("CanvasLayer/Control/ProgressBar")

func _ready():
	# Ensure sprite exists; create if missing
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
		sprite.name = "Sprite2D"
		move_child(sprite, 0)
	# Set texture if provided
	if hero_texture:
		sprite.texture = hero_texture
	current_health = max_health
	setup_health_bar()
	update_display()

func setup_health_bar():
	if health_bar:
		# Configure the health bar
		health_bar.min_value = 0
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false
		
		# Position the health bar below the sprite
		if sprite and sprite.texture:
			var sprite_height = sprite.texture.get_height()
			health_bar.position.y = sprite_height + 5
		else:
			var sprite_height = 32
			health_bar.position.y = sprite_height + 5

func take_damage(damage: int):
	current_health -= damage
	current_health = max(0, current_health)
	update_display()
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)
	update_display()

func update_display():
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		
		# Optional: Change color based on health percentage
		var health_percentage = float(current_health) / max_health
		if health_percentage > 0.7:
			health_bar.add_theme_stylebox_override("fill", load("res://theme/green_fill.tres"))
		elif health_percentage > 0.3:
			health_bar.add_theme_stylebox_override("fill", load("res://theme/yellow_fill.tres"))
		else:
			health_bar.add_theme_stylebox_override("fill", load("res://theme/red_fill.tres"))

func die():
	queue_free()
	print(hero_name, " has died!")

# Movement function that can be overridden by specific hero types
func move_towards(target_position: Vector2, delta: float):
	var direction = (target_position - global_position).normalized()
	global_position += direction * movement_speed * delta
	
	# Update health bar position to follow the hero
	if health_bar:
		# CanvasLayer is two parents up from the ProgressBar (ProgressBar -> Control -> CanvasLayer)
		health_bar.get_parent().get_parent().offset = -global_position
