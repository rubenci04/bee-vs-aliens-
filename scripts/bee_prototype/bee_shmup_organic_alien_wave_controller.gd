class_name BeeShmupOrganicAlienWaveController
extends Node3D

signal wave_completed

@export var alien_scene: PackedScene
@export var entry_screen_x := 10.8
@export var second_entry_delay := 1.7

@onready var stage: BeeShmupStage = get_parent() as BeeShmupStage
@onready var bee: BeePlayer = stage.get_node("BeePlayer")
@onready var camera: Camera3D = stage.get_node("ShmupCamera")
@onready var wave_label: Label = stage.get_node("CanvasLayer/Wave")

var wave_index := 0
var spawned_count := 0
var defeated_count := 0
var max_active_seen := 0
var _wave_defeated := 0
var _wave_expected := 0
var _wave_done := true
var _complete := false
var _paused := false
var _pending_height := 0.0
var _pending_delay := -1.0
var _living: Array[OrganicAlienEnemy] = []

func _physics_process(delta: float) -> void:
	if _paused or _complete:
		return
	var thresholds := [6.0, 25.0, 48.0]
	if _wave_done and wave_index < 3 and stage.distance >= thresholds[wave_index]:
		_start_wave(wave_index + 1)
	if _pending_delay >= 0.0:
		_pending_delay -= delta
		if _pending_delay < 0.0:
			_spawn(_pending_height)
	max_active_seen = maxi(max_active_seen, _living.size())
	wave_label.text = "ORGANIC ALIEN · ENCUENTRO %d/3" % wave_index

func _start_wave(number: int) -> void:
	wave_index = number
	_wave_defeated = 0
	_wave_expected = 2 if number == 3 else 1
	_wave_done = false
	match number:
		1: _spawn(3.9)
		2: _spawn(5.5)
		3:
			_spawn(3.2)
			_pending_height = 5.5
			_pending_delay = second_entry_delay

func _spawn(height: float) -> void:
	assert(_living.size() < 2)
	var unit := alien_scene.instantiate() as OrganicAlienEnemy
	unit.name = "Wave%dAlien%d" % [wave_index, spawned_count + 1]
	add_child(unit)
	unit.global_position = Vector3(camera.global_position.x + entry_screen_x, height, 0.0)
	unit.defeated.connect(_on_alien_defeated)
	_living.append(unit)
	spawned_count += 1
	unit.activate(bee)

func _on_alien_defeated(unit: OrganicAlienEnemy) -> void:
	_living.erase(unit)
	defeated_count += 1
	_wave_defeated += 1
	if _wave_defeated == _wave_expected:
		_wave_done = true
		if wave_index == 3 and not _complete:
			_complete = true
			wave_completed.emit()

func active_count() -> int:
	return _living.size()

func is_complete() -> bool:
	return _complete

func freeze_enemies() -> void:
	_paused = true
	for unit in _living:
		unit.set_physics_process(false)
		unit.attack_hitbox.set_enabled(false)
		unit.telegraph.hide()
