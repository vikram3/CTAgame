extends Area2D

var stats: Stats

func _ready() -> void:
	
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("do_damage"):
		apply_damage(area.do_damage())


func apply_damage(damage: int) -> void:
	if not stats:
		push_warning("HurtBox cannot apply damage without a Stats reference.")
		return
	stats._damage_deduction(damage)
