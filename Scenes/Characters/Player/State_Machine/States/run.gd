# run.gd  –  attach to State_Transition_Manager/Run
extends Node

@export var speed: float = 100.0
@export var accel: float = 80.0

var _player: CharacterBody2D
var _sm: Node

func _get_player() -> CharacterBody2D:
	if _player == null: _player = get_parent().get_parent()
	return _player

func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _on_run_state_entered() -> void:
	_get_sm().anim.play("Run_Main", -1, -1)  # -1 speed = use anim's own speed

func _on_run_state_physics_processing(delta: float) -> void:
	var p = _get_player()
	p.velocity.x = lerp(p.velocity.x, speed * p._set_direction().x, accel * delta)

func _on_run_state_exited() -> void:
	var p = _get_player()
	# Only play Run_End when stopping on ground (not when jumping/dashing)
	if p._set_direction().x == 0.0 and p.is_on_floor():
		_get_sm().anim.play("Run_End")
