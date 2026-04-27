# attacks.gd  –  BASE CLASS. Do NOT attach directly. Extend with ground_attacks.gd / air_attacks.gd
# Place this file at res://Scripts/Player/attacks.gd (or wherever your scripts folder is)
extends Node
class_name AttacksClass

# How many seconds into the animation hitboxes become active / deactivate
@export var hitbox_enable_frame: float  = 0.15
@export var hitbox_disable_frame: float = 0.40

var current_combo: int     = 0
var combo_requested: bool  = false
var active: bool           = false
var _expected_anim: String = ""

var _player: CharacterBody2D
var _sm: Node

func _get_player() -> CharacterBody2D:
	if _player == null: _player = get_parent().get_parent()
	return _player

func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

# ── Start an attack animation ──────────────────────────────────────
func _attack_name(anim_name: String) -> void:
	var a: AnimationPlayer = _get_sm().anim

	if not a.has_animation(anim_name):
		push_warning("Attacks: animation '%s' not found — resetting can_attack." % anim_name)
		_get_player().can_attack = true
		return

	# Disconnect any leftover one-shot to prevent double-firing
	if a.animation_finished.is_connected(_on_attack_anim_done):
		a.animation_finished.disconnect(_on_attack_anim_done)

	active          = true
	combo_requested = false
	_expected_anim  = anim_name

	_disable_active_hitboxes()
	_get_sm().hurt_box.disabled = true
	a.play(anim_name)

	# Hitbox ON after enable_frame seconds
	get_tree().create_timer(hitbox_enable_frame, false).timeout.connect(
		func() -> void:
			if active and _expected_anim == anim_name:
				_enable_active_hitboxes()
	)

	# Hitbox OFF after disable_frame seconds
	get_tree().create_timer(hitbox_disable_frame, false).timeout.connect(
		func() -> void:
			if _expected_anim == anim_name:
				_disable_active_hitboxes()
	)

	a.animation_finished.connect(_on_attack_anim_done, CONNECT_ONE_SHOT)

# ── Animation finished callback ────────────────────────────────────
func _on_attack_anim_done(anim_name: String) -> void:
	if anim_name != _expected_anim:
		return          # wrong animation finished (state changed mid-way)
	_finish_attack()

func _finish_attack() -> void:
	if not active:
		return
	active         = false
	_expected_anim = ""
	_get_sm().hurt_box.disabled = false
	_disable_active_hitboxes()

	if combo_requested:
		combo_requested = false
		# The combo state machine (ground_attacks / air_attacks) will send the
		# next state event in its own _on_*_state_entered. We just leave
		# can_attack = false so the transition continues.
		return

	_get_player().can_attack = true

# ── Hitbox helpers ─────────────────────────────────────────────────
# Expected scene structure: Body → Hit_Box → <Area2D children> → CollisionShape2D
func _enable_active_hitboxes() -> void:
	var hb = _get_player().get_node_or_null("Body/Hit_Box")
	if hb == null:
		push_warning("Attacks: 'Body/Hit_Box' not found!")
		return
	for child in hb.get_children():
		if child is Area2D:
			var shape = child.get_node_or_null("CollisionShape2D")
			if shape:
				shape.disabled = false

func _disable_active_hitboxes() -> void:
	var hb = _get_player().get_node_or_null("Body/Hit_Box")
	if hb == null: return
	for child in hb.get_children():
		if child is Area2D:
			var shape = child.get_node_or_null("CollisionShape2D")
			if shape:
				shape.disabled = true

# ── Combo window check ─────────────────────────────────────────────
# Call this in each combo state's _physics_processing
func _check_combo_input() -> void:
	if Input.is_action_just_pressed("Attack") and active:
		combo_requested = true


func _on_combo_1_state_entered() -> void:
	current_combo = 1
	_attack_name("Attack_1")

func _on_combo_state_exited() -> void:
	if combo_requested:
		_get_player().can_attack = false

func _on_combo_state_physics_processing(delta: float) -> void:
	_check_combo_input()

func _on_combo_2_state_entered() -> void:
	current_combo = 2
	active = false
	_attack_name("Attack_2")

func _on_combo_2_state_exited() -> void:
	if combo_requested:
		_get_player().can_attack = false

func _on_combo_2_state_physics_processing(delta: float) -> void:
	_check_combo_input()

func _on_combo_3_state_entered() -> void:
	current_combo = 3
	active = false
	_attack_name("Attack_3")

func _on_combo_3_state_exited() -> void:
	current_combo = 0
	if active:
		active = false
		_disable_active_hitboxes()
		_get_sm().hurt_box.disabled = false
	_get_player().can_attack = true

func _on_combo_3_state_physics_processing(delta: float) -> void:
	_check_combo_input()


func _on_player_combo_attack() -> void:
	pass # Replace with function body.
