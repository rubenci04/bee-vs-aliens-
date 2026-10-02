class_name BeeShmupWorldScaleController
extends Node3D

signal wave_completed

@onready var stage: BeeShmupStage = get_parent() as BeeShmupStage
@onready var hazard: GiantHumanCrossingHazard = stage.get_node("GiantHuman")

var _complete := false
var _paused := false

func _physics_process(_delta: float) -> void:
	if _paused or _complete or stage.bee.is_defeated:
		return
	if hazard.crossings_started == 0 and stage.distance >= 18.0:
		hazard.begin_crossing(stage.camera)
	elif hazard.crossings_started == 1 and hazard.crossings_exited == 1 and stage.distance >= 43.0:
		hazard.begin_crossing(stage.camera)
	if hazard.crossings_exited == 2 and not _complete:
		_complete = true
		wave_completed.emit()

func is_complete() -> bool:
	return _complete

func freeze_enemies() -> void:
	_paused = true
	hazard.freeze()
