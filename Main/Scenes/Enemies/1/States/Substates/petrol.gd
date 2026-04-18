extends Node

var direction = 1
var turn_cooldown = 0.0
const TURN_DELAY = 0.3

func _on_patrol_state_entered() -> void:
	var enemy = get_parent().parent
	enemy.current_state = "patrol"  # ADD THIS
	direction = 1
	turn_cooldown = 0.0
	_update_facing(enemy)

func _on_patrol_state_physics_processing(delta: float) -> void:
	var enemy = get_parent().parent

	if turn_cooldown > 0.0:
		turn_cooldown -= delta

	if not enemy.is_on_floor():
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, enemy.accel * delta)
		return

	if turn_cooldown <= 0.0 and (enemy.is_on_wall() or not enemy.has_floor_ahead()):
		direction *= -1
		_update_facing(enemy)
		turn_cooldown = TURN_DELAY

	enemy.velocity.x = move_toward(enemy.velocity.x, enemy.patrol_speed * direction, enemy.accel * delta)

func _update_facing(enemy: CharacterBody2D) -> void:
	if direction != 0:
		enemy.update_facing(float(direction))
		#enemy.body.scale.x = direction * abs(enemy.body.scale.x)
