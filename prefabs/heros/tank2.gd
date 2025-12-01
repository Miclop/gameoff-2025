extends "res://prefabs/heros/hero_base.gd"

func _ready():
	hero_name = "Tank 2"
	reaction_time = 0.7
	max_health = 180
	movement_speed = 160.0
	attack_speed = 0.6
	
	sprite.texture = load("res://images/heros/tank2.png")
	super._ready()
