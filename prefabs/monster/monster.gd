# res://prefabs/monster/monster.gd
# Edit file: res://prefabs/monster/monster.gd
extends Node2D

class_name EvolvingMonster

enum EvolutionStage {STAGE1, STAGE2, STAGE3}
enum AttackType {EYE_BEAM, TENTACLE_SMASH, OOZING_BARRAGE, SOUL_LEECH, ELDRITCH_BLAST}
var health: float = 100.0

@export var current_stage: int = EvolutionStage.STAGE1
@export var evolution_interval: int = 4  # Evolve every 4 waves
var waves_completed: int = 0

# Stats that improve with evolution

@export var Max_health: float = 100.0
@export var attack_power: float = 10.0
@export var attack_cooldown: float = 2.0

# Attack properties
@export var attack_range: float = 300.0
var attack_timer: float = 0.0
var current_target: Node2D = null

# Skill properties
@export var eye_beam_damage: float = 25.0
@export var tentacle_smash_damage: float = 40.0
@export var oozing_barrage_damage: float = 15.0
@export var soul_leech_heal: float = 30.0
@export var eldritch_blast_damage: float = 50.0

# References
@onready var sprite: Sprite2D = $Sprite2D
@export var evolution_particle_scene: PackedScene
@export var attack_particle_scene: PackedScene
var is_evolving: bool = false
var is_attacking: bool = false
var ability_order: Array = []
var next_ability =0

# Arena reference for finding enemies
@onready var arena = get_node("/root/TestScene/Arena")

signal attack_used(attack_type, target)
signal skill_activated(skill_name)

func _ready():
	# Initialize appearance
	update_appearance()

	# Connect to CardContainer to receive card order updates
	var card_container = get_tree().get_first_node_in_group("card_container")
	if card_container and card_container.has_signal("card_order_updated"):
		card_container.card_order_updated.connect(_on_card_order_updated)
		# If container can provide current order, initialize ability_order
		if card_container.has_method("get_card_order"):
			ability_order = card_container.get_card_order()
func _process(delta):
	if is_evolving or is_attacking:
		return
	
	# Attack cooldown
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		# Find a target and attack
		find_target()
		if current_target:
			use_abilities(ability_order[next_ability])
			next_ability+=1
			if next_ability ==4:
				next_ability=0 
			attack_timer = 0.0

# Call this method when a wave is completed
func on_wave_completed(wave_number: int):
	waves_completed += 1
	next_ability=0 
	print("Wave completed. Total waves: ", waves_completed)
	
	# Check if it's time to evolve (every 7 waves)
	if waves_completed % evolution_interval == 0 and current_stage < EvolutionStage.STAGE3:
		start_evolution()

func find_target():
	if arena and arena.has_method("get_enemy_count") and arena.get_enemy_count() > 0:
		var enemies = arena.current_enemies
		if enemies.size() > 0:
			# Find the closest enemy
			var closest_enemy = null
			var closest_distance = attack_range
			
			for enemy in enemies:
				if is_instance_valid(enemy):
					var distance = global_position.distance_to(enemy.global_position)
					if distance < closest_distance:
						closest_distance = distance
						closest_enemy = enemy
			
			current_target = closest_enemy

func use_random_attack():
	if not current_target:
		return
	
	var available_attacks = [AttackType.EYE_BEAM, AttackType.TENTACLE_SMASH, AttackType.OOZING_BARRAGE, AttackType.SOUL_LEECH, AttackType.ELDRITCH_BLAST]
	
	var selected_attack = available_attacks.pick_random()
	
	match selected_attack:
		AttackType.EYE_BEAM:
			eye_beam_attack()
		AttackType.TENTACLE_SMASH:
			tentacle_smash_attack()
		AttackType.OOZING_BARRAGE:
			oozing_barrage_attack()
		AttackType.SOUL_LEECH:
			soul_leech_attack()
		AttackType.ELDRITCH_BLAST:
			eldritch_blast_attack()

# Skill 1: Eye Beam - aoe attack
func eye_beam_attack():
	if not current_target or not current_target.has_method("take_damage"):
		return
	
	is_attacking = true
	print("Monster uses Eye Beam!")
	
	var damage = eye_beam_damage + (1.0*attack_power)
	var enemies = get_nearby_enemies(400.0)
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy.has_method("take_damage"):
			enemy.take_damage(int(damage))
	
	await get_tree().create_timer(0.8).timeout
	is_attacking = false

