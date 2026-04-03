extends Node2D

@onready var chapter_grid = $CanvasLayer/ScrollContainer/ChapterGrid
@onready var coin_label = $CanvasLayer/CoinDisplay/coin_label

# Define all chapters
const CHAPTERS = [
	{"num": 1, "title": "The Troll Awakens", "coins_to_unlock": 0},
	{"num": 2, "title": "The Coin Cave",      "coins_to_unlock": 50},
	{"num": 3, "title": "Bridge of Doom",     "coins_to_unlock": 100},
	{"num": 4, "title": "The Final Troll",    "coins_to_unlock": 200},
]

func _ready():
	coin_label.text = str(GameData.data.coins) + " 🪙"
	$CanvasLayer/TopBar/BackButton.pressed.connect(SceneManager.go_to_title)
	$CanvasLayer/TopBar2/BackButton.pressed.connect(SceneManager.go_to_title)
	build_chapter_grid()

func build_chapter_grid():
	for ch in CHAPTERS:
		var card = create_chapter_card(ch)
		chapter_grid.add_child(card)

func create_chapter_card(ch: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 150)
	
	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	
	# Chapter number - comic style
	var num_label = Label.new()
	num_label.text = "CH. " + str(ch.num)
	num_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(num_label)
	
	# Chapter title
	var title_label = Label.new()
	title_label.text = ch.title
	vbox.add_child(title_label)
	
	var is_unlocked = GameData.is_chapter_unlocked(ch.num)
	var has_progress = GameData.get_chapter_progress(ch.num) > 0
	
	if is_unlocked:
		# Play button
		var play_btn = Button.new()
		play_btn.text = "▶ READ" if not has_progress else "↩ CONTINUE"
		play_btn.pressed.connect(SceneManager.go_to_chapter.bind(ch.num))
		vbox.add_child(play_btn)
		
		# Progress indicator
		if has_progress:
			var progress = Label.new()
			progress.text = "📖 In Progress"
			vbox.add_child(progress)
	else:
		# Locked - show coin cost
		var lock_label = Label.new()
		lock_label.text = "🔒 " + str(ch.coins_to_unlock) + " coins"
		vbox.add_child(lock_label)
		
		var unlock_btn = Button.new()
		unlock_btn.text = "UNLOCK"
		unlock_btn.pressed.connect(_on_unlock_chapter.bind(ch))
		vbox.add_child(unlock_btn)
	
	return card

func _on_unlock_chapter(ch: Dictionary):
	if GameData.spend_coins(ch.coins_to_unlock):
		GameData.unlock_chapter(ch.num)
		# Refresh grid
		for child in chapter_grid.get_children():
			child.queue_free()
		build_chapter_grid()
	else:
		# Not enough coins - flash message
		print("Not enough coins!")
