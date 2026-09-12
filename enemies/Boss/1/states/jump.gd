extends Node

signal jump_init

@export var jump_force:float
@export var jump_time:float = 1.1

func _on_jump_state_entered() -> void:
	var boss = get_parent().get_parent()
	var target:Vector2
	if boss.is_player_detected():
		boss.jump_to_player = false
		jump_force = 700.0
		target = boss.choose_other_platform()
		boss.starting_pos = target
		boss.face_player()
	else:
		if boss.jump_to_player:
			%big_boss_animation.play("slam_start")
			jump_force = 400.0
			target = Global.player.global_position
			boss.face_player()
		else:
			jump_force = 700.0
			target = boss.starting_pos
			boss.face_toward(target)

	boss.jump = true
	boss.velocity.x = (target.x - boss.global_position.x) / jump_time
	boss.velocity.y = -jump_force
	emit_signal("jump_init")

func _on_jump_state_physics_processing(_delta: float) -> void:
	pass
