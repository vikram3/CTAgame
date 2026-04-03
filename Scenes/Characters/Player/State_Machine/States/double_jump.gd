extends Node


func _on_double_jump_state_entered():
	get_parent().anim.play("Double_Jump_Main")
	get_parent().parent.emit_signal("double_jump")


func _on_double_jump_state_physics_processing(delta: float) -> void:
	pass
