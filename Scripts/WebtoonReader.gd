extends Control

@onready var scroll_container = $ScrollContainer
@onready var panel_container = $ScrollContainer/PanelContainer
@onready var chapter_label = $CanvasLayer/TopBar/HBoxContainer/ChapterLabel
@onready var prev_btn = $CanvasLayer/TopBar/HBoxContainer/PrevButton
@onready var next_btn = $CanvasLayer/TopBar/HBoxContainer/NextButton
@onready var home_btn = $CanvasLayer/TopBar/HBoxContainer/HomeButton
@onready var chapter_select_btn = $CanvasLayer/TopBar/HBoxContainer/ChapterSelectButton
@onready var coin_label = $CoinDisplay/CoinLabel
const UNLOAD_DISTANCE_PX = 3000.0
const LOAD_AHEAD_PX = 1500.0  # load panels within 1500px of viewport

var chapter_panels: Array = []
var current_scroll_tween: Tween
var current_chapter: int = 1
var total_games: int = 0
var completed_game_indexes: Array = []  # track which games done this session
var saved_scroll_position: float = 0.0  # ← store scroll to restore after game

var _load_queue: Array = []  # [{rect, path}]
var _is_loading: bool = false

func _ready():
	# ... your existing code ...
	print("EXISTS CHECK: ", ResourceLoader.exists("res://Assets/webtoon/Ch1/ch1_01.jpg"))
	# DEBUG ONLY - remove before release
	var debug_btn = Button.new()
	debug_btn.text = "+100 Coins"
	debug_btn.position = Vector2(10, 100)
	debug_btn.pressed.connect(func():
		GameData.add_coins(100)
		coin_label.text = str(GameData.data.coins)
		print("Coins: ", GameData.data.coins)
	)
	$CanvasLayer.add_child(debug_btn)
	print("=== WEBTOON READER STARTED ===")
	print("Current chapter: ", GameData.data.current_chapter)

	current_chapter = GameData.data.current_chapter
	chapter_panels = ChapterData.get_chapter(current_chapter)

	print("Total panels loaded: ", chapter_panels.size())
	for i in chapter_panels.size():
		var p = chapter_panels[i]
		print("Panel ", i, " | type: ", p.type, " | path: ", p.image_path)

	current_chapter = GameData.data.current_chapter
	total_games = ChapterData.get_total_games(current_chapter)

	scroll_container.anchor_right = 1.0
	scroll_container.anchor_bottom = 1.0
	scroll_container.offset_top = 60
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	setup_navigation()
	build_chapter()  # ← only ONE call here

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	panel_container.queue_sort()
	await get_tree().process_frame

	var saved = GameData.get_chapter_progress(current_chapter)
	if saved > 0:
		scroll_container.scroll_vertical = saved
		print("Restored scroll on load: ", saved)

func _load_image_from_file(path: String) -> Texture2D:
	# Convert res:// path to absolute path
	var abs_path = ProjectSettings.globalize_path(path)
	
	var image = Image.new()
	var err = image.load(abs_path)
	
	if err != OK:
		# On Android, try using FileAccess directly
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Cannot open: " + path + " err: " + str(FileAccess.get_open_error()))
			return null
		var buffer = file.get_buffer(file.get_length())
		file.close()
		
		err = image.load_jpg_from_buffer(buffer)
		if err != OK:
			err = image.load_png_from_buffer(buffer)
		if err != OK:
			push_error("Failed to decode image: " + path)
			return null
	
	return ImageTexture.create_from_image(image)

#func _lazy_load_visible_panels():
	#var scroll_y = scroll_container.scroll_vertical
	#var viewport_h = scroll_container.size.y
	#
	#for child in panel_container.get_children():
		#if child is TextureRect and child.texture == null:
			#var child_y = child.position.y
			#if child_y < scroll_y + viewport_h + LOAD_AHEAD_PX:
				## Trigger load for this panel (store path in metadata)
				#var path = child.get_meta("image_path", "")
				#if path != "":
					#_poll_texture(child, path)

