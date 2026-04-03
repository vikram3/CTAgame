extends Node

signal state_finished

enum{
	CHASE,
	REPOSITION
}

@export var move_time: float = 1.0
@export var speed:float = 50.0
@export var accel:float = 30.0


var movement_type = CHASE

var move_timer: float = 0.0

func match_movement(delta):
	match  movement_type:
		CHASE:
			var vel = get_parent().parent.get_direction_to_player().x * speed
			get_parent().main_parent.velocity.x = lerp(get_parent().main_parent.velocity.x, vel, accel * delta)
		REPOSITION:
			pass

func choose_movment():
	pass

func _on_move_state_entered() -> void:
	choose_movment()
	
	# Enable regeneration while moving
	get_parent().parent.regenration = true

	# Play movement animation
	get_parent().anim.play("Walk")

	move_timer = move_time

func _on_move_state_physics_processing(delta: float) -> void:
	get_parent().main_parent.move_and_slide()
	# Regenerate energy
	get_parent().parent.energy_regenration(delta)

	# Reactive melee interrupt (early exit)
	if get_parent().parent.can_reactive_meele():
		emit_signal("state_finished")
		return

	# Movement duration timer
	move_timer -= delta
	move_timer = clamp(move_timer, 0.0, move_time)
	
	match_movement(delta)
	
	if move_timer <= 0.0:
		emit_signal("state_finished")

func _on_move_state_exited() -> void:
	# Disable regeneration when leaving move
	get_parent().parent.regenration = false
