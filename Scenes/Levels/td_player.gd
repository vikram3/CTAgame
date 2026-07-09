extends CharacterBody2D
class_name Player

# =====================================================
# SIGNALS
# =====================================================
signal died
signal damaged(current_health: float)
signal hidden_state_changed(is_hidden: bool)

# =====================================================
# MOVEMENT MODE
#
# TOP_DOWN  -> exact original Level 1 behaviour (4-directional, hiding, etc).
# PLATFORMER -> new Level 2 behaviour (gravity, jumping, left/right only).
#
# Defaults to TOP_DOWN so any existing scene (Level 1) that doesn't set this
# in the Inspector keeps working exactly as before. Level 2's Player node
# just needs this switched to Platformer in the Inspector (Level2Controller
# also sets it in code as a safety net).
# =====================================================
enum MovementMode { TOP_DOWN, PLATFORMER }

@export_group("Movement Mode")
@export var movement_mode: MovementMode = MovementMode.TOP_DOWN

# =====================================================
# EXPORTS (original — unchanged)
# =====================================================
@export var speed: float = 120.0
@export var invulnerable_time: float = 1.0
@export var knockback_strength: float = 220.0
@export var knockback_time: float = 0.16

@export var stats: Stats
@export var anim: AnimationPlayer        # AnimationPlayer node
@export var sprite: Node2D               # your AnimatedSprite2D or Sprite2D (for flipping/modulate)
@export var hurt_box: Area2D

# --- Hiding (Top-Down only) ---
## Input action that both enters AND exits hiding. Defaults to Godot's built-in
## "ui_accept" (Space/Enter/gamepad A). Must be standing inside a HidingSpot's
## zone to hide; can be pressed from anywhere while hidden to break cover.
@export var hide_action: StringName = &"ui_accept"
## How long the little "scurry into hiding" dash takes when first entering cover.
## Movement is locked for this brief moment only.
@export var hide_dash_time: float = 0.18
## How squashed the sprite gets mid-dash (comedic pop). x>1, y<1 = wide & flat.
@export var hide_squash_scale: Vector2 = Vector2(1.3, 0.7)
## Speed multiplier applied while hidden and moving around inside cover (1.0 = normal speed).
@export var hide_move_speed_multiplier: float = 1.0
## Color/alpha applied while hidden (dim, blended into the prop).
@export var hidden_tint: Color = Color(0.62, 0.85, 0.62, 0.78)
## Distance of the step-out dash when exiting cover via the hide key.
@export var hide_exit_dash_distance: float = 20.0
## How long that step-out dash takes — the in-between beat before free movement resumes.
@export var hide_exit_dash_time: float = 0.16

# --- Platformer (Level 2 only) ---
@export_group("Platformer Movement")
## Downward acceleration applied every physics frame while in Platformer mode
## (used while rising / on the ground; see platformer_fall_gravity_multiplier
## for the falling case).
@export var platformer_gravity: float = 900.0
## Multiplies gravity while falling (velocity.y > 0). Real platformers almost
## never use the same gravity for rising and falling — falling faster than
## you rise is a huge part of what makes a jump feel snappy instead of floaty.
## 1.0 = no difference (the "floaty" feeling you're getting right now).
## Try 1.5–2.0.
@export var platformer_fall_gravity_multiplier: float = 1.7
## Upward velocity applied on jump (negative = up).
@export var platformer_jump_velocity: float = -320.0
## Terminal fall speed so you don't accelerate forever off a big drop.
@export var platformer_max_fall_speed: float = 700.0
## Max horizontal run speed.
@export var platformer_run_speed: float = 160.0
## How fast horizontal velocity ramps toward target speed (higher = snappier).
@export var platformer_ground_acceleration: float = 1400.0
## Multiplier applied to acceleration while airborne (lower = floatier air control).
@export var platformer_air_control_multiplier: float = 0.65
## Grace window after walking off a ledge where a jump still registers.
@export var platformer_coyote_time: float = 0.1
## Grace window where a jump press slightly before landing still registers.
@export var platformer_jump_buffer_time: float = 0.1
## Releasing jump early while still rising cuts velocity by this factor (variable jump height).
@export var platformer_jump_release_dampen: float = 0.45
## Input action used to jump in Platformer mode.
@export var platformer_jump_action: StringName = &"ui_accept"

# Animation names expected on `anim`:
#   idle_down, idle_up, idle_right, idle_left (or use idle_right + scale flip)
#   walk_down, walk_up, walk_right, walk_left (or use walk_right + scale flip)

enum Facing { DOWN, UP, LEFT, RIGHT }

var facing: Facing = Facing.DOWN
var is_dead: bool = false
var is_invulnerable: bool = false
var is_hidden: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0

var _invuln_timer: Timer

