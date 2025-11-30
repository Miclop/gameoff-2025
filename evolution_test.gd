extends Node2D

@onready var monster: EvolvingMonster = $EvolvingMonster

func _ready():
	# Test the evolution system
	print("Initial stats: ", monster.get_stats())
	
	# Add experience to trigger evolution
	monster.add_experience(50.0)
	print("After 50 XP: ", monster.get_stats())
	
	monster.add_experience(60.0)  # This should trigger first evolution
	print("After 110 XP: ", monster.get_stats())
	
	monster.add_experience(200.0)  # This should trigger second evolution
	print("After 310 XP: ", monster.get_stats())
