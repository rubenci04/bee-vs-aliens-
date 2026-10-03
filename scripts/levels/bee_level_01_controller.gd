class_name BeeLevel01Controller
extends Node3D

signal wave_completed
## Enemy-free director set pieces ("opening_can", "human_aftermath", ...; "last_silence" before the UFO).
signal director_moment(id: StringName)

const WASP = preload("res://scenes/bee_prototype/wasp_enemy.tscn")
const PROBE = preload("res://scenes/bee_prototype/alien_probe_ranged.tscn")
const EYE = preload("res://scenes/bee_prototype/eye_drone_enemy.tscn")
const TURRET = preload("res://scenes/bee_prototype/ground_turret_enemy.tscn")
const SPEEDER = preload("res://scenes/bee_prototype/speeder_enemy.tscn")
const ORGANIC = preload("res://scenes/bee_prototype/organic_alien_enemy.tscn")
const WALKER = preload("res://scenes/bee_prototype/ground_walker_enemy.tscn")
const UFO_BOSS = preload("res://scenes/levels/ufo_boss_01.tscn")
const DRAGONFLY = preload("res://scenes/levels/controlled_dragonfly.tscn")
## One-off hint the first time controlled fauna appears: the animal is not the enemy, the implant is.
const FAUNA_HINT := "DESTRUÍ EL IMPLANTE"
## Breather between the last encounter and the UFO approach (arena already locked): "the last silence"
## (light dips, a hum rises, the UFO shadow sweeps the garden), then the unchanged reveal. Was 1.6 s.
const BOSS_BREATHER := 2.6
## Up to three threats at once from here on (was X=300): the second half of the route is where the pressure is.
const THREE_AT_ONCE_FROM := 150.0

