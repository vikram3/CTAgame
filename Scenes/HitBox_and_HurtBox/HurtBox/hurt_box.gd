extends Area2D

func _ready() -> void:
	area_entered.connect(_on_hurtbox_area_entered)  # connect to self, not $HurtBox

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		var damage = area.do_damage()  # use HitBox's own do_damage()
		get_parent().take_damage(damage)  # call take_damage on enemy root
