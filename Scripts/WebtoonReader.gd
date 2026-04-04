extends Control

@onready var scroll_container   = $ScrollContainer
@onready var center_container   = $ScrollContainer/CenterContainer
@onready var panel_container    = $ScrollContainer/CenterContainer/PanelContainer
@onready var chapter_label      = $CanvasLayer/TopBar/HBoxContainer/ChapterLabel
@onready var prev_btn           = $CanvasLayer/TopBar/HBoxContainer/PrevButton
@onready var next_btn           = $CanvasLayer/TopBar/HBoxContainer/NextButton
@onready var home_btn           = $CanvasLayer/TopBar/HBoxContainer/HomeButton
@onready var chapter_select_btn = $CanvasLayer/TopBar/HBoxContainer/ChapterSelectButton
@onready var coin_label         = $CoinDisplay/CoinLabel
@onready var zoom_in_btn        = $CanvasLayer/ZoomBar/ZoomIn
@onready var zoom_out_btn       = $CanvasLayer/ZoomBar/ZoomOut
@onready var zoom_reset_btn     = $CanvasLayer/ZoomBar/ZoomReset
@onready var zoom_label         = $CanvasLayer/ZoomBar/ZoomLabel
@onready var scroll_indicator   = $CanvasLayer/ScrollIndicator

# ─────────────────────────────────────────────
#  TUNABLE CONSTANTS
# ─────────────────────────────────────────────
const BASE_PANEL_WIDTH    = 720.0   # webtoon column width at 100% zoom (px)
const MIN_ZOOM            = 0.5
const MAX_ZOOM            = 2.5
const ZOOM_STEP           = 0.15
const SMOOTH_SCROLL_TIME  = 0.4    # seconds
const AUTO_SAVE_INTERVAL  = 2.0
const UI_HIDE_DELAY       = 3.5    # seconds idle before top/zoom bar fades

# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────
var chapter_panels: Array         = []
var current_chapter: int          = 1
var total_games: int              = 0
var saved_scroll_position: float  = 0.0

var _zoom: float                  = 1.0
var _zoom_busy: bool              = false   # re-entry guard
var _load_queue: Array            = []
var _is_loading: bool             = false
var _save_timer: float            = 0.0
var _resize_timer: float          = 0.0
var _resize_pending: bool         = false
var _scroll_tween: Tween          = null
var _ui_visible: bool             = true
var _ui_hide_timer: float         = UI_HIDE_DELAY


# ════════════════════════════════════════════
#  READY
# ════════════════════════════════════════════
func _ready():
	current_chapter = GameData.data.current_chapter
	chapter_panels  = ChapterData.get_chapter(current_chapter)
	total_games     = ChapterData.get_total_games(current_chapter)

	_setup_scroll_container()
	_setup_navigation()
	_setup_zoom_bar()
	_setup_scroll_indicator()

	build_chapter()

	# Wait for layout to settle, then restore scroll
	for _i in 4:
		await get_tree().process_frame
	panel_container.queue_sort()
	await get_tree().process_frame

	var saved = GameData.get_chapter_progress(current_chapter)
	if saved > 0:
		scroll_container.scroll_vertical = int(saved)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	AchievementManager.check_and_unlock("first_read")


# ════════════════════════════════════════════
#  SETUP
# ════════════════════════════════════════════
func _setup_scroll_container():
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.offset_top = 64
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO

	# CenterContainer: horizontal centering wrapper
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.alignment             = BoxContainer.ALIGNMENT_CENTER

	# PanelContainer: vertical strip of panels
	panel_container.size_flags_horizontal  = Control.SIZE_SHRINK_CENTER
	panel_container.add_theme_constant_override("separation", 0)



func _setup_navigation():
	chapter_label.text = "Chapter " + str(current_chapter)

	home_btn.text = "🏠"
	home_btn.pressed.connect(_on_home_pressed)

	chapter_select_btn.text = "📖"
	chapter_select_btn.pressed.connect(_on_chapter_select_pressed)

	prev_btn.text     = "◀"
	prev_btn.disabled = (current_chapter <= 1)
	prev_btn.pressed.connect(_on_prev_chapter)

	next_btn.text     = "▶"
	next_btn.disabled = not GameData.is_chapter_unlocked(current_chapter + 1)
	next_btn.pressed.connect(_on_next_chapter)

	coin_label.text = str(GameData.data.coins)


