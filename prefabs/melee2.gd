extends "res://prefabs/hero_base.gd"

func _ready():
	hero_name = "Melee 2"
	reaction_time = 0.4
	max_health = 110
	movement_speed = 270.0
	attack_speed = 1.4
	
	sprite.texture = load("res://images/heros/meele2.png")
	super._ready()
