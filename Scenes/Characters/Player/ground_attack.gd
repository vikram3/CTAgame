# ground_attacks.gd  –  attach to State_Transition_Manager/Attacks  (or Ground_Attack node)
# Extends the base Attacks class. Handles the 3-hit ground combo.
# StateChart events needed: attack → combo_1 → combo_2 → combo_3 → (idle/run)
extends Attacks

# ── Combo 1 ───────────────────────────────────────────────────────
func _on_combo_1_state_entered() -> void:
	current_combo = 1
	_attack_name("Attack_1")

func _on_combo_1_state_physics_processing(_delta: float) -> void:
	_check_combo_input()

func _on_combo_1_state_exited() -> void:
	# If a combo was requested, keep can_attack false so combo_2 is entered.
	# If not, _finish_attack already reset can_attack.
	if combo_requested:
		_get_player().can_attack = false   # ensure state machine stays in attack

# ── Combo 2 ───────────────────────────────────────────────────────
func _on_combo_2_state_entered() -> void:
	current_combo = 2
	# Reset active/combo flags so _attack_name works cleanly
	active = false
	_attack_name("Attack_2")

func _on_combo_2_state_physics_processing(_delta: float) -> void:
	_check_combo_input()

func _on_combo_2_state_exited() -> void:
	if combo_requested:
		_get_player().can_attack = false

# ── Combo 3 ───────────────────────────────────────────────────────
func _on_combo_3_state_entered() -> void:
	current_combo = 3
	active = false
	_attack_name("Attack_3")
	_get_player().emit_signal("combo_attack")   # signal for VFX / camera shake etc.

func _on_combo_3_state_physics_processing(_delta: float) -> void:
	_check_combo_input()   # optional: allow a new combo chain immediately after

func _on_combo_3_state_exited() -> void:
	current_combo = 0
	# _finish_attack has already reset can_attack = true when the anim finished
	# If it hasn't (state forced out), make sure we clean up.
	if active:
		active = false
		_disable_active_hitboxes()
		_get_sm().hurt_box.disabled = false
		_get_player().can_attack = true
