extends Node

@export var hurt_box:Area2D

func _on_hurt_box_area_entered(area: Area2D) -> void:
	hurt_box.apply_damage(area.do_damage())
