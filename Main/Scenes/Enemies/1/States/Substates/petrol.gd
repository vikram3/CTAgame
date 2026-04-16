extends Node

var direction = 1

func _on_patrol_state_entered() -> void:
	pass # Replace with function body.

func _on_patrol_state_physics_processing(delta: float) -> void:
	var enemy = get_parent().parent

	enemy.velocity.x = move_toward(
		enemy.velocity.x,
		enemy.patrol_speed * direction,
		enemy.accel * delta
	)

	if !enemy.sight.is_colliding():
		direction *= -1
		enemy.body.scale.x *= -1
	
