# jump_and_gravity_manager.gd
# Node: Jump_and_Gravity_Manager (child of Player)
# Handles all jump physics. Its signal callbacks are connected FROM the StateChart.
extends Node

@export var air_speed: float       = 50.0
@export var air_accel: float       = 65.0
@export var fall_gravity: float    = 350.0
@export var gravity: float         = 290.0
@export var double_jump_velocity: float = -125.0
@export var jump_velocity: float   = -135.0
@export var coyote_time: float     = 0.1
@export var jump_buffer_time: float = 0.1
@export var var_jump_multiplier: float = 0.5

var coyote_timer: float = 0.0
var jump_buffer: float  = 0.0

@onready var _player: CharacterBody2D = get_parent()

func _ready() -> void:
	coyote_timer = 0.0
	jump_buffer  = 0.0
	_player.can_double_jump = false

# ── Ground state callback ─────────────────────────────────────────
# Connect: Ground_state → state_physics_processing → _on_ground_state_state_physics_processing
func _on_ground_state_state_physics_processing(_delta: float) -> void:
	coyote_timer = coyote_time
	_player.can_double_jump = true

	if Input.is_action_just_pressed("jump"):
		jump_buffer = jump_buffer_time

	if jump_buffer > 0.0:
		_player.velocity.y = jump_velocity
		jump_buffer = 0.0
		coyote_timer = 0.0

# ── Air state callback ────────────────────────────────────────────
# Connect: Air_state → state_physics_processing → _on_air_state_state_physics_processing
func _on_air_state_state_physics_processing(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer = jump_buffer_time
	_gravity_and_jump_mechanic(delta)

# ──────────────────────────────────────────────────────────────────
func _gravity_and_jump_mechanic(delta: float) -> void:
	var GRAVITY = gravity if _player.velocity.y < 0.0 else fall_gravity
	_player.velocity.y += GRAVITY * delta

	coyote_timer -= delta
	coyote_timer   = clamp(coyote_timer, 0.0, coyote_time)
	jump_buffer   -= delta
	jump_buffer    = max(jump_buffer, 0.0)

	# Coyote jump (ran off ledge, still has coyote window)
	if jump_buffer > 0.0 and coyote_timer > 0.0:
		_player.velocity.y  = jump_velocity
		jump_buffer         = 0.0
		coyote_timer        = 0.0
		return

	# Double jump
	if jump_buffer > 0.0 and _player.can_double_jump:
		_player.velocity.y      = double_jump_velocity
		_player.can_double_jump = false
		jump_buffer             = 0.0

	# Variable jump height (hold vs tap)
	if Input.is_action_just_released("jump") and _player.velocity.y < 0.0:
		_player.velocity.y *= var_jump_multiplier

	_air_movement(air_speed, air_accel, delta)

func _air_movement(speed: float, accel: float, delta: float) -> void:
	var dir = _player._set_direction().x
	if dir != 0.0:
		_player.velocity.x = lerp(_player.velocity.x, speed * dir, accel * delta)
	else:
		_player.velocity.x = lerp(_player.velocity.x, 0.0, accel * delta)
