# hurt.gd  –  attach to State_Transition_Manager/Hurt
# Triggered when an enemy hitbox overlaps the player's HurtBox area.
extends Node

# The Area2D HurtBox node (assign in inspector OR resolve at runtime)
@export var hurt_box_area: Area2D

var _sm: Node
func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _get_player() -> CharacterBody2D:
	return _get_sm().get_parent()

# Called by the HurtBox Area2D when an enemy hitbox enters
func _on_hurt_box_area_entered(area: Area2D) -> void:
	var p = _get_player()
	if p.is_dead: return   # don't process damage after death

	p.velocity      = Vector2.ZERO
	var damage = area.do_damage()   # Area2D on the enemy's hitbox must have do_damage()
	p.take_damage(damage)

	p.can_block = true              # reset block so we don't get stuck
	p.is_hurt   = true

	# Knock player away from the attacker
	var knockback_dir = Vector2(area.get_parent().scale.x, -0.15).normalized()
	p.apply_force(knockback_dir, 28.0)

	if Global.cam:
		Global.cam.screen_shake(8, 0.1)
	Global._freeze(0.1, 0.4)

func _on_hurt_state_entered() -> void:
	var sm = _get_sm()
	sm.anim.play("Hurt")
	await sm.anim.animation_finished
	_get_player().is_hurt = false

func _on_hurt_state_physics_processing(_delta: float) -> void:
	# Restore all action flags during hurt so the player can immediately act after
	var p = _get_player()
	p.can_ground_dash = true
	p.can_air_dash    = true
	p.can_attack      = true
