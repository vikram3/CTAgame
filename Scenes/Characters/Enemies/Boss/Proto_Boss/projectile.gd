extends Node2D

@export var animation:AnimationPlayer
@export var stats:Stats

func _ready() -> void:
	animation.play("anim")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "anim":
		queue_free()
