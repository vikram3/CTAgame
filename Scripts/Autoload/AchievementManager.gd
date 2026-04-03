# AchievementManager.gd - Autoload
extends Node

const ACHIEVEMENTS = {
	"first_read": {
		"title": "First Page!",
		"desc": "Read your first panel",
		"icon": "📖"
	},
	"first_game": {
		"title": "Game On!",
		"desc": "Played first game segment",
		"icon": "🎮"
	},
	"coin_10": {
		"title": "Coin Collector",
		"desc": "Collected 10 coins",
		"icon": "🪙"
	},
	"coin_100": {
		"title": "Troll Treasury",
		"desc": "Collected 100 coins",
		"icon": "💰"
	},
	"chapter_1": {
		"title": "Chapter 1 Clear!",
		"desc": "Completed Chapter 1",
		"icon": "⭐"
	},
	"speedrun": {
		"title": "Speed Troll",
		"desc": "Completed level under 60s",
		"icon": "⚡"
	},
	"no_exit": {
		"title": "True Reader",
		"desc": "Finished game without skipping",
		"icon": "👑"
	}
}

# Queue system so popups don't overlap
var popup_queue: Array = []
var is_showing: bool = false

func check_and_unlock(id: String):
	if not ACHIEVEMENTS.has(id):
		push_warning("Unknown achievement: " + id)
		return
	
	if GameData.unlock_achievement(id):
		# Newly unlocked - add to queue
		popup_queue.append(id)
		if not is_showing:
			show_next_popup()

func show_next_popup():
	if popup_queue.is_empty():
		is_showing = false
		return
	
	is_showing = true
	var id = popup_queue.pop_front()
	var ach = ACHIEVEMENTS[id]
	
	var popup = preload("res://Scenes/UI/achievement_popup.tscn").instantiate()
	get_tree().root.add_child(popup)
	popup.show_achievement(ach.icon, ach.title, ach.desc)
	
	# Wait for popup to finish then show next
	await get_tree().create_timer(3.8).timeout
	show_next_popup()

# Call this when coins change to check coin achievements
func check_coin_achievements():
	var coins = GameData.data.coins
	if coins >= 10:
		check_and_unlock("coin_10")
	if coins >= 100:
		check_and_unlock("coin_100")

# Call this when level completed without pressing exit button
func check_speedrun(time_taken: float):
	if time_taken < 60.0:
		check_and_unlock("speedrun")
