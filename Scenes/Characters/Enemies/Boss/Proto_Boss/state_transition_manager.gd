extends Node

@export var main_parent:CharacterBody2D
@export var anim:AnimationPlayer
@export var parent:Node
@export var state_chart:StateChart

func _on_root_behaviour_intent_idle() -> void:
	state_chart.send_event("idle")

func _on_root_behaviour_intent_attack(attack_type: Variant) -> void:
	state_chart.send_event(attack_type)

func _on_root_behaviour_intent_move() -> void:
	state_chart.send_event("move")

func _on_root_behaviour_died() -> void:
	state_chart.send_event("dead")
