extends Area2D

var stats: Stats

func _ready() -> void:
	stats = get_parent().get_parent().stats


func apply_damage(damage: int) -> void:
	stats._damage_deduction(damage)
