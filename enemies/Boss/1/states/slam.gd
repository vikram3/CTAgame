extends Node

signal slam_complete

func _on_slam_state_entered() -> void:
	var boss = get_parent().get_parent()
	boss.jump_to_player = false
	Global.cam.screen_shake(5,0.3)
	%big_boss_animation.play("slam_end")
	await %big_boss_animation.animation_finished
	emit_signal("slam_complete")


func _on_slam_state_physics_processing(delta: float) -> void:
	var boss = get_parent().get_parent()
	boss.velocity = Vector2.ZERO
