extends Node

signal state_finished

@export var _init_attack:AnimationPlayer
@export var energy_consumption:float

func _on_area_attack_state_entered() -> void:
	get_parent().parent.is_attacking = true
	if !get_parent().parent.energy_checking(energy_consumption):
		emit_signal("state_finished")
		return
	
	get_parent().anim.play("Area_Attack")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Area_Attack":
		get_parent().anim.play("Idle")
		await _init_attack.animation_finished
		emit_signal("state_finished")

func init_attack():
	_init_attack.play("anim")
