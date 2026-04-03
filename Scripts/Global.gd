extends Node

var player:CharacterBody2D
var boss:CharacterBody2D
var cam:Camera2D

func _freeze(timeScale,duration):
	Engine.time_scale = timeScale
	await get_tree().create_timer(duration * timeScale).timeout
	Engine.time_scale = 1.0
