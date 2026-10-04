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
const SWARM = preload("res://scenes/levels/popcorn_drone.tscn")
## GARDEN IDENTITY 04: alien-controlled garden spider, a VERTICAL LANE THREAT (3 appearances: acts 2, 3, 4).
const SPIDER = preload("res://scenes/levels/controlled_spider.tscn")
## Camera-relative X where a spider drops in from above the top edge when the event gives none (inside the screen).
const SPIDER_ENTRY_X := 1.2
## One-off hint the first time controlled fauna appears: the animal is not the enemy, the implant is.
const FAUNA_HINT := "DESTRUÍ EL IMPLANTE"
## Breather between the last encounter and the UFO approach (arena already locked): "the last silence"
## (light dips, a hum rises, the UFO shadow sweeps the garden), then the unchanged reveal. Was 1.6 s.
const BOSS_BREATHER := 2.6
## ARCADE REBUILD 02: threats alive at once (popcorn never counts). BEFORE: 2, then 3 from X=150.
## AFTER: 2 for the first lesson, 3 from X=24, 4 from X=96 (with the Eye fans). See `threat_cap()`.
## REBUILD 03: threats now live longer (HP by role), so the cap follows the composition target instead:
## 2 until X=96 (first half reads 1-2), 3 until X=240, 4 in the last third (peaks).
const THREE_AT_ONCE_FROM := 96.0
const FOUR_AT_ONCE_FROM := 240.0
## Popcorn drones alive at once (their own budget, outside the threat cap).
const MAX_SWARM_ALIVE := 6
## Live hostile shots before Level 01 units hold their fire (see BeeShmupFairness.live_shot_ceiling).
const LIVE_SHOT_CEILING := 10
## Smallest gap between two authored entries of the same encounter (never the same frame).
const MIN_FORMATION_GAP := 0.2
## REBUILD 03: Wasp implant sting / overload are introduced progressively (see `_spawn`).
const STING_FROM_X := 40.0
const OVERLOAD_FROM_X := 150.0
## Camera-relative X where a cinematic depth entry reaches the flight plane (inside the right half of the screen).
const DEPTH_TARGET_X := 3.4
## Scroll speed while a showcase Walker ("hold") is alive: it walks with Bee instead of being left behind.
const HOLD_SCROLL := 1.0
## BOSS V2: never more than this many minions alive; they fly out of the saucer in MINION_LAUNCH_SECONDS.
const MAX_BOSS_MINIONS := 2
const MINION_LAUNCH_SECONDS := 0.7

# Level-only HP; reusable enemy scenes and attacks are unchanged.
## THREAT, CAMERA & BOSS REBUILD 03 — HP by ROLE (not by tradition). Reasonable Base fire ~27-33 DPS (3 taps/s, 10 HP,
## auto-aim). Target time-to-kill: POPCORN 0.1-0.8 s, LIGHT 1-2 s, MEDIUM 2.5-4.5 s, HEAVY 4-7 s, SHOWCASE 5-8 s.
##   POPCORN  Swarm 10
##   LIGHT    Wasp 36->44, EyeDrone 28->40, Speeder 30
##   MEDIUM   Probe 38->80, Turret 46->70, OrganicAlien 47->100
##   HEAVY    Walker 72->120 (a showcase Walker gets SHOWCASE_HP 150)
## "Dragonfly" is the HP of its alien IMPLANT (special fauna, unchanged).
const LEVEL_HP = {"Wasp": 44, "Probe": 80, "EyeDrone": 40, "Turret": 70, "Speeder": 30, "OrganicAlien": 100, "Walker": 120, "Dragonfly": 60, "Swarm": 10, "Spider": 90}
const SHOWCASE_HP := 150
const ROLES := {"Swarm": &"POPCORN", "Wasp": &"LIGHT", "EyeDrone": &"LIGHT", "Speeder": &"LIGHT", "Probe": &"MEDIUM",
		"Turret": &"MEDIUM", "OrganicAlien": &"MEDIUM", "Walker": &"HEAVY", "Dragonfly": &"SPECIAL", "Spider": &"MEDIUM"}
