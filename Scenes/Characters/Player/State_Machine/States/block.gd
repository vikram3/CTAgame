# block.gd  –  attach to State_Transition_Manager/Block
# The block state:
#   1. Disables hurt_box (invulnerable while blocking)
#   2. Enables check_hit area so we can detect incoming attacks
#   3. Counter-timer runs: hit within window = parry, hit outside = normal block
#   4. Release block button (or timer runs out) = exits block
extends Node

@export var counter_timer: Timer   # Assign in inspector – a Timer node on this same node

var hit: bool                = false
var block_end_requested: bool = false
var can_parry_now: bool      = false

var _player: CharacterBody2D
var _sm: Node

func _get_player() -> CharacterBody2D:
	if _player == null: _player = get_parent().get_parent()
	return _player

func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _on_block_state_entered() -> void:
	counter_timer.start()
	block_end_requested = false
	hit                 = false
	can_parry_now       = false

	_get_sm().check_hit.disabled = false
	_get_sm().hurt_box.disabled  = true
	_get_player().can_attack     = true      # can cancel block into attack
	_get_player().can_ground_dash = true
	_get_sm().anim.play("Block")

func _on_block_state_physics_processing(_delta: float) -> void:
	var p = _get_player()
	p.velocity.x = lerp(p.velocity.x, 0.0, 20.0 * _delta)

	# Perfect parry window (animation event calls enable_parry_window)
	if can_parry_now and hit:
		hit             = false
		can_parry_now   = false
		p.parried       = true
		block_end_requested = true
		_show_perfect_parry_feedback()
		return

	# Normal block hit (within counter_timer window)
	if hit and counter_timer.time_left > 0.0:
		hit             = false
		p.parried       = true
		block_end_requested = true
		return

	# Exit when button released OR timer expired
	if not block_end_requested:
		if not Input.is_action_pressed("block") or counter_timer.time_left <= 0.0:
			block_end_requested = true

	if block_end_requested:
		_end_block()

func _on_block_state_exited() -> void:
	_end_block()

func _end_block() -> void:
	block_end_requested             = false
	_get_player().can_block         = true
	_get_sm().check_hit.disabled    = true
	_get_sm().hurt_box.disabled     = false

func _on_check_hit_area_entered(_area: Area2D) -> void:
	hit = true

# Called from animation track or an AnimationPlayer callback on the "Block" animation
func enable_parry_window() -> void:
	can_parry_now = true
	await get_tree().create_timer(0.5, false).timeout
	can_parry_now = false

# ── Perfect parry feedback ─────────────────────────────────────────
func _show_perfect_parry_feedback() -> void:
	Global._freeze(0.25, 0.05)
	if Global.cam:
		Global.cam.screen_shake(15, 0.3)
	_spawn_perfect_text()
	_spawn_flash_effect()

func _spawn_perfect_text() -> void:
	var cl = CanvasLayer.new()
	cl.layer = 102
	get_tree().root.add_child(cl)

	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(container)

	var label = Label.new()
	label.text = "PERFECT!"
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-150.0, -30.0)
	label.size     = Vector2(300.0, 60.0)
	container.add_child(label)

	var vp_size = get_viewport().get_visible_rect().size
	container.pivot_offset = vp_size / 2.0
	container.scale        = Vector2.ZERO

	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(container, "scale", Vector2(1.3, 1.3), 0.12)
	tw.tween_property(container, "scale", Vector2(1.0, 1.0), 0.08)
	tw.tween_interval(0.1)
	tw.tween_property(label, "position:y", label.position.y - 40.0, 0.4)
	tw.parallel().tween_property(container, "modulate:a", 0.0, 0.4)
	await tw.finished
	cl.queue_free()

func _spawn_flash_effect() -> void:
	var cl = CanvasLayer.new()
	cl.layer = 103
	get_tree().root.add_child(cl)

	var flash = ColorRect.new()
	flash.color        = Color(1.0, 1.0, 1.0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(flash)

	var tw = create_tween()
	tw.tween_property(flash, "color:a", 0.6, 0.05)
	tw.tween_property(flash, "color:a", 0.0, 0.15)
	await tw.finished
	cl.queue_free()
