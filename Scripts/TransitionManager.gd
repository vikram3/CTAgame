extends Node

var reader_ref: Node = null
var game_instance: Node = null
var transition_overlay: ColorRect = null
var is_transitioning: bool = false

var current_panel_index: int = -1
var current_game_index: int = -1


func _ready():
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.anchor_right = 1.0
	transition_overlay.anchor_bottom = 1.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.z_index = 100
	canvas.add_child(transition_overlay)

func start_game_segment(scene_path: String, reader: Node):
	reader_ref = reader
	
	await fade_to_black()
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	await get_tree().create_timer(0.3).timeout
	
	var game_scene = load(scene_path)
	game_instance = game_scene.instantiate()
	
	# Add to scene FIRST
	get_tree().root.add_child(game_instance)
	
	# Connect AFTER it's in the scene tree
	await get_tree().process_frame
	game_instance.level_completed.connect(_on_level_completed)
	print("Signal connected to: ", game_instance.name)
	print("Signal connections: ", game_instance.level_completed.get_connections())
	
	reader_ref.hide()
	await fade_to_clear()
	print("Game started, waiting for level_completed...")

func _on_level_completed(success: bool):
	print("_on_level_completed FIRED! success=", success)
	if is_transitioning:
		return
	is_transitioning = true
	
	await end_game_segment(success)

func end_game_segment(success: bool):
	print("end_game_segment started...")
	
	await fade_to_black()
	
	if game_instance and is_instance_valid(game_instance):
		game_instance.queue_free()
		game_instance = null
	
	await get_tree().create_timer(0.2).timeout
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	await get_tree().create_timer(0.3).timeout
	
	if reader_ref and is_instance_valid(reader_ref):
		reader_ref.show()
		if success:
			# Player reached exit — mark complete, scroll to next panel
			reader_ref.advance_past_playable()
		else:
			# Player pressed back — just restore scroll, keep trigger
			reader_ref.restore_scroll_only()
	else:
		push_error("reader_ref is null!")
	
	await fade_to_clear()
	is_transitioning = false

func fade_to_black() -> void:
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), 0.5)
	await tween.finished

func fade_to_clear() -> void:
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
