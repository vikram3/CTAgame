extends CharacterBody2D
class_name Player

# =====================================================
# SIGNALS
# =====================================================
signal died
signal damaged(current_health: float)

# =====================================================
# EXPORTS
# =====================================================
@export var speed: float = 120.0
@export var invulnerable_time: float = 0.6

@export var stats: Stats
@export var anim: AnimationPlayer        # AnimationPlayer node
@export var sprite: Node2D               # your AnimatedSprite2D or Sprite2D (for flipping/modulate)
@export var hurt_box: Area2D

# Animation names expected on `anim`:
#   idle_down, idle_up, idle_right, idle_left (or use idle_right + scale flip)
#   walk_down, walk_up, walk_right, walk_left (or use walk_right + scale flip)

enum Facing { DOWN, UP, LEFT, RIGHT }

var facing: Facing = Facing.DOWN
var is_dead: bool = false
var is_invulnerable: bool = false

var _invuln_timer: Timer


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
