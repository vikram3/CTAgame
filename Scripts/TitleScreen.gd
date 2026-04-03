extends Control

@onready var coin_label = $CanvasLayer/ButtonsPanel/CoinDisplay/HBoxContainer2/CoinLabel
@onready var continue_btn = $CanvasLayer/ButtonsPanel/HBoxContainer/ContinueButton
@onready var anim_player = $AnimationPlayer

func _ready():
	# Update coin display
	coin_label.text = str(GameData.data.coins)
	
	# Show continue only if progress exists
	var has_progress = not GameData.data.chapter_progress.is_empty()
	continue_btn.visible = has_progress
	
	# Comic style title animation
	anim_player.play("title_entrance")
	
	# Connect buttons
	$CanvasLayer/ButtonsPanel/HBoxContainer/StartButton.pressed.connect(_on_start)
	$CanvasLayer/ButtonsPanel/HBoxContainer/ContinueButton.pressed.connect(_on_continue)
	$CanvasLayer/ButtonsPanel/HBoxContainer/ChaptersButton.pressed.connect(_on_chapters)
	$CanvasLayer/ButtonsPanel/HBoxContainer2/SettingsButton.pressed.connect(_on_settings)

func _on_start():
	GameData.data.chapter_progress.clear()  # fresh start
	SceneManager.go_to_chapter(1)

func _on_continue():
	SceneManager.go_to_chapter(GameData.data.current_chapter)

func _on_chapters():
	SceneManager.go_to_chapter_select()

func _on_settings():
	SceneManager.go_to_settings()
