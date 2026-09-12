extends Node

@onready var state_chart = %StateChart

func _on_idle_timer_timeout() -> void:
	var boss = get_parent()
	if boss and boss.is_player_detected():
		state_chart.send_event("jump")
		return
	var attacks = ["slash", "jump"]
	attacks.shuffle()
	var attack = attacks[0]
	state_chart.send_event(attack)

func _physics_process(_delta: float) -> void:
	transition()

func transition():
	if get_parent().velocity.y > 0:
		state_chart.send_event("fall")

func _on_slash_slash_complete() -> void:
	state_chart.send_event("idle")

func _on_fall_slam_attack() -> void:
	state_chart.send_event("slam")

func _on_slam_slam_complete() -> void:
	state_chart.send_event("idle")

func _on_fall_lamded() -> void:
	state_chart.send_event("idle")
