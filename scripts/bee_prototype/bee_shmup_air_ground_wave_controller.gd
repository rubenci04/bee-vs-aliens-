class_name BeeShmupAirGroundWaveController
extends Node3D

signal wave_completed

@export var probe_scene: PackedScene
@export var eye_scene: PackedScene
@export var speeder_scene: PackedScene
@export var entry_speed := 7.0
@export var entry_screen_x := 10.8
@export var formation_screen_x := 5.0

@onready var stage: BeeShmupStage = get_parent() as BeeShmupStage
@onready var bee: BeePlayer = stage.get_node("BeePlayer")
@onready var camera: Camera3D = stage.get_node("ShmupCamera")
@onready var turrets: Array[GroundTurretEnemy] = [
	stage.get_node("Turrets/TurretA"), stage.get_node("Turrets/TurretB"),
	stage.get_node("Turrets/TurretC"), stage.get_node("Turrets/TurretD")]

const THRESHOLDS := [6.0, 24.0, 43.0, 62.0, 80.0]

var wave_index := 0
var spawned_count := 0
var defeated_count := 0
var resolved_count := 0
var max_active_seen := 0
var _wave_resolved := 0
var _wave_done := true
var _complete := false
var _paused := false
var _pending_scene: PackedScene
var _pending_turret: GroundTurretEnemy
var _pending_height := 0.0
var _pending_delay := 0.0
var _living: Array[Node3D] = []
var _entrants: Array[Node3D] = []
var _resolved: Dictionary = {}

func _ready() -> void:
	for turret: GroundTurretEnemy in turrets:
		turret.defeated.connect(_on_enemy_defeated)

func _physics_process(delta: float) -> void:
	if _paused or _complete or bee.is_defeated:
		return
	for turret: GroundTurretEnemy in turrets:
		if turret.is_active() and turret.global_position.x < camera.global_position.x + stage.screen_left - 1.0:
			turret.deactivate()
			_resolve(turret, false)
	if _wave_done and wave_index < 5 and stage.distance >= THRESHOLDS[wave_index]:
		_start_wave(wave_index + 1)
	if _pending_scene != null or _pending_turret != null:
		_pending_delay -= delta
		if _pending_delay <= 0.0:
			if _pending_scene != null:
				_spawn(_pending_scene, _pending_height)
				_pending_scene = null
			else:
				_activate_turret(_pending_turret)
				_pending_turret = null
	for unit: Node3D in _entrants.duplicate():
		unit.global_position.x = move_toward(unit.global_position.x, camera.global_position.x + formation_screen_x, entry_speed * delta)
		if unit.global_position.x <= camera.global_position.x + formation_screen_x + 0.01:
			_entrants.erase(unit)
			unit.call("activate", bee)
	max_active_seen = maxi(max_active_seen, active_count())

func _start_wave(number: int) -> void:
	wave_index = number
	_wave_resolved = 0
	_wave_done = false
	match number:
		1:
			_spawn(probe_scene, 4.7)
			_schedule_turret(turrets[0], 1.4)
		2:
			_spawn(eye_scene, 5.1)
			_schedule_turret(turrets[1], 1.8)
		3:
			_spawn(speeder_scene, 4.4)
			_schedule_turret(turrets[2], 2.3)
		4:
			_spawn(eye_scene, 3.1)
			_schedule_air(speeder_scene, 5.5, 1.7)
		5:
			_activate_turret(turrets[3])
			_schedule_air(probe_scene, 5.5, 1.5)

func _schedule_air(scene: PackedScene, height: float, delay: float) -> void:
	_pending_scene = scene
	_pending_height = height
	_pending_delay = delay

func _schedule_turret(turret: GroundTurretEnemy, delay: float) -> void:
	_pending_turret = turret
	_pending_delay = delay

func _activate_turret(turret: GroundTurretEnemy) -> void:
	assert(_living.size() < 2)
	_living.append(turret)
	spawned_count += 1
	if turret.global_position.x < camera.global_position.x + stage.screen_left - 1.0:
		_resolve(turret, false)
	else:
		turret.activate(bee)

func _spawn(scene: PackedScene, height: float) -> void:
	assert(_living.size() < 2)
	var unit := scene.instantiate() as Node3D
	var base_name := "Wave%dAir" % wave_index
	unit.name = base_name + "2" if has_node(base_name) else base_name
	add_child(unit)
	unit.global_position = Vector3(camera.global_position.x + entry_screen_x, height, 0.0)
	unit.show()
	unit.connect("defeated", Callable(self, "_on_enemy_defeated"))
	_living.append(unit)
	_entrants.append(unit)
	spawned_count += 1

func _on_enemy_defeated(unit: Node3D) -> void:
	_resolve(unit, true)

func _resolve(unit: Node3D, destroyed: bool) -> void:
	if _resolved.has(unit.get_instance_id()):
		return
	_resolved[unit.get_instance_id()] = true
	_living.erase(unit)
	_entrants.erase(unit)
	resolved_count += 1
	_wave_resolved += 1
	if destroyed:
		defeated_count += 1
	if _wave_resolved == 2:
		_wave_done = true
		if wave_index == 5 and not _complete:
			_complete = true
			wave_completed.emit()

func active_count() -> int:
	return _living.size()

func is_complete() -> bool:
	return _complete

func freeze_enemies() -> void:
	_paused = true
	for unit: Node3D in _living:
		unit.set_physics_process(false)
