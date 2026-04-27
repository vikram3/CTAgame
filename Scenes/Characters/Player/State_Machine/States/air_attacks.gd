# air_attacks.gd  –  attach to State_Transition_Manager/Air_Attacks
# Extends the base Attacks class. Handles 3-hit air combo.
extends AttacksClass

# While attacking in the air, clamp fall speed so the player hangs briefly.
const AIR_ATTACK_MAX_FALL: float = 40.0

# ── Combo 1 ───────────────────────────────────────────────────────
func _on_combo_1_state_entered() -> void:
	current_combo = 1
	_attack_name("Air_attack_1")

func _on_combo_1_state_physics_processing(_delta: float) -> void:
	_check_combo_input()
	_get_player().velocity.y = clamp(_get_player().velocity.y, -999.0, AIR_ATTACK_MAX_FALL)

func _on_combo_1_state_exited() -> void:
	if combo_requested:
		_get_player().can_attack = false

# ── Combo 2 ───────────────────────────────────────────────────────
func _on_combo_2_state_entered() -> void:
	current_combo = 2
	active = false
	_attack_name("Air_attack_2")

func _on_combo_2_state_physics_processing(_delta: float) -> void:
	_check_combo_input()
	_get_player().velocity.y = clamp(_get_player().velocity.y, -999.0, AIR_ATTACK_MAX_FALL)

func _on_combo_2_state_exited() -> void:
	if combo_requested:
		_get_player().can_attack = false

# ── Combo 3 – downward slam ────────────────────────────────────────
func _on_combo_3_state_entered() -> void:
	current_combo = 3
	active = false
	_attack_name("Air_attack_3")
	_get_player().velocity.y = 200.0   # slam downward

func _on_combo_3_state_physics_processing(_delta: float) -> void:
	pass  # let gravity / slam velocity resolve naturally

func _on_combo_3_state_exited() -> void:
	current_combo = 0
	if active:
		active = false
		_disable_active_hitboxes()
		_get_sm().hurt_box.disabled = false
	_get_player().can_attack = true