# Skill 2: Tentacle Smash - High damage area attack
func tentacle_smash_attack():
	if not current_target or not current_target.has_method("take_damage"):
		return
	
	is_attacking = true
	print("Monster uses Tentacle Smash!")
	
	var damage = tentacle_smash_damage + (1.5*attack_power)
	
	# Area effect around target
	hit_enemies_in_radius(current_target.global_position, 100.0, damage)
	
	attack_used.emit(AttackType.TENTACLE_SMASH, current_target)
	skill_activated.emit("Tentacle Smash")
	
	# Visual effect - shockwave
	create_circle_effect(current_target.global_position, 100.0, Color.PURPLE)
	
	await get_tree().create_timer(1.0).timeout
	is_attacking = false

# Skill 4: Oozing Barrage - Multiple projectiles
func oozing_barrage_attack():
	is_attacking = true
	print("Monster uses Oozing Barrage!")
	
	var damage = oozing_barrage_damage + (1.0*attack_power)
	
	# Fire multiple projectiles at different enemies
	var enemies = get_nearby_enemies(400.0)
	for i in range(min(3, enemies.size())):
		var enemy = enemies[i]
		if enemy.has_method("take_damage"):
			enemy.take_damage(int(damage))
			# Visual effect for each projectile
			create_projectile_effect(global_position, enemy.global_position, Color.GREEN)
			await get_tree().create_timer(0.2).timeout
	
	attack_used.emit(AttackType.OOZING_BARRAGE, current_target)
	skill_activated.emit("Oozing Barrage")
	
	await get_tree().create_timer(0.5).timeout
	is_attacking = false

# Skill 5: Soul Leech - Damage enemy and heal self
func soul_leech_attack():
	if not current_target or not current_target.has_method("take_damage"):
		return
	
	is_attacking = true
	print("Monster uses Soul Leech!")
	
	var damage = soul_leech_heal + attack_power * 0.6
	current_target.take_damage(int(damage))
	
	# Heal the monster
	var heal_amount = soul_leech_heal + attack_power * 0.6
	health = min(health + heal_amount, Max_health)
	
	attack_used.emit(AttackType.SOUL_LEECH, current_target)
	skill_activated.emit("Soul Leech")
	
	# Visual effect - healing particles
	create_healing_effect(global_position, Color.YELLOW)
	
	await get_tree().create_timer(0.6).timeout
	is_attacking = false

# Skill 6: Eldritch Blast - Ultimate attack (Stage 3 only)
func eldritch_blast_attack():
	if current_stage != EvolutionStage.STAGE3:
		return
	
	is_attacking = true
	print("Monster uses Eldritch Blast!")
	
	var damage = eldritch_blast_damage
	
	# Massive area damage
	var enemies = get_nearby_enemies(500.0)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(int(damage))
	
	attack_used.emit(AttackType.ELDRITCH_BLAST, current_target)
	skill_activated.emit("Eldritch Blast")
	
	# Visual effect - large explosion
	create_explosion_effect(global_position, 200.0, Color(1.0, 0.5, 0.0))  # Orange
	
	await get_tree().create_timer(1.2).timeout
	is_attacking = false

# Helper functions for area attacks
func hit_enemies_in_line(direction: Vector2, damage: float):
	var enemies = get_nearby_enemies(attack_range)
	for enemy in enemies:
		var to_enemy = (enemy.global_position - global_position).normalized()
		if direction.dot(to_enemy) > 0.9:  # Within 25 degrees of beam direction
			if enemy.has_method("take_damage"):
				enemy.take_damage(int(damage))

func hit_enemies_in_radius(center: Vector2, radius: float, damage: float):
	var enemies = get_nearby_enemies(radius + 100.0)  # Slightly larger search radius
	for enemy in enemies:
		if enemy.global_position.distance_to(center) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(int(damage))

func get_nearby_enemies(radius: float) -> Array:
	var nearby_enemies = []
	if arena and arena.has_method("get_enemy_count") and arena.get_enemy_count() > 0:
		for enemy in arena.current_enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= radius:
				nearby_enemies.append(enemy)
	return nearby_enemies

# Visual effect functions (use simple shapes instead of particles)
func create_attack_effect(position: Vector2, color: Color):
	# Backwards compatible wrapper: create a small circle indicator
	create_circle_effect(position, 20.0, color)

func create_line_effect(start: Vector2, end: Vector2, color: Color):
	# Create a Line2D between start and end and fade it out
	var line = Line2D.new()
	line.add_point(start)
	line.add_point(end)
	line.width = 8.0
	line.default_color = color
	line.antialiased = true
	get_parent().add_child(line)

	# Animate and remove
	var tween = create_tween()
	tween.tween_property(line, "modulate", Color(1,1,1,0), 0.3)
	tween.tween_callback(line.queue_free)

