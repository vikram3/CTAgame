extends Area2D

var damage: int

@export var main_body: Node2D


func do_damage() -> int:
	if main_body != null:
		damage = main_body.stats._damage_given()
		return damage
	else:
		damage = 10
		return damage
