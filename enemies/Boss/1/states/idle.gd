extends Node

@export var idle_time:float = 1.5

func _on_idle_state_entered() -> void:
	%idle_timer.start(idle_time)
	%big_boss_animation.play("idle",-1,1.2)
	get_parent().get_parent().velocity = Vector2.ZERO
