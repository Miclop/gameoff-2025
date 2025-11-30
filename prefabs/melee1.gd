extends "res://prefabs/hero_base.gd"

func _ready():
	hero_name = "Melee 1"
	reaction_time = 0.3
	max_health = 120
	movement_speed = 250.0
	attack_speed = 1.2
	
	sprite.texture = load("res://images/heros/meele1.png")
	super._ready()
