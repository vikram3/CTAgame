extends Dash

func _on_ground_dash_state_entered() -> void:
	_get_player().velocity.y = 0.0
	_start_dash("Ground_dash")

func _on_ground_dash_state_physics_processing(delta: float) -> void:
	_dash_physics(delta)
	if not dashing:
		_get_player().can_ground_dash = true

func _on_ground_dash_state_exited() -> void:
	dashing = false
	_get_player().can_ground_dash = true
	_get_sm().hurt_box.disabled = false
