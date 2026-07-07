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
	SEARCH,
	RETURN
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

@export_group("Top Down Patrol")
## Turn patrolling on/off.
@export var patrol_enabled: bool = true
## Patrol back and forth Horizontally (left/right) or Vertically (up/down).
@export_enum("Horizontal", "Vertical") var patrol_axis: String = "Horizontal"
## Total distance (px) walked along the chosen axis, centered on spawn point.
@export var patrol_distance: float = 200.0

@export_group("Top Down Combat")
## Distance at which the enemy first notices the player and starts chasing
## (assuming line-of-sight isn't blocked). This is the "detection radius" —
## separate from how close it needs to be to actually land a hit.
@export var chase_distance: float = 220.0
## Distance at which the enemy can actually land an attack on the player.
## Should be small — this is melee/contact range, not detection range.
@export var attack_distance: float = 78.0
@export var contact_damage: int = 25
## Collision layers that block line-of-sight to the player (your wall/tile layers).
## Chasing is cancelled if a wall on this mask is between the enemy and the player.
@export_flags_2d_physics var vision_wall_mask: int = 1

## How long (seconds) the enemy stands still "looking around" after losing the player.
@export var search_duration: float = 1.6
## How often (seconds) it flips its look direction while searching (left/right/left...).
@export var search_look_interval: float = 0.4
## How many look-flips before giving up and going back to patrol. Leave 0 to just use search_duration.
@export var search_look_count: int = 3

## Fraction of the "attack" animation's length to wait before actually
## applying damage (i.e. when the swing "connects"). Tune this to match
## the real impact frame of your animation. 0.5 = halfway through.
@export_range(0.0, 1.0, 0.05) var attack_impact_fraction: float = 0.5

var direction : int = 1
var _player: Player
var _attack_cooldown: float = 0.0
var _is_attacking: bool = false

var _top_down_state: TopDownState = TopDownState.PATROL
var _search_timer: float = 0.0
var _search_look_timer: float = 0.0
var _search_looks_done: int = 0
var _last_known_player_pos: Vector2

# Spawn point patrol is centered around, captured once in _ready().
var _spawn_position: Vector2
# +1 or -1: which way along the patrol axis the enemy is currently walking.
var _patrol_dir: int = 1


func _ready() -> void:
	if top_down_mode:
		_spawn_position = global_position
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
	if player_hidden:
		player_in_range = false

	var dist_to_player := INF
	if is_instance_valid(_player):
		dist_to_player = global_position.distance_to(_player.global_position)

	var can_see_player: bool
	if _top_down_state == TopDownState.CHASE:
		# Already chasing: only stop if the player is actually hidden.
		# (No distance cutoff here — once chasing, it commits until it loses
		# sight, otherwise it'd flicker in/out right at chase_distance's edge.)
		can_see_player = is_instance_valid(_player) and not player_hidden
	else:
		# Not chasing yet: needs to be within chase_distance (the "notice"
		# radius) with line of sight to actually start.
		can_see_player = is_instance_valid(_player) and not player_hidden \
			and dist_to_player <= chase_distance and _has_line_of_sight()

	# Player reappeared / came back into range at any point -> always resume chase.
	if can_see_player and _top_down_state != TopDownState.CHASE:
		_top_down_state = TopDownState.CHASE

	# Just lost the player (i.e. they hid) while chasing -> start searching.
	if not can_see_player and _top_down_state == TopDownState.CHASE and not _is_attacking:
		_start_searching()

	# While a swing is in progress, don't let movement/state logic override it.
	if _is_attacking:
		return

	match _top_down_state:
		TopDownState.CHASE:
			_process_chase(can_see_player)
		TopDownState.SEARCH:
			_process_search(delta)
		TopDownState.RETURN:
			_process_return(delta)
		TopDownState.PATROL:
			_process_patrol(delta)

## Casts a ray from this enemy to the player. Returns false (no line of sight)
## if anything on vision_wall_mask (walls/tiles) is in the way, so the enemy
## won't blindly chase/attack straight through a wall.
func _has_line_of_sight() -> bool:
	if not is_instance_valid(_player):
		return false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, _player.global_position, vision_wall_mask
	)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	return result.is_empty()


func _process_chase(can_see_player: bool) -> void:
	if not can_see_player:
		return
	var to_player := _player.global_position - global_position
	_last_known_player_pos = _player.global_position
	if to_player.length() <= attack_distance:
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
		_top_down_state = TopDownState.RETURN


## After giving up the search, walk back to the very first spawn position
## before resuming patrol. Prevents the enemy from getting stuck patrolling
## from some random spot it ended up at after chasing the player.
func _process_return(delta: float) -> void:
	var to_spawn := _spawn_position - global_position

	if to_spawn.length() <= max(patrol_speed * delta, 6.0):
		global_position = _spawn_position
		velocity = Vector2.ZERO
		move_and_slide()
		_patrol_dir = 1
		_top_down_state = TopDownState.PATROL
		return

	velocity = to_spawn.normalized() * patrol_speed
	move_and_slide()
	_face_towards(velocity)

	if anim:
		anim.play("walk")


func _process_patrol(delta: float) -> void:
	if not patrol_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		if anim:
			anim.play("idle")
		return

	var axis_vec := Vector2.RIGHT if patrol_axis == "Horizontal" else Vector2.DOWN

	velocity = axis_vec * patrol_speed * _patrol_dir
	move_and_slide()

	# Hit a wall tile -> turn back immediately.
	if get_slide_collision_count() > 0:
		_patrol_dir *= -1

	# How far we've walked along the patrol axis from spawn -> flip direction
	# once we hit the edge of patrol_distance.
	var offset := (global_position - _spawn_position).dot(axis_vec)
	if offset >= patrol_distance * 0.5:
		_patrol_dir = -1
	elif offset <= -patrol_distance * 0.5:
		_patrol_dir = 1

	_face_towards(velocity)

	if anim:
		anim.play("walk" if velocity.length() > 1.0 else "idle")


func _face_towards(dir: Vector2) -> void:
	if body and absf(dir.x) > 1.0:
		body.scale.x = 1 if dir.x > 0.0 else -1


## Plays the attack swing and only applies damage once the animation has
## actually reached its impact point AND the player is still within
## attack_distance at that moment. This stops the enemy from "hitting" the
## player instantly from far away just because an attack was triggered.
func _hit_player() -> void:
	if _attack_cooldown > 0.0 or not is_instance_valid(_player) or _is_attacking:
		return

	_attack_cooldown = 1.0
	_is_attacking = true
	velocity = Vector2.ZERO

	if anim:
		anim.play("attack")
		var impact_delay := anim.current_animation_length * attack_impact_fraction
		await get_tree().create_timer(impact_delay).timeout

	# Re-validate right before applying damage: the player may have moved
	# away, hidden, or been invalidated during the wind-up.
	if is_instance_valid(_player) and not _player.is_hidden:
		if global_position.distance_to(_player.global_position) <= attack_distance:
			_player.take_level_damage(contact_damage, global_position)

	# Let the rest of the swing animation finish before resuming movement/AI.
	if anim and anim.is_playing() and anim.current_animation == "attack":
		await anim.animation_finished

	_is_attacking = false


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
			# Don't attack here directly — entering this Area2D just marks the
			# player as "in attack range". Whether a hit actually lands is
			# decided in _hit_player(), which re-checks the real attack_distance
			# and times the damage to the animation's impact point instead of
			# firing the instant this area is touched.

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = false

func _on_idle_and_walk_timeout() -> void:
	choose_state()
