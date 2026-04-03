extends Node


func _on_death_state_entered() -> void:
	get_parent().anim.play("Death")
	get_parent().main_parent.velocity = Vector2.ZERO
