extends Node2D

signal level_completed(success: bool)

@onready var exit_zone = $ExitZone
var is_exiting: bool = false  # ← guard

func _ready():
	var exit_btn = $CanvasLayer/ExitButton
	exit_btn.text = "✕  Back to Story"
	exit_btn.custom_minimum_size = Vector2(160, 50)
	exit_btn.modulate = Color(1, 1, 1, 0.7)
	exit_btn.pressed.connect(_on_exit_pressed)

func _process(delta):
	if is_exiting:
		return  # ← stop checking once triggered
	
	var player = get_node_or_null("Player")
	if player and exit_zone:
		var shape = exit_zone.get_node_or_null("CollisionShape2D")
		if shape:
			var zone_rect = Rect2(
				exit_zone.global_position - shape.shape.size / 2,
				shape.shape.size
			)
			if zone_rect.has_point(player.global_position):
				_on_exit_pressed()

func _on_exit_pressed():
	if is_exiting:
		return
	is_exiting = true
	print("EMITTING!")
	level_completed.emit(true)

func _on_game_over():
	level_completed.emit(false)
