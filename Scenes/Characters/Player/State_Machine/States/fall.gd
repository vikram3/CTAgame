# fall.gd  –  attach to State_Transition_Manager/Fall
extends Node

@export var land_squash_scale: Vector2 = Vector2(1.2, 0.8)
@export var land_squash_duration: float = 0.08

var _player: CharacterBody2D
var _sm: Node
var _was_falling_fast: bool = false

func _get_player() -> CharacterBody2D:
	if _player == null: _player = get_parent().get_parent()
	return _player

func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _on_fall_state_entered() -> void:
	_get_player().can_ground_dash = true   # restore ground dash on landing
	_get_sm().anim.play("Fall_Main")

func _on_fall_state_physics_processing(_delta: float) -> void:
	_was_falling_fast = _get_player().velocity.y > 200.0

func _on_fall_state_exited() -> void:
	if _was_falling_fast and _get_player().is_on_floor():
		_do_land_squash()

func _do_land_squash() -> void:
	var p  = _get_player()
	var sx = p.body.scale.x          # preserve facing direction
	var tw = p.create_tween()
	tw.tween_property(p.body, "scale", Vector2(sx * land_squash_scale.x, land_squash_scale.y), land_squash_duration)
	tw.tween_property(p.body, "scale", Vector2(sx, 1.0), land_squash_duration)
