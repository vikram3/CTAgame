extends Attacks

@export var slam_start_speed: float = 130.0
@export var slam_fall_accel: float = 1250.0
@export var slam_max_fall_speed: float = 520.0

func _on_combo_1_state_entered():
	var player = get_parent().parent
	player.suspend_air_physics = true
	player.velocity = Vector2.ZERO
	_enter_combo(1, "Air_Attack_1")

func _on_combo_2_state_entered():
	get_parent().parent.suspend_air_physics = false
	_enter_combo(2, "Air_Attack_2")

func _on_combo_3_state_entered():
	var player = get_parent().parent
	player.suspend_air_physics = true
	player.velocity.x = 0.0
	player.velocity.y = max(player.velocity.y, slam_start_speed)
	_enter_combo(3, "Air_Attack_3")

func _on_combo_state_physics_processing(delta):
	_next_attack()
	
	var player = get_parent().parent
	if current_combo == 1:
		player.velocity = Vector2.ZERO
		return
	
	if current_combo == 3:
		player.velocity.x = 0.0
		player.velocity.y = min(player.velocity.y + slam_fall_accel * delta, slam_max_fall_speed)

func _on_combo_3_state_processing(delta: float) -> void:
	pass

func _on_combo_state_exited():
	super._on_combo_state_exited()
	get_parent().parent.suspend_air_physics = false
