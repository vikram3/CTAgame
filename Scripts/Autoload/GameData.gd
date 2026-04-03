extends Node

const SAVE_PATH = "user://save_data.json"

var data = {
	"coins": 10000,
	"current_chapter": 1,
	"unlocked_chapters": [1,2,3,4],
	"chapter_progress": {},     # chapter_num -> scroll position
	"chapter_games_completed": {},  # "chapter_num" -> [0, 1, 2] list of completed game indexes
	"chapters_fully_completed": [], # list of fully completed chapter nums
	"achievements": {},
	"settings": {
		"music_volume": 1.0,
		"sfx_volume": 1.0,
	}
}

func _ready():
	load_data()

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		save_data()
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed:
		data.merge(parsed, true)

# --- Coins ---
func add_coins(amount: int):
	data.coins += amount
	save_data()
	
func spend_coins(amount: int) -> bool:
	if data.coins >= amount:
		data.coins -= amount
		save_data()
		return true
	return false

# --- Chapters ---
func unlock_chapter(num: int):
	if num not in data.unlocked_chapters:
		data.unlocked_chapters.append(num)
		save_data()

func is_chapter_unlocked(num: int) -> bool:
	return num in data.unlocked_chapters

func is_chapter_fully_completed(num: int) -> bool:
	return num in data.chapters_fully_completed

# --- Scroll Progress ---
func save_chapter_progress(chapter: int, scroll_pos: float):
	data.chapter_progress[str(chapter)] = scroll_pos
	save_data()

func get_chapter_progress(chapter: int) -> float:
	return float(data.chapter_progress.get(str(chapter), 0))
	
# --- Game Segments Tracking ---
func mark_game_completed(chapter: int, game_index: int):
	var key = str(chapter)
	if not data.chapter_games_completed.has(key):
		data.chapter_games_completed[key] = []
	if game_index not in data.chapter_games_completed[key]:
		data.chapter_games_completed[key].append(game_index)
	save_data()

func is_game_completed(chapter: int, game_index: int) -> bool:
	var key = str(chapter)
	if not data.chapter_games_completed.has(key):
		return false
	return game_index in data.chapter_games_completed[key]

func get_completed_games_count(chapter: int) -> int:
	var key = str(chapter)
	if not data.chapter_games_completed.has(key):
		return 0
	return data.chapter_games_completed[key].size()

func check_chapter_complete(chapter: int, total_games: int):
	var completed = get_completed_games_count(chapter)
	if completed >= total_games:
		if chapter not in data.chapters_fully_completed:
			data.chapters_fully_completed.append(chapter)
			unlock_chapter(chapter + 1)
			save_data()
			return true  # newly completed
	return false

# --- Achievements ---
func unlock_achievement(id: String) -> bool:
	if not data.achievements.get(id, false):
		data.achievements[id] = true
		save_data()
		return true
	return false

func has_achievement(id: String) -> bool:
	return data.achievements.get(id, false)