# --- Hiding state ---
var _current_hide_spot: HidingSpot = null
## Hide spot the player is currently standing inside but not yet hidden in.
## Set/cleared by HidingSpot when the player enters/exits its zone.
var _nearby_hide_spot: HidingSpot = null
var _is_dashing_to_hide: bool = false
var _is_exiting_hide: bool = false
var _saved_z_index: int = 0
var _saved_z_as_relative: bool = true

# --- Platformer state ---
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")

	if stats:
		stats.health_updated.connect(_on_health_updated)
		stats.health_depleated.connect(_on_health_depleated)

	if hurt_box:
		hurt_box.stats = stats
		if hurt_box.has_signal("area_entered"):
			hurt_box.area_entered.connect(_on_hurt_box_area_entered)

	_invuln_timer = Timer.new()
	_invuln_timer.one_shot = true
	add_child(_invuln_timer)
	_invuln_timer.timeout.connect(func(): is_invulnerable = false)


func _physics_process(_delta: float) -> void:
	# --- Shared across both modes (unchanged from original) ---
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _knockback_timer > 0.0:
		_knockback_timer -= _delta
		velocity = _knockback_velocity
		move_and_slide()
		return

	# --- Mode split ---
	if movement_mode == MovementMode.PLATFORMER:
		_physics_process_platformer(_delta)
		return

	# --- Everything below this line is the ORIGINAL Top-Down logic,
	#     completely untouched, and only runs when movement_mode == TOP_DOWN. ---

	if _is_dashing_to_hide:
		# The entry dash tween is driving global_position — don't fight it with velocity.
		velocity = Vector2.ZERO
		return

	if _is_exiting_hide:
		# Committed to a break-cover step-out dash — same deal.
		velocity = Vector2.ZERO
		return

	# Space (hide_action) toggles hiding: hide when standing in a zone, exit when already hidden.
	if Input.is_action_just_pressed(hide_action):
		if is_hidden:
			_break_cover(_facing_vector())
			return
		elif _nearby_hide_spot:
			hide_at(_nearby_hide_spot)
			return

	if is_hidden and _current_hide_spot:
		_process_hidden(_delta)
		return

	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	velocity = input_dir * speed
	move_and_slide()

	_update_facing(input_dir)
	_update_animation(input_dir)


# =====================================================
# PLATFORMER MOVEMENT (Level 2 only — new)
# =====================================================
func _physics_process_platformer(delta: float) -> void:
	# Gravity — stronger while falling than while rising. This single change
	# is usually what turns a jump from "floaty/mushy" into "snappy/normal
	# feeling", since a symmetric rise/fall arc is not how good platformer
	# jumps are tuned.
	var current_gravity := platformer_gravity
	if velocity.y > 0.0:
		current_gravity *= platformer_fall_gravity_multiplier
	velocity.y += current_gravity * delta
	if velocity.y > platformer_max_fall_speed:
		velocity.y = platformer_max_fall_speed

	# Coyote time bookkeeping
	if is_on_floor():
		_coyote_timer = platformer_coyote_time
	else:
		_coyote_timer -= delta

	# Jump buffering
	if Input.is_action_just_pressed(platformer_jump_action):
		_jump_buffer_timer = platformer_jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = platformer_jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	# Variable jump height — tap for a short hop, hold for full height.
	if Input.is_action_just_released(platformer_jump_action) and velocity.y < 0.0:
		velocity.y *= platformer_jump_release_dampen

	var horizontal := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var target_speed := horizontal * platformer_run_speed
	var accel := platformer_ground_acceleration
	if not is_on_floor():
		accel *= platformer_air_control_multiplier
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	move_and_slide()

	var facing_input := Vector2(horizontal, 0.0)
	_update_facing(facing_input)
	_update_animation(facing_input)


