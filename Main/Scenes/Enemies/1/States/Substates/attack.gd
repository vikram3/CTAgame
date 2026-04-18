extends Node

var attack_cooldown = 0.0
const ATTACK_RATE = 1.0

func _on_attack_state_entered() -> void:
	var enemy = get_parent().parent
	enemy.current_state = "attack"  # ADD THIS
	enemy.velocity.x = 0
	attack_cooldown = ATTACK_RATE
	enemy.update_facing(enemy.get_direction().x)
	

func _on_attack_state_physics_processing(delta: float) -> void:
	var enemy = get_parent().parent
	#print("ATTACK PROCESSING | cooldown: ", attack_cooldown, " | current_state: ", enemy.current_state, " | anim: ", enemy.animation_player.current_animation)
	enemy.velocity.x = 0
	#print("current anim: ", enemy.animation_player.current_animation, " | is_playing: ", enemy.animation_player.is_playing(), " | cooldown: ", attack_cooldown)

	if enemy.animation_player.is_playing() and enemy.animation_player.current_animation == "attack":
		return

	attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		enemy.update_facing(enemy.get_direction().x)
		enemy.animation_player.play("attack")
		print("PLAYING ATTACK ANIMATION")
		attack_cooldown = ATTACK_RATE


func _on_attack_state_exited() -> void:
	var enemy = get_parent().parent
	enemy.current_state = "patrol"
