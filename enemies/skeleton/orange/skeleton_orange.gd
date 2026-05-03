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

var direction : int = 1

func _physics_process(delta: float) -> void:
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
	player_in_range = true

func _on_player_detector_body_exited(body: Node2D) -> void:
	player_in_range = false

func _on_attack_range_body_entered(body: Node2D) -> void:
	player_in_attack_range = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	player_in_attack_range = false

func _on_idle_and_walk_timeout() -> void:
	choose_state()
