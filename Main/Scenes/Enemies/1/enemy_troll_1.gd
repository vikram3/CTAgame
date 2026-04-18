extends CharacterBody2D

@export var patrol_speed: float = 25.0
@export var chase_speed: float = 50.0
@export var accel: float = 140.0
@export var follow_distance: float = 100.0
@export var attack_range: float = 20.0
@export var gravity: float = 500.0
@export var stats: Stats
@export var body: MeshInstance2D
@export var sight: RayCast2D
var current_state: String = "patrol"  # track state manually
@onready var state_manager: Node = $State_Manager
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	state_manager._transition()
	_apply_gravity(delta)
	# Flip raycast to always point forward
	sight.target_position.x = abs(sight.target_position.x) * sign(body.scale.x)
	move_and_slide()
	_update_animation()

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += gravity * delta

func _update_animation() -> void:
	if current_state in ["attack", "hurt", "death"]:
		return
	if abs(velocity.x) > 1.0:
		animation_player.play("walk")
	else:
		animation_player.play("idle")

func update_facing(direction_x: float) -> void:
	#print("update_facing called with: ", direction_x)
	if not is_zero_approx(direction_x):
		body.scale.x = abs(body.scale.x) * sign(direction_x)
		#print("body.scale.x is now: ", body.scale.x)

func has_floor_ahead() -> bool:
	return sight.is_colliding()

func get_direction() -> Vector2:
	if not Global.player:
		return Vector2.ZERO
	return (Global.player.global_position - global_position).normalized()

func get_distance_to_player() -> float:
	if Global.player:
		return global_position.distance_to(Global.player.global_position)
	return INF

func take_damage(amount: int) -> void:
	print("take_damage called, amount: ", amount, " | health: ", stats.health)
	if stats.health <= 0:
		return
	stats.health -= amount
	_flash()
	print("health after hit: ", stats.health)
	if stats.health <= 0:
		print("sending death event")
		state_manager.state_chart.send_event("death")
	else:
		print("sending hurt event")
		state_manager.state_chart.send_event("hurt")

func _flash() -> void:
	body.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	body.modulate = Color.WHITE
