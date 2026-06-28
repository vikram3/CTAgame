extends Area2D

@export var damage: int = 10


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func do_damage() -> int:
	return damage


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var player := body as Player
	if player.is_dead or player.is_invulnerable or not player.hurt_box:
		return
	player.hurt_box.apply_damage(damage)
	player._start_invulnerability()
