class_name ChapterData
extends Node

enum PanelType { STATIC, PLAYABLE }


const PANEL_WIDTH = 720.0

# ── CHAPTER PAGE COUNTS ─────────────────────────────────────
const CHAPTER_PAGE_COUNTS = {
	1:  19,
	2:  34,
	3:  22,
	4:  18,
	5:  24,
	6:  26,
	7:  18,
	8:  26,
}

class PanelEntry:
	var type: PanelType
	var image_path: String
	var playable_scene: String
	var transition_text: String
	var game_index: int

	func _init(t, img="", scene="", text="", idx=0):
		type            = t
		image_path      = img
		playable_scene  = scene
		transition_text = text
		game_index      = idx

# ── MAIN ENTRY POINT ────────────────────────────────────────
static func get_chapter(num: int) -> Array:
	var panels: Array = []

	if not CHAPTER_PAGE_COUNTS.has(num):
		push_error("Chapter " + str(num) + " page count not set!")
		return panels

	var page_count    = CHAPTER_PAGE_COUNTS[num]
	var playable_defs = ChapterData.get_playable_definitions(num)
	var scene         = "res://Scenes/Environments/Proto_Levels/proto_level.tscn"

	for page in range(1, page_count + 1):
		for pd in playable_defs:
			if pd.before_page == page:
				panels.append(PanelEntry.new(
					PanelType.PLAYABLE, "", scene, pd.text, pd.game_index
				))
		var path = ChapterData.get_page_path(num, page)
		panels.append(PanelEntry.new(PanelType.STATIC, path))

	for pd in playable_defs:
		if pd.before_page > page_count:
			panels.append(PanelEntry.new(
				PanelType.PLAYABLE, "", scene, pd.text, pd.game_index
			))

	return panels

# ── PATH FORMAT PER CHAPTER ─────────────────────────────────
static func get_page_path(chapter: int, page: int) -> String:
	var page_str = str(page).pad_zeros(2)
	var base = ""
	match chapter:
		1: base = "res://Assets/webtoon/Ch1/ch1_" + page_str
		2: base = "res://Assets/webtoon/Ch2/Ch2_" + page_str
		3: base = "res://Assets/webtoon/Ch3/Ch3_" + page_str
		4: base = "res://Assets/webtoon/Ch4/Ch4_" + page_str
		5: base = "res://Assets/webtoon/Ch5/Ch5_" + page_str
		6: base = "res://Assets/webtoon/Ch6/Ch6_" + page_str
		7: base = "res://Assets/webtoon/Ch7/Ch7_" + page_str
		8: base = "res://Assets/webtoon/Ch8/Ch8_" + page_str
		_: return ""

	if ResourceLoader.exists(base + ".jpg"):
		return base + ".jpg"
	elif ResourceLoader.exists(base + ".png"):
		return base + ".png"
	else:
		push_error("Image not found: " + base + ".jpg or .png")
		return base + ".jpg"

static func get_total_games(chapter: int) -> int:
	return get_playable_definitions(chapter).size()

static func get_total_chapters() -> int:
	return CHAPTER_PAGE_COUNTS.size()

# ── GAME SEGMENTS PER CHAPTER ────────────────────────────────
static func get_playable_definitions(chapter: int) -> Array:
	match chapter:
		1: return [
			{"before_page": 3,  "text": "Look for coins!",         "game_index": 0},
			{"before_page": 18, "text": "The Troll faces danger!", "game_index": 1},
		]
		2: return [
			{"before_page": 8,  "text": "Into the cave!",   "game_index": 0},
			{"before_page": 20, "text": "Boss fight!",      "game_index": 1},
			{"before_page": 30, "text": "Final escape!",    "game_index": 2},
		]
		3: return [
			{"before_page": 10, "text": "Chapter 3 battle!", "game_index": 0},
		]
		_: return []
