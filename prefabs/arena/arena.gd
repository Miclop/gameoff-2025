# res://prefabs/arena/arena.gd
extends Node2D

class_name Arena

@export var max_enemies: int = 5
@export var spawn_interval: float = 3.0
@export var spawn_radius: float = 300.0
@export var arena_center: Vector2 = Vector2(576, 320)

@onready var botton =$"Next wave button"

# Fixed spawn points around the arena
@export var spawn_points: Array[Vector2] = [
	Vector2(0, 160),   # Top
	Vector2(160, 0),   # right
	Vector2(-160, 0),   # left
	Vector2(0, -160)    # Bottom
]

# Available hero types to spawn
@export var available_hero_types: Array[PackedScene] = [
	preload("res://prefabs/heros/tank1.tscn"),
	preload("res://prefabs/heros/tank2.tscn"),
	preload("res://prefabs/heros/melee1.tscn"),
	preload("res://prefabs/heros/melee2.tscn"),
	preload("res://prefabs/heros/ranged1.tscn"),
	preload("res://prefabs/heros/ranged2.tscn"),
	preload("res://prefabs/heros/healer1.tscn"),
	preload("res://prefabs/heros/healer2.tscn")
]

# 14 waves configuration - each wave spawns the same heroes every time
@export var wave_configurations: Array[Dictionary] = [
	# Wave 1-3: Basic waves
	{"name": "Wave 1", "hero_types": [2], "count": 1},  #Melee1
	{"name": "Wave 2", "hero_types": [0, 4], "count": 2},  # Tank1, Ranged1
	{"name": "Wave 3", "hero_types": [0, 2, 4], "count": 3},  # Tank1, Melee1, Ranged1
	
	# Wave 4-6: Balanced waves
	{"name": "Wave 4", "hero_types": [1, 3], "count": 2},  # Tank2, Melee2
	{"name": "Wave 5", "hero_types": [1, 5], "count": 2},  # Tank2, Ranged2
	{"name": "Wave 6", "hero_types": [1, 3, 5], "count": 3},  # Tank2, Melee2, Ranged2
	
	# Wave 7-9: Mixed waves
	{"name": "Wave 7", "hero_types": [0, 1, 2, 3], "count": 4},  # Both tanks, both melee
	{"name": "Wave 8", "hero_types": [0, 1, 4, 5], "count": 4},  # Both tanks, both ranged
	{"name": "Wave 9", "hero_types": [2, 3, 4, 5], "count": 4},  # Both melee, both ranged
	
	# Wave 10-12: Advanced waves with healers
	{"name": "Wave 10", "hero_types": [0, 2, 6], "count": 3},  # Tank1, Melee1, Healer1
	{"name": "Wave 11", "hero_types": [1, 3, 7], "count": 3},  # Tank2, Melee2, Healer2
	{"name": "Wave 12", "hero_types": [0, 1, 6, 7], "count": 4},  # Both tanks, both healers
	
	# Wave 13-14: Elite waves
	{"name": "Wave 13", "hero_types": [0, 1, 2, 3, 4, 5], "count": 6},  # All combat types
	{"name": "Wave 14", "hero_types": [0, 1, 2, 3, 4, 5, 6, 7], "count": 8}  # All hero types
]

var current_enemies: Array = []
var spawn_timer: float = 0.0
var is_active: bool = false
var current_wave: int = -1  # -1 means no active wave
var enemies_to_spawn: Array = []
var enemies_spawned_this_wave: int = 0
var wave_complete: bool = false
# Add reference to monster
@onready var monster = get_node("/root/TestScene/EvolvingMonster")  # Adjust path as needed
@onready var C_D = get_node("/root/TestScene/CardContainer")  

signal enemy_spawned(enemy)
signal enemy_died(enemy)
signal wave_started(wave_number, wave_name)
signal wave_preparing(wave_number, wave_name)
signal wave_completed(wave_number)
signal all_waves_completed
signal wave_ready(next_wave_number)

func _ready():
	# Add to group for easy access so UI can find this arena
	add_to_group("arena")
	# Set arena center if not specified
	if arena_center == Vector2.ZERO:
		arena_center = global_position
	# Initialize spawn points if empty
	if spawn_points.is_empty():
		setup_default_spawn_points()
	# Signal that wave 1 is ready
	wave_ready.emit(1)
func setup_default_spawn_points():
	# Create 4 spawn points around the arena center
	spawn_points = [
		arena_center + Vector2(0, 190),  # Top
		arena_center + Vector2(190, 0),   # right
		arena_center + Vector2(0, -190),   # Bottom
		arena_center + Vector2(-190, 0)     # left
	]

