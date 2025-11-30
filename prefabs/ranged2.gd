extends "res://prefabs/hero_base.gd"

func _ready():
	hero_name = "Ranged 2"
	reaction_time = 0.5
	max_health = 85
	movement_speed = 190.0
	attack_speed = 2.0
	
	sprite.texture = load("res://images/heros/ranged2.png")
	super._ready()