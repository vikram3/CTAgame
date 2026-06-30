extends Node2D
## Tutorial level controller.
##
## This script no longer generates the level at runtime. Paint the TileMap,
## place Coin / Prop / Guard scenes, and set patrol points directly in the
## Godot editor. This script only wires up signals, HUD text, the camera,
## and win/lose flow.

signal level_completed(success: bool)

# ---------------------------------------------------------------------------
# Core references — assign these in the Inspector.
# ---------------------------------------------------------------------------
@export_group("Core Nodes")
@export var player: Player
@export var exit_door: ExitDoor
@export var hud: Control
@export var game_over_panel: Control
@export var win_panel: Control
@export var tile_map: TileMap

# ---------------------------------------------------------------------------
# Spawn points — drop Marker2D nodes in the scene and link them here.
# If left empty, the player/exit keep whatever position they already have
# in the scene tree (i.e. exactly where you placed them in the editor).
# ---------------------------------------------------------------------------
@export_group("Spawn Points")
@export var player_start: Marker2D
@export var exit_position: Marker2D

# ---------------------------------------------------------------------------
# Gameplay tuning
# ---------------------------------------------------------------------------
@export_group("Objective")
@export var required_coins: int = 20
@export var objective_text: String = "Time to grab those coins before anyone notices..."
@export var exit_open_text: String = "The exit is open. Slip out before the skull guards notice."
@export var missing_coins_text: String = "Need more coins."
@export var hidden_text: String = "Hidden"
@export var toast_duration: float = 1.4

# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------
@export_group("Camera")
@export var camera_zoom: Vector2 = Vector2(0.8, 0.8)
@export var camera_smoothing_enabled: bool = true
@export var camera_smoothing_speed: float = 6.0
@export var use_camera_limits: bool = false
@export var camera_limit_rect: Rect2 = Rect2()

# ---------------------------------------------------------------------------
# Collision layers — exposed so you can tune them per-level without editing code.
# ---------------------------------------------------------------------------
@export_group("Collision")
@export_flags_2d_physics var player_collision_layer: int = 2
@export_flags_2d_physics var player_collision_mask: int = 1

var _status_label: Label
var _toast_timer: Timer
var _level_finished: bool = false
var _base_status_text: String


func _ready() -> void:
	CollectedItems.reset()
	_base_status_text = objective_text
	_wire_level()


func _wire_level() -> void:
	_wire_player()
	_wire_exit_door()
	_wire_hud()
	_wire_panels()

	CollectedItems.coins_collected.connect(_on_coins_collected)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	add_child(_toast_timer)
	_toast_timer.timeout.connect(_restore_objective_text)


func _wire_player() -> void:
	if not player:
		return

	player.add_to_group("player")
	player.collision_layer = player_collision_layer
	player.collision_mask = player_collision_mask

	if player_start:
		player.position = player_start.position

	player.died.connect(_on_player_died)
	player.hidden_state_changed.connect(_on_player_hidden_state_changed)

	_configure_camera()


func _wire_exit_door() -> void:
	if not exit_door:
		return

	if exit_position:
		exit_door.position = exit_position.position

	exit_door.required_coins = required_coins
	exit_door.exit_reached.connect(_on_exit_reached)
	exit_door.missing_coins.connect(_on_exit_missing_coins)


func _wire_hud() -> void:
	if not hud:
		return

	_status_label = hud.get_node_or_null("StatusLabel") as Label
	if _status_label:
		_status_label.text = objective_text


func _wire_panels() -> void:
	if game_over_panel:
		game_over_panel.hide()
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _configure_camera() -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if not camera:
		return

	camera.enabled = true
	camera.position_smoothing_enabled = camera_smoothing_enabled
	camera.position_smoothing_speed = camera_smoothing_speed
	camera.zoom = camera_zoom

	if use_camera_limits and camera_limit_rect.size != Vector2.ZERO:
		camera.limit_left = int(camera_limit_rect.position.x)
		camera.limit_top = int(camera_limit_rect.position.y)
		camera.limit_right = int(camera_limit_rect.position.x + camera_limit_rect.size.x)
		camera.limit_bottom = int(camera_limit_rect.position.y + camera_limit_rect.size.y)


func _on_coins_collected() -> void:
	if _status_label and CollectedItems.coins_amount >= required_coins:
		_base_status_text = exit_open_text
		_status_label.text = _base_status_text


func _on_exit_missing_coins(_needed: int) -> void:
	if _status_label:
		_status_label.text = missing_coins_text
	if _toast_timer:
		_toast_timer.start(toast_duration)


func _restore_objective_text() -> void:
	if _status_label:
		_status_label.text = _base_status_text


func _on_player_hidden_state_changed(is_hidden: bool) -> void:
	if not _status_label:
		return
	_status_label.text = hidden_text if is_hidden else _base_status_text


func _on_player_died() -> void:
	get_tree().paused = true
	if game_over_panel:
		game_over_panel.show()


func _on_exit_reached() -> void:
	if _level_finished:
		return
	_level_finished = true

	var has_completion_listener := not level_completed.get_connections().is_empty()
	level_completed.emit(true)
	if has_completion_listener:
		return

	get_tree().paused = true
	if win_panel:
		win_panel.show()


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_to_menu(menu_scene_path: String = "res://Scenes/UI/TitleScreen.tscn") -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene_path)
