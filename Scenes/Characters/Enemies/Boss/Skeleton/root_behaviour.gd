extends Base_Boss

signal intent_idle
signal intent_move
signal intent_attack(attack_type)
signal intent_phase_transition
signal died
signal hurt

@export_range(0.0, 1.0)
var idle_state_chance: float = 0.2

@export
var meele_cooldown: float = 0.7

@export var body:Node2D

# ---- Runtime state ----

var is_attacking: bool = false
var dead:bool = false

# ---- Melee control ----
var is_in_meele_range: bool = false
var meele_requested: bool = false
var meele_committed: bool = false
var meele_cd_timer: float = 0.0

const ATTACK_MEELE := &"meele_attack"

# -------------------------------------------------

func _physics_process(delta: float) -> void:
	
	if dead:
		return
	
	# Update distance FIRST
	is_in_meele_range = check_distance_to_player() <= attack_range

	# Raise request (sensor only)
	if is_in_meele_range:
		meele_requested = true
	else:
		meele_requested = false

	# Tick cooldown independently
	if meele_cd_timer > 0.0:
		meele_cd_timer -= delta
	
	if is_attacking == false:
		flipping()

# -------------------------------------------------
	
func decide_next_action() -> void:
	if get_parent().decision_locked:
		$State_Transition_Manager.anim.play("Idle")
		return
	
	if dead:
		return

	# Reactive melee has TOP priority
	if can_reactive_meele():
		commit_meele()
		return

	# Phase-based attacks
	if can_attack_now():
		var attack = choose_attack()
		if attack != null:
			is_attacking = true
			emit_signal("intent_attack", attack)
			return

	# Fallback
	choose_idle_or_move()

# -------------------------------------------------

func can_reactive_meele() -> bool:
	if meele_committed:
		return false

	if meele_cd_timer > 0.0:
		return false

	if !meele_requested:
		return false

	if is_attacking:
		return false

	if get_parent().decision_locked:
		return false

	return true

# -------------------------------------------------

func commit_meele() -> void:
	meele_requested = false
	meele_committed = true
	is_attacking = true
	meele_cd_timer = meele_cooldown

	emit_signal("intent_attack", ATTACK_MEELE)

# -------------------------------------------------

func can_attack_now() -> bool:
	if phase_config == null:
		return false

	if !phase_config.phases.has(current_phase):
		return false

	var allowed_attacks = phase_config.phases[current_phase]["attacks"]
	return allowed_attacks.size() > 0

func choose_attack():
	if !phase_config.phases.has(current_phase):
		return null

	var allowed_attacks = phase_config.phases[current_phase]["attacks"]
	if allowed_attacks.is_empty():
		return null

	return allowed_attacks.pick_random()

# -------------------------------------------------

func choose_idle_or_move() -> void:
	if randf() <= idle_state_chance:
		emit_signal("intent_idle")
	else:
		emit_signal("intent_move")

# -------------------------------------------------
# Phase handling

func _on_phase_changed(_new_phase) -> void:
	get_parent().decision_locked = true
	emit_signal("intent_phase_transition")

func _on_phase_transition_finished() -> void:
	get_parent().decision_locked = false
	choose_idle_or_move()

# -------------------------------------------------
# flip

func flipping():
	if sign(get_direction_to_player().x) != 0:
		body.scale.x = sign(get_direction_to_player().x)

# -------------------------------------------------
# State callbacks

func _on_idle_state_finished() -> void:
	decide_next_action()

func _on_move_state_finished() -> void:
	decide_next_action()

func _on_projectile_state_finished() -> void:
	is_attacking = false
	choose_idle_or_move()

func _on_area_attack_state_finished() -> void:
	is_attacking = false
	choose_idle_or_move()

func _on_meele_attack_state_finished() -> void:
	meele_committed = false
	is_attacking = false
	choose_idle_or_move()

func _on_stats_health_depleated() -> void:
	dead = true
	emit_signal("died")
