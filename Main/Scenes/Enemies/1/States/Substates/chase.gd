extends Node

func _on_chase_state_entered() -> void:
	var enemy = get_parent().parent
	_update_facing(enemy, enemy.get_direction().x)

func _on_chase_state_physics_processing(delta: float) -> void:
	var enemy = get_parent().parent
	var direction_to_player = enemy.get_direction().x

	if is_zero_approx(direction_to_player):
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, enemy.accel * delta)
		return

	enemy.velocity.x = move_toward(
		enemy.velocity.x,
		direction_to_player * enemy.chase_speed,
		enemy.accel * delta
	)
	_update_facing(enemy, direction_to_player)

func _update_facing(enemy: CharacterBody2D, direction_x: float) -> void:
	if !is_zero_approx(direction_x):
		enemy.body.scale.x = sign(direction_x) * abs(enemy.body.scale.x)
