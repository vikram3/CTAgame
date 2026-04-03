extends Node

signal state_finished

@export var height:float = 37.0

@export var projectile:PackedScene
@export var energy_consumption:float

func _on_projectile_state_entered() -> void:
	get_parent().parent.is_attacking = true
	if !get_parent().parent.energy_checking(energy_consumption):
		emit_signal("state_finished")
		return
	
	get_parent().anim.play("Cast_Spell")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Cast_Spell":
		emit_signal("state_finished")

func _init_projectile():
	var disc = projectile.instantiate()
	disc.global_position.x = Global.player.global_position.x
	disc.global_position.y = Global.player.global_position.y - height
	get_tree().current_scene.add_child(disc)