# Level-only HP; reusable enemy scenes and attacks are unchanged.
const LEVEL_HP = {"Wasp": 36, "Probe": 32, "EyeDrone": 24, "Turret": 40, "Speeder": 30, "OrganicAlien": 47, "Walker": 60, "Dragonfly": 60}
# "Dragonfly" is the HP of its alien IMPLANT (the animal itself has no health): measured ~1.8-2.4 s of reasonable Base fire.
# Level-only tuning (reusable scenes and the family POCs keep their values). Damage, projectile speed and telegraph
# (windup) are never touched; HP is global-unchanged. BEFORE (Arcade Pressure pass 01) -> AFTER (Combat Pattern pass 02):
#   Wasp      2 passes, recovery 0.9 s            -> 3 passes, recovery 1.1 s, stalk 2.2/2.9/3.6 s on lanes (no simultaneous attacks)
#   Probe     burst of 2, cooldown 1.6 s          -> AIMED burst of 3 (0.2 s) -> short recovery 0.8 s -> burst of 3 -> cooldown 2.0 s
#                                                    with advance + vertical reposition
#   EyeDrone  burst of 2, cooldown 1.7 s          -> alternates AIMED burst of 3 and a FAN of 5 (12-18 deg), cooldown 2.0 s
#   Turret    cooldown 1.45 s, single shot        -> fan of 3 (14 deg) centred on Bee, cooldown 1.55 s
#   Walker    recovery 0.9 s, single shot         -> slow burst of 3 (0.35 s apart), recovery 0.9 s
const LEVEL_TUNING = {
	"Wasp": {"arcade_mode": true, "max_passes": 3, "arcade_recovery": 1.1, "restalk_time": 1.0, "drift_amplitude": 0.8},
	"Probe": {"cooldown_time": 2.0, "burst_shots": 3, "burst_gap": 0.2, "short_recovery": 0.8, "bursts_per_cycle": 2,
			"advance_speed": 0.5, "reposition_speed": 1.2, "maximum_range": 7.5},
	"EyeDrone": {"cooldown_time": 2.0, "burst_shots": 3, "burst_gap": 0.2, "fan_every": 2, "fan_count": 5, "fan_min_distance": 3.0, "fan_windup": 0.6},
	"Turret": {"cooldown_time": 1.55, "fan_count": 3, "fan_step_degrees": 14.0},
	"Walker": {"recovery_time": 0.9, "burst_shots": 3, "burst_gap": 0.35},
}
# LEVEL 01 TRANSFORMATION PASS 01 — EVENTS V2 (docs/BEE_LEVEL01_ARCADE_DIRECTOR_BLUEPRINT_01.md).
# Five internal acts (never shown to the player). Cadence is no longer a 14 m metronome: thresholds are 4-16 m apart,
# with popcorn micro events, formations, persistent groups, deliberate gates and enemy-free "moments".
# Optional per-event keys (all plain data):
#   "act"        1..5                      "formation"  readable name of the entry shape (dev/tests)
#   "delays"     seconds per unit (asc.)   "y"          spawn height per unit (formations; ground units ignore it)
#   "x"          extra spawn X per unit    "moment"     id emitted through `director_moment` (visual/interactive set piece)
#   "hard"/"human" as before.
const ACT_STARTS := [0.0, 68.0, 140.0, 198.0, 340.0] # ACT 1 AWAKENING, 2 CONTROLLED GARDEN, 3 HUMAN TERRITORY, 4 ALIEN ESCALATION, 5 FIRST CONTACT
## EyeDrone fans are introduced from here on (before: aimed bursts only).
const FAN_FROM_X := 96.0
const EVENTS = [
	# ACT 1 — AWAKENING (intensity 1 -> 2)
	{"at": 4.0, "act": 1, "label": "DESPERTAR · LATA GIGANTE", "units": [], "moment": "opening_can"},
	{"at": 8.0, "act": 1, "label": "JARDÍN · PRIMERA AVISPA", "units": ["Wasp"]},
	{"at": 20.0, "act": 1, "label": "JARDÍN · PAREJA DESFASADA", "units": ["Wasp", "Wasp"], "formation": "pair", "delays": [0.0, 2.0], "y": [4.8, 2.8]},
	{"at": 36.0, "act": 1, "label": "FORMACIÓN A · SONDA Y AVISPA", "units": ["Probe", "Wasp"], "formation": "escort", "delays": [0.0, 1.5]},
	{"at": 50.0, "act": 1, "label": "TRONCO · AVISPA, SONDA Y AVISPA", "units": ["Wasp", "Probe", "Wasp"], "formation": "staggered", "delays": [0.0, 0.8, 4.5], "y": [5.4, 3.6, 1.8]},
	{"at": 62.0, "act": 1, "label": "POPCORN · SPEEDER", "units": ["Speeder"]},
	# ACT 2 — CONTROLLED GARDEN (2 -> 3)
	{"at": 70.0, "act": 2, "label": "LÍNEA · DOS OJOS Y SONDA", "units": ["EyeDrone", "EyeDrone", "Probe"], "formation": "horizontal", "delays": [0.0, 0.5, 4.0], "y": [4.4, 4.4, 2.6], "x": [0.0, 1.6, 0.0]},
	{"at": 84.0, "act": 2, "label": "FORMACIÓN D · SONDAS DESFASADAS", "units": ["Probe", "Wasp", "Probe"], "formation": "staggered", "delays": [0.0, 1.0, 4.0], "y": [5.6, 3.0, 2.4]},
	{"at": 98.0, "act": 2, "label": "COLUMNA · DOS OJOS Y AVISPA", "units": ["EyeDrone", "EyeDrone", "Wasp"], "formation": "vertical", "delays": [0.0, 0.3, 3.5], "y": [2.0, 5.6, 3.8]},
	{"at": 110.0, "act": 2, "label": "CONTACTO · SPEEDER, SONDA Y AVISPA", "units": ["Speeder", "Probe", "Wasp"], "delays": [0.0, 0.8, 4.0]},
	{"at": 124.0, "act": 2, "label": "FAUNA · PRIMERA LIBÉLULA CONTROLADA", "units": ["Dragonfly"]},
	{"at": 140.0, "act": 3, "label": "ALERTA · HUMANO GIGANTE", "units": [], "human": true},
	# ACT 3 — HUMAN TERRITORY (2 -> 4 -> 2)
	{"at": 146.0, "act": 3, "label": "SECUELA · EL MUNDO SIGUE VIVO", "units": [], "moment": "human_aftermath"},
	{"at": 156.0, "act": 3, "label": "TENAZA · TORRETA, OJO Y AVISPA", "units": ["Turret", "EyeDrone", "Wasp"], "formation": "top_bottom", "delays": [0.0, 0.8, 4.0], "y": [-0.2, 6.0, 3.0]},
	{"at": 166.0, "act": 3, "label": "POPCORN · DIAGONAL DE AVISPAS", "units": ["Wasp", "Wasp"], "formation": "diagonal", "delays": [0.0, 0.6], "y": [5.8, 2.2], "x": [0.0, 1.4]},
	{"at": 174.0, "act": 3, "label": "FORMACIÓN B · OJO, TORRETA, AVISPA Y SONDA", "units": ["EyeDrone", "Turret", "Wasp", "Probe"], "formation": "top_bottom", "delays": [0.0, 0.8, 2.5, 5.0]},
	{"at": 186.0, "act": 3, "label": "DEFENSAS · AVISPA", "units": ["Wasp"]},
	# ACT 4 — ALIEN ESCALATION (3 -> 4 with valleys): 4a tech, 4b invasion, 4c last defence
	{"at": 198.0, "act": 4, "label": "DEFENSAS · SONDA, SPEEDER Y OJO", "units": ["Probe", "Speeder", "EyeDrone"]},
	{"at": 207.0, "act": 4, "label": "ROCA · TORRETA DETRÁS DE LA PIEDRA", "units": ["Turret", "Probe"], "formation": "rock_turret", "delays": [0.0, 2.0], "y": [-0.2, 5.6]},
	{"at": 218.0, "act": 4, "label": "DIAGONAL · DOS SONDAS Y OJO", "units": ["Probe", "Probe", "EyeDrone"], "formation": "diagonal", "delays": [0.0, 0.9, 3.0], "y": [6.0, 4.2, 2.4], "x": [0.0, 1.2, 0.0]},
	{"at": 230.0, "act": 4, "label": "CONTACTO · AVISPA, SONDA Y AVISPA", "units": ["Wasp", "Probe", "Wasp"], "delays": [0.0, 1.0, 2.5]},
	{"at": 242.0, "act": 4, "label": "CONTACTO · OJO, SPEEDER Y AVISPA", "units": ["EyeDrone", "Speeder", "Wasp"]},
	{"at": 254.0, "act": 4, "label": "ORGANISMO · AVISPA Y OJO", "units": ["OrganicAlien", "Wasp", "EyeDrone"], "hard": true, "delays": [0.0, 0.8, 3.0]},
	{"at": 262.0, "act": 4, "label": "JARDÍN CONTAMINADO · LIBÉLULA Y SONDA", "units": ["Dragonfly", "Probe"], "delays": [2.0, 4.5], "moment": "contaminated_garden"},
	{"at": 270.0, "act": 4, "label": "OLA · SONDA, OJO Y TORRETA", "units": ["Probe", "EyeDrone", "Turret"], "formation": "wave", "delays": [0.0, 1.5, 3.0]},
	{"at": 284.0, "act": 4, "label": "DEFENSAS · TORRETA, AVISPA Y SONDA", "units": ["Turret", "Wasp", "Probe"], "delays": [0.0, 0.8, 3.5]},
	{"at": 296.0, "act": 4, "label": "FORMACIÓN C · WALKER, OJO Y AVISPA", "units": ["Walker", "EyeDrone", "Wasp"], "formation": "escort", "hard": true, "delays": [0.0, 0.8, 3.0]},
	{"at": 302.0, "act": 4, "label": "RECOMPENSA · BOMBA", "units": [], "moment": "bomb_reward"},
	{"at": 312.0, "act": 4, "label": "OLA FINAL · AVISPA, SPEEDER, SONDA Y OJO", "units": ["Wasp", "Speeder", "Probe", "EyeDrone"], "formation": "wave", "delays": [0.0, 0.8, 1.6, 5.0]},
	{"at": 326.0, "act": 4, "label": "V · OJO Y DOS SONDAS", "units": ["EyeDrone", "Probe", "Probe"], "formation": "v", "delays": [0.0, 0.5, 0.5], "y": [4.2, 5.8, 2.6], "x": [0.0, 1.4, 1.4]},
	{"at": 340.0, "act": 4, "label": "ÚLTIMA DEFENSA · WALKER, SONDA, TORRETA Y AVISPA", "units": ["Walker", "Probe", "Turret", "Wasp"], "hard": true, "delays": [0.0, 0.8, 1.6, 5.0]},
]

