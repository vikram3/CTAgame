# hitbox_area.gd  –  attach to every Area2D child inside Body/Hit_Box
# (Attack_1_2, Attack_3, Air_Attack_1, Air_Attack_2, Air_Attack_3, Counter_Attack)
# Each of these must be in the group "player_hitbox".
extends Area2D

@export var damage_override: int = 0   # Set > 0 to override stats damage for this hit

func _ready() -> void:
	add_to_group("player_hitbox")
	# All hitbox shapes start disabled; Attacks script enables them per frame window
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true

func do_damage() -> int:
	if damage_override > 0:
		return damage_override
	# Walk up to Player root, ask Stats for current damage value
	var player = _get_player_root()
	if player and player.has_node("Player_Stats"):
		return player.get_node("Player_Stats").stats._damage_given()
	return 10   # safe fallback

func _get_player_root() -> Node:
	var n = get_parent()
	while n != null:
		if n is CharacterBody2D:
			return n
		n = n.get_parent()
	return null
