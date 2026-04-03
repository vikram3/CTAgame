extends Node2D

@export var animation:AnimationPlayer

func _ready() -> void:
	Global.cam.screen_shake(0.5,0.1)
	rotation = randf_range(-120, 10)
	scale = Vector2(1,1) * randf_range(0.05,0.1)
	animation.play("anim")
	await animation.animation_finished
	queue_free()
