extends "res://prefabs/heros/hero_base.gd"

func _ready():
	hero_name = "Ranged 1"
	reaction_time = 0.6
	max_health = 90
	movement_speed = 180.0
	attack_speed = 1.8
	
	sprite.texture = load("res://images/heros/ranged1.png")
	super._ready()
