extends Node

@export var impact_effect: AnimatedSprite2D

func _on_parry_state_entered() -> void:
	get_parent().parent.velocity = Vector2.ZERO
	get_parent().hurt_box.disabled = true
	get_parent().check_hit.disabled = true
	
	impact_effect.stop()
	impact_effect.play("Counter", 5)
	get_parent().parent.apply_force(Vector2(-get_parent().parent.body.scale.x, 0), 10)
	Global._freeze(0.1, 0.4)
	if Global.cam:
		Global.cam.screen_shake(10, 0.2)
	
	_try_start_counter()
	

func _on_parry_state_physics_processing(delta: float) -> void:
	if _try_start_counter():
		return
	
	if !impact_effect.is_playing():
		get_parent().parent.can_block = true
		get_parent().parent.parried = false

func _on_parry_state_exited() -> void:
	get_parent().parent.can_block = true
	get_parent().check_hit.disabled = true
	get_parent().hurt_box.disabled = false

func _try_start_counter() -> bool:
	var player = get_parent().parent
	if !(player.consume_attack_buffer() or Input.is_action_pressed("Attack")):
		return false
	
	player.doing_counter = true
	player.parried = false
	get_parent().state_chart.send_event("counter")
	return true
