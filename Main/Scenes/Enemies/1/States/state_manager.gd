extends Node

@export var parent:CharacterBody2D
@export var state_chart:StateChart

func _transition():
	if parent.get_distance_to_player() > parent.attack_range:
		if parent.get_distance_to_player() > parent.follow_distance:
			state_chart.send_event("patrol")
		else:
			state_chart.send_event("chase")
	else:
		state_chart.send_event("attack")
