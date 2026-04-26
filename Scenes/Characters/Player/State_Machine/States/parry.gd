# parry.gd  –  attach to State_Transition_Manager/Parry
# Entered when a block was successful. Player can follow up with Counter.
extends Node

@export var impact_effect: AnimatedSprite2D   # assign in inspector

var _sm: Node
func _get_sm() -> Node:
	if _sm == null: _sm = get_parent()
	return _sm

func _on_parry_state_entered() -> void:
	var p = _get_sm().get_parent()    # Player root

	impact_effect.stop()
	impact_effect.play("Counter", 5)   # "Counter" animation in the AnimatedSprite2D

	# Slight push-back on the player
	p.apply_force(Vector2(-p.body.scale.x, 0.0), 10.0)

	Global._freeze(0.1, 0.4)
	if Global.cam:
		Global.cam.screen_shake(10, 0.2)

func _on_parry_state_physics_processing(_delta: float) -> void:
	var p = _get_sm().get_parent()

	# Press Attack during parry window → enter counter
	if Input.is_action_pressed("Attack"):
		p.doing_counter = true
		p.parried       = false
		return

	# Wait until impact animation finishes, then return to normal
	if not impact_effect.is_playing():
		p.can_block = true
		p.parried   = false

func _on_parry_state_exited() -> void:
	var p = _get_sm().get_parent()
	p.can_block                  = true
	_get_sm().check_hit.disabled = true
	_get_sm().hurt_box.disabled  = false
