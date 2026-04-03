extends Node
class_name Base_Boss

signal next_phase(phase)

@export var attack_range:float = 20.0

@export var can_attack:bool = false
@export var regenration:bool = false

@export var phase_config:PhaseConfig


var current_phase : StringName = ""

func _ready() -> void:
	if phase_config == null:
		push_error("PhaseConfig resource not assigned!")
		return
	
	_init_phase()
	get_parent().stats.connect("health_updated", change_phase)
	

func _init_phase():
# pick the starting phase (highest hp_ratio)
	var phases := phase_config.phases
	var phase_names := phases.keys()

	phase_names.sort_custom(func(a, b):
		return phases[a]["hp_ratio"] > phases[b]["hp_ratio"]
	)

	current_phase = phase_names[0]

func energy_checking(amount) -> bool:
	var activate :bool = get_parent().stats._energy_consumption(amount)
	return activate

func energy_regenration(amount):
	if !regenration:
		return
	get_parent().stats._energy_refill(amount)

func update_phase() -> float:
	var hp_ratio = get_parent().stats.current_health /  get_parent().stats.stats.max_health
	return hp_ratio

func change_phase(_health: float = 0.0):
	var current_hp_ratio := update_phase()

	# Get phase names
	var phase_names = phase_config.phases.keys()

	# Sort by hp_ratio (LOW → HIGH)
	phase_names.sort_custom(func(a, b):
		return phase_config.phases[a]["hp_ratio"] < phase_config.phases[b]["hp_ratio"]
	)

	# Find the first phase that matches
	for phase_name in phase_names:
		if current_hp_ratio <= phase_config.phases[phase_name]["hp_ratio"]:
			if current_phase == phase_name:
				return

			current_phase = phase_name
			emit_signal("next_phase", current_phase)
			return


func get_direction_to_player() -> Vector2:
	return (Global.player.global_position - get_parent().global_position).normalized()

func check_distance_to_player() -> float:
	var distance = get_parent().global_position.distance_to(Global.player.global_position)
	return distance