func create_circle_effect(center: Vector2, radius: float, color: Color):
	# Create a simple filled circle using Polygon2D and fade/scale it out
	var circle = Polygon2D.new()

	# Create a circle polygon
	var points = PackedVector2Array()
	var segments = 16
	for i in range(segments):
		var angle = i * (2 * PI) / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	circle.polygon = points
	circle.color = color
	circle.global_position = center
	get_parent().add_child(circle)

	# Animate and remove
	var tween = create_tween()
	tween.tween_property(circle, "modulate", Color(1,1,1,0), 0.5)
	tween.parallel().tween_property(circle, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_callback(circle.queue_free)

func create_projectile_effect(start: Vector2, end: Vector2, color: Color):
	# Create a small projectile shape (circle) and tween it to the target, then fade
	var p = Polygon2D.new()
	var pts = PackedVector2Array()
	var segs = 8
	for i in range(segs):
		var a = i * (2 * PI) / segs
		pts.append(Vector2(cos(a), sin(a)) * 6)
		
	p.polygon = pts
	p.color = color
	p.global_position = start
	get_parent().add_child(p)

	var tween = create_tween()
	tween.tween_property(p, "global_position", end, 0.3)
	tween.tween_property(p, "modulate", Color(1,1,1,0), 0.35)
	tween.tween_callback(p.queue_free)

func create_healing_effect(position: Vector2, color: Color):
	# Create a short healing line from the target to the monster
	create_line_effect(position, global_position, color)

func create_explosion_effect(center: Vector2, radius: float, color: Color):
	# Reuse circle effect to represent an explosion/aoe
	create_circle_effect(center, radius, color)
# Evolution functions (existing code)
func start_evolution():
	if is_evolving:
		return

	is_evolving = true
	print("Evolution starting! Current stage: ", current_stage + 1)

	if evolution_particle_scene:
		var particles = evolution_particle_scene.instantiate()
		add_child(particles)
		particles.global_position = global_position

	await get_tree().create_timer(1.5).timeout
	evolve()
	is_evolving = false

func evolve():
	match current_stage:
		EvolutionStage.STAGE1:
			current_stage = EvolutionStage.STAGE2
			Max_health *= 1.5
			attack_power *= 1.3
			attack_cooldown -=0.2
			print("Monster evolved to Stage 2!")
		EvolutionStage.STAGE2:
			current_stage = EvolutionStage.STAGE3
			Max_health *= 2.0
			attack_power *= 1.5
			attack_cooldown -=0.2
			print("Monster evolved to Stage 3!")
		EvolutionStage.STAGE3:
			print("Monster is fully evolved!")
			return

	update_appearance()
	print("New stats: ", get_stats())

func update_appearance():
	match current_stage:
		EvolutionStage.STAGE1:
			sprite.texture = load("res://images/monsters/monster1.png")
			sprite.scale = Vector2(0.1, 0.1)
		EvolutionStage.STAGE2:
			sprite.texture = load("res://images/monsters/monster2.png")
			sprite.scale = Vector2(0.125, 0.125)
		EvolutionStage.STAGE3:
			sprite.texture = load("res://images/monsters/monster3.png")
			sprite.scale = Vector2(0.15, 0.15)


func get_stats() -> Dictionary:
	return {
		"Max health": Max_health,
		"attack power": attack_power,
		"speed": attack_cooldown,
		"waves_completed": waves_completed
	}

func get_stage_name() -> String:
	match current_stage:
		EvolutionStage.STAGE1: return "Baby Monster"
		EvolutionStage.STAGE2: return "Adult Monster"
		EvolutionStage.STAGE3: return "Ancient Monster"
	return "Unknown"

func _on_card_order_updated(new_order: Array):
	ability_order = new_order
	print("Ability order updated: ", ability_order)
	# Here you would update the monster's ability execution order

func use_abilities(i:int):
	if i==0:
		eye_beam_attack()
	if i==1:
		soul_leech_attack()
	if i==2:
		tentacle_smash_attack()
	if i==3:
		oozing_barrage_attack()
	if i==4:
		eldritch_blast_attack()
func execute_ability(ability_data: Dictionary):
	# Implement your ability execution logic here
	if ability_data.has("name"):
		print("Executing ability: ", ability_data["name"])
	else:
		print("Executing ability with data: ", ability_data)
