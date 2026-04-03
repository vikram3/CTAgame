extends Node
class_name Stats

signal health_updated(health)
signal energy_updated(energy)
signal health_depleated
signal energy_depleated

@export var stats: stats_resource
@export var min_damage: float = 0.0

var current_health: float
var current_energy: float


func _ready() -> void:
	current_health = stats.max_health
	current_energy = stats.max_energy


# =================================
# DAMAGE GIVEN (USED BY HITBOX)
# =================================
func _damage_given() -> int:
	var damage = stats.damage

	# critical hit check
	if randf() <= stats.crit_chance:
		damage *= stats.crit_damage

	# minimum damage clamp
	damage = max(damage, min_damage)

	return damage


# =================================
# DAMAGE TAKEN (USED BY HURTBOX)
# =================================
func _damage_deduction(damage: int) -> void:
	var final_damage = damage - stats.defense
	final_damage = max(final_damage, min_damage)

	current_health -= final_damage
	emit_signal("health_updated", current_health)

	if current_health <= 0:
		current_health = 0
		emit_signal("health_depleated")


# =================================
# ENERGY MANAGEMENT
# =================================

func _energy_consumption(ammount) -> bool:
	if current_energy < ammount:
		return false
	
	_energy_deduction(ammount)
	return true

func _energy_deduction(value: float) -> void:
	current_energy -= value
	emit_signal("energy_updated", current_energy)

	if current_energy <= 0:
		current_energy = 0
		emit_signal("energy_depleated")

func _energy_refill(value: float) -> void:
	current_energy = min(current_energy + value, stats.max_energy)
	emit_signal("energy_updated", current_energy)

# =================================
# HEALTH MANAGEMENT
# =================================
func _health_refill(value: float) -> void:
	current_health = min(current_health + value, stats.max_health)
	emit_signal("health_updated", current_health)
