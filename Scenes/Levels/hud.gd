extends Control

# =====================================================
# EXPORTS - wire these in the editor inspector
# =====================================================
@export var stats: Stats              # the player's Stats node
@export var health_bar: ProgressBar
@export var coin_label: Label


func _ready() -> void:
	if stats:
		health_bar.max_value = stats.stats.max_health
		health_bar.value = stats.current_health
		stats.health_updated.connect(_on_health_updated)

	CollectedItems.coins_collected.connect(_on_coins_changed)
	_on_coins_changed()


func _on_health_updated(current_health: float) -> void:
	health_bar.value = current_health


func _on_coins_changed() -> void:
	coin_label.text = "Coins: %d" % CollectedItems.coins_amount
