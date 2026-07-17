extends Node

func go_to_title():
	get_tree().change_scene_to_file("res://Scenes/UI/TitleScreen.tscn")

func go_to_chapter_select():
	get_tree().change_scene_to_file("res://Scenes/UI/chapter_select.tscn")

func go_to_chapter(num: int):
	GameData.data.current_chapter = num
	GameData.save_data()
	get_tree().change_scene_to_file("res://Scenes/UI/WebtoonReader.tscn")

func go_to_settings():
	get_tree().change_scene_to_file("res://Scenes/UI/settings_screen.tscn")
