# player.gd
# Attach to: Player (CharacterBody2D)
# This is the root script. It holds state flags and delegates everything to child nodes.
extends CharacterBody2D

signal double_jump
signal combo_attack

# ── Inspector exports ──────────────────────────────────────────────
@export var projectile: PackedScene
@export var force_decay: float = 750.0

@export var body: Node2D                    # Body node (holds Sprite + HitBox)
@export var projectile_point: Node2D
@export var state_manager: Node             # State_Transition_Manager
@export var state_chart: StateChart         # Godot StateChart plugin node
@export var stats: Stats                    # Player_Stats node
@export var anim: AnimationPlayer
@export var health_bar: ProgressBar         # HealthBar ProgressBar
@export var hurt_box: CollisionShape2D      # HurtBox/CollisionShape2D
@export var check_hit: CollisionShape2D     # check_hit/CollisionShape2D

# ── State flags (read by state nodes) ─────────────────────────────
@export var can_double_jump: bool = false
@export var can_attack: bool = true
@export var can_block: bool = true
@export var parried: bool = false
@export var can_ground_dash: bool = true
@export var can_air_dash: bool = true
@export var is_hurt: bool = false
@export var is_dead: bool = false
@export var doing_counter: bool = false

# ── Runtime vars ───────────────────────────────────────────────────
var input_locked := false
var cam_root: Node2D
var external_velocity: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO

# ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	Global.player = self
	cam_root = get_tree().get_first_node_in_group("camera")
	health_bar._init_health(stats.stats.max_health)

	# Safety checks – remove once scene is confirmed correct
	assert(get_node_or_null("Body/Hit_Box") != null,   "Missing Body/Hit_Box node!")
	assert(hurt_box  != null, "hurt_box export not assigned!")
	assert(check_hit != null, "check_hit export not assigned!")

func _physics_process(delta: float) -> void:
	state_manager._transition()

	if input_locked or is_dead:
		return

	if Input.is_action_just_pressed("projectile"):
		_init_projectile()

	if external_velocity != Vector2.ZERO:
		velocity += external_velocity
		external_velocity = external_velocity.move_toward(Vector2.ZERO, force_decay * delta)
		external_velocity.y = clamp(external_velocity.y, -200.0, 200.0)

	move_and_slide()
	_flip_face()

# ──────────────────────────────────────────────────────────────────
func _flip_face() -> void:
	if _set_direction().x != 0.0:
		body.scale.x = _set_direction().x

func _set_direction() -> Vector2:
	input_dir = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"), 0.0
	).normalized()
	return input_dir

func apply_force(direction: Vector2, strength: float) -> void:
	external_velocity += direction.normalized() * strength

func take_damage(damage: int) -> void:
	stats._damage_deduction(damage)

# ── Signal callbacks ───────────────────────────────────────────────
func _on_player_stats_health_updated(health: Variant) -> void:
	health_bar._set_health(health)

func _on_player_stats_health_depleated() -> void:
	is_dead = true

# ── Projectile ────────────────────────────────────────────────────
func _init_projectile() -> void:
	if CollectedItems.coins_amount > 0:
		var p = projectile.instantiate()
		p.global_position = projectile_point.global_position
		get_tree().current_scene.add_child(p)
		CollectedItems.coins_amount -= 1
		CollectedItems.emit_signal("coins_collected")

# ── Input lock (called by animation events) ────────────────────────
func lock_input() -> void:
	input_locked = true

func unlock_input() -> void:
	input_locked = false
