class_name BeeShmupAirWaveController
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

var wave_index := 0
var spawned_count := 0
var defeated_count := 0
var max_active_seen := 0
var _wave_defeated := 0
var _wave_expected := 0
var _wave_done := true
var _complete := false
var _paused := false
var _pending_scene: PackedScene
var _pending_height := 0.0
var _pending_delay := 0.0
var _living: Array[Node3D] = []
var _entrants: Array[Node3D] = []

func _physics_process(delta: float) -> void:
	if _paused or _complete:
		return
	var thresholds := [6.0,20.0,38.0,55.0]
	if _wave_done and wave_index < 4 and stage.distance >= thresholds[wave_index]:
		_start_wave(wave_index + 1)
	if _pending_scene != null:
		_pending_delay -= delta
		if _pending_delay <= 0.0:
			_spawn(_pending_scene, _pending_height)
			_pending_scene = null
	for unit: Node3D in _entrants.duplicate():
		unit.global_position.x = move_toward(unit.global_position.x, camera.global_position.x + formation_screen_x, entry_speed * delta)
		if unit.global_position.x <= camera.global_position.x + formation_screen_x + 0.01:
			_entrants.erase(unit)
			unit.call("activate", bee)
	for unit: Node3D in _living:
		if not unit is SpeederEnemy and bool(unit.call("is_active")):
			unit.global_position.x = maxf(unit.global_position.x, camera.global_position.x - 4.7)
	max_active_seen = maxi(max_active_seen, _living.size())

func _start_wave(number: int) -> void:
	wave_index = number
	_wave_defeated = 0
	_wave_expected = 1 if number == 1 or number == 3 else 2
	_wave_done = false
	match number:
		1:
			_spawn(probe_scene,3.5)
		2:
			_spawn(eye_scene,5.3)
			_schedule(eye_scene,2.5,1.6)
		3:
			_spawn(speeder_scene,4.1)
		4:
			_spawn(eye_scene,3.2)
			_schedule(speeder_scene,5.3,1.6)

func _schedule(scene: PackedScene, height: float, delay: float) -> void:
	_pending_scene = scene
	_pending_height = height
	_pending_delay = delay

func _spawn(scene: PackedScene, height: float) -> void:
	assert(_living.size() < 2)
	var unit := scene.instantiate() as Node3D
	unit.name = "Wave%dEnemy%d" % [wave_index, spawned_count + 1]
	add_child(unit)
	unit.global_position = Vector3(camera.global_position.x + entry_screen_x,height,0.0)
	unit.show()
	unit.connect("defeated",Callable(self,"_on_enemy_defeated"))
	_living.append(unit)
	_entrants.append(unit)
	spawned_count += 1

func _on_enemy_defeated(unit: Node3D) -> void:
	_living.erase(unit)
	_entrants.erase(unit)
	defeated_count += 1
	_wave_defeated += 1
	if _wave_defeated == _wave_expected:
		_wave_done = true
		if wave_index == 4 and not _complete:
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
