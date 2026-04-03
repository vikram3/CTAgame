extends Node2D

signal tutorial_started
signal tutorial_complete

@export var action_name: String
@export var action_count:int
@export var completion_count:int

@export var one_shot_input:bool = false

@export var label:Label

var active:bool = false

func _physics_process(delta: float) -> void:
	print(active)
	if action_count >= completion_count:
		emit_signal("tutorial_complete")
		active = false
		queue_free()
		return
	else:
		var input = Input.is_action_just_pressed(action_name) if one_shot_input else Input.is_action_pressed(action_name)
		if input:
			action_count += 1
	
	label.visible = active
	ui_update()

func _on_tutorial_trigger_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		active = true
		emit_signal("tutorial_started")

func ui_update():
	label.text = "presses " + "[" + action_name + "] "
