extends Area2D

var damage: int

@export var main_body: Node2D

func do_damage() -> int:
	damage = main_body.stats._damage_given()
	return damage
