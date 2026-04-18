extends Node

const KNOCKBACK_FORCE = 150.0

func _on_hurt_state_entered() -> void:
	var enemy = get_parent().parent
	enemy.current_state = "hurt"  # ADD THIS
	enemy.animation_player.play("hurt")
	var knockback_dir = sign(enemy.global_position.x - Global.player.global_position.x)
	enemy.velocity.x = knockback_dir * KNOCKBACK_FORCE

func _on_hurt_state_physics_processing(delta: float) -> void:
	var enemy = get_parent().parent
	
	# Slow down knockback
	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 300.0 * delta)
	
	# Return to correct state when animation finishes
	if not enemy.animation_player.is_playing():
		if enemy.get_distance_to_player() <= enemy.attack_range:
			get_parent().state_chart.send_event("attack")
		elif enemy.get_distance_to_player() <= enemy.follow_distance:
			get_parent().state_chart.send_event("chase")
		else:
			get_parent().state_chart.send_event("patrol")


func _on_hurt_state_exited() -> void:
	var enemy = get_parent().parent
	enemy.current_state = "patrol"
