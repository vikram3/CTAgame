@tool
extends StaticBody2D
## Reusable "hideable prop" — a static obstacle with an attached hide zone.
##
## Build a scene from this script (StaticBody2D root) with the following
## children added once in the editor:
##   - Sprite2D       (assign texture + region_rect per-instance)
##   - CollisionShape2D (RectangleShape2D, sized to the prop)
##   - HideZone (Area2D) -> CollisionShape2D (RectangleShape2D)
##
## Then save it as Prop.tscn and instance it wherever you need a hiding
## spot. Every value below is editable per-instance in the Inspector.
##
## Requires the player to be in group "player" (already done in Player.gd)
## and to have a method set_hidden_state(bool) (already exists in Player.gd).
@export_group("Sprite")
@export var sprite_texture: Texture2D:
	set(value):
		sprite_texture = value
		_apply_sprite_settings()
@export var region_rect: Rect2:
	set(value):
		region_rect = value
		_apply_sprite_settings()
@export var sprite_scale: float = 1.0:
	set(value):
		sprite_scale = value
		_apply_sprite_settings()
@export var sprite_offset: Vector2 = Vector2(0, 28):
	set(value):
		sprite_offset = value
		_apply_sprite_settings()
@export_group("Collision")
@export_flags_2d_physics var hide_zone_detect_mask: int = 2  # must match Player's collision_layer
@export var collision_size: Vector2 = Vector2(90, 90):
	set(value):
		collision_size = value
		_apply_collision_settings()
@export var hide_zone_size: Vector2 = Vector2(150, 128):
	set(value):
		hide_zone_size = value
		_apply_collision_settings()
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _hide_zone: Area2D = $HideZone
@onready var _hide_collision: CollisionShape2D = $HideZone/CollisionShape2D
func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_sprite_settings()
		_apply_collision_settings()
		return
	collision_layer = 1
	collision_mask = 0
	# HideZone must match whatever layer the Player actually ends up on.
	# LevelController sets player.collision_layer = player_collision_layer
	# (default 2), so this needs to match that — not be hardcoded to layer 1.
	_hide_zone.collision_layer = 0
	_hide_zone.collision_mask = hide_zone_detect_mask
	_apply_sprite_settings()
	_apply_collision_settings()
	_hide_zone.body_entered.connect(_on_hide_zone_body_entered)
	_hide_zone.body_exited.connect(_on_hide_zone_body_exited)
func _apply_sprite_settings() -> void:
	if not is_inside_tree() or not _sprite:
		return
	_sprite.texture = sprite_texture
	if sprite_texture and region_rect.size == Vector2.ZERO:
		# No region configured yet — default to the whole texture instead of
		# rendering an empty 0x0 region.
		_sprite.region_enabled = false
	else:
		_sprite.region_enabled = true
		_sprite.region_rect = region_rect
	_sprite.scale = Vector2.ONE * sprite_scale
	_sprite.position = sprite_offset
func _apply_collision_settings() -> void:
	if not is_inside_tree() or not _collision or not _hide_collision:
		return
	var box := RectangleShape2D.new()
	box.size = collision_size
	_collision.shape = box
	var hide_box := RectangleShape2D.new()
	hide_box.size = hide_zone_size
	_hide_collision.shape = hide_box
func _on_hide_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("set_hidden_state"):
		body.set_hidden_state(true)
func _on_hide_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("set_hidden_state"):
		body.set_hidden_state(false)
