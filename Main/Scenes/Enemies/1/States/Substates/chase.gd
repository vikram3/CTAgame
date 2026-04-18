extends Node

var stuck_timer = 0.0
var last_position = Vector2.ZERO
const STUCK_TIME = 0.8
const STUCK_THRESHOLD = 2.0

func _on_chase_state_entered() -> void:
	var enemy = get_parent().parent
	enemy.current_state = "chase"  # ADD THIS
	last_position = enemy.global_position
	stuck_timer = 0.0

func _on_chase_state_physics_processing(delta: float) -> void:
	var enemy = get_parent().parent

	if not enemy.is_on_floor():
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, enemy.accel * delta)
		return

	# Stop at edge, count as stuck
	if not enemy.has_floor_ahead():
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, enemy.accel * delta)
		stuck_timer += delta
		if stuck_timer >= STUCK_TIME:
			get_parent().state_chart.send_event("patrol")
		return

	var direction_to_player = enemy.get_direction().x

	# Stuck on wall detection
	var distance_moved = enemy.global_position.distance_to(last_position)
	if distance_moved < STUCK_THRESHOLD:
		stuck_timer += delta
		if stuck_timer >= STUCK_TIME:
			get_parent().state_chart.send_event("patrol")
			return
	else:
		stuck_timer = 0.0
		last_position = enemy.global_position

	if is_zero_approx(direction_to_player):
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, enemy.accel * delta)
		return

	enemy.velocity.x = move_toward(
		enemy.velocity.x,
		direction_to_player * enemy.chase_speed,
		enemy.accel * delta
	)
	_update_facing(enemy, direction_to_player)



func _update_facing(enemy: CharacterBody2D, direction_to_player: float) -> void:
	if not is_zero_approx(direction_to_player):
		enemy.update_facing(direction_to_player)
		#enemy.body.scale.x = sign(direction_x) * abs(enemy.body.scale.x)
