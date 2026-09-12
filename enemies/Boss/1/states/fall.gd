extends Node

signal slam_attack
signal lamded

func _on_fall_state_entered() -> void:
	get_parent().get_parent().jump = false
	%big_boss_animation.play("slam_loop")


func _on_fall_state_physics_processing(_delta: float) -> void:
	var boss = get_parent().get_parent()
	if boss.is_on_floor():
		if boss.jump_to_player:
			emit_signal("slam_attack")
		else:
			emit_signal("lamded")
			boss.jump_to_player = true
