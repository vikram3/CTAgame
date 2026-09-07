extends CharacterBody2D
class_name EnemyBase

signal defeated

@export var stats: Stats
@export var enemy_data: EnemyData

var is_dead: bool = false


func _ready() -> void:
	_apply_enemy_data()
	if stats and not stats.health_depleated.is_connected(_on_health_depleated):
		stats.health_depleated.connect(_on_health_depleated)


func take_hit(damage_info: DamageInfo) -> void:
	if is_dead or stats == null:
		return
	stats.take_damage_info(damage_info)


func _apply_enemy_data() -> void:
	if enemy_data and enemy_data.stats and stats:
		stats.initialize(enemy_data.stats)


func _on_health_depleated() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	defeated.emit()
