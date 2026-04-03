extends PanelContainer

signal play_pressed

@onready var description_label = $VBoxContainer/Description
@onready var play_button = $VBoxContainer/PlayButton
@onready var anim_player = $AnimationPlayer

var is_completed: bool = false

func _ready():
	play_button.pressed.connect(func(): play_pressed.emit())
	anim_player.play("pulse")

func setup(text: String):
	description_label.text = text
	custom_minimum_size = Vector2(800, 300)

func set_play_again_mode():
	is_completed = true
	play_button.text = "🔄 Play Again"
	
	# Optional: change panel style to show completed
	description_label.text = "✅ Completed! " + description_label.text
	
	# Stop pulse animation, play completed animation if you have one
	if anim_player.has_animation("completed"):
		anim_player.play("completed")
	else:
		anim_player.stop()
