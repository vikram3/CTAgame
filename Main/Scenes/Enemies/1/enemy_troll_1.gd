extends CharacterBody2D

@export var patrol_speed : float = 25.0
@export var chase_speed : float = 50.0
@export var accel:float = 140.0
@export var follow_distance:float = 100.0
@export var attack_range:float = 20.0

@export var gravity:float = 500.0

@export var stats: Stats
@export var body:MeshInstance2D
@export var sight: RayCast2D


func _physics_process(delta: float) -> void:
	move_and_slide()
	_gravity(delta)

func _gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += gravity * delta

func get_direction() -> Vector2:
	var direction = Global.player.global_position - self.global_position
	var dir = direction.normalized()
	return dir

func get_distance_to_player() -> float:
	if Global.player:
		return global_position.distance_to(Global.player.global_position)
	return INF
