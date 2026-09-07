extends Node
class_name EnemySpawner

signal enemy_spawned(enemy: Node)

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Marker2D] = []
@export var spawn_parent: Node

var _spawn_index: int = 0


func spawn_enemy() -> Node:
	if enemy_scene == null or spawn_points.is_empty():
		return null
	var enemy := enemy_scene.instantiate()
	var parent := spawn_parent if spawn_parent else get_parent()
	parent.add_child(enemy)
	var spawn_point := spawn_points[_spawn_index % spawn_points.size()]
	_spawn_index += 1
	if enemy is Node2D:
		(enemy as Node2D).global_position = spawn_point.global_position
	enemy_spawned.emit(enemy)
	return enemy
