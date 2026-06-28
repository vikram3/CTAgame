extends Area2D
class_name ExitDoor

signal exit_reached

@export var required_coins: int = 18


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if CollectedItems.coins_amount >= required_coins:
		exit_reached.emit()
	else:
		# not enough coins yet - hook this up to a HUD toast/message if wanted
		print("Need %d more coins" % (required_coins - CollectedItems.coins_amount))