# Level-only tuning (reusable scenes and the family POCs keep their values). Damage, projectile speed and telegraph
# (windup) are never touched; HP is global-unchanged. BEFORE (Arcade Pressure pass 01) -> AFTER (Combat Pattern pass 02):
#   Wasp      2 passes, recovery 0.9 s            -> 3 passes, recovery 1.1 s, stalk 2.2/2.9/3.6 s on lanes (no simultaneous attacks)
#   Probe     burst of 2, cooldown 1.6 s          -> AIMED burst of 3 (0.2 s) -> short recovery 0.8 s -> burst of 3 -> cooldown 2.0 s
#                                                    with advance + vertical reposition
#   EyeDrone  burst of 2, cooldown 1.7 s          -> alternates AIMED burst of 3 and a FAN of 5 (12-18 deg), cooldown 2.0 s
#   Turret    cooldown 1.45 s, single shot        -> fan of 3 (14 deg) centred on Bee, cooldown 1.55 s
#   Walker    recovery 0.9 s, single shot         -> slow burst of 3 (0.35 s apart), recovery 0.9 s
# ARCADE REBUILD 02 (first attack sooner, more presence; windups/damage/shot speed still untouched):
#   Probe     holds and fires from 8.0 m (was 7.5) and never from outside the screen (`stay_on_screen`)
#   EyeDrone  hovers at 3.0-5.0 m (was 2.5-4.0), on screen: attacks from mid range instead of diving into Bee
#   Walker    walks 2.4 m/s, repositions 2.4 m, sees Bee from 10 m: keeps pace with the scroll and stays on screen
#   Cadence   shorter rests between attacks: Probe recovery 0.8->0.55 / cooldown 2.0->1.6, Eye cooldown 2.0->1.5,
#             Turret 1.55->1.3, Walker recovery 0.9->0.7 (telegraphs unchanged, so every attack stays readable)
#   Bursts    Probe / EyeDrone / Walker aimed bursts 3 -> 4 shots (same gap; every shot re-aims and flies straight)
#   Organic   alternates its stalk height above / below Bee after every lunge, recovery 0.75 -> 0.6 s (HP still 47)
# THREAT, CAMERA & BOSS REBUILD 03 (roles; see ROLES / LEVEL_HP):
#   Probe     moves 2.2 -> 3.0 m/s, holds at 8.5 m: telegraphs within ~1 s of being fully on screen
#   Wasp      implant sting (2 aimed bolts while stalking) on some Wasps; OVERLOAD (kamikaze dash from the implant)
#             from mid level - both assigned per spawn in `_spawn`
#   Organic   ranged bio-orbs (fan of 3) -> reposition -> lunge -> recovery (never both at once)
#   Walker    alternates its aimed burst with a high-to-low SWEEP of 5 (violet charge) that forces a height change
#   Speeder   lane telegraph across the screen before its straight dash (fast crossing threat)
#   Cadence   combat-only pressure: Probe cooldown 1.6->1.3 / recovery 0.55->0.45, Eye 1.5->1.2, Turret 1.3->1.1,
#             Walker recovery 0.7->0.6 (telegraphs, damage and shot speed unchanged)
# GARDEN IDENTITY 04 micro-pass (playtest: "a bit more challenge", no rebuild; measured with threat_analysis_04.gd):
#   Wasp      rest between passes (restalk) 1.0 -> 0.85 s
#   EyeDrone  cooldown 1.2 -> 1.1 s
#   Popcorn   the two act-4 rows at X=222 / 245: 3 shooters instead of 2 (one more slow aimed shot each)
#   Spider    new MEDIUM family (90 HP, 3 appearances) - the main new demand: change height on its column
const LEVEL_TUNING = {
	"Wasp": {"arcade_mode": true, "max_passes": 3, "arcade_recovery": 1.1, "restalk_time": 0.85, "drift_amplitude": 0.8},
	"Probe": {"cooldown_time": 1.3, "burst_shots": 4, "burst_gap": 0.2, "short_recovery": 0.45, "bursts_per_cycle": 2, "move_speed": 3.0,
			"advance_speed": 0.5, "reposition_speed": 1.2, "maximum_range": 8.5, "stay_on_screen": true},
	"EyeDrone": {"cooldown_time": 1.1, "burst_shots": 4, "burst_gap": 0.2, "fan_every": 2, "fan_count": 5, "fan_min_distance": 3.0, "fan_windup": 0.6,
			"minimum_range": 3.0, "maximum_range": 5.0, "stay_on_screen": true},
	"Turret": {"cooldown_time": 1.1, "fan_count": 3, "fan_step_degrees": 14.0},
	"OrganicAlien": {"vary_height": true, "recovery_time": 0.6, "ranged_enabled": true},
	"Speeder": {"lane_telegraph": true},
	"Walker": {"recovery_time": 0.6, "burst_shots": 4, "burst_gap": 0.35, "walk_speed": 2.4, "reposition_distance": 2.4, "detection_range": 10.0, "stay_on_screen": true, "sweep_every": 2},
}
# ARCADE CONTENT & SPECTACLE REBUILD 02 — EVENTS V3 (on top of the Transformation Pass EVENTS V2).
# Playtest verdict: "still empty, not challenging, too static". V3 layers each stretch instead of enemy -> kill -> wait:
# popcorn swarms (rhythm, one-shot kills) between medium threats, Walker x5 (clean presentation, showcase, escort, two
# late gates), OrganicAlien x3 (presentation, crossfire, late gate), cinematic depth entries, two showcase set pieces,
# the frog scale event and a guaranteed pre-boss weapon power moment. The five internal acts are unchanged.
# Optional per-event keys (all plain data):
#   "act"        1..5                      "formation"  readable name of the entry shape (dev/tests)
#   "delays"     seconds per unit (asc.)   "y"          spawn height per unit (formations; ground units ignore it)
#   "x"          extra spawn X per unit    "moment"     id emitted through `director_moment` (visual/interactive set piece)
#   "path"       Swarm path: sine | arc_top | arc_bottom | dive
#   "shooters"   unit indexes (Swarm only) that fire one slow aimed shot
#   "hard"/"human" as before.
const ACT_STARTS := [0.0, 68.0, 140.0, 198.0, 340.0] # ACT 1 AWAKENING, 2 CONTROLLED GARDEN, 3 HUMAN TERRITORY, 4 ALIEN ESCALATION, 5 FIRST CONTACT
## EyeDrone fans are introduced from here on (before: aimed bursts only).
const FAN_FROM_X := 96.0
const EVENTS = [
	# ACT 1 — AWAKENING (intensity 1 -> 2)
	{"at": 4.0, "act": 1, "label": "DESPERTAR · LATA GIGANTE", "units": [], "moment": "opening_can"},
	{"at": 8.0, "act": 1, "label": "JARDÍN · PRIMERA AVISPA", "units": ["Wasp"]},
	{"at": 14.0, "act": 1, "label": "POPCORN · FILA ONDULANTE", "units": ["Swarm", "Swarm", "Swarm"], "formation": "snake", "path": "sine", "delays": [0.0, 0.4, 0.8], "y": [4.2, 4.2, 4.2]},
	{"at": 22.0, "act": 1, "label": "JARDÍN · PAREJA DESFASADA", "units": ["Wasp", "Wasp"], "formation": "pair", "delays": [0.0, 1.2], "y": [4.8, 2.8]},
	{"at": 29.0, "act": 1, "label": "FORMACIÓN A · SONDA Y AVISPA", "units": ["Probe", "Wasp"], "formation": "escort", "delays": [0.0, 0.8]},
	{"at": 38.0, "act": 1, "label": "POPCORN · ARCO ALTO", "units": ["Swarm", "Swarm", "Swarm"], "formation": "arc", "path": "arc_top", "delays": [0.0, 0.35, 0.7], "y": [5.8, 5.8, 5.8], "shooters": [0, 2]},
	{"at": 46.0, "act": 1, "label": "TRONCO · AVISPA, SONDA Y OJO", "units": ["Wasp", "Probe", "EyeDrone"], "formation": "staggered", "delays": [0.0, 0.6, 1.6], "y": [5.4, 3.6, 1.8]},
	{"at": 56.0, "act": 1, "label": "PROFUNDIDAD · PRIMERA SONDA", "units": ["Probe"], "y": [4.6], "depth": true},
	# ACT 2 — CONTROLLED GARDEN (2 -> 3)
	{"at": 68.0, "act": 2, "label": "PROFUNDIDAD · V DE OJOS", "units": ["EyeDrone", "EyeDrone", "EyeDrone"], "formation": "v", "delays": [0.0, 0.3, 0.3], "y": [4.4, 5.8, 3.0], "x": [0.0, 1.0, 1.0], "depth": true},
	{"at": 76.0, "act": 2, "label": "CARRIL · SPEEDER", "units": ["Speeder"], "y": [5.2]},
	{"at": 80.0, "act": 2, "label": "ORGANISMO · PRESENTACIÓN", "units": ["OrganicAlien"], "y": [4.0], "depth": true},
	{"at": 87.0, "act": 2, "label": "POPCORN · FILA BAJA", "units": ["Swarm", "Swarm", "Swarm"], "formation": "snake", "path": "sine", "delays": [0.0, 0.4, 0.8], "y": [2.2, 2.2, 2.2], "shooters": [0, 2]},
	# GARDEN IDENTITY 04 — the spider is presented alone (clean read of the column, the ring and the lock).
	{"at": 91.0, "act": 2, "label": "ARAÑA · PRESENTACIÓN (CARRIL VERTICAL)", "units": ["Spider"], "x": [1.2]},
	{"at": 96.0, "act": 2, "label": "COLUMNA · OJO Y AVISPA", "units": ["EyeDrone", "Wasp"], "formation": "vertical", "delays": [0.0, 1.4], "y": [5.6, 3.0]},
	{"at": 105.0, "act": 2, "label": "WALKER · PRESENTACIÓN", "units": ["Walker"], "hold": true},
	{"at": 112.0, "act": 2, "label": "CONTACTO · SONDA Y OJO", "units": ["Probe", "EyeDrone"], "delays": [0.0, 0.8], "y": [5.4, 2.6]},
	{"at": 118.0, "act": 2, "label": "POPCORN · ARCO BAJO", "units": ["Swarm", "Swarm", "Swarm"], "formation": "arc", "path": "arc_bottom", "delays": [0.0, 0.35, 0.7], "y": [1.6, 1.6, 1.6], "shooters": [0, 2]},
	{"at": 124.0, "act": 2, "label": "FAUNA · PRIMERA LIBÉLULA CONTROLADA", "units": ["Dragonfly"]},
	{"at": 132.0, "act": 2, "label": "POPCORN · ANTES DEL GIGANTE", "units": ["Swarm", "Swarm", "Swarm"], "formation": "snake", "path": "sine", "delays": [0.0, 0.4, 0.8], "y": [5.0, 5.0, 5.0], "shooters": [1]},
	{"at": 140.0, "act": 3, "label": "ALERTA · HUMANO GIGANTE", "units": [], "human": true},
	# ACT 3 — HUMAN TERRITORY (2 -> 4 -> 2)
	{"at": 146.0, "act": 3, "label": "SECUELA · EL MUNDO SIGUE VIVO", "units": [], "moment": "human_aftermath"},
	{"at": 152.0, "act": 3, "label": "CARRILES · DOS SPEEDERS", "units": ["Speeder", "Speeder"], "formation": "pair", "delays": [0.0, 0.9], "y": [5.6, 2.0]},
	{"at": 158.0, "act": 3, "label": "TENAZA · TORRETA, OJO Y AVISPA", "units": ["Turret", "EyeDrone", "Wasp"], "formation": "top_bottom", "delays": [0.0, 0.6, 1.6], "y": [-0.2, 6.0, 3.0]},
	# GARDEN IDENTITY 04 — medium combination: a vertical column (spider) while a Wasp works the horizontal line.
	{"at": 166.0, "act": 3, "label": "ARAÑA · COLUMNA Y AVISPA", "units": ["Spider", "Wasp"], "delays": [0.0, 1.6], "x": [0.6, 0.0], "y": [0.0, 3.0]},
	{"at": 172.0, "act": 3, "label": "FORMACIÓN B · OJO, TORRETA Y DOS SONDAS", "units": ["EyeDrone", "Turret", "Probe", "Probe"], "formation": "top_bottom", "delays": [0.0, 0.6, 1.4, 2.4]},
	{"at": 180.0, "act": 3, "label": "SET PIECE A · WALKER BAJO EL ENJAMBRE", "units": ["Walker", "Swarm", "Swarm", "Swarm", "Wasp"], "formation": "showcase", "path": "dive", "delays": [0.0, 1.2, 1.5, 1.8, 3.0], "y": [0.0, 5.6, 5.6, 5.6, 3.8], "shooters": [1, 3], "moment": "walker_showcase", "hold": true},
	{"at": 188.0, "act": 3, "label": "ESCALA · LA RANA", "units": [], "moment": "scale_event"},
	# ACT 4 — ALIEN ESCALATION (3 -> 4 with valleys): 4a tech, 4b invasion, 4c last defence
	{"at": 198.0, "act": 4, "label": "DEFENSAS · SONDA Y OJO", "units": ["Probe", "EyeDrone"], "delays": [0.0, 0.6], "y": [5.6, 2.6]},
	{"at": 206.0, "act": 4, "label": "ROCA · TORRETA DETRÁS DE LA PIEDRA", "units": ["Turret", "Probe"], "formation": "rock_turret", "delays": [0.0, 1.0], "y": [-0.2, 5.6]},
	{"at": 214.0, "act": 4, "label": "SET PIECE B · ORGANISMO EN FUEGO CRUZADO", "units": ["OrganicAlien", "Probe", "EyeDrone"], "formation": "crossfire", "delays": [0.0, 0.6, 1.2], "y": [3.6, 5.8, 2.2]},
	{"at": 222.0, "act": 4, "label": "POPCORN · FILA ALTA", "units": ["Swarm", "Swarm", "Swarm"], "formation": "snake", "path": "sine", "delays": [0.0, 0.4, 0.8], "y": [5.2, 5.2, 5.2], "shooters": [0, 1, 2]},
	{"at": 228.0, "act": 4, "label": "PROFUNDIDAD · ROMBO", "units": ["Probe", "EyeDrone", "EyeDrone"], "formation": "v", "delays": [0.0, 0.25, 0.25], "y": [4.2, 5.8, 2.6], "x": [0.0, 1.2, 1.2], "depth": true},
	{"at": 238.0, "act": 4, "label": "WALKER · ESCOLTA", "units": ["Walker", "Probe"], "formation": "escort", "delays": [0.0, 0.8], "y": [0.0, 5.6]},
	{"at": 245.0, "act": 4, "label": "POPCORN · ARCO ALTO", "units": ["Swarm", "Swarm", "Swarm"], "formation": "arc", "path": "arc_top", "delays": [0.0, 0.35, 0.7], "y": [5.8, 5.8, 5.8], "shooters": [0, 1, 2]},
	{"at": 254.0, "act": 4, "label": "ORGANISMO · SONDA Y OJO", "units": ["OrganicAlien", "Probe", "EyeDrone"], "hard": true, "delays": [0.0, 0.8, 1.8]},
	{"at": 262.0, "act": 4, "label": "JARDÍN CONTAMINADO · LIBÉLULA Y SONDA", "units": ["Dragonfly", "Probe"], "delays": [2.0, 3.0], "moment": "contaminated_garden"},
	{"at": 270.0, "act": 4, "label": "OLA · OJO Y TORRETA", "units": ["EyeDrone", "Turret"], "formation": "wave", "delays": [0.0, 0.8]},
	{"at": 278.0, "act": 4, "label": "POPCORN · PICADA", "units": ["Swarm", "Swarm", "Swarm"], "formation": "dive", "path": "dive", "delays": [0.0, 0.3, 0.6], "y": [5.6, 4.4, 5.6], "shooters": [0, 1, 2]},
	{"at": 284.0, "act": 4, "label": "DEFENSAS · TORRETA Y AVISPA", "units": ["Turret", "Wasp"], "delays": [0.0, 0.8]},
	{"at": 289.0, "act": 4, "label": "CARRILES · DOS SPEEDERS", "units": ["Speeder", "Speeder"], "formation": "pair", "delays": [0.0, 0.9], "y": [2.4, 5.4]},
	{"at": 296.0, "act": 4, "label": "FORMACIÓN C · WALKER, OJO Y AVISPA", "units": ["Walker", "EyeDrone", "Wasp"], "formation": "escort", "hard": true, "delays": [0.0, 0.8, 1.8]},
	{"at": 302.0, "act": 4, "label": "RECOMPENSA · BOMBA", "units": [], "moment": "bomb_reward"},
	{"at": 308.0, "act": 4, "label": "OLA FINAL · SONDA", "units": ["Probe"], "y": [4.6]},
	# GARDEN IDENTITY 04 — late, optional pressure in the longest act-4 gap (308 -> 324): the spider.s column over an Eye.s fans.
	{"at": 315.0, "act": 4, "label": "ARAÑA · ÚLTIMA TELARAÑA", "units": ["Spider", "EyeDrone"], "delays": [0.0, 0.8], "x": [1.6, 0.0], "y": [0.0, 5.6]},
	{"at": 324.0, "act": 4, "label": "V · OJO Y DOS SONDAS", "units": ["EyeDrone", "Probe", "Probe"], "formation": "v", "delays": [0.0, 0.5, 0.5], "y": [4.2, 5.8, 2.6], "x": [0.0, 1.4, 1.4], "depth": true},
	{"at": 330.0, "act": 4, "label": "POTENCIA · PREPARATE", "units": [], "moment": "preboss_power"},
	{"at": 340.0, "act": 4, "label": "ÚLTIMA DEFENSA · WALKER, SONDA, TORRETA Y AVISPA", "units": ["Walker", "Probe", "Turret", "Wasp"], "hard": true, "delays": [0.0, 0.8, 1.6, 3.0]},
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
var swarm_units: Array[Node3D] = [] # Popcorn alive (outside the threat cap).
var _swarm_pending: Array[Dictionary] = []
var _clock := 0.0
var _hard_gate := false
var _waiting_for_human := false
var _complete := false
var _frozen := false
var boss: UfoBoss01
var boss_defeated := false
var _boss_breather_left := -1.0
var current_act := 1 # Internal act (1-5) of the last launched event; 5 = FIRST CONTACT.
var depth_entries := 0 # Cinematic depth entries started (dev/tests).
var _holding := false
var fauna_hint_shown := false

func _ready() -> void:
	human.crossing_exited.connect(_on_human_exited)
	BeeShmupFairness.live_shot_ceiling = LIVE_SHOT_CEILING
	BeeShmupFairness.screen_bound_combat = true
	BeeAttackTokens.enabled = true # REBUILD 03: one heavy pattern at a time.
	BeeAttackTokens.reset()

func _exit_tree() -> void:
	BeeShmupFairness.live_shot_ceiling = 0 # Static: never leak the Level 01 rules into POCs or other scenes.
	BeeShmupFairness.screen_bound_combat = false
	BeeAttackTokens.enabled = false

func _physics_process(delta: float) -> void:
	if _frozen or _complete:
		return
	_clock += delta
	_retire_soft_units(delta)
	_update_hold()
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
	if boss != null and is_instance_valid(boss):
		boss.minions_alive = boss_minions().size() # BOSS V2: the saucer only summons when the field allows it.
	if event_index >= EVENTS.size():
		if active_units.is_empty() and _pending.is_empty() and swarm_units.is_empty() and _swarm_pending.is_empty():
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
	var depth := bool(event.get("depth", false))
	var hold := bool(event.get("hold", false))
	var anchor := _depth_anchor(event) if depth else Vector2.ZERO
	for i in units.size():
		var delays: Array = event.get("delays", [])
		var due: float = float(delays[i]) if i < delays.size() else float(i) * group_delay
		var request := {"family": str(units[i]), "slot": i, "event": launched_index, "due": _clock + due, "hard": _hard_gate}
		for key in ["y", "x"]: # Formation data, optional per unit.
			var values: Array = event.get(key, [])
			if i < values.size():
				request[key] = float(values[i])
		if depth:
			request["depth"] = true # Cinematic 2.5D entry from the background (formations open up on arrival).
			request["anchor"] = anchor
		if hold:
			request["hold"] = true
		if str(units[i]) == "Swarm":
			request["path"] = str(event.get("path", "sine"))
			request["shooter"] = i in event.get("shooters", [])
			_swarm_pending.append(request) # Popcorn has its own queue: never waits behind (or blocks) threats.
		else:
			_pending.append(request)
	_spawn_pending()

## Threats alive at once at this point of the route (popcorn excluded).
static func threat_cap(distance: float) -> int:
	if distance >= FOUR_AT_ONCE_FROM:
		return 4
	return 3 if distance >= THREE_AT_ONCE_FROM else 2

func _spawn_swarm_pending() -> void:
	for unit in swarm_units.duplicate():
		if not is_instance_valid(unit):
			swarm_units.erase(unit)
		elif bool(unit.get("escaped")):
			swarm_units.erase(unit)
			escaped_count += 1
			unit.queue_free()
	while not _swarm_pending.is_empty() and _clock >= float(_swarm_pending[0]["due"]) and swarm_units.size() < MAX_SWARM_ALIVE:
		_spawn(_swarm_pending.pop_front())

func _spawn_pending() -> void:
	_spawn_swarm_pending()
	var cap := threat_cap(stage.distance)
	while not _pending.is_empty() and active_units.size() < cap:
		if _clock < float(_pending[0]["due"]):
			return
		var request: Dictionary = _pending.pop_front()
		var late := _clock - float(request["due"]) > 0.1
		_spawn(request)
		# A full cap can delay several requests past their original due time.
		# Still separate actual entries instead of releasing them in one frame.
		# REBUILD 02: on-time requests keep their authored spacing (formations such as a V arrive together, never in the
		# same frame: at least MIN_FORMATION_GAP); only a backlog is spread by `group_delay`.
		if not _pending.is_empty():
			var gap := group_delay if late else MIN_FORMATION_GAP
			_pending[0]["due"] = maxf(float(_pending[0]["due"]), _clock + gap)
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
		"Swarm": scene = SWARM
		"Spider": scene = SPIDER
		_: return
	var unit := scene.instantiate() as Node3D
	unit.name = "%s_%d_%d" % [family, int(request["event"]), int(request["slot"])]
	get_node("../Enemies").add_child(unit)
	var air := family in ["Wasp", "Probe", "EyeDrone", "Speeder", "OrganicAlien", "Dragonfly", "Swarm"]
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
	if family == "Spider":
		# Drops in from above the top edge INSIDE the screen (its thread is seen first); `x` is camera-relative here.
		unit.global_position = Vector3(stage.camera.global_position.x + float(request.get("x", SPIDER_ENTRY_X)), BeeLevel01Framing.top_y() + 1.6, 0)
	unit.set_meta("level_hard", bool(request["hard"]))
	unit.set_meta("level_born", _clock)
	unit.set_meta("level_retreat", false)
	unit.connect("defeated", _on_unit_defeated)
	if unit.has_signal("liberated_now"):
		unit.connect("liberated_now", _on_unit_liberated) # A freed animal stops counting as a threat at once.
	if family == "Swarm":
		swarm_units.append(unit)
		unit.set("path", ["sine", "arc_top", "arc_bottom", "dive"].find(str(request.get("path", "sine"))))
		unit.set("shooter", bool(request.get("shooter", false)))
	else:
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
		# REBUILD 03, introduced progressively: implant sting on the second Wasp of a group from X=40 and on every
		# Wasp from X=150; OVERLOAD on the first Wasp of a group from X=150 and on every Wasp from X=240.
		if stage.distance >= STING_FROM_X and (slot % 2 == 1 or stage.distance >= 150.0):
			unit.set("sting_shots", 2)
		if stage.distance >= OVERLOAD_FROM_X and (slot % 2 == 0 or stage.distance >= 240.0):
			unit.set("overload_enabled", true)
	elif family == "Probe" or family == "EyeDrone":
		unit.set("initial_delay", 0.35 * float(slot % 3)) # Never the same first-shot frame as a neighbour.
	if family == "EyeDrone" and stage.distance < FAN_FROM_X:
		unit.set("fan_every", 0) # Projectile language: aimed bursts first, fans only from FAN_FROM_X.
	if family == "Dragonfly" and not fauna_hint_shown:
		fauna_hint_shown = true
		player_label = FAUNA_HINT
		get_tree().create_timer(3.5, false).timeout.connect(_clear_fauna_hint) # Bound method: dropped if the level reloads.
	if bool(request.get("hold", false)) and family == "Walker":
		unit.set_meta("level_hold", true) # Showcase: the scroll slows while it lives, so it stays on screen.
		health.max_health = SHOWCASE_HP # REBUILD 03: SHOWCASE role (5-8 s of reasonable fire).
		health.current_health = SHOWCASE_HP
	max_active_seen = maxi(max_active_seen, active_units.size())
	if bool(request.get("minion", false)):
		unit.set_meta("boss_minion", true)
		CinematicDepthEntry.begin_from(unit, request["launch_from"], request["launch_slot"], _on_depth_arrived.bind(unit.get_instance_id()), MINION_LAUNCH_SECONDS)
		return
	if bool(request.get("depth", false)):
		var slot_point := Vector2(DEPTH_TARGET_X + float(request.get("x", 0.0)), height)
		CinematicDepthEntry.begin(unit, slot_point, request.get("anchor", slot_point), _on_depth_arrived.bind(unit.get_instance_id()))
		depth_entries += 1
		return # Activated on arrival at the flight plane (no AI, shots, collision or auto-aim before).
	if not unit.call("activate", bee):
		push_error("Level 01 failed to activate %s" % family)

## Shared start point of a depth formation: the middle of its slots (camera-relative X, absolute Y).
func _depth_anchor(event: Dictionary) -> Vector2:
	var xs: Array = event.get("x", [])
	var ys: Array = event.get("y", [])
	var mean_x := 0.0
	var mean_y := 4.4
	if not xs.is_empty():
		mean_x = xs.reduce(func(a, b): return float(a) + float(b), 0.0) / float(xs.size())
	if not ys.is_empty():
		mean_y = ys.reduce(func(a, b): return float(a) + float(b), 0.0) / float(ys.size())
	return Vector2(DEPTH_TARGET_X + mean_x, mean_y)

func _on_depth_arrived(id: int) -> void:
	var unit := instance_from_id(id) as Node3D
	if unit == null or not is_instance_valid(unit) or _frozen or not active_units.has(unit):
		return
	unit.set_meta("level_born", _clock) # Its soft lifetime starts on the flight plane.
	if not unit.call("activate", bee):
		push_error("Level 01 failed to activate %s after its depth entry" % unit.name)

func _retire_soft_units(delta: float) -> void:
	for unit in active_units.duplicate():
		if bool(unit.get_meta("level_hard")):
			continue
		# REBUILD 02: a ground unit left behind the left edge is out of play at once (it can never come back on its
		# own and would hold the next gate with an empty screen).
		var left_behind: bool = (unit is GroundWalkerEnemy or unit is GroundTurretEnemy) \
				and unit.global_position.x < stage.camera.global_position.x - BeeLevel01Framing.half_width_min(BeeLevel01Framing.DESIGN_ASPECT) - 0.8
		if left_behind or _clock - float(unit.get_meta("level_born")) >= soft_pressure_seconds:
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
	swarm_units.erase(unit)
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
	for unit in active_units + swarm_units:
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
	boss.summon_requested.connect(_on_boss_summon)
	encounter_label = "PRIMER CONTACTO · OVNI"
	player_label = "¡PRIMER CONTACTO!"
	boss.begin(stage.camera, bee)

func _on_boss_phase(state: int) -> void:
	if state == UfoBoss01.State.DEATH:
		for minion in boss_minions():
			minion.get_node("HealthComponent").take_damage(99999) # The minions fall with their ship.
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

## Showcase hold: while a "hold" unit (showcase Walker) is alive and in play, the scroll slows to HOLD_SCROLL so the
## set piece stays on screen; it never overrides gates, the human or the boss arena (they stop the scroll anyway).
func _update_hold() -> void:
	var hold := false
	for unit in active_units:
		if bool(unit.get_meta("level_hold", false)) and not bool(unit.get_meta("level_retreat", false)):
			hold = true
			break
	if hold and not _holding and is_equal_approx(stage.scroll_speed, 2.0):
		stage.scroll_speed = HOLD_SCROLL
		_holding = true
	elif not hold and _holding:
		_holding = false
		if is_equal_approx(stage.scroll_speed, HOLD_SCROLL):
			stage.scroll_speed = 2.0

# --- BOSS CHALLENGE V2 (REBUILD 03): minions ------------------------------------------------------------------

## Live minions launched by the UFO (never more than MAX_BOSS_MINIONS).
func boss_minions() -> Array[Node3D]:
	var list: Array[Node3D] = []
	for unit in active_units:
		if is_instance_valid(unit) and unit.has_meta("boss_minion"):
			list.append(unit)
	return list

## Minions leave the saucer's hatch and fly to their slots (no AI, shots or collision until they arrive), then fight
## as normal Level 01 units that never retreat on their own.
func _on_boss_summon(family: StringName, count: int) -> void:
	if boss == null or not is_instance_valid(boss) or _frozen:
		return
	var slots := [Vector2(DEPTH_TARGET_X - 0.6, 5.6), Vector2(DEPTH_TARGET_X - 0.2, 2.2)]
	for i in count:
		if boss_minions().size() >= MAX_BOSS_MINIONS:
			return
		var free_slot: Vector2 = slots[(boss_minions().size() + i) % slots.size()]
		_spawn({"family": str(family), "slot": i, "event": EVENTS.size() - 1, "hard": true, "y": free_slot.y, "minion": true,
				"launch_from": boss.global_position - Vector3(stage.camera.global_position.x, 0.0, 0.0), "launch_slot": free_slot})
