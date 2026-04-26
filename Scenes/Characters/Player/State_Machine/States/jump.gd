# jump.gd  –  attach to State_Transition_Manager/Jump
extends Node

var _sm: Node
func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _on_jump_state_entered() -> void:
	_get_sm().anim.play("Jump_main", -1, 2.0)

func _on_jump_state_physics_processing(_delta: float) -> void:
	pass  # Physics handled by Jump_and_Gravity_Manager

func _on_jump_state_exited() -> void:
	pass