@export var show_debug_labels := false # Internal event names ("JARDÍN · AVISPA"...) only for development.
@export var group_delay := 0.8
@export var soft_pressure_seconds := 14.0
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
var current_act := 1 # Internal act (1-5) of the last launched event; 5 = FIRST CONTACT.
var fauna_hint_shown := false

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
	current_act = int(event.get("act", current_act))
	if event.has("moment"):
		director_moment.emit(StringName(event["moment"]))
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
		var delays: Array = event.get("delays", [])
		var due: float = float(delays[i]) if i < delays.size() else float(i) * group_delay
		var request := {"family": str(units[i]), "slot": i, "event": launched_index, "due": _clock + due, "hard": _hard_gate}
		for key in ["y", "x"]: # Formation data, optional per unit.
			var values: Array = event.get(key, [])
			if i < values.size():
				request[key] = float(values[i])
		_pending.append(request)
	_spawn_pending()

func _spawn_pending() -> void:
	var cap := 3 if stage.distance >= THREE_AT_ONCE_FROM else 2
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
		"Dragonfly": scene = DRAGONFLY
		_: return
	var unit := scene.instantiate() as Node3D
	unit.name = "%s_%d_%d" % [family, int(request["event"]), int(request["slot"])]
	get_node("../Enemies").add_child(unit)
	var air := family in ["Wasp", "Probe", "EyeDrone", "Speeder", "OrganicAlien", "Dragonfly"]
	var height: float = [4.6, 2.6, 6.0][int(request["slot"]) % 3] if air else -0.2
	if air and request.has("y"):
		height = float(request["y"]) # Formation height.
	if air:
		height = minf(height, BeeLevel01Framing.max_entity_y()) # Never above the visible top edge - margin.
	# Moving enemies are born just past the right visible edge; the static turret stays on screen
	# (a hard gate must always be clearable).
	var spawn_offset := BeeLevel01Framing.ONSCREEN_SPAWN_X if family == "Turret" \
			else BeeLevel01Framing.spawn_offset_x(BeeLevel01Framing.view_aspect(get_viewport()))
	unit.global_position = Vector3(stage.camera.global_position.x + spawn_offset + float(request.get("x", 0.0)), height, 0)
	unit.set_meta("level_hard", bool(request["hard"]))
	unit.set_meta("level_born", _clock)
	unit.set_meta("level_retreat", false)
	unit.connect("defeated", _on_unit_defeated)
	if unit.has_signal("liberated_now"):
		unit.connect("liberated_now", _on_unit_liberated) # A freed animal stops counting as a threat at once.
	active_units.append(unit)
	spawned_by_family[family] = int(spawned_by_family.get(family, 0)) + 1
	spawn_history.append({"event": request["event"], "family": family, "time": _clock, "distance": stage.distance})
	var health := unit.get_node("HealthComponent") as HealthComponent
	health.max_health = int(LEVEL_HP[family])
	health.current_health = health.max_health
	var tuning: Dictionary = LEVEL_TUNING.get(family, {})
	for key in tuning:
		unit.set(key, tuning[key])
	var slot := int(request["slot"])
	if family == "Wasp":
		# Different presence per Wasp and different hover lines, so two Wasps never attack in lockstep.
		unit.set("stalk_time", 2.2 + 0.7 * float(slot % 3))
		unit.set("stalk_lane", [0.0, 1.1, -1.1][slot % 3])
	elif family == "Probe" or family == "EyeDrone":
		unit.set("initial_delay", 0.35 * float(slot % 3)) # Never the same first-shot frame as a neighbour.
	if family == "EyeDrone" and stage.distance < FAN_FROM_X:
		unit.set("fan_every", 0) # Projectile language: aimed bursts first, fans only from FAN_FROM_X.
	if family == "Dragonfly" and not fauna_hint_shown:
		fauna_hint_shown = true
		player_label = FAUNA_HINT
		get_tree().create_timer(3.5, false).timeout.connect(_clear_fauna_hint) # Bound method: dropped if the level reloads.
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
	get_tree().create_timer(1.0).timeout.connect(_release_unit.bind(unit.get_instance_id())) # Bound method + id: safe across reloads.

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
	current_act = 1
	for index in ACT_STARTS.size():
		if progress >= float(ACT_STARTS[index]):
			current_act = index + 1
	for event: Dictionary in EVENTS:
		if "Dragonfly" in event["units"] and float(event["at"]) < progress:
			fauna_hint_shown = true # Already learnt before the checkpoint.
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
			current_act = 5
			director_moment.emit(&"last_silence")
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

func _clear_fauna_hint() -> void:
	if player_label == FAUNA_HINT:
		player_label = ""

func _on_unit_liberated(unit: Node3D) -> void:
	active_units.erase(unit)

func _release_unit(id: int) -> void:
	var unit := instance_from_id(id) as Node
	if unit != null and is_instance_valid(unit):
		unit.queue_free()
