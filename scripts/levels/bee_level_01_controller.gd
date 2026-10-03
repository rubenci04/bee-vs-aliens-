class_name BeeLevel01Controller
extends Node3D

signal wave_completed

const WASP = preload("res://scenes/bee_prototype/wasp_enemy.tscn")
const PROBE = preload("res://scenes/bee_prototype/alien_probe_ranged.tscn")
const EYE = preload("res://scenes/bee_prototype/eye_drone_enemy.tscn")
const TURRET = preload("res://scenes/bee_prototype/ground_turret_enemy.tscn")
const SPEEDER = preload("res://scenes/bee_prototype/speeder_enemy.tscn")
const ORGANIC = preload("res://scenes/bee_prototype/organic_alien_enemy.tscn")
const WALKER = preload("res://scenes/bee_prototype/ground_walker_enemy.tscn")
const UFO_BOSS = preload("res://scenes/levels/ufo_boss_01.tscn")
## Breather between the last encounter and the UFO approach (arena already locked).
const BOSS_BREATHER := 1.6

# Level-only HP; reusable enemy scenes and attacks are unchanged.
const LEVEL_HP = {"Wasp": 36, "Probe": 32, "EyeDrone": 24, "Turret": 40, "Speeder": 30, "OrganicAlien": 47, "Walker": 60}
# CHALLENGE & BALANCE PASS 01: level-only cadence tuning of the two weakest ranged families
# (reusable scenes and the family POCs keep their values). Telegraph (windup), projectile speed and
# damage are untouched. BEFORE -> AFTER: Probe cooldown 1.25 -> 1.10 s (-12 %), EyeDrone 1.40 -> 1.25 s (-11 %).
const LEVEL_TUNING = {"Probe": {"cooldown_time": 1.10}, "EyeDrone": {"cooldown_time": 1.25}}
const EVENTS = [
	{"at": 12.0, "label": "JARDÍN · AVISPA", "units": ["Wasp"]},
	{"at": 26.0, "label": "JARDÍN · DOS AVISPAS", "units": ["Wasp", "Wasp"]},
	{"at": 40.0, "label": "JARDÍN · SONDA Y AVISPA", "units": ["Probe", "Wasp"]},
	{"at": 54.0, "label": "TRONCO · AVISPA Y SONDA", "units": ["Wasp", "Probe"]},
	{"at": 68.0, "label": "CONTACTO · DOS OJOS", "units": ["EyeDrone", "EyeDrone"]},
	{"at": 82.0, "label": "CONTACTO · SONDA Y AVISPA", "units": ["Probe", "Wasp"]},
	{"at": 96.0, "label": "ROCAS · OJO Y AVISPA", "units": ["EyeDrone", "Wasp"]},
	{"at": 110.0, "label": "CONTACTO · SPEEDER Y SONDA", "units": ["Speeder", "Probe"]},
	{"at": 124.0, "label": "JARDÍN · ÚLTIMA AVISPA", "units": ["Wasp"]},
	{"at": 140.0, "label": "ALERTA · HUMANO GIGANTE", "units": [], "human": true},
	{"at": 156.0, "label": "DEFENSAS · TORRETA Y AVISPA", "units": ["Turret", "Wasp"]},
	{"at": 170.0, "label": "DEFENSAS · OJO Y TORRETA", "units": ["EyeDrone", "Turret"]},
	{"at": 184.0, "label": "DEFENSAS · AVISPA", "units": ["Wasp"]},
	{"at": 198.0, "label": "DEFENSAS · SONDA Y SPEEDER", "units": ["Probe", "Speeder"]},
	{"at": 212.0, "label": "DEFENSAS · TORRETA Y OJO", "units": ["Turret", "EyeDrone"]},
	{"at": 226.0, "label": "CONTACTO · DOS AVISPAS", "units": ["Wasp", "Wasp"]},
	{"at": 240.0, "label": "CONTACTO · OJO Y SPEEDER", "units": ["EyeDrone", "Speeder"]},
	{"at": 254.0, "label": "ORGANISMO · AVISPA", "units": ["OrganicAlien", "Wasp"], "hard": true},
	{"at": 268.0, "label": "DEFENSAS · SONDA Y OJO", "units": ["Probe", "EyeDrone"]},
	{"at": 282.0, "label": "DEFENSAS · TORRETA Y AVISPA", "units": ["Turret", "Wasp"]},
	{"at": 296.0, "label": "WALKER · OJO", "units": ["Walker", "EyeDrone"], "hard": true},
	{"at": 310.0, "label": "FINAL · AVISPA, SPEEDER Y SONDA", "units": ["Wasp", "Speeder", "Probe"]},
	{"at": 324.0, "label": "FINAL · TRES AMENAZAS", "units": ["Probe", "EyeDrone", "Wasp"]},
	{"at": 340.0, "label": "ÚLTIMA DEFENSA · TRES AMENAZAS", "units": ["Walker", "Probe", "Turret"], "hard": true},
]

