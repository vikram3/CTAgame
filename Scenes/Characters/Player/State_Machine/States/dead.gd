# dead.gd  –  attach to State_Transition_Manager/Dead
extends Node

var _sm: Node
func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _get_player() -> CharacterBody2D:
	return _get_sm().get_parent()

func _on_dead_state_entered() -> void:
	var p = _get_player()
	p.velocity        = Vector2.ZERO
	p.is_dead         = true
	p.input_locked    = true
	_get_sm().hurt_box.disabled = true

	_get_sm().anim.play("Death")
	await _get_sm().anim.animation_finished
	# Optional: emit signal, show game-over screen, etc.
	# get_tree().change_scene_to_file("res://Scenes/UI/game_over.tscn")

func _on_dead_state_physics_processing(_delta: float) -> void:
	# Freeze in place while dead
	var p = _get_player()
	p.velocity.x = 0.0

func _on_dead_state_exited() -> void:
	pass  # Respawn / scene change handles cleanup


func _on_player_stats_health_depleated() -> void:
	pass # Replace with function body.
