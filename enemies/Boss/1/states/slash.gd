extends Node

signal slash_complete

@export var slash:PackedScene
@onready var projectile_init: Marker2D = $"../../body/projectile_init"

func _init_projectile():
	var slash_projectile = slash.instantiate()
	slash_projectile.global_position = projectile_init.global_position
	get_tree().current_scene.add_child(slash_projectile)


func _on_slash_state_entered() -> void:
	%big_boss_animation.play("slash")
	await %big_boss_animation.animation_finished
	emit_signal("slash_complete")
