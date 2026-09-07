extends Node
class_name ObjectiveController

signal all_completed
signal objective_failed(objective: ObjectiveBase)
signal objective_progress_changed(objective: ObjectiveBase, current: float, target: float)

@export var objectives: Array[ObjectiveBase] = []
@export var start_on_ready: bool = false

var _completed_objectives: Dictionary = {}
var _is_finished: bool = false
var _is_started: bool = false


func _ready() -> void:
	if start_on_ready:
		start()


func start() -> void:
	if _is_started:
		return
	_is_started = true
	if objectives.is_empty():
		for child in get_children():
			if child is ObjectiveBase:
				objectives.append(child)
	for objective in objectives:
		if objective == null:
			continue
		objective.completed.connect(_on_objective_completed)
		objective.failed.connect(_on_objective_failed)
		objective.progress_changed.connect(_on_objective_progress_changed)
		objective.activate()


func _on_objective_completed(objective: ObjectiveBase) -> void:
	if _is_finished:
		return
	_completed_objectives[objective] = true
	if not objectives.is_empty() and _completed_objectives.size() >= objectives.size():
		_is_finished = true
		all_completed.emit()


func _on_objective_failed(objective: ObjectiveBase) -> void:
	if _is_finished:
		return
	_is_finished = true
	objective_failed.emit(objective)


func _on_objective_progress_changed(objective: ObjectiveBase, current: float, target: float) -> void:
	objective_progress_changed.emit(objective, current, target)
