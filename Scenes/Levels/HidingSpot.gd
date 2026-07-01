extends Area2D
class_name HidingSpot

## The prop's visual node (its Sprite2D/Node2D root) — the player's z_index gets
## set just below this so they visually disappear behind it, not just tint green.
@export var occluder: Node2D

## Optional exact spot the player dashes to when first entering hiding — usually a
## Marker2D placed slightly behind the prop's visual center. If left empty, this
## Area2D's own position is used.
@export var hide_marker: Marker2D

var _player: Player = null


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_hide_position() -> Vector2:
	return hide_marker.global_position if hide_marker else global_position


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body as Player
	_player.hide_at(self)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player") or body != _player:
		return
	# Player is free to walk around while hidden, so this fires the normal way
	# they become visible again — no button, no hold, just walking out of cover.
	_player.unhide_from(self)
	_player = null
