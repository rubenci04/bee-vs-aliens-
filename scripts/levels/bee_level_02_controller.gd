class_name BeeLevel02Controller
extends Node3D
## NOCHE 01 · ETAPA 4 — Level 02 "Laguna" PROTOTYPE director (~90 s). A small, separate copy of the Level 01 rules:
## events by distance, a threat cap, time on camera, the freed-animal tally and an arena lock for the toad mini-boss.
## It reuses the Level 01 families (AssetFauna scenes) plus three lake ones (water strider, dragonfly nymph, perch).
## Nothing here is used by Level 01.

signal wave_completed

const SCROLL := 1.5
const THREAT_CAP := 3
const CAMERA_TIME := 13.0
const BOSS_X := 112.0
const FAUNA := {
	"Strider": preload("res://scenes/levels/asset_fauna/strider.tscn"),
	"Nymph": preload("res://scenes/levels/asset_fauna/nymph.tscn"),
	"Perch": preload("res://scenes/levels/asset_fauna/perch.tscn"),
	"WaveDragonfly": preload("res://scenes/levels/asset_fauna/dragonfly.tscn"),
	"Mosquito": preload("res://scenes/levels/asset_fauna/mosquito.tscn"),
}
const AIR := ["WaveDragonfly", "Mosquito"]
const HP := {"Strider": 40, "Nymph": 50, "Perch": 60, "WaveDragonfly": 56, "Mosquito": 36}
const EVENTS := [
	{"at": 6.0, "label": "ZAPATERO", "units": ["Strider"]},
	{"at": 16.0, "label": "NINFAS", "units": ["Nymph", "Nymph"], "delays": [0.0, 1.4]},
	{"at": 28.0, "label": "PERCA SALTARINA", "units": ["Perch"]},
	{"at": 38.0, "label": "LIBÉLULA Y ZAPATERO", "units": ["WaveDragonfly", "Strider"], "delays": [0.0, 1.2], "y": [3.4, 0.0]},
	{"at": 52.0, "label": "DOS PERCAS Y NINFA", "units": ["Perch", "Perch", "Nymph"], "delays": [0.0, 2.2, 1.0]},
	{"at": 66.0, "label": "MOSQUITOS DEL JUNCAL", "units": ["Mosquito", "Mosquito"], "delays": [0.0, 0.9], "y": [4.6, 2.4]},
	{"at": 80.0, "label": "ORILLA", "units": ["Strider", "Perch", "WaveDragonfly"], "delays": [0.0, 1.2, 2.4], "y": [0.0, 0.0, 4.0]},
]

@onready var stage: BeeShmupStage = get_parent() as BeeShmupStage
@onready var bee: BeePlayer = stage.get_node("BeePlayer")

var event_index := 0
var active_units: Array[Node3D] = []
var pending: Array[Dictionary] = []
var boss: BeeLakeToadBoss
var boss_defeated := false
var animals_total := 0
var liberated_count := 0
var player_label := ""
var _clock := 0.0
var _complete := false
var _frozen := false


func _ready() -> void:
	stage.scroll_speed = SCROLL
	BeeShmupFairness.screen_bound_combat = true
	BeeAttackTokens.enabled = true
	BeeAttackTokens.reset()


func _exit_tree() -> void:
	BeeShmupFairness.screen_bound_combat = false
	BeeAttackTokens.enabled = false


func is_complete() -> bool:
	return _complete


func liberation_text() -> String:
	return "LIBERADOS %d/%d" % [liberated_count, animals_total]


func freeze_enemies() -> void:
	_frozen = true
	for unit in active_units:
		if is_instance_valid(unit):
			unit.set_physics_process(false)
	if boss != null and is_instance_valid(boss):
		boss.set_physics_process(false)
	stage.scroll_speed = 0.0


func _physics_process(delta: float) -> void:
	if _frozen or _complete:
		return
	_clock += delta
	_retire()
	_spawn_pending()
	if boss != null:
		return
	if event_index >= EVENTS.size():
		if stage.distance >= BOSS_X and active_units.is_empty() and pending.is_empty():
			_start_boss()
		return
	var event: Dictionary = EVENTS[event_index]
	if stage.distance < float(event["at"]):
		return
	event_index += 1
	var units: Array = event["units"]
	for i in units.size():
		var delays: Array = event.get("delays", [])
		var ys: Array = event.get("y", [])
		pending.append({"family": str(units[i]), "due": _clock + (float(delays[i]) if i < delays.size() else 0.8 * i),
				"y": float(ys[i]) if i < ys.size() else 4.0, "slot": i})


func _spawn_pending() -> void:
	pending.sort_custom(func(a, b): return float(a["due"]) < float(b["due"]))
	while not pending.is_empty() and _clock >= float(pending[0]["due"]) and active_units.size() < THREAT_CAP:
		_spawn(pending.pop_front())


func _spawn(request: Dictionary) -> void:
	var family := str(request["family"])
	var unit := (FAUNA[family] as PackedScene).instantiate() as AssetFauna
	unit.name = "%s_%d_%d" % [family, event_index, int(request["slot"])]
	stage.get_node("Enemies").add_child(unit)
	var air := family in AIR
	unit.global_position = Vector3(stage.camera.global_position.x + 8.0, float(request["y"]) if air else -0.2, 0.0)
	unit.health.max_health = BeeGameSettings.scaled_hp(int(HP[family]))
	unit.health.current_health = unit.health.max_health
	unit.max_cycles = 99
	unit.set_meta("level_born", _clock)
	unit.defeated.connect(_on_defeated)
	unit.liberated_now.connect(_on_liberated)
	if not bool(unit.config.get("machine", false)):
		animals_total += 1
	active_units.append(unit)
	unit.activate(bee)


func _retire() -> void:
	for unit in active_units.duplicate():
		if not is_instance_valid(unit):
			active_units.erase(unit)
			continue
		var old: bool = _clock - float(unit.get_meta("level_born")) >= CAMERA_TIME
		var behind: bool = unit.global_position.x < stage.camera.global_position.x - 9.0
		if old or behind:
			active_units.erase(unit)
			unit.queue_free()


func _on_liberated(unit: Node3D) -> void:
	active_units.erase(unit)
	if unit.is_in_group("bee_liberated") or (unit is AssetFauna and not bool((unit as AssetFauna).config.get("machine", false))):
		liberated_count += 1


func _on_defeated(unit: Node3D) -> void:
	active_units.erase(unit)
	get_tree().create_timer(1.0, false).timeout.connect(func(): if is_instance_valid(unit): unit.queue_free())


func _start_boss() -> void:
	stage.scroll_speed = 0.0 # Arena lock.
	player_label = "SAPO CONTROLADO"
	boss = BeeLakeToadBoss.new()
	boss.name = "LakeToad"
	stage.get_node("Enemies").add_child(boss)
	boss.global_position = Vector3(stage.camera.global_position.x + 10.0, -0.15, 0.0)
	animals_total += 1
	boss.liberated_now.connect(func(_b):
		liberated_count += 1
		player_label = "")
	boss.defeated.connect(_on_boss_freed)
	boss.activate(bee)


func _on_boss_freed(_b: Node3D) -> void:
	boss_defeated = true
	_complete = true
	stage.scroll_speed = 2.0
	wave_completed.emit()
