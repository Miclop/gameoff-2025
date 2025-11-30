# res://monster.gd
extends Node2D

class_name EvolvingMonster

enum EvolutionStage {STAGE1, STAGE2, STAGE3}

@export var current_stage: int = EvolutionStage.STAGE1
@export var evolution_interval: float = 5.0
var evolution_timer: float = 0.0

# Stats that improve with evolution
@export var health: float = 100.0
@export var attack: float = 10.0
@export var speed: float = 50.0

# References
@onready var sprite: Sprite2D = $Sprite2D
@export var evolution_particle_scene: PackedScene
var is_evolving: bool = false

func _ready():
	# Initialize appearance based on current stage
	update_appearance()

func _process(delta):
	# Accumulate time and trigger evolution every evolution_interval seconds
	if is_evolving:
		return
	evolution_timer += delta
	if evolution_timer >= evolution_interval and current_stage < EvolutionStage.STAGE3:
		evolution_timer = 0.0
		start_evolution()

func start_evolution():
	if is_evolving:
		return

	is_evolving = true
	print("Evolution starting! Current stage: ", current_stage + 1)

	# Optional particle effect during evolution
	if evolution_particle_scene:
		var particles = evolution_particle_scene.instantiate()
		add_child(particles)
		particles.global_position = global_position

	# Simulate a short evolution delay without using a Timer node
	await get_tree().create_timer(1.5).timeout

	evolve()
	is_evolving = false

func evolve():
	match current_stage:
		EvolutionStage.STAGE1:
			current_stage = EvolutionStage.STAGE2
			health *= 1.5
			attack *= 1.3
			speed *= 1.1
		EvolutionStage.STAGE2:
			current_stage = EvolutionStage.STAGE3
			health *= 2.0
			attack *= 1.5
			speed *= 1.2
		EvolutionStage.STAGE3:
			# Fully evolved - can't evolve further
			return

	update_appearance()
	print("Monster evolved to stage: ", current_stage + 1)
	print("New stats: ", get_stats())

func update_appearance():
	match current_stage:
		EvolutionStage.STAGE1:
			sprite.texture = load("res://images/monsters/monster1.png")
			sprite.scale = Vector2(0.8, 0.8)
		EvolutionStage.STAGE2:
			sprite.texture = load("res://images/monsters/monster2.png")
			sprite.scale = Vector2(1.0, 1.0)
		EvolutionStage.STAGE3:
			sprite.texture = load("res://images/monsters/monster3.png")
			sprite.scale = Vector2(1.2, 1.2)

func get_stats() -> Dictionary:
	return {
		"stage": current_stage + 1,
		"health": health,
		"attack": attack,
		"speed": speed
	}

func get_stage_name() -> String:
	match current_stage:
		EvolutionStage.STAGE1:
			return "Baby Monster"
		EvolutionStage.STAGE2:
			return "Adult Monster"
		EvolutionStage.STAGE3:
			return "Ancient Monster"
	return "Unknown"
