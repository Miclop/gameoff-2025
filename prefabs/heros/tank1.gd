extends "res://prefabs/heros/hero_base.gd"

func _ready():
	hero_name = "Tank 1"
	reaction_time = 0.8
	max_health = 200
	movement_speed = 150.0
	attack_speed = 0.5
	
	sprite.texture = load("res://images/heros/tank1.png")
	super._ready()
