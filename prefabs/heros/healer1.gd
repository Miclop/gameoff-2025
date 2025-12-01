extends "res://prefabs/heros/hero_base.gd"

func _ready():
	
	hero_name = "Healer 1"
	reaction_time = 0.9
	max_health = 80
	movement_speed = 170.0
	attack_speed = 0.8
	
	sprite.texture = load("res://images/heros/healer1.png")
	super._ready()
