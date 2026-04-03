extends CharacterBody2D

signal double_jump
signal combo_attack

@export var projectile:PackedScene

@export var force_decay:float = 750.0

@export var body:Node2D
@export var projectile_point:Node2D
@export var state_manager:Node
@export var state_chart: StateChart
@export var stats:Stats
@export var anim: AnimationPlayer
@export var health_bar:ProgressBar
@export var hurt_box: CollisionShape2D
@export var check_hit: CollisionShape2D

var input_locked := false

@export var can_double_jump:bool = false
@export var can_attack:bool = true
@export var can_block:bool = true
@export var parried:bool = false
@export var can_ground_dash:bool = true
@export var can_air_dash:bool = true
@export var is_hurt:bool = false
@export var is_dead:bool = false
@export var doing_counter:bool = false

var cam_root:Node2D

var external_velocity: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO

func _ready():
	Global.player = self
	cam_root = get_tree().get_first_node_in_group("camera")
	health_bar._init_health(stats.stats.max_health)

func _physics_process(delta):
	
	state_manager._transition()
	
	if input_locked:
		return

	if is_dead:
		return
	
	if Input.is_action_just_pressed("projectile"):
		_init_projectile()
	
	move_and_slide()
	_smoothing_external_velocity(delta)
	_flip_face()

func _smoothing_external_velocity(delta):
	external_velocity = external_velocity.move_toward(Vector2.ZERO, force_decay * delta)
	velocity += external_velocity

func _flip_face():
	if _set_direction().x != 0:
		body.scale.x = _set_direction().x

func _set_direction():
	# checking input of player
	input_dir = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"), 0).normalized()
	return input_dir

func apply_force(direction: Vector2, strength: float) -> void:
	external_velocity += direction.normalized() * strength

func _on_player_stats_health_updated(health: Variant) -> void:
	health_bar._set_health(health)

func _init_projectile():
	if CollectedItems.coins_amount > 0:
		var p = projectile.instantiate()
		p.global_position = projectile_point.global_position
		get_tree().current_scene.add_child(p)
		CollectedItems.coins_amount -= 1
		CollectedItems.emit_signal("coins_collected")

	else:
		print("No coins")

func lock_input():
	input_locked = true

func unlock_input():
	input_locked = false
