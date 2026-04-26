# double_jump.gd  –  attach to State_Transition_Manager/Double_Jump
extends Node

var _player: CharacterBody2D
var _sm: Node

func _get_player() -> CharacterBody2D:
	if _player == null: _player = get_parent().get_parent()
	return _player

func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _on_double_jump_state_entered() -> void:
	if _get_sm().anim.has_animation("Double_jump_main"):
		_get_sm().anim.play("Double_jump_main")
	_get_player().emit_signal("double_jump")

func _on_double_jump_state_physics_processing(_delta: float) -> void:
	pass  # Physics handled by Jump_and_Gravity_Manager

func _on_double_jump_state_exited() -> void:
	pass
