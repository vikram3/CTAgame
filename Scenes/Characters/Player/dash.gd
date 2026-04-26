# dash.gd  –  BASE CLASS. Do NOT attach directly.
# Place at res://Scripts/Player/dash.gd
extends Node
class_name Dash

@export var dash_speed: float      = 320.0
@export var dash_duration: float   = 0.18
@export var dash_invincible: bool  = true

var dashing: bool       = false
var dash_timer: float   = 0.0

var _player: CharacterBody2D
var _sm: Node

func _get_player() -> CharacterBody2D:
	if _player == null: _player = get_parent().get_parent()
	return _player

func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _start_dash(anim_name: String) -> void:
	dashing    = true
	dash_timer = dash_duration

	var a: AnimationPlayer = _get_sm().anim
	if a.has_animation(anim_name):
		a.play(anim_name)
	else:
		push_warning("Dash: animation '%s' not found." % anim_name)

	if dash_invincible:
		_get_sm().hurt_box.disabled = true

	var p = _get_player()
	p.velocity.x = dash_speed * p.body.scale.x   # dash in faced direction
	p.velocity.y = 0.0

func _dash_physics(delta: float) -> void:
	if not dashing: return

	var p = _get_player()
	p.velocity.x = dash_speed * p.body.scale.x
	p.velocity.y = 0.0

	dash_timer -= delta
	if dash_timer <= 0.0:
		dashing = false
		if dash_invincible:
			_get_sm().hurt_box.disabled = false
