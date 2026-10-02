class_name BeeShmupGroundWaveController
extends Node3D

signal wave_completed

@onready var stage: BeeShmupStage = get_parent() as BeeShmupStage
@onready var bee: BeePlayer = stage.get_node("BeePlayer")
@onready var turret_a: GroundTurretEnemy = stage.get_node("Turrets/TurretA")
@onready var turret_b: GroundTurretEnemy = stage.get_node("Turrets/TurretB")
@onready var turret_c: GroundTurretEnemy = stage.get_node("Turrets/TurretC")
@onready var turret_d: GroundTurretEnemy = stage.get_node("Turrets/TurretD")

var wave_index := 0
var max_active_seen := 0
var defeated_count := 0
var resolved_count := 0
var _resolved: Dictionary = {}
var _complete := false
var _paused := false

func _ready() -> void:
	for turret: GroundTurretEnemy in [turret_a,turret_b,turret_c,turret_d]:
		turret.defeated.connect(_on_turret_defeated)

func _physics_process(_delta: float) -> void:
	if _paused or _complete or bee.is_defeated:
		return
	for turret: GroundTurretEnemy in [turret_a,turret_b,turret_c,turret_d]:
		if turret.is_active() and turret.global_position.x < stage.camera.global_position.x + stage.screen_left - 1.0:
			turret.deactivate()
			_mark_resolved(turret,false)
	if wave_index == 0 and stage.distance >= 5.5:
		wave_index = 1
		turret_a.activate(bee)
	elif wave_index == 1 and _is_resolved(turret_a) and stage.distance >= 22.0:
		wave_index = 2
		turret_b.activate(bee)
	elif wave_index == 2 and _is_resolved(turret_b) and stage.distance >= 39.0:
		wave_index = 3
		turret_c.activate(bee)
	if wave_index == 3 and not turret_d.is_active() and not _is_resolved(turret_d) and stage.distance >= 46.0:
		turret_d.activate(bee)
	max_active_seen = maxi(max_active_seen,active_count())

func _on_turret_defeated(turret: GroundTurretEnemy) -> void:
	_mark_resolved(turret,true)

func _is_resolved(turret: GroundTurretEnemy) -> bool:
	return _resolved.has(turret.get_instance_id())

func _mark_resolved(turret: GroundTurretEnemy, destroyed: bool) -> void:
	if _is_resolved(turret):
		return
	_resolved[turret.get_instance_id()] = true
	resolved_count += 1
	if destroyed:
		defeated_count += 1
	if resolved_count == 4 and not _complete:
		_complete = true
		wave_completed.emit()
func active_count() -> int:
	var total := 0
	for turret: GroundTurretEnemy in [turret_a,turret_b,turret_c,turret_d]:
		if turret.is_active(): total += 1
	return total

func is_complete() -> bool:
	return _complete

func freeze_enemies() -> void:
	_paused = true
	for turret: GroundTurretEnemy in [turret_a,turret_b,turret_c,turret_d]:
		turret.set_physics_process(false)