func setup_navigation():
	chapter_label.text = "Chapter " + str(current_chapter)
	home_btn.text = "🏠"
	home_btn.pressed.connect(_on_home_pressed)
	chapter_select_btn.text = "📖"
	chapter_select_btn.pressed.connect(_on_chapter_select_pressed)
	prev_btn.text = "◀"
	prev_btn.disabled = current_chapter <= 1
	prev_btn.pressed.connect(_on_prev_chapter)
	next_btn.text = "▶"
	next_btn.disabled = not GameData.is_chapter_unlocked(current_chapter + 1)
	next_btn.pressed.connect(_on_next_chapter)
	coin_label.text = str(GameData.data.coins)

func build_chapter():
	# Reset load queue on rebuild
	_load_queue.clear()
	_is_loading = false

	for child in panel_container.get_children():
		child.queue_free()
	
	for i in chapter_panels.size():
		var entry = chapter_panels[i]
		match entry.type:
			ChapterData.PanelType.STATIC:
				add_static_panel(entry, i)
			ChapterData.PanelType.PLAYABLE:
				add_playable_trigger_panel(entry, i)
	
	AchievementManager.check_and_unlock("first_read")

func add_static_panel(entry: ChapterData.PanelEntry, index: int):
	var texture_rect = TextureRect.new()
	texture_rect.name = "Panel_" + str(index)
	texture_rect.custom_minimum_size = Vector2(ChapterData.PANEL_WIDTH, 400)
	texture_rect.set_meta("image_path", entry.image_path)
	panel_container.add_child(texture_rect)

	if entry.image_path == "" or not ResourceLoader.exists(entry.image_path):
		push_error("Image not found: " + entry.image_path)
		return

	_load_queue.append({"rect": texture_rect, "path": entry.image_path})
	if not _is_loading:
		_process_load_queue()

func _process_load_queue():
	if _load_queue.is_empty():
		_is_loading = false
		return

	_is_loading = true
	var item = _load_queue.pop_front()
	var rect: TextureRect = item["rect"]
	var path: String = item["path"]

	# Yield one frame so UI stays responsive between loads
	await get_tree().process_frame

	if not is_instance_valid(rect):
		_process_load_queue()  # skip freed nodes, continue queue
		return

	var texture = ResourceLoader.load(path, "Texture2D")
	if is_instance_valid(rect):
		_apply_texture(rect, texture)

	_process_load_queue()  # load next

func _apply_texture(texture_rect: TextureRect, texture: Texture2D):
	if texture == null or not is_instance_valid(texture_rect):
		return
	var aspect = float(texture.get_height()) / float(texture.get_width())
	texture_rect.texture = texture
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.size = Vector2(ChapterData.PANEL_WIDTH, ChapterData.PANEL_WIDTH * aspect)
	texture_rect.custom_minimum_size = texture_rect.size
	
	
func add_playable_trigger_panel(entry: ChapterData.PanelEntry, index: int):
	# Skip if this game already completed
	if GameData.is_game_completed(current_chapter, entry.game_index):
		return
	
	var trigger_panel = preload("res://Scenes/PlayableTriggerPanel.tscn").instantiate()
	trigger_panel.name = "Playable_" + str(index)
	panel_container.add_child(trigger_panel)
	trigger_panel.setup(entry.transition_text)
	trigger_panel.play_pressed.connect(_on_play_pressed.bind(entry, index))
	

func _unload_distant_panels():
	var scroll_y = scroll_container.scroll_vertical
	for child in panel_container.get_children():
		if child is TextureRect and child.texture != null:
			if child.position.y < scroll_y - UNLOAD_DISTANCE_PX:
				child.texture = null  # free VRAM, keep placeholder size
	
	
func _on_play_pressed(entry: ChapterData.PanelEntry, panel_index: int):
	# Save scroll RIGHT before launching game
	saved_scroll_position = scroll_container.scroll_vertical
	GameData.save_chapter_progress(current_chapter, saved_scroll_position)
	print("Saved scroll before game: ", saved_scroll_position)
	
	TransitionManager.current_panel_index = panel_index
	TransitionManager.current_game_index = entry.game_index
	TransitionManager.start_game_segment(entry.playable_scene, self)

