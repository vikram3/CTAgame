extends Area2D

@export var anim:AnimationPlayer
 
func _ready() -> void:
	anim.play("animated")
	connect("body_entered", on_player_entered)

func on_player_entered(body):
	if body is CharacterBody2D:
		CollectedItems.coins_amount += 1
		CollectedItems.emit_signal("coins_collected")
		queue_free()