@export var show_debug_labels := false # Internal event names ("JARDÍN · AVISPA"...) only for development.
@export var group_delay := 0.8
@export var soft_pressure_seconds := 6.0
@export var retreat_speed := 10.0
@onready var stage: BeeShmupStage = get_parent() as BeeShmupStage
@onready var bee: BeePlayer = stage.get_node("BeePlayer")
@onready var human: GiantHumanCrossingHazard = stage.get_node("GiantHuman")
@onready var warning: Label = stage.get_node("CanvasLayer/HumanWarning")

var event_index := 0 # Next threshold, not the number of killed encounters.
var max_active_seen := 0
var spawned_by_family: Dictionary = {}
var active_units: Array[Node3D] = []
var encounter_label := "JARDÍN · APRENDÉ A VOLAR"
var player_label := "" # What the HUD shows: only important messages unless show_debug_labels.
var escaped_count := 0
var spawn_history: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _clock := 0.0
var _hard_gate := false
var _waiting_for_human := false
var _complete := false
var _frozen := false
var boss: UfoBoss01
var boss_defeated := false
var _boss_breather_left := -1.0

func _ready() -> void:
	human.crossing_exited.connect(_on_human_exited)

func _physics_process(delta: float) -> void:
	if _frozen or _complete:
		return
	_clock += delta
	_retire_soft_units(delta)
	if _waiting_for_human:
		return
	if _hard_gate:
		if active_units.is_empty() and _pending.is_empty():
			_hard_gate = false
			stage.scroll_speed = 2.0
		else:
			_spawn_pending()
			return
	_spawn_pending()
	if event_index >= EVENTS.size():
		if active_units.is_empty() and _pending.is_empty():
			_advance_boss(delta) # Level complete only after the UFO is destroyed.
		return
	var event: Dictionary = EVENTS[event_index]
	if stage.distance < float(event["at"]) or not _pending.is_empty():
		return
	# Hard gates/human never overlap surviving soft actors.
	if (bool(event.get("hard", false)) or bool(event.get("human", false))) and not active_units.is_empty():
		stage.scroll_speed = 0.0
		return
	encounter_label = str(event["label"])
	player_label = encounter_label if show_debug_labels or bool(event.get("human", false)) else ""
	var launched_index := event_index
	event_index += 1
	if bool(event.get("human", false)):
		stage.scroll_speed = 0.0
		_waiting_for_human = true
		warning.show()
		if not human.begin_crossing(stage.camera):
			push_error("Level 01 giant human could not start")
		return
	_hard_gate = bool(event.get("hard", false))
	if _hard_gate:
		stage.scroll_speed = 0.0
	var units: Array = event["units"]
	for i in units.size():
		_pending.append({"family": str(units[i]), "slot": i, "event": launched_index,
			"due": _clock + float(i) * group_delay, "hard": _hard_gate})
	_spawn_pending()

func _spawn_pending() -> void:
	var cap := 3 if stage.distance >= 300.0 else 2
	while not _pending.is_empty() and active_units.size() < cap:
		if _clock < float(_pending[0]["due"]):
			return
		var request: Dictionary = _pending.pop_front()
		_spawn(request)
		# A full cap can delay several requests past their original due time.
		# Still separate actual entries instead of releasing them in one frame.
		if not _pending.is_empty():
			_pending[0]["due"] = maxf(float(_pending[0]["due"]), _clock + group_delay)
		return

func _spawn(request: Dictionary) -> void:
	var family := str(request["family"])
	var scene: PackedScene
	match family:
		"Wasp": scene = WASP
		"Probe": scene = PROBE
		"EyeDrone": scene = EYE
		"Turret": scene = TURRET
		"Speeder": scene = SPEEDER
		"OrganicAlien": scene = ORGANIC
		"Walker": scene = WALKER
		_: return
	var unit := scene.instantiate() as Node3D
	unit.name = "%s_%d_%d" % [family, int(request["event"]), int(request["slot"])]
	get_node("../Enemies").add_child(unit)
	var air := family in ["Wasp", "Probe", "EyeDrone", "Speeder", "OrganicAlien"]
	var height: float = [4.6, 2.6, 6.0][int(request["slot"])] if air else -0.2
	if air:
		height = minf(height, BeeLevel01Framing.max_entity_y()) # Never above the visible top edge - margin.
	# Moving enemies are born just past the right visible edge; the static turret stays on screen
	# (a hard gate must always be clearable).
	var spawn_offset := BeeLevel01Framing.ONSCREEN_SPAWN_X if family == "Turret" \
			else BeeLevel01Framing.spawn_offset_x(BeeLevel01Framing.view_aspect(get_viewport()))
	unit.global_position = Vector3(stage.camera.global_position.x + spawn_offset, height, 0)
	unit.set_meta("level_hard", bool(request["hard"]))
	unit.set_meta("level_born", _clock)
	unit.set_meta("level_retreat", false)
	unit.connect("defeated", _on_unit_defeated)
	active_units.append(unit)
	spawned_by_family[family] = int(spawned_by_family.get(family, 0)) + 1
	spawn_history.append({"event": request["event"], "family": family, "time": _clock, "distance": stage.distance})
	var health := unit.get_node("HealthComponent") as HealthComponent
	health.max_health = int(LEVEL_HP[family])
	health.current_health = health.max_health
	var tuning: Dictionary = LEVEL_TUNING.get(family, {})
	for key in tuning:
		unit.set(key, tuning[key])
	if not unit.call("activate", bee):
		push_error("Level 01 failed to activate %s" % family)
	max_active_seen = maxi(max_active_seen, active_units.size())

