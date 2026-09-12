extends Node
class_name Attacks

enum type {
	TAP,
	HOLD
}

@export var fire_combo:type = type.TAP

@export var attack_cooldown_timer:Timer
@export var anim_speed:float = 1.2
@export var max_combo_count: int = 3
@export var attack_recovery_time: float = 0.08
@export var allow_combo_loop := false

var next_attack:bool = false
var current_combo: int = 0

func _combo_attack_window():
	next_attack = true

func _enter_combo(combo_index: int, attack_name: String) -> void:
	current_combo = combo_index
	_attack_name(attack_name)

func _attack_name(NAME:String):
	if attack_cooldown_timer.is_stopped():
		next_attack = false
		get_parent().anim.play(NAME,-1,anim_speed)
		attack_cooldown_timer.start(_attack_duration(NAME))

func _attack_duration(attack_name: String) -> float:
	var animation: Animation = get_parent().anim.get_animation(attack_name)
	if animation == null:
		return attack_cooldown_timer.wait_time
	
	var speed: float = maxf(absf(anim_speed), 0.01)
	return maxf(animation.length / speed + attack_recovery_time, 0.05)

func _next_attack():
	if !next_attack:
		return
	
	if current_combo >= max_combo_count and !allow_combo_loop:
		_clear_final_combo_input()
		return
	
	if _wants_next_attack():
		get_parent().state_chart.send_event("next")

func _clear_final_combo_input() -> void:
	var player = get_parent().parent
	if player.has_attack_buffer() or Input.is_action_pressed("Attack"):
		player.clear_attack_buffer()

func _wants_next_attack() -> bool:
	var player = get_parent().parent
	
	if fire_combo == type.HOLD and Input.is_action_pressed("Attack"):
		player.clear_attack_buffer()
		return true
	
	return player.consume_attack_buffer()

func _end_of_attack():
	if current_combo >= max_combo_count and !allow_combo_loop:
		get_parent().parent.clear_attack_buffer()
	
	next_attack = false
	current_combo = 0
	attack_cooldown_timer.stop()

func _on_combo_state_physics_processing(delta):
	_next_attack()
	get_parent().parent.velocity = Vector2.ZERO

func _on_combo_state_exited():
	_end_of_attack()

func _on_attack_cool_down_timer_timeout():
	get_parent().parent.can_attack = true
	get_parent().parent.can_ground_dash = true
	get_parent().parent.can_air_dash = true

func _on_air_attack_cool_down_timer_timeout():
	_on_attack_cool_down_timer_timeout()
	
