extends "res://prefabs/hero_base.gd"

func _ready():
	hero_name = "Healer 2"
	reaction_time = 0.8
	max_health = 75
	movement_speed = 175.0
	attack_speed = 1.0
	
	sprite.texture = load("res://images/heros/healer2.png")
	super._ready()
