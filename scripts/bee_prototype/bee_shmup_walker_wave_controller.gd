class_name BeeShmupWalkerWaveController
extends Node3D

signal wave_completed

@export var second_walker_delay := 2.1

@onready var stage: BeeShmupStage = get_parent() as BeeShmupStage
@onready var bee: BeePlayer = stage.get_node("BeePlayer")
@onready var walker_a: GroundWalkerEnemy = stage.get_node("Walkers/WalkerA")
@onready var walker_b: GroundWalkerEnemy = stage.get_node("Walkers/WalkerB")
@onready var walker_c: GroundWalkerEnemy = stage.get_node("Walkers/WalkerC")
@onready var walker_d: GroundWalkerEnemy = stage.get_node("Walkers/WalkerD")

var wave_index := 0
var max_active_seen := 0
var defeated_count := 0
var resolved_count := 0
var _resolved: Dictionary = {}
var _second_delay_left := -1.0
var _complete := false
var _paused := false

func _ready() -> void:
	for walker: GroundWalkerEnemy in [walker_a, walker_b, walker_c, walker_d]:
		walker.defeated.connect(_on_walker_defeated)

func _physics_process(delta: float) -> void:
	if _paused or _complete or bee.is_defeated:
		return
	for walker: GroundWalkerEnemy in [walker_a, walker_b, walker_c, walker_d]:
		if walker.is_active() and walker.global_position.x < stage.camera.global_position.x + stage.screen_left - 1.0:
			walker.deactivate()
			_mark_resolved(walker, false)
	if wave_index == 0 and stage.distance >= 5.0:
		wave_index = 1
		walker_a.activate(bee)
	elif wave_index == 1 and _is_resolved(walker_a) and stage.distance >= 23.0:
		wave_index = 2
		walker_b.activate(bee)
	elif wave_index == 2 and _is_resolved(walker_b) and stage.distance >= 42.0:
		wave_index = 3
		walker_c.activate(bee)
		_second_delay_left = second_walker_delay
	if _second_delay_left >= 0.0:
		_second_delay_left -= delta
		if _second_delay_left < 0.0:
			walker_d.activate(bee)
	max_active_seen = maxi(max_active_seen, active_count())

func _on_walker_defeated(walker: GroundWalkerEnemy) -> void:
	_mark_resolved(walker, true)

func _is_resolved(walker: GroundWalkerEnemy) -> bool:
	return _resolved.has(walker.get_instance_id())

func _mark_resolved(walker: GroundWalkerEnemy, destroyed: bool) -> void:
	if _is_resolved(walker):
		return
	_resolved[walker.get_instance_id()] = true
	resolved_count += 1
	if destroyed:
		defeated_count += 1
	if resolved_count == 4 and not _complete:
		_complete = true
		wave_completed.emit()

func active_count() -> int:
	var total := 0
	for walker: GroundWalkerEnemy in [walker_a, walker_b, walker_c, walker_d]:
		if walker.is_active():
			total += 1
	return total

func is_complete() -> bool:
	return _complete

func freeze_enemies() -> void:
	_paused = true
	for walker: GroundWalkerEnemy in [walker_a, walker_b, walker_c, walker_d]:
		walker.set_physics_process(false)
