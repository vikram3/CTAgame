extends Node2D



func _on_reset_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		get_tree().reload_current_scene()
