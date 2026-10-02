extends Node3D

signal wave_completed
signal probe_spawned(probe: AlienProbeRanged)

@export var probe_scene: PackedScene
@export var first_spawn_distance := 6.0
@export var pair_spawn_distance := 16.0
@export var entry_speed := 7.0
@export var entry_screen_x := 10.8
@export var position_screen_x := 4.2

@onready var stage: BeeShmupStage = get_parent() as BeeShmupStage
@onready var bee: BeePlayer = stage.get_node("BeePlayer")
@onready var camera: Camera3D = stage.get_node("ShmupCamera")

var spawned_count := 0
var defeated_count := 0
var max_active_seen := 0
var _entrants: Array[AlienProbeRanged] = []
var _living: Array[AlienProbeRanged] = []
var _paused := false
var _complete := false

func _physics_process(delta: float) -> void:
	if _paused or _complete:
		return
	if spawned_count == 0 and stage.distance >= first_spawn_distance:
		_spawn_probe(3.5)
	if spawned_count == 1 and defeated_count == 1 and stage.distance >= pair_spawn_distance:
		_spawn_probe(5.5)
		_spawn_probe(2.3)
	for probe: AlienProbeRanged in _entrants.duplicate():
		probe.global_position.x = move_toward(probe.global_position.x, camera.global_position.x + position_screen_x, entry_speed * delta)
		if probe.global_position.x <= camera.global_position.x + position_screen_x + 0.01:
			_entrants.erase(probe)
			probe.activate(bee)
	for probe: AlienProbeRanged in _living:
		if probe.is_active():
			probe.global_position.x = maxf(probe.global_position.x, camera.global_position.x - 4.7)
	max_active_seen = maxi(max_active_seen, _living.size())

func _spawn_probe(height: float) -> void:
	assert(_living.size() < 2)
	var probe := probe_scene.instantiate() as AlienProbeRanged
	probe.name = "Probe%d" % (spawned_count + 1)
	add_child(probe)
	probe.global_position = Vector3(camera.global_position.x + entry_screen_x, height, 0.0)
	probe.show() # Entry is visible, but its AI/hurtbox activate only at the formation point.
	probe.defeated.connect(_on_probe_defeated)
	_living.append(probe)
	_entrants.append(probe)
	spawned_count += 1
	probe_spawned.emit(probe)

func _on_probe_defeated(probe: AlienProbeRanged) -> void:
	_living.erase(probe)
	_entrants.erase(probe)
	defeated_count += 1
	if defeated_count == 3 and not _complete:
		_complete = true
		wave_completed.emit()

func is_complete() -> bool:
	return _complete

func active_count() -> int:
	return _living.size()

func freeze_enemies() -> void:
	_paused = true
	for probe: AlienProbeRanged in _living:
		probe.set_physics_process(false)

