# ═══════════════════════════════════════════════════════════════════
# idle.gd  –  attach to State_Transition_Manager/Idle  (or your SM child node)
# ═══════════════════════════════════════════════════════════════════
# idle.gd
extends Node

@export var de_accel: float = 80.0

var _player: CharacterBody2D
var _sm: Node
var _active: bool = false

func _get_player() -> CharacterBody2D:
	if _player == null: _player = get_parent().get_parent()
	return _player

func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _on_idle_state_entered() -> void:
	_active = true
	_get_sm().anim.play("Idle_Main")

func _on_idle_state_physics_processing(delta: float) -> void:
	_get_player().velocity.x = lerp(_get_player().velocity.x, 0.0, de_accel * delta)

func _on_idle_state_exited() -> void:
	_active = false

# Called when AnimationPlayer finishes any animation – we only care about Run_End
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if not _active: return
	if anim_name == "Run_End":
		_get_sm().anim.play("Idle_Main", -1, 0.5)