func restore_scroll_only():
	await get_tree().process_frame
	await get_tree().process_frame
	
	var saved = GameData.get_chapter_progress(current_chapter)
	print("Restoring scroll to: ", saved)
	scroll_container.scroll_vertical = saved

func advance_past_playable():
	var panel_index = TransitionManager.current_panel_index
	var game_index = TransitionManager.current_game_index
	
	# Mark game complete
	GameData.mark_game_completed(current_chapter, game_index)
	coin_label.text = str(GameData.data.coins)
	
	# Hide completed trigger panel
	for child in panel_container.get_children():
		if child.name == "Playable_" + str(panel_index):
			child.hide()
			break
	
	# Check chapter completion
	var newly_completed = GameData.check_chapter_complete(current_chapter, total_games)
	if newly_completed:
		_on_chapter_fully_completed()
	
	# Wait for layout to fully rebuild
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # extra frame to be safe
	
	# Restore EXACT scroll position saved before game launched
	scroll_container.scroll_vertical = saved_scroll_position
	print("Restored scroll to: ", saved_scroll_position)
	
	# Then scroll forward to next panel after trigger
	await get_tree().create_timer(0.5).timeout
	_scroll_to_next_panel_after(panel_index)

func _scroll_to_next_panel_after(panel_index: int):
	# Find next visible panel after the trigger
	for child in panel_container.get_children():
		if child.name.begins_with("Panel_"):
			var idx = int(child.name.split("_")[1])
			if idx > panel_index and child.visible:
				print("Scrolling to panel: ", child.name, " at y: ", child.global_position.y)
				smooth_scroll_to(child.global_position.y)
				# Save this new position
				GameData.save_chapter_progress(
					current_chapter,
					child.global_position.y
				)
				return

func _on_chapter_fully_completed():
	print("Chapter ", current_chapter, " fully completed!")
	AchievementManager.check_and_unlock("chapter_" + str(current_chapter))
	# Unlock next chapter
	GameData.unlock_chapter(current_chapter + 1)
	next_btn.disabled = false
	# Show completion popup or effect here
	show_chapter_complete_banner()

func show_chapter_complete_banner():
	var label = Label.new()
	label.text = "⭐ Chapter " + str(current_chapter) + " Complete! ⭐"
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var canvas = CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	canvas.add_child(label)
	
	label.set_anchors_preset(Control.PRESET_CENTER)
	
	# Auto remove after 3 seconds
	await get_tree().create_timer(3.0).timeout
	canvas.queue_free()

func smooth_scroll_to(target_y: float):
	if current_scroll_tween:
		current_scroll_tween.kill()
	current_scroll_tween = create_tween()
	current_scroll_tween.set_ease(Tween.EASE_IN_OUT)
	current_scroll_tween.set_trans(Tween.TRANS_CUBIC)
	current_scroll_tween.tween_property(
		scroll_container.get_v_scroll_bar(),
		"value",
		target_y,
		1.2
	)

# Save scroll every few seconds (not every frame - too heavy)
var save_timer: float = 0.0
func _process(delta):
	save_timer += delta
	if save_timer >= 2.0:
		save_timer = 0.0
		GameData.save_chapter_progress(current_chapter, scroll_container.scroll_vertical)
	
	#_lazy_load_visible_panels()

func save_progress():
	GameData.save_chapter_progress(current_chapter, scroll_container.scroll_vertical)

func _on_home_pressed():
	save_progress()
	SceneManager.go_to_title()

func _on_chapter_select_pressed():
	save_progress()
	SceneManager.go_to_chapter_select()

func _on_prev_chapter():
	if current_chapter > 1:
		save_progress()
		SceneManager.go_to_chapter(current_chapter - 1)

func _on_next_chapter():
	var next = current_chapter + 1
	if GameData.is_chapter_unlocked(next):
		save_progress()
		SceneManager.go_to_chapter(next)
