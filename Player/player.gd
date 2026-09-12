extends CharacterBody2D

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

@export var attack_buffer_time: float = 0.35

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
var attack_buffer_timer: float = 0.0
var suspend_air_physics := false

func _ready():
	Global.player = self
	cam_root = get_tree().get_first_node_in_group("camera")
	health_bar._init_health(stats.stats.max_health)

func _physics_process(delta):
	_capture_combat_input(delta)
	
	state_manager._transition()
	
	if input_locked:
		return

	if is_dead:
		return
	
	if Input.is_action_just_pressed("projectile"):
		_init_projectile()
	
	_smoothing_external_velocity(delta)
	move_and_slide()
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

func _capture_combat_input(delta: float) -> void:
	attack_buffer_timer = max(attack_buffer_timer - delta, 0.0)
	
	if input_locked or is_dead:
		return
	
	if Input.is_action_just_pressed("Attack"):
		buffer_attack()

func buffer_attack() -> void:
	attack_buffer_timer = attack_buffer_time

func has_attack_buffer() -> bool:
	return attack_buffer_timer > 0.0

func consume_attack_buffer() -> bool:
	if !has_attack_buffer():
		return false
	
	attack_buffer_timer = 0.0
	return true

func clear_attack_buffer() -> void:
	attack_buffer_timer = 0.0

func reset_combat_flags() -> void:
	can_attack = true
	can_block = true
	can_ground_dash = true
	can_air_dash = true
	parried = false
	doing_counter = false
	suspend_air_physics = false

func clear_attack_hitboxes() -> void:
	var hit_box = get_node_or_null("Body/Hit_Box")
	if hit_box == null:
		return
	
	for child in hit_box.get_children():
		if child is CollisionShape2D:
			set_collision_shape_disabled(child, true)

func set_collision_shape_disabled(shape: CollisionShape2D, disabled: bool) -> void:
	if shape == null:
		return
	
	shape.set_deferred("disabled", disabled)

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

# In your coin pickup script or player script
func collect_coin():
	GameData.add_coins(1)
	# Update HUD
	$CanvasLayer/CoinLabel.text = str(GameData.data.coins)
