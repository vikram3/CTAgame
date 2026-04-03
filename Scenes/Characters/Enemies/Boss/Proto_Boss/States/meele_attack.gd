extends Node

signal state_finished
@export var energy_consumption: float
@export var player: Node

var prompt_container: Control = null
var prompt_label: Label = null
var tap_indicator: Label = null
var grey_overlay: ColorRect = null
var canvas_layer_overlay: CanvasLayer = null
var canvas_layer_prompt: CanvasLayer = null
var original_zoom: Vector2

func _ready() -> void:
	call_deferred("_setup_ui")
	# Store original camera zoom
	if Global.cam:
		original_zoom = Global.cam.zoom

func _setup_ui() -> void:
	_setup_grey_overlay()
	_setup_prompt_ui()

func _on_meele_attack_state_entered() -> void:
	get_parent().parent.is_attacking = true
	if !get_parent().parent.energy_checking(energy_consumption):
		emit_signal("state_finished")
		return
	
	get_parent().anim.play("Meele_Attack")

func show_parry_prompt() -> void:
	# Check if player is on ground before showing prompt
	if !_is_player_grounded():
		return  # Don't show prompt if player is in air
	
	Global._freeze(0.5, 0.25)  # Slow motion
	_apply_camera_zoom(true)
	_apply_grey_screen(true)
	_show_prompt(true)
	_animate_prompt()
	
	if player:
		var state_chart = player.get_node_or_null("StateChart")
		if state_chart:
			var state_manager = state_chart.get_node_or_null("State_Transition_Manager")
			if state_manager:
				var block_node = state_manager.get_node_or_null("Block")
				if block_node and block_node.has_method("enable_parry_window"):
					block_node.enable_parry_window()

func hide_parry_prompt() -> void:
	_apply_camera_zoom(false)
	_apply_grey_screen(false)
	_show_prompt(false)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Meele_Attack":
		_apply_camera_zoom(false)
		_apply_grey_screen(false)
		_show_prompt(false)
		emit_signal("state_finished")

# Check if player is on the ground
func _is_player_grounded() -> bool:
	if !player:
		return false
	
	# Method 1: Check if player has is_on_floor() (for CharacterBody2D)
	if player.has_method("is_on_floor"):
		return player.is_on_floor()
	
	# Method 2: Check a custom grounded variable
	if "is_grounded" in player:
		return player.is_grounded
	
	# Method 3: Check velocity.y (if on ground, y velocity should be ~0)
	if "velocity" in player:
		return abs(player.velocity.y) < 10.0
	
	return true  # Default to true if we can't determine

func _setup_grey_overlay() -> void:
	if canvas_layer_overlay:
		return
	
	canvas_layer_overlay = CanvasLayer.new()
	canvas_layer_overlay.name = "ParryOverlay"
	canvas_layer_overlay.layer = 100
	get_tree().root.call_deferred("add_child", canvas_layer_overlay)
	
	grey_overlay = ColorRect.new()
	grey_overlay.color = Color(0.1, 0.1, 0.15, 0.0)  # Dark blue-grey tint
	grey_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grey_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	canvas_layer_overlay.call_deferred("add_child", grey_overlay)

func _setup_prompt_ui() -> void:
	if canvas_layer_prompt:
		return
	
	canvas_layer_prompt = CanvasLayer.new()
	canvas_layer_prompt.name = "ParryPrompt"
	canvas_layer_prompt.layer = 101
	get_tree().root.call_deferred("add_child", canvas_layer_prompt)
	
	# Container for all UI elements - centered on screen
	prompt_container = Control.new()
	prompt_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	prompt_container.modulate.a = 0.0
	prompt_container.pivot_offset = Vector2(0, 0)
	canvas_layer_prompt.call_deferred("add_child", prompt_container)
	
	# Warning text - centered
	prompt_label = Label.new()
	prompt_label.text = "!"
	prompt_label.add_theme_font_size_override("font_size", 40)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))  # Bright red
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 8)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	prompt_label.position = Vector2(-40, -70)
	prompt_label.size = Vector2(80, 60)
	prompt_container.call_deferred("add_child", prompt_label)
	
	# Button prompt (the E key visual) - centered below warning
	tap_indicator = Label.new()
	tap_indicator.text = "[E]"
	tap_indicator.add_theme_font_size_override("font_size", 36)
	tap_indicator.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))  # Bright yellow
	tap_indicator.add_theme_color_override("font_outline_color", Color.BLACK)
	tap_indicator.add_theme_constant_override("outline_size", 6)
	tap_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tap_indicator.set_anchors_preset(Control.PRESET_CENTER)
	tap_indicator.position = Vector2(-40, -5)
	tap_indicator.size = Vector2(80, 50)
	prompt_container.call_deferred("add_child", tap_indicator)

func _animate_prompt() -> void:
	if !tap_indicator or !is_instance_valid(tap_indicator):
		return
	
	# Intense pulse animation for the E key
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Scale pulse
	tween.tween_property(tap_indicator, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(tap_indicator, "scale", Vector2(1.0, 1.0), 0.15)

func _apply_camera_zoom(zoom_in: bool) -> void:
	if !Global.cam:
		return
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	if zoom_in:
		# Zoom in closer (increase zoom value)
		var target_zoom = original_zoom * 1.3  # 30% closer
		tween.tween_property(Global.cam, "zoom", target_zoom, 0.2)
	else:
		# Zoom back out to original
		tween.tween_property(Global.cam, "zoom", original_zoom, 0.3)

func _apply_grey_screen(enable: bool) -> void:
	if !grey_overlay or !is_instance_valid(grey_overlay):
		return
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	
	if enable:
		# Fade in grey overlay with vignette effect
		tween.tween_property(grey_overlay, "color:a", 0.65, 0.15)
	else:
		# Fade out
		tween.tween_property(grey_overlay, "color:a", 0.0, 0.25)

func _show_prompt(show: bool) -> void:
	if !prompt_container or !is_instance_valid(prompt_container):
		return
	
	# Get viewport size to calculate center
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	if show:
		# Start from center point (scale 0) and pop out
		prompt_container.pivot_offset = center
		prompt_container.scale = Vector2(0.0, 0.0)
		prompt_container.modulate.a = 1.0
		
		# Pop out animation - expands from center with overshoot
		tween.tween_property(prompt_container, "scale", Vector2(1.15, 1.15), 0.2)
		tween.tween_property(prompt_container, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		# Shrink back to center quickly
		tween.tween_property(prompt_container, "scale", Vector2(0.0, 0.0), 0.12)
		tween.parallel().tween_property(prompt_container, "modulate:a", 0.0, 0.12)
