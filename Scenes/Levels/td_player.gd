extends CharacterBody2D
class_name Player

# =====================================================
# SIGNALS
# =====================================================
signal died
signal damaged(current_health: float)
signal hidden_state_changed(is_hidden: bool)

# =====================================================
# EXPORTS
# =====================================================
@export var speed: float = 120.0
@export var invulnerable_time: float = 1.0
@export var knockback_strength: float = 220.0
@export var knockback_time: float = 0.16

@export var stats: Stats
@export var anim: AnimationPlayer        # AnimationPlayer node
@export var sprite: Node2D               # your AnimatedSprite2D or Sprite2D (for flipping/modulate)
@export var hurt_box: Area2D

# --- Hiding ---
## How long the little "scurry into hiding" dash takes when first entering cover.
## Movement is locked for this brief moment only.
@export var hide_dash_time: float = 0.18
## How squashed the sprite gets mid-dash (comedic pop). x>1, y<1 = wide & flat.
@export var hide_squash_scale: Vector2 = Vector2(1.3, 0.7)
## Speed multiplier applied while hidden and moving around inside cover (1.0 = normal speed).
@export var hide_move_speed_multiplier: float = 1.0
## Color/alpha applied while hidden (dim, blended into the prop).
@export var hidden_tint: Color = Color(0.62, 0.85, 0.62, 0.78)

# --- Peek (dedicated button, independent of movement so you can still walk around while hidden) ---
## Input action held to lean/peek and, if held long enough, break cover early.
## Defaults to Godot's built-in "ui_accept" (Enter/Space/gamepad A) — remap in the
## Input Map to something like "peek" bound to Shift if you'd rather use that.
@export var peek_action: StringName = &"ui_accept"
## How far the sprite visually leans out while peeking.
@export var peek_offset: float = 14.0
## How many degrees the sprite tilts while peeking, selling a "leaning out" look.
@export var peek_lean_rotation_degrees: float = 12.0
## How quickly the peek offset/tint/rotation catch up (higher = snappier).
@export var peek_lerp_speed: float = 10.0
## How much the dim clears while peeking, 0-1. 1 = fully visible mid-peek.
@export var peek_reveal_amount: float = 0.9
## How long the peek button must be held before it commits to breaking cover.
@export var hide_exit_hold_time: float = 0.4
## Distance of the committed "stepping out" dash once cover is broken via the peek button.
@export var hide_exit_dash_distance: float = 20.0
## How long that step-out dash takes — the in-between beat before free movement resumes.
@export var hide_exit_dash_time: float = 0.16

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
var _is_dashing_to_hide: bool = false
var _is_exiting_hide: bool = false
var _saved_z_index: int = 0
var _saved_z_as_relative: bool = true
var _hide_exit_hold_timer: float = 0.0


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
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _knockback_timer > 0.0:
		_knockback_timer -= _delta
		velocity = _knockback_velocity
		move_and_slide()
		return

	if _is_dashing_to_hide:
		# The entry dash tween is driving global_position — don't fight it with velocity.
		velocity = Vector2.ZERO
		return

	if _is_exiting_hide:
		# Committed to a break-cover step-out dash — same deal.
		velocity = Vector2.ZERO
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
# FACING / ANIMATION
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
# HIDING
# =====================================================
## Called by a HidingSpot when the player enters its trigger area.
## Plays the dash-lock into cover; free movement resumes once it finishes.
func hide_at(spot: HidingSpot) -> void:
	if is_dead or _current_hide_spot == spot:
		return

	_current_hide_spot = spot
	_hide_exit_hold_timer = 0.0
	set_hidden_state(true)

	# Make sure the prop draws in front of the player, not just a color tint.
	if spot.occluder:
		_saved_z_index = z_index
		_saved_z_as_relative = z_as_relative
		z_as_relative = false
		z_index = spot.occluder.z_index - 1

	_dash_to(spot.get_hide_position())


## Called by a HidingSpot when the player's collider actually leaves its trigger area —
## the "normal" way out: just walk out of cover and you're immediately visible again.
func unhide_from(spot: HidingSpot) -> void:
	if _current_hide_spot != spot:
		return

	_current_hide_spot = null
	_hide_exit_hold_timer = 0.0
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


## While hidden: movement is completely normal (real velocity from input, moves the actual
## collider) so walking fully out of the HidingSpot's Area2D naturally un-hides via
## unhide_from() above. The peek button is a separate, optional layer on top: hold it to
## lean/reveal in place, or hold it long enough to force an early break-cover from anywhere.
func _process_hidden(delta: float) -> void:
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

	_process_peek_button(delta, input_dir)


func _process_peek_button(delta: float, input_dir: Vector2) -> void:
	var peek_held := Input.is_action_pressed(peek_action)
	var peek_dir := input_dir if input_dir.length() > 0.1 else _facing_vector()

	var lean_amount := 0.0
	if peek_held:
		_hide_exit_hold_timer += delta
		lean_amount = clampf(_hide_exit_hold_timer / hide_exit_hold_time, 0.0, 1.0)
		if _hide_exit_hold_timer >= hide_exit_hold_time:
			_break_cover(peek_dir)
			return
	else:
		_hide_exit_hold_timer = 0.0

	if sprite:
		var target_offset := peek_dir * peek_offset * lean_amount
		sprite.position = sprite.position.lerp(target_offset, clampf(peek_lerp_speed * delta, 0.0, 1.0))

		var target_tint := hidden_tint.lerp(Color.WHITE, lean_amount * peek_reveal_amount)
		sprite.modulate = sprite.modulate.lerp(target_tint, clampf(peek_lerp_speed * delta, 0.0, 1.0))

		var target_rotation := deg_to_rad(peek_lean_rotation_degrees) * lean_amount \
			* signf(peek_dir.x if absf(peek_dir.x) > 0.05 else peek_dir.y)
		sprite.rotation = lerp_angle(sprite.rotation, target_rotation, clampf(peek_lerp_speed * delta, 0.0, 1.0))


## Forces an early exit from anywhere inside the hiding zone (not just at its edge):
## restores visibility/z-order immediately, then a short committed step-out dash before
## free movement resumes — mirroring the dash into hiding.
func _break_cover(exit_dir: Vector2) -> void:
	var spot := _current_hide_spot
	_hide_exit_hold_timer = 0.0
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
# DAMAGE / HEALTH
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