# =====================================================
# FACING / ANIMATION (shared — unchanged)
# =====================================================
func _update_facing(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		return
	if absf(input_dir.x) > absf(input_dir.y):
		facing = Facing.RIGHT if input_dir.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if input_dir.y > 0 else Facing.UP


func _update_animation(input_dir: Vector2) -> void:
	if anim == null:
		return

	var moving := input_dir != Vector2.ZERO

	if sprite:
		sprite.scale.x = 1.0

	match facing:
		Facing.RIGHT:
			anim.play("walk_right" if moving else "idle_right")
		Facing.LEFT:
			if moving:
				if sprite:
					sprite.scale.x = -1.0
				anim.play("walk_right")
			else:
				anim.play("idle_left")
		Facing.UP:
			anim.play("walk_up" if moving else "idle_up")
		Facing.DOWN:
			anim.play("walk_down" if moving else "idle_down")


func _facing_vector() -> Vector2:
	match facing:
		Facing.RIGHT: return Vector2.RIGHT
		Facing.LEFT: return Vector2.LEFT
		Facing.UP: return Vector2.UP
		_: return Vector2.DOWN


# =====================================================
# HIDING (Top-Down only — unchanged)
# =====================================================
## Called by a HidingSpot when the player enters its trigger area — makes this
## spot available to hide in, but does NOT hide automatically. Press hide_action
## (space) while standing inside to actually duck into cover.
func set_nearby_hide_spot(spot: HidingSpot) -> void:
	_nearby_hide_spot = spot


## Called by a HidingSpot when the player's collider leaves its trigger area.
## Just clears availability — does NOT un-hide. If the player is currently
## hidden, they stay hidden until they press hide_action to break cover.
func clear_nearby_hide_spot(spot: HidingSpot) -> void:
	if _nearby_hide_spot == spot:
		_nearby_hide_spot = null


## Ducks the player into cover: dash-locks movement briefly, tints the sprite,
## and makes sure the prop draws in front of the player.
func hide_at(spot: HidingSpot) -> void:
	if is_dead or _current_hide_spot == spot:
		return

	_current_hide_spot = spot
	set_hidden_state(true)

	# Make sure the prop draws in front of the player, not just a color tint.
	if spot.occluder:
		_saved_z_index = z_index
		_saved_z_as_relative = z_as_relative
		z_as_relative = false
		z_index = spot.occluder.z_index - 1

	_dash_to(spot.get_hide_position())


## Restores visibility/z-order. Used internally by _break_cover(); HidingSpot no
## longer calls this on body_exited since exiting cover is now a manual action.
func unhide_from(spot: HidingSpot) -> void:
	if _current_hide_spot != spot:
		return

	_current_hide_spot = null
	set_hidden_state(false)
	z_as_relative = _saved_z_as_relative
	z_index = _saved_z_index

	if sprite:
		sprite.position = Vector2.ZERO
		sprite.rotation = 0.0
		var pop_tween := create_tween()
		pop_tween.tween_property(sprite, "scale", Vector2(1.15, 0.85), 0.08)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(sprite, "scale", Vector2.ONE, 0.14)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _dash_to(target_pos: Vector2) -> void:
	_is_dashing_to_hide = true

	var pos_tween := create_tween()
	pos_tween.tween_property(self, "global_position", target_pos, hide_dash_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pos_tween.finished.connect(func(): _is_dashing_to_hide = false)

	if sprite:
		sprite.scale = Vector2.ONE
		var squash_tween := create_tween()
		squash_tween.tween_property(sprite, "scale", hide_squash_scale, hide_dash_time * 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		squash_tween.tween_property(sprite, "scale", Vector2.ONE, hide_dash_time * 0.5)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## While hidden, movement is normal (real velocity from input) so you can walk
## around inside cover. Exiting only happens via hide_action (handled in
## _physics_process above) — walking to the edge of the zone no longer un-hides.
func _process_hidden(_delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	velocity = input_dir * speed * hide_move_speed_multiplier
	move_and_slide()

	_update_facing(input_dir)
	_update_animation(input_dir)


## Manual break-cover, triggered by pressing hide_action while hidden: restores
## visibility/z-order immediately, then a short committed step-out dash before
## free movement resumes — mirroring the dash into hiding.
func _break_cover(exit_dir: Vector2) -> void:
	var spot := _current_hide_spot
	if spot:
		unhide_from(spot)

	if exit_dir.length() < 0.1:
		return

	_is_exiting_hide = true
	_update_facing(exit_dir)
	if anim:
		_update_animation(exit_dir)

	var exit_target := global_position + exit_dir.normalized() * hide_exit_dash_distance
	var pos_tween := create_tween()
	pos_tween.tween_property(self, "global_position", exit_target, hide_exit_dash_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pos_tween.finished.connect(func(): _is_exiting_hide = false)


# =====================================================
# DAMAGE / HEALTH (shared — unchanged)
# =====================================================
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if is_dead or is_invulnerable:
		return
	if area.has_method("do_damage"):
		_start_invulnerability()


func _start_invulnerability() -> void:
	is_invulnerable = true
	_invuln_timer.start(invulnerable_time)
	# Flash the sprite node, not the AnimationPlayer
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
		tween.set_loops(int(invulnerable_time / 0.2))


func take_level_damage(damage: int, source_position: Vector2) -> void:
	if is_dead or is_invulnerable or not hurt_box:
		return
	hurt_box.apply_damage(damage)
	var away := global_position - source_position
	_knockback_velocity = away.normalized() * knockback_strength if away.length() > 0.0 else Vector2.DOWN * knockback_strength
	_knockback_timer = knockback_time
	_start_invulnerability()


func set_hidden_state(value: bool) -> void:
	if is_hidden == value:
		return
	is_hidden = value
	hidden_state_changed.emit(is_hidden)
	if sprite:
		sprite.modulate = hidden_tint if is_hidden else Color.WHITE


func _on_health_updated(current_health: float) -> void:
	damaged.emit(current_health)


func _on_health_depleated() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate.a = 1.0
	if anim:
		anim.stop()
	died.emit()

func _draw() -> void:
	if OS.is_debug_build():
		draw_line(Vector2(-8, 0), Vector2(8, 0), Color.CYAN, 1.5)
