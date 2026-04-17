extends Node

var direction = 1

func _on_patrol_state_entered() -> void:
	var enemy = get_parent().parent
	_update_facing(enemy)

func _on_patrol_state_physics_processing(delta: float) -> void:
	var enemy = get_parent().parent
	var target_speed = enemy.patrol_speed * direction

	enemy.velocity.x = move_toward(enemy.velocity.x, target_speed, enemy.accel * delta)

	if enemy.is_on_floor() and !enemy.sight.is_colliding():
		direction *= -1
		_update_facing(enemy)

func _update_facing(enemy: CharacterBody2D) -> void:
	if direction != 0:
		enemy.body.scale.x = direction * abs(enemy.body.scale.x)