func _setup_zoom_bar():
	zoom_in_btn.text    = "＋"
	zoom_out_btn.text   = "－"
	zoom_reset_btn.text = "⟲"
	zoom_in_btn.pressed.connect(_zoom_in)
	zoom_out_btn.pressed.connect(_zoom_out)
	zoom_reset_btn.pressed.connect(_zoom_reset)
	_refresh_zoom_ui()


func _setup_scroll_indicator():
	scroll_indicator.min_value = 0.0
	scroll_indicator.max_value = 1.0
	scroll_indicator.value     = 0.0


# ════════════════════════════════════════════
#  PROCESS  (delta loop)
# ════════════════════════════════════════════
func _process(delta: float):
	# — Debounced resize rebuild —
	if _resize_pending:
		_resize_timer -= delta
		if _resize_timer <= 0.0:
			_resize_pending = false
			_rebuild_for_new_size()

	# — Auto-save scroll —
	_save_timer += delta
	if _save_timer >= AUTO_SAVE_INTERVAL:
		_save_timer = 0.0
		GameData.save_chapter_progress(current_chapter, scroll_container.scroll_vertical)

	# — Scroll indicator (every frame — works with tweens and direct sets) —
	_update_scroll_indicator()

	# — UI auto-hide —
	if _ui_visible:
		_ui_hide_timer -= delta
		if _ui_hide_timer <= 0.0:
			_fade_ui(false)


# ════════════════════════════════════════════
#  INPUT  (keyboard + ctrl-scroll for PC)
# ════════════════════════════════════════════
func _unhandled_input(event: InputEvent):
	var vp_h = scroll_container.size.y

	if event is InputEventKey and event.pressed:
		_wake_ui()
		match event.keycode:
			KEY_DOWN, KEY_S:
				smooth_scroll_to(scroll_container.scroll_vertical + 300)
			KEY_UP, KEY_W:
				smooth_scroll_to(scroll_container.scroll_vertical - 300)
			KEY_PAGEDOWN:
				smooth_scroll_to(scroll_container.scroll_vertical + vp_h * 0.85)
			KEY_PAGEUP:
				smooth_scroll_to(scroll_container.scroll_vertical - vp_h * 0.85)
			KEY_HOME:
				smooth_scroll_to(0)
			KEY_END:
				smooth_scroll_to(panel_container.size.y)
			KEY_EQUAL, KEY_KP_ADD:
				if event.ctrl_pressed: _zoom_in()
			KEY_MINUS, KEY_KP_SUBTRACT:
				if event.ctrl_pressed: _zoom_out()
			KEY_0:
				if event.ctrl_pressed: _zoom_reset()

	# Ctrl + mouse wheel = zoom on PC
	if event is InputEventMouseButton and event.pressed:
		_wake_ui()
		if event.ctrl_pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:   _zoom_in()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _zoom_out()

	# Touch: tap centre of screen to toggle UI
	if event is InputEventScreenTouch and event.pressed:
		_wake_ui()


# ════════════════════════════════════════════
#  UI FADE (auto-hide top/zoom bars)
# ════════════════════════════════════════════
func _wake_ui():
	_ui_hide_timer = UI_HIDE_DELAY
	if not _ui_visible:
		_fade_ui(true)


func _fade_ui(show: bool):
	_ui_visible = show
	var target   = 1.0 if show else 0.0
	var duration = 0.25 if show else 0.6

	var tween = create_tween().set_parallel(true)
	tween.tween_property($CanvasLayer/TopBar, "modulate:a", target, duration)
	tween.tween_property($CanvasLayer/ZoomBar, "modulate:a",
		target if show else 0.35, duration)


# ════════════════════════════════════════════
#  SCROLL INDICATOR
# ════════════════════════════════════════════
func _update_scroll_indicator():
	var vbar  = scroll_container.get_v_scroll_bar()
	var range = vbar.max_value - vbar.page
	if range > 0.0:
		scroll_indicator.value = clamp(vbar.value / range, 0.0, 1.0)
	else:
		scroll_indicator.value = 0.0


# ════════════════════════════════════════════
#  ZOOM
# ════════════════════════════════════════════
func _zoom_in():
	if _zoom < MAX_ZOOM - 0.001:
		_do_zoom(_zoom + ZOOM_STEP)

func _zoom_out():
	if _zoom > MIN_ZOOM + 0.001:
		_do_zoom(_zoom - ZOOM_STEP)

func _zoom_reset():
	_do_zoom(1.0)