func start_next_wave():
	if current_wave >= wave_configurations.size() - 1:
		print("All waves completed!")
		all_waves_completed.emit()
		return
	
	current_wave += 1
	var wave_config = wave_configurations[current_wave]
	
	# Prepare wave
	wave_complete = false
	enemies_spawned_this_wave = 0
	enemies_to_spawn = []
	
	# Create the wave composition (same every time for this wave)
	var hero_indices = wave_config.get("hero_types", [])
	var wave_count = wave_config.get("count", 2)
	
	for i in range(wave_count):
		var hero_index = hero_indices[i % hero_indices.size()]
		if hero_index < available_hero_types.size():
			enemies_to_spawn.append(available_hero_types[hero_index])
	
	# Signal wave preparation
	wave_preparing.emit(current_wave + 1, wave_config.get("name", "Wave " + str(current_wave + 1)))
	
	# Start spawning after a brief delay
	await get_tree().create_timer(1.0).timeout
	
	# Start the wave
	var wave_name = wave_config.get("name", "Wave " + str(current_wave + 1))
	wave_started.emit(current_wave + 1, wave_name)
	print("Starting " + wave_name + " with " + str(enemies_to_spawn.size()) + " enemies")
	
	is_active = true
	spawn_timer = 0.0

func _process(delta):
	if not is_active or wave_complete:
		return
	
	# Remove dead enemies
	cleanup_dead_enemies()
	
	# Check if wave is complete
	if enemies_spawned_this_wave >= enemies_to_spawn.size() and current_enemies.is_empty():
		complete_current_wave()
		return
	
	# Spawn new enemies if needed
	if enemies_spawned_this_wave < enemies_to_spawn.size():
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_enemy()
			spawn_timer = 0.0

func spawn_enemy():
	if enemies_spawned_this_wave >= enemies_to_spawn.size():
		return
	
	var hero_type = enemies_to_spawn[enemies_spawned_this_wave]
	var enemy = hero_type.instantiate()
	
	# Set enemy position at a random spawn point
	var spawn_position = get_random_spawn_point()
	enemy.global_position = spawn_position
	
	# Add to scene and track
	add_child(enemy)
	current_enemies.append(enemy)
	enemies_spawned_this_wave += 1
	
	# Connect to enemy's death signal if available
	#if enemy.has_method("die"):
	#	enemy.die.connect(_on_enemy_died.bind(enemy))
	#elif enemy.has_signal("died"):
	#	enemy.died.connect(_on_enemy_died.bind(enemy))
	
	enemy_spawned.emit(enemy)
	print("Spawned enemy: ", enemy.hero_name if enemy.has_method("get_hero_name") else "Unknown")

func get_random_spawn_point() -> Vector2:
	if spawn_points.is_empty():
		return get_spawn_position()
	return spawn_points.pick_random()

func get_spawn_position() -> Vector2:
	# Fallback: generate a random position around the arena center
	var angle = randf() * 2 * PI
	var distance = randf() * spawn_radius
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return arena_center + offset

func cleanup_dead_enemies():
	var enemies_to_remove = []
	
	for enemy in current_enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			enemies_to_remove.append(enemy)
	
	for enemy in enemies_to_remove:
		current_enemies.erase(enemy)

func _on_enemy_died(enemy):
	if enemy in current_enemies:
		current_enemies.erase(enemy)
		enemy_died.emit(enemy)
		print("Enemy died: ", enemy.hero_name if enemy.has_method("get_hero_name") else "Unknown")

func complete_current_wave():
	wave_complete = true
	is_active = false
	wave_completed.emit(current_wave + 1)
	print("Wave " + str(current_wave + 1) + " completed!")
	# Notify monster about wave completion
	if monster and monster.has_method("on_wave_completed"):
		monster.on_wave_completed(current_wave + 1)
		botton._on_arena_wave_ready(current_wave + 1)
	# Signal that next wave is ready (if there is one)
	if current_wave < wave_configurations.size() - 1:
		var next_wave_config = wave_configurations[current_wave + 1]
		var next_wave_name = next_wave_config.get("name", "Wave " + str(current_wave + 2))
		wave_ready.emit(current_wave + 2)

func get_enemy_count() -> int:
	return current_enemies.size()

func get_max_enemies() -> int:
	return max_enemies

func get_current_wave() -> int:
	return current_wave + 1

func get_total_waves() -> int:
	return wave_configurations.size()

func is_wave_active() -> bool:
	return is_active

func is_wave_ready() -> bool:
	return not is_active and current_wave < wave_configurations.size() - 1

func get_next_wave_info() -> Dictionary:
	if current_wave < wave_configurations.size() - 1:
		return wave_configurations[current_wave + 1]
	return {}

func clear_all_enemies():
	for enemy in current_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	current_enemies.clear()

# Manual wave control
func force_start_wave(wave_index: int):
	if wave_index >= 0 and wave_index < wave_configurations.size():
		current_wave = wave_index - 1
		start_next_wave()

func start_wave():
	print("Arena: Starting wave!")
	# Ensure arena is in group
	add_to_group("arena")
	# Update GameState if available
	# Start the next wave (begin spawning)
	start_next_wave()

func end_wave():
	print("Arena: Ending wave!")
	# Perform cleanup and mark wave as complete
	complete_current_wave()
# Add spawn point dynamically
func add_spawn_point(position: Vector2):
	if not spawn_points.has(position):
		spawn_points.append(position)

# Remove spawn point
func remove_spawn_point(position: Vector2):
	spawn_points.erase(position)
func update_monster():
	monster._on_card_order_updated(C_D.get_card_order())
