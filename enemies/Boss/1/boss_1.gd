extends CharacterBody2D

@export var gravity:float = 980.0
@export var stats:Stats

var starting_pos:Vector2
var platform_positions:Array = []
var current_platform_index:int = -1

@export var body:Node2D
@export var player_detector:ShapeCast2D

var jump_to_player:bool = true
var jump:bool = false

func _ready() -> void:
	starting_pos = global_position
	_gather_platform_positions()
	player_detector.enabled = true
	_update_current_platform_index()

func _physics_process(_delta: float) -> void:
	_gravity()
	move_and_slide()
	_update_current_platform_index()

func _gravity():
	if is_on_floor() and jump == false:
		velocity.y = 0
		velocity.x = 0
	else:
		velocity.y += gravity * get_physics_process_delta_time()	

func _gather_platform_positions() -> void:
	platform_positions.clear()
	for platform in get_tree().get_nodes_in_group("platform"):
		if platform is Node2D:
			platform_positions.append(platform.global_position)

func _update_current_platform_index() -> void:
	if platform_positions.size() == 0:
		current_platform_index = -1
		return
	current_platform_index = _find_closest_platform_index()

func _find_closest_platform_index() -> int:
	var best_index:int = -1
	var best_distance:float = INF
	for i in range(platform_positions.size()):
		var distance = platform_positions[i].distance_to(global_position)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func is_player_detected() -> bool:
	if player_detector and not player_detector.enabled:
		player_detector.enabled = true
	player_detector.force_shapecast_update()
	return player_detector.is_colliding()

func choose_other_platform() -> Vector2:
	if platform_positions.size() <= 1:
		return starting_pos
	_update_current_platform_index()
	if current_platform_index < 0:
		return starting_pos
	var best_index:int = -1
	var best_distance:float = INF
	for i in range(platform_positions.size()):
		if i == current_platform_index:
			continue
		var distance = platform_positions[i].distance_to(global_position)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	if best_index == -1:
		best_index = (current_platform_index + 1) % platform_positions.size()
	return platform_positions[best_index]

func face_toward(target_pos: Vector2) -> void:
	var direction = 1 if target_pos.x >= global_position.x else -1
	if body:
		body.scale.x = abs(body.scale.x) * direction
	if has_node("sprite"):
		var sprite = $sprite
		sprite.scale.x = abs(sprite.scale.x) * direction

func face_player() -> void:
	if not Global.has_node("player"):
		return
	var player = Global.player
	if player:
		face_toward(player.global_position)
