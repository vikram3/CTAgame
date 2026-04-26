# counter.gd  –  attach to State_Transition_Manager/Counter
# Played after a successful parry + Attack press.
extends Node

var _sm: Node
func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _on_counter_state_entered() -> void:
	var p = _get_sm().get_parent()
	p.velocity               = Vector2.ZERO
	_get_sm().hurt_box.disabled = true
	_get_sm().anim.play("Counter")
	# Animation calls _reset() via an animation track Method call at the last frame

# Called from AnimationPlayer animation track on the Counter animation's last frame
func _reset() -> void:
	var p = _get_sm().get_parent()
	p.doing_counter              = false
	_get_sm().hurt_box.disabled  = false
	_get_sm().anim.play("Idle_Main")   # return to idle cleanly

func _on_counter_state_exited() -> void:
	var p = _get_sm().get_parent()
	p.doing_counter = false
	_get_sm().hurt_box.disabled = false