func _do_zoom(new_zoom: float):
	if _zoom_busy:
		return
	_zoom_busy = true

	new_zoom = clamp(new_zoom, MIN_ZOOM, MAX_ZOOM)

	# Save ratio before any change
	var total_h = panel_container.size.y
	var ratio   = float(scroll_container.scroll_vertical) / max(total_h, 1.0)

	# Apply synchronously
	_zoom = new_zoom
	_refresh_zoom_ui()
	_resize_all_panels()

	# Wait for layout then restore scroll
	await get_tree().process_frame
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(ratio * panel_container.size.y)

	_zoom_busy = false


func _refresh_zoom_ui():
	zoom_label.text       = str(int(round(_zoom * 100))) + "%"
	zoom_in_btn.disabled  = (_zoom >= MAX_ZOOM - 0.001)
	zoom_out_btn.disabled = (_zoom <= MIN_ZOOM + 0.001)


func _panel_width() -> float:
	return BASE_PANEL_WIDTH * _zoom


func _resize_all_panels():
	var pw = _panel_width()
	for child in panel_container.get_children():
		if child is TextureRect:
			if child.texture != null:
				var aspect = float(child.texture.get_height()) / float(child.texture.get_width())
				child.custom_minimum_size = Vector2(pw, pw * aspect)
				child.size               = child.custom_minimum_size
				child.stretch_mode       = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				child.expand_mode        = TextureRect.EXPAND_IGNORE_SIZE
			else:
				child.custom_minimum_size = Vector2(pw, pw * 1.45)
		else:
			child.custom_minimum_size.x = pw
	panel_container.queue_sort()


# ════════════════════════════════════════════
#  VIEWPORT RESIZE / ROTATION
# ════════════════════════════════════════════
func _on_viewport_size_changed():
	_resize_pending = true
	_resize_timer   = 0.25   # seconds debounce


func _rebuild_for_new_size():
	var total_h = panel_container.size.y
	var ratio   = float(scroll_container.scroll_vertical) / max(total_h, 1.0)

	build_chapter()

	for _i in 4:
		await get_tree().process_frame
	panel_container.queue_sort()
	await get_tree().process_frame

	scroll_container.scroll_vertical = int(ratio * panel_container.size.y)


# ════════════════════════════════════════════
#  BUILD CHAPTER
# ════════════════════════════════════════════
func build_chapter():
	_load_queue.clear()
	_is_loading = false

	for child in panel_container.get_children():
		child.queue_free()

	for i in chapter_panels.size():
		var entry = chapter_panels[i]
		match entry.type:
			ChapterData.PanelType.STATIC:
				_add_static_panel(entry, i)
			ChapterData.PanelType.PLAYABLE:
				_add_playable_trigger_panel(entry, i)


func _add_static_panel(entry: ChapterData.PanelEntry, index: int):
	var pw           = _panel_width()
	var rect         = TextureRect.new()
	rect.name        = "Panel_" + str(index)
	# Placeholder size until image loads (roughly manga aspect)
	rect.custom_minimum_size       = Vector2(pw, pw * 1.45)
	rect.size_flags_horizontal     = Control.SIZE_SHRINK_CENTER
	rect.set_meta("image_path", entry.image_path)
	panel_container.add_child(rect)

	if entry.image_path == "" or not ResourceLoader.exists(entry.image_path):
		push_error("Image not found: " + entry.image_path)
		return

	_load_queue.append({"rect": rect, "path": entry.image_path})
	if not _is_loading:
		_process_load_queue()


func _add_playable_trigger_panel(entry: ChapterData.PanelEntry, index: int):
	if GameData.is_game_completed(current_chapter, entry.game_index):
		return

	var trigger = preload("res://Scenes/PlayableTriggerPanel.tscn").instantiate()
	trigger.name                    = "Playable_" + str(index)
	trigger.size_flags_horizontal   = Control.SIZE_SHRINK_CENTER
	trigger.custom_minimum_size.x   = _panel_width()
	panel_container.add_child(trigger)
	trigger.setup(entry.transition_text)
	trigger.play_pressed.connect(_on_play_pressed.bind(entry, index))


# ════════════════════════════════════════════
#  ASYNC IMAGE LOADING
# ════════════════════════════════════════════
func _process_load_queue():
	if _load_queue.is_empty():
		_is_loading = false
		return

	_is_loading  = true
	var item     = _load_queue.pop_front()
	var rect: TextureRect = item["rect"]
	var path: String      = item["path"]

	# Yield one frame to keep UI responsive between loads
	await get_tree().process_frame

	if not is_instance_valid(rect):
		_process_load_queue()
		return

	var texture = ResourceLoader.load(path, "Texture2D")
	if is_instance_valid(rect):
		_apply_texture(rect, texture)

	_process_load_queue()


