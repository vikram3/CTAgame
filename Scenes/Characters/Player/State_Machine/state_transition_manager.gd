# state_transition_manager.gd
# Node: State_Transition_Manager (child of Player)
# Sends events to the StateChart every physics frame.
# Also receives physics_processing signals from StateChart compound states.
extends Node

@onready var state_chart: StateChart    = get_parent().state_chart
@onready var anim: AnimationPlayer      = get_parent().anim
@onready var parent: CharacterBody2D    = get_parent()
@onready var hurt_box: CollisionShape2D = get_parent().hurt_box
@onready var check_hit: CollisionShape2D = get_parent().check_hit

# Called every frame by player._physics_process BEFORE move_and_slide.
func _transition() -> void:
	# Global overrides (highest priority)
	if parent.is_dead:
		state_chart.send_event("dead")
		return
	if parent.is_hurt:
		state_chart.send_event("hurt")
		return

	# Root compound: ground vs air
	if parent.is_on_floor():
		state_chart.send_event("ground")
	else:
		state_chart.send_event("air")

# ── Ground compound state ─────────────────────────────────────────
# Connect StateChart "Ground_state → state_physics_processing" to this.
func _on_ground_state_state_physics_processing(_delta: float) -> void:
	# Counter / parry take priority over everything inside ground
	if parent.doing_counter:
		state_chart.send_event("counter")
		return
	if parent.parried:
		state_chart.send_event("parry")
		return

	# Block: can_block is true  = allowed to block again.
	# The flag is cleared when block is entered and restored when block exits.
	if not parent.can_block:
		state_chart.send_event("block")
		return
	if Input.is_action_just_pressed("block"):
		parent.can_block = false
		return

	# Attack
	if not parent.can_attack:
		state_chart.send_event("attack")
		return
	if Input.is_action_just_pressed("Attack"):
		parent.can_attack = false
		return

	# Dash
	if not parent.can_ground_dash:
		state_chart.send_event("dash")
		return
	if Input.is_action_just_pressed("dash"):
		parent.can_ground_dash = false
		return

	# Locomotion
	if parent._set_direction().x != 0.0:
		state_chart.send_event("run")
	else:
		state_chart.send_event("idle")

# ── Air compound state ────────────────────────────────────────────
# Connect StateChart "Air_state → state_physics_processing" to this.
func _on_air_state_state_physics_processing(_delta: float) -> void:
	# Attack
	if not parent.can_attack:
		state_chart.send_event("attack")
		return
	if Input.is_action_just_pressed("Attack"):
		parent.can_attack = false
		return

	# Air dash
	if not parent.can_air_dash:
		state_chart.send_event("dash")
		return
	if Input.is_action_just_pressed("dash"):
		parent.can_air_dash = false
		return

	# Vertical sub-state
	if parent.velocity.y >= 0.0:
		state_chart.send_event("fall")
	else:
		if not parent.can_double_jump:
			state_chart.send_event("double_jump")
		else:
			state_chart.send_event("jump")
