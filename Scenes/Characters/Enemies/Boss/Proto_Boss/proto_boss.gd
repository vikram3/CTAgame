extends CharacterBody2D

@export var gravity:float = 490.0
@export var hurt:AnimationPlayer
@export var stats:Stats

@export var decision_locked: bool = true

func _ready() -> void:
	Global.boss = self
	$CanvasLayer/HealthBar._init_health(stats.stats.max_health)

func _physics_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += gravity * delta

func _active():
	$CanvasLayer/health_bar.play("anim")

func _on_stats_energy_updated(energy: Variant) -> void:
	pass

func _on_stats_health_updated(health: Variant) -> void:
	hurt.play("anim")
	$CanvasLayer/HealthBar._set_health(health)
