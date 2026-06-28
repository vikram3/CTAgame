extends CharacterBody2D


enum states{
	IDLE,
	PATROL,
	CHASE,
	DASH_ATTACK,
	ATTACK,
	HURT,
	DIE
}

var player_in_range:bool = false
var player_in_attack_range :bool = false
var is_hurt:bool = false
var is_dead:bool = false

var current_states:states = states.IDLE

@export var idle_walk_timer:Timer
@export var floor_detector:RayCast2D
@export var wall_detector:RayCast2D
@export var body:Node2D
@export var stats:Stats
@export var anim:AnimationPlayer

@export var patrol_speed:float = 30.0
@export var dash_speed:float = 80.0

@export var chase_speed:float = 100.0
@export var accel:float = 100.0
@export var gravity:float = 980.0

@export var top_down_mode: bool = false
@export var top_down_patrol_a: Vector2
@export var top_down_patrol_b: Vector2
@export var restart_level_on_catch: bool = false
@export var catch_distance: float = 78.0

var direction : int = 1
var _top_down_target: Vector2
var _player: Player
var _caught: bool = false


func _ready() -> void:
	if top_down_mode:
		_top_down_target = top_down_patrol_b
		if top_down_patrol_a == Vector2.ZERO and top_down_patrol_b == Vector2.ZERO:
			top_down_patrol_a = global_position
			top_down_patrol_b = global_position + Vector2(260, 0)
			_top_down_target = top_down_patrol_b
		if anim:
			anim.play("walk")

func _physics_process(delta: float) -> void:
	if top_down_mode:
		_top_down_physics(delta)
		return

	_gravity()
	match_state()
	state_transition()
	move_and_slide()

	if wall_detector.is_colliding() or !floor_detector.is_colliding():
		direction *= -1
	
	body.scale.x = direction

func _gravity():
	if !is_on_floor():
		velocity.y += gravity * get_process_delta_time()
	else:
		velocity.y = 0


func _top_down_physics(delta: float) -> void:
	if _caught:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player

	var desired_velocity := Vector2.ZERO
	var chasing := player_in_range and is_instance_valid(_player)

	if chasing:
		var to_player := _player.global_position - global_position
		if to_player.length() <= catch_distance:
			_catch_player()
			return
		desired_velocity = to_player.normalized() * chase_speed
	else:
		var to_target := _top_down_target - global_position
		if to_target.length() <= max(patrol_speed * delta, 6.0):
			global_position = _top_down_target
			_top_down_target = top_down_patrol_a if _top_down_target == top_down_patrol_b else top_down_patrol_b
			to_target = _top_down_target - global_position
		if to_target.length() > 0.0:
			desired_velocity = to_target.normalized() * patrol_speed

	velocity = desired_velocity
	move_and_slide()

	if absf(velocity.x) > 1.0 and body:
		body.scale.x = 1 if velocity.x > 0.0 else -1

	if anim:
		anim.play("walk" if velocity.length() > 1.0 else "idle")


func _catch_player() -> void:
	if _caught:
		return
	_caught = true
	velocity = Vector2.ZERO
	if anim:
		anim.play("attack")
	if restart_level_on_catch:
		get_tree().call_deferred("reload_current_scene")

func match_state():
	match current_states:
		states.IDLE:
			anim.play("idle")
			velocity.x = 0
		states.PATROL:
			velocity.x = patrol_speed * direction
			anim.play("walk")
		states.CHASE:
			pass
		states.ATTACK:
			velocity.x = 0
			anim.play("attack")
			await anim.animation_finished
			current_states = states.IDLE
		states.HURT:
			pass
		states.DIE:
			pass

func state_transition():
	if is_dead:
		current_states = states.DIE
		return
	
	if is_hurt:
		current_states = states.HURT
		return
	
	if player_in_attack_range:
		current_states = states.ATTACK
		return
	
	#if player_in_range:
		#current_states = states.CHASE
		#return
	
	if idle_walk_timer.is_stopped():
		if current_states == states.IDLE:
			idle_walk_timer.start(1)
		else:
			idle_walk_timer.start(3)

func choose_state():
	var rand_states = [states.IDLE,states.PATROL]
	rand_states.shuffle()
	var nxt_state = rand_states[0]
	if current_states != nxt_state:
		current_states = nxt_state
	else:
		choose_state()
	

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		_player = body as Player

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = true
		if top_down_mode:
			_player = body as Player
			_catch_player()

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = false

func _on_idle_and_walk_timeout() -> void:
	choose_state()
