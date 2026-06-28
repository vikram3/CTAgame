extends Node2D

@export var player: Player
@export var exit_door: ExitDoor
@export var hud: Control
@export var game_over_panel: Control
@export var win_panel: Control

const COIN_WIN_TARGET := 20
const TRIGGER_TEXT := "Time to grab those coins before anyone notices..."


func _ready() -> void:
	CollectedItems.reset()
	_wire_level()


func _wire_level() -> void:
	if player:
		player.add_to_group("player")
		player.collision_layer = 2
		player.collision_mask = 1
		player.died.connect(_on_player_died)

	if exit_door:
		exit_door.required_coins = 0
		exit_door.exit_reached.connect(_on_exit_reached)

	if hud:
		var status_label := hud.get_node_or_null("StatusLabel") as Label
		if status_label:
			status_label.text = TRIGGER_TEXT

	CollectedItems.coins_collected.connect(_on_coins_collected)

	if game_over_panel:
		game_over_panel.hide()
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_coins_collected() -> void:
	if CollectedItems.coins_amount >= COIN_WIN_TARGET:
		_on_exit_reached()


func _on_player_died() -> void:
	get_tree().paused = true
	if game_over_panel:
		game_over_panel.show()


func _on_exit_reached() -> void:
	get_tree().paused = true
	if win_panel:
		win_panel.show()


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_to_menu(menu_scene_path: String = "res://Scenes/UI/TitleScreen.tscn") -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene_path)