func _retire_soft_units(delta: float) -> void:
	for unit in active_units.duplicate():
		if bool(unit.get_meta("level_hard")):
			continue
		if _clock - float(unit.get_meta("level_born")) >= soft_pressure_seconds:
			if not bool(unit.get_meta("level_retreat")):
				unit.set_meta("level_retreat", true)
				unit.set_physics_process(false)
				unit.remove_from_group("bee_auto_aim_targets")
				for area: Area3D in unit.find_children("*", "Area3D", true, false):
					if area is DamageHitbox3D:
						(area as DamageHitbox3D).set_enabled(false)
					area.set_deferred("monitoring", false)
					area.set_deferred("monitorable", false)
			unit.global_position.x -= retreat_speed * delta
		if unit.global_position.x < stage.camera.global_position.x - 8.0:
			active_units.erase(unit)
			escaped_count += 1
			unit.queue_free()

func _on_unit_defeated(unit: Node3D) -> void:
	active_units.erase(unit)
	# Keep the existing death feedback briefly, then release its subtree.
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(unit):
			unit.queue_free())

func _on_human_exited() -> void:
	if not _waiting_for_human or _frozen:
		return
	_waiting_for_human = false
	warning.hide()
	stage.scroll_speed = 2.0
	encounter_label = "RUTA DESPEJADA · AVANZÁ →"
	player_label = encounter_label

func is_complete() -> bool:
	return _complete

func resume_after_checkpoint(progress: float) -> void:
	# New scene: no actors/pending shots to serialize. Earlier events are consumed.
	event_index = 0
	while event_index < EVENTS.size() and float(EVENTS[event_index]["at"]) < progress:
		event_index += 1
	encounter_label = "CHECKPOINT · SEGUNDA MITAD"
	player_label = encounter_label if show_debug_labels else "CHECKPOINT"
	if progress > 140.0:
		human.freeze()
		human.current_phase = GiantHumanCrossingHazard.Phase.EXITED
		human.crossings_started = 1
		human.crossings_exited = 1

func freeze_enemies() -> void:
	_frozen = true
	human.freeze()
	for unit in active_units:
		unit.set_physics_process(false)
	if boss != null and is_instance_valid(boss):
		boss.freeze()
	stage.scroll_speed = 0.0

# --- UFO BOSS 01 (FIRST CONTACT) -------------------------------------------------------------
# last encounter -> breather (arena locked) -> UFO approach -> boss -> death -> wave_completed.

func _advance_boss(delta: float) -> void:
	if boss_defeated:
		return
	if boss == null:
		if _boss_breather_left < 0.0:
			_boss_breather_left = BOSS_BREATHER
			stage.scroll_speed = 0.0 # Arena lock: no more scroll, no more encounters.
			encounter_label = "FINAL · CONTACTO"
			player_label = ""
		_boss_breather_left -= delta
		if _boss_breather_left <= 0.0:
			_start_boss()

func _start_boss() -> void:
	boss = UFO_BOSS.instantiate() as UfoBoss01
	boss.name = "UfoBoss01"
	get_node("../Enemies").add_child(boss)
	boss.defeated.connect(_on_boss_defeated)
	boss.phase_changed.connect(_on_boss_phase)
	encounter_label = "PRIMER CONTACTO · OVNI"
	player_label = "¡PRIMER CONTACTO!"
	boss.begin(stage.camera, bee)

func _on_boss_phase(state: int) -> void:
	if state == UfoBoss01.State.PHASE_1:
		player_label = "" # The health bar takes over.

func _on_boss_defeated(_boss: UfoBoss01) -> void:
	boss_defeated = true
	boss = null
	_complete = true
	stage.scroll_speed = 2.0 # Short roll to the sector end, then SECTOR DESPEJADO.
	wave_completed.emit()

func boss_active() -> bool:
	return boss != null and is_instance_valid(boss) and boss.is_active()
