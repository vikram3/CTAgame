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

# Top-down enemy sub-state (separate from the platformer `states` above,
# since top-down mode drives its own tiny state machine in _top_down_physics)
enum TopDownState{
	PATROL,
	CHASE,
	SEARCH
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
@export var top_down_patrol_points: Array[Vector2] = []
@export var catch_distance: float = 78.0
@export var contact_damage: int = 25

## How long (seconds) the enemy stands still "looking around" after losing the player.
@export var search_duration: float = 1.6
## How often (seconds) it flips its look direction while searching (left/right/left...).
@export var search_look_interval: float = 0.4
## How many look-flips before giving up and going back to patrol. Leave 0 to just use search_duration.
@export var search_look_count: int = 3

var direction : int = 1
var _top_down_target: Vector2
var _top_down_target_index: int = 0
var _player: Player
var _attack_cooldown: float = 0.0

var _top_down_state: TopDownState = TopDownState.PATROL
var _search_timer: float = 0.0
var _search_look_timer: float = 0.0
var _search_looks_done: int = 0
var _last_known_player_pos: Vector2


func _ready() -> void:
	if top_down_mode:
		if top_down_patrol_points.is_empty():
			top_down_patrol_points = [top_down_patrol_a, top_down_patrol_b]
		if top_down_patrol_points.size() < 2:
			top_down_patrol_a = global_position
			top_down_patrol_b = global_position + Vector2(260, 0)
			top_down_patrol_points = [top_down_patrol_a, top_down_patrol_b]
		_top_down_target_index = 1
		_top_down_target = top_down_patrol_points[_top_down_target_index]
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
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player

	var player_hidden := is_instance_valid(_player) and _player.is_hidden
	var can_see_player := player_in_range and is_instance_valid(_player) and not player_hidden
	if player_hidden:
		player_in_range = false

	# Player reappeared / came back into range at any point -> always resume chase.
	if can_see_player and _top_down_state != TopDownState.CHASE:
		_top_down_state = TopDownState.CHASE

	# Just lost the player while chasing -> start searching instead of snapping to patrol.
	if not can_see_player and _top_down_state == TopDownState.CHASE:
		_start_searching()

	match _top_down_state:
		TopDownState.CHASE:
			_process_chase(can_see_player)
		TopDownState.SEARCH:
			_process_search(delta)
		TopDownState.PATROL:
			_process_patrol(delta)


func _process_chase(can_see_player: bool) -> void:
	if not can_see_player:
		return
	var to_player := _player.global_position - global_position
	_last_known_player_pos = _player.global_position
	if to_player.length() <= catch_distance:
		_hit_player()
		return
	velocity = to_player.normalized() * chase_speed
	move_and_slide()
	_face_towards(velocity)
	if anim:
		anim.play("walk")


func _start_searching() -> void:
	_top_down_state = TopDownState.SEARCH
	_search_timer = search_duration
	_search_look_timer = search_look_interval
	_search_looks_done = 0
	velocity = Vector2.ZERO
	# First glance towards wherever the player was last headed.
	_face_towards(_last_known_player_pos - global_position)


func _process_search(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if anim:
		anim.play("idle")

	_search_timer -= delta
	_search_look_timer -= delta

	if _search_look_timer <= 0.0:
		_search_look_timer = search_look_interval
		# Flip which way it's "looking" — alternates left/right like it's scanning.
		if body:
			body.scale.x = -body.scale.x if body.scale.x != 0 else 1
		_search_looks_done += 1

	var done_looking := search_look_count > 0 and _search_looks_done >= search_look_count
	if _search_timer <= 0.0 or done_looking:
		_top_down_state = TopDownState.PATROL


func _process_patrol(delta: float) -> void:
	var to_target := _top_down_target - global_position
	if to_target.length() <= max(patrol_speed * delta, 6.0):
		global_position = _top_down_target
		_top_down_target_index = (_top_down_target_index + 1) % top_down_patrol_points.size()
		_top_down_target = top_down_patrol_points[_top_down_target_index]
		to_target = _top_down_target - global_position

	velocity = Vector2.ZERO
	if to_target.length() > 0.0:
		velocity = to_target.normalized() * patrol_speed

	move_and_slide()
	_face_towards(velocity)

	if anim:
		anim.play("walk" if velocity.length() > 1.0 else "idle")


func _face_towards(dir: Vector2) -> void:
	if body and absf(dir.x) > 1.0:
		body.scale.x = 1 if dir.x > 0.0 else -1


func _hit_player() -> void:
	if _attack_cooldown > 0.0 or not is_instance_valid(_player):
		return
	_attack_cooldown = 1.0
	velocity = Vector2.ZERO
	if anim:
		anim.play("attack")
	_player.take_level_damage(contact_damage, global_position)

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
		_player = body as Player
		player_in_range = not _player.is_hidden

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = true
		if top_down_mode:
			_player = body as Player
			if not _player.is_hidden:
				_hit_player()

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = false

func _on_idle_and_walk_timeout() -> void:
	choose_state()
