extends Node

var counter_active := false

func _on_counter_state_entered() -> void:
	counter_active = true
	get_parent().parent.velocity = Vector2.ZERO
	get_parent().parent.parried = false
	get_parent().parent.doing_counter = true
	get_parent().parent.clear_attack_buffer()
	get_parent().check_hit.disabled = true
	get_parent().hurt_box.disabled = true
	get_parent().anim.play("Counter")
	
	var finished_anim: StringName = await get_parent().anim.animation_finished
	if counter_active and finished_anim == &"Counter":
		_reset()

func _reset(send_transition: bool = true):
	if !counter_active:
		return
	
	counter_active = false
	get_parent().parent.doing_counter = false
	get_parent().parent.can_attack = true
	get_parent().parent.can_block = true
	get_parent().parent.can_ground_dash = true
	get_parent().hurt_box.disabled = false
	get_parent().check_hit.disabled = true
	
	if !send_transition:
		return
	
	if get_parent().parent._set_direction().x != 0:
		get_parent().state_chart.send_event("run")
	else:
		get_parent().state_chart.send_event("idle")

func _on_counter_state_exited() -> void:
	if counter_active:
		_reset(false)
