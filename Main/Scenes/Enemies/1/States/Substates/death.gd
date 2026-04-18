extends Node

var death_done = false

func _on_death_state_entered() -> void:
	var enemy = get_parent().parent
	enemy.current_state = "death"  # ADD THIS
	death_done = false
	enemy.animation_player.play("death")
	enemy.get_node("Hit_Box").monitoring = false
	enemy.get_node("Hit_Box").monitorable = false
	enemy.get_node("HurtBox").monitoring = false
	enemy.get_node("HurtBox").monitorable = false
	
func _on_death_state_physics_processing(delta: float) -> void:
	var enemy = get_parent().parent
	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, enemy.accel * delta)
	
	if not enemy.animation_player.is_playing() and not death_done:
		death_done = true
		_drop_items(enemy)
		enemy.queue_free()

func _drop_items(enemy: CharacterBody2D) -> void:
	pass  # spawn your drop scene here like:
	# var drop = preload("res://items/coin.tscn").instantiate()
	# drop.global_position = enemy.global_position
	# enemy.get_parent().add_child(drop)
