extends Node

@export var hurt_box:Area2D

func _on_hurt_box_area_entered(area):
	var player = get_parent().parent
	if player.is_dead or player.is_hurt:
		return
	
	player.velocity = Vector2.ZERO
	player.clear_attack_buffer()
	player.clear_attack_hitboxes()
	player.can_block = true
	player.can_attack = true
	player.can_ground_dash = true
	player.can_air_dash = true
	player.parried = false
	player.doing_counter = false
	player.suspend_air_physics = false
	player.is_hurt = true
	
	hurt_box.apply_damage(area.do_damage())
	
	if player.is_dead:
		get_parent().state_chart.send_event("dead")
		return
	
	player.apply_force(Vector2(area.get_parent().scale.x, 0.1), 22)
	if Global.cam:
		Global.cam.screen_shake(8,0.1)
	Global._freeze(0.1,0.4)
	get_parent().state_chart.send_event("hurt")

func _on_hurt_state_entered():
	get_parent().anim.play("Hurt", -1, 1.5)
	var finished_anim: StringName = await get_parent().anim.animation_finished
	if finished_anim == &"Hurt":
		get_parent().parent.is_hurt = false

func _on_hurt_state_physics_processing(delta):
	get_parent().parent.can_ground_dash = true
	get_parent().parent.can_air_dash = true
	get_parent().parent.can_attack = true
