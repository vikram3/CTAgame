# hurtbox.gd  –  attach to HurtBox Area2D node (child of Player root, NOT Body)
# This is the area that RECEIVES damage from enemy hitboxes.
extends Area2D

@export var stats: Stats   # Assign Player_Stats in inspector

func _ready() -> void:
	area_entered.connect(_on_hurtbox_area_entered)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Only respond to enemy hitboxes tagged "enemy_hitbox"
	if area.is_in_group("enemy_hitbox"):
		var damage = area.do_damage()
		# Bubble damage up to the player root's take_damage so stats update
		get_parent().take_damage(damage)

# Called directly by Hurt state (older path) – kept for compatibility
func apply_damage(damage: int) -> void:
	stats._damage_deduction(damage)
