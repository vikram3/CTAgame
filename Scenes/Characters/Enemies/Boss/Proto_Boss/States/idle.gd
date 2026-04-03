extends Node

signal state_finished

@export var idle_time: float = 1.0

var idle_timer: float = 0.0

func _on_idle_state_entered() -> void:
	get_parent().main_parent.velocity.x = 0
	# Enable regeneration while idling
	get_parent().parent.regenration = true

	# Play idle animation
	get_parent().anim.play("Idle")

	idle_timer = idle_time

func _on_idle_state_physics_processing(delta: float) -> void:
	# Stop movement
	get_parent().main_parent.velocity = Vector2.ZERO

	# Regenerate energy
	get_parent().parent.energy_regenration(delta)

	# 🔴 Reactive melee interrupt (early exit)
	if get_parent().parent.can_reactive_meele():
		emit_signal("state_finished")
		return

	# Idle timer countdown
	idle_timer -= delta
	idle_timer = clamp(idle_timer, 0.0, idle_time)

	if idle_timer <= 0.0:
		emit_signal("state_finished")

func _on_idle_state_exited() -> void:
	# Disable regeneration when leaving idle
	get_parent().parent.regenration = false