func _apply_texture(rect: TextureRect, texture: Texture2D):
	if texture == null or not is_instance_valid(rect):
		return
	var pw     = _panel_width()
	var aspect = float(texture.get_height()) / float(texture.get_width())
	rect.texture              = texture
	# KEEP_ASPECT_CENTERED ensures no stretching — letterboxes if aspect differs
	rect.stretch_mode         = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.expand_mode          = TextureRect.EXPAND_IGNORE_SIZE
	rect.size                 = Vector2(pw, pw * aspect)
	rect.custom_minimum_size  = rect.size
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


# ════════════════════════════════════════════
#  SMOOTH SCROLL
# ════════════════════════════════════════════
func smooth_scroll_to(target_y: float):
	target_y = clamp(target_y, 0.0, panel_container.size.y)
	if _scroll_tween:
		_scroll_tween.kill()
	_scroll_tween = create_tween()
	_scroll_tween.set_ease(Tween.EASE_OUT)
	_scroll_tween.set_trans(Tween.TRANS_QUART)
	_scroll_tween.tween_property(
		scroll_container.get_v_scroll_bar(), "value", target_y, SMOOTH_SCROLL_TIME
	)


# ════════════════════════════════════════════
#  GAME SEGMENT FLOW
# ════════════════════════════════════════════
func _on_play_pressed(entry: ChapterData.PanelEntry, panel_index: int):
	saved_scroll_position = scroll_container.scroll_vertical
	GameData.save_chapter_progress(current_chapter, saved_scroll_position)
	TransitionManager.current_panel_index = panel_index
	TransitionManager.current_game_index  = entry.game_index
	TransitionManager.start_game_segment(entry.playable_scene, self)


func restore_scroll_only():
	await get_tree().process_frame
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(GameData.get_chapter_progress(current_chapter))


func advance_past_playable():
	var panel_index = TransitionManager.current_panel_index
	var game_index  = TransitionManager.current_game_index

	GameData.mark_game_completed(current_chapter, game_index)
	coin_label.text = str(GameData.data.coins)

	for child in panel_container.get_children():
		if child.name == "Playable_" + str(panel_index):
			child.hide()
			break

	if GameData.check_chapter_complete(current_chapter, total_games):
		_on_chapter_fully_completed()

	for _i in 3:
		await get_tree().process_frame
	scroll_container.scroll_vertical = int(saved_scroll_position)

	await get_tree().create_timer(0.5).timeout
	_scroll_to_next_panel_after(panel_index)


func _scroll_to_next_panel_after(panel_index: int):
	for child in panel_container.get_children():
		if child.name.begins_with("Panel_"):
			var idx = int(child.name.split("_")[1])
			if idx > panel_index and child.visible:
				smooth_scroll_to(child.global_position.y)
				GameData.save_chapter_progress(current_chapter, child.global_position.y)
				return


# ════════════════════════════════════════════
#  CHAPTER COMPLETION
# ════════════════════════════════════════════
func _on_chapter_fully_completed():
	AchievementManager.check_and_unlock("chapter_" + str(current_chapter))
	GameData.unlock_chapter(current_chapter + 1)
	next_btn.disabled = false
	_show_completion_banner()


func _show_completion_banner():
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	canvas.add_child(panel)

	var label = Label.new()
	label.text = "⭐  Chapter " + str(current_chapter) + " Complete!  ⭐"
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)

	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.35)
	tween.tween_interval(2.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	await tween.finished
	canvas.queue_free()


# ════════════════════════════════════════════
#  NAVIGATION
# ════════════════════════════════════════════
func save_progress():
	GameData.save_chapter_progress(current_chapter, scroll_container.scroll_vertical)

func _on_home_pressed():
	save_progress(); SceneManager.go_to_title()

func _on_chapter_select_pressed():
	save_progress(); SceneManager.go_to_chapter_select()

func _on_prev_chapter():
	if current_chapter > 1:
		save_progress(); SceneManager.go_to_chapter(current_chapter - 1)

func _on_next_chapter():
	var next = current_chapter + 1
	if GameData.is_chapter_unlocked(next):
		save_progress(); SceneManager.go_to_chapter(next)
