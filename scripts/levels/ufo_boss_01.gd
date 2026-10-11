class_name UfoBoss01
extends Node3D
## BEE UFO BOSS 01 — FIRST CONTACT. Level 01 climax: the first alien ship Bee sees.
## Five combat phases, transitions, then the existing death cinematic.
## Gameplay stays on the Z=0 plane; only the approach uses visual depth (it flies in from far Z).
## Everything is built in code (no external UFO asset) with Style C toon materials.

signal defeated(boss: UfoBoss01)
signal phase_changed(state: int)
signal projectile_fired(projectile: AlienEnemyProjectile, pattern: StringName)
## BOSS CHALLENGE V2 (REBUILD 03): the level director spawns `count` minions of `family` launched from the saucer.
signal summon_requested(family: StringName, count: int)

enum State { APPROACH, PHASE_1, PHASE_2, PHASE_3, PHASE_4, PHASE_5, TRANSITION, DEATH, DONE }

const PROJECTILE := preload("res://scenes/levels/ufo_boss_projectile.tscn")
const PROJECTILE_GROUP := &"ufo_boss_projectiles"
const DISPLAY_NAME := "NODO ALIEN"

## LOTE 9 · ETAPA C — a real final fight (playtest: "too easy, even on Normal"). LOTE 10 target: 75-100 s with Base and sustained Spread.
##   PHASE 1  100-70 %  faster aimed bursts (4 shots, 0.11 s apart) and an aimed fan every third attack
##   PHASE 2   70-40 %  cyan SHIELD (no damage) powered by SHIELD_NODES orbiting nodes; it throws mines meanwhile. Breaking
##                      every node drops the shield for SHIELD_WINDOW s (damage x WINDOW_DAMAGE_SCALE), then it reforms
##   PHASE 3   40-25 %  tractor beam every other attack, faster mines, a side change every SIDE_SWITCH[PHASE_3] s
##   PHASE 4   25-15 %    FURY: red core, combined pattern (beam + mines together, fans, long bursts), faster side changes
##   PHASE 5  <15 % OVERLOAD: violet core, denser movement, line drones; shared sustained hull DPS budget.
## Every damaging attack is announced >= MIN_TELEGRAPH s before it can hurt (see `hazards`).
## BEFORE: 500 HP, 3 phases (66 / 33 %), bomb 32 (6 % of its life), shortest fight ~25 s with dodging.
@export var max_hp := 1200
const PHASE_2_RATIO := 0.70
const PHASE_3_RATIO := 0.40
const PHASE_4_RATIO := 0.25
const PHASE_5_RATIO := 0.15
const HULL_DPS_RATIO := 0.0143
const HULL_BURST := 14.0
const EASY_HULL_DPS_RATIO := 0.0125
const OVERLOAD_COLOR := Color(0.65, 0.24, 1.0)
## The Alien Bomb takes this fraction of the max HP (was its normal 32 damage = 6 %).
const BOMB_FRACTION := 0.08
## Phase 2 shield: nodes on the first raise / on every later raise, node HP, open window and reform warning (s).
const SHIELD_NODES := 3
const SHIELD_NODES_AGAIN := 2
const SHIELD_NODE_HP := 16
const SHIELD_WINDOW := 24.0
const SHIELD_REFORM := 1.2
const WINDOW_DAMAGE_SCALE := 2.0
const SHIELD_RADIUS := 2.9
## The nodes guard the arc of the saucer that faces Bee: total spread (rad) of their slots.
const SHIELD_ARC := 1.9
const SHIELD_COLOR := Color(0.25, 0.95, 1.0, 0.22)
const FURY_COLOR := Color(1.0, 0.25, 0.2)

const APPROACH_SECONDS := 3.2
const START_OFFSET := Vector3(4.0, 2.4, -38.0) # Far in depth, up and to the side (x mirrored by `side`).
const ANCHOR_DX := 3.0 # Arena position: |x| from the camera centre on the current side.
const CENTER_Y := 3.6
## BOSS v2 (combat variety 01): the saucer lives on ONE side of the screen (`side` +1 right / -1 left), enters from either
## side and CROSSES to the other side at every phase change (and every SIDE_SWITCH_P3 s in phase 3). While crossing it
## flies high, does not attack and its hull does not hurt. Bee may use the whole width during the fight.
const CROSS_SECONDS := 1.5
const CROSS_LIFT := 1.8
const SIDE_SWITCH_P3 := 4.5 # LOTE 9: 6.5 -> 4.5 s.
const SIDE_SWITCH := {State.PHASE_3: SIDE_SWITCH_P3, State.PHASE_4: 3.5, State.PHASE_5: 3.0}
## BOSS v2 MINES: thrown from the core, they fly TRAVEL s to their spot, hang still with a shrinking warning ring and
## explode in MINE_RADIUS (radius drawn the whole time). LOTE 9: phase 3 faster (1.5 -> 1.25 s), phase 4 with the beam.
const MINE_COUNT := {State.PHASE_2: 2, State.PHASE_3: 3, State.PHASE_4: 2, State.PHASE_5: 2}
const MINE_FUSE := {State.PHASE_2: 2.0, State.PHASE_3: 1.25, State.PHASE_4: 1.1, State.PHASE_5: 1.1}
const MINE_RADIUS := 1.5
const MINE_DAMAGE := 4 # LOTE 10: stronger bullets and new hull attacks share the damage budget.
const MINE_SPREAD := 2.4 # m between neighbouring mines (one lands on Bee's spot, the rest beside it)
const MINE_TELEGRAPH := 0.5 # core swell before the throw
## Every damage source the boss owns must be announced at least this long before it can hurt (tests read `hazards`).
const MIN_TELEGRAPH := 0.42
const TRANSITION_SECONDS := 0.9
## Visual root scale: ring radius ~2.7 m (5.4 m wide). A full 6 m would cover Bee's flight window in the preset E frame.
const VISUAL_SCALE := 1.6
## PHASE 3 TRACTOR BEAM: a vertical column on the ground line, marked 1 s before, 15 damage once per exposure.
const BEAM_TELEGRAPH := 1.0
## LOTE 9: the beam warns a little shorter later on (still >= MIN_TELEGRAPH).
const BEAM_TELEGRAPH_BY_PHASE := {State.PHASE_3: 0.85, State.PHASE_4: 0.7, State.PHASE_5: 0.65}
const BEAM_ACTIVE := 0.8
const BEAM_WIDTH := 1.5
const BEAM_DAMAGE := 8 # LOTE 9: 15 -> 8.
const BEAM_GROUND_Y := -0.2
const BEAM_TOP_Y := 7.3

# Per phase: [bob amplitude, bob period, cooldown, aimed telegraph, fan telegraph].
# Amplitude keeps the whole saucer inside the preset E frame (top edge ~7.1 m at the play plane).
## BOSS CHALLENGE V2 (REBUILD 03): more active movement per phase - a figure-eight over the right part of the arena
## (X amplitude per phase) plus, from phase 2, a slow approach / retreat. Never chases Bee and never leaves the band
## [X_MIN, half width - X_EDGE] in front of the camera, so the left of the screen is always an escape route.
## BOSS v2: wider bands - |x| in [X_MIN, half width - X_EDGE] on its side, vertical amplitude per phase in PHASE_TUNING.
const MOVE_X := {State.PHASE_1: 1.4, State.PHASE_2: 1.6, State.PHASE_3: 1.8, State.PHASE_4: 2.0, State.PHASE_5: 2.0}
const APPROACH_X := {State.PHASE_1: 0.0, State.PHASE_2: 0.8, State.PHASE_3: 1.1, State.PHASE_4: 1.2, State.PHASE_5: 1.2}
const X_MIN := 1.2
const X_EDGE := 2.9
## Minions: phase 2 launches 2 EyeDrones (then again whenever none is left, every MINION_COOLDOWN s); phase 3 launches
## a single Probe only when the screen is clean enough. While summoning the saucer does not attack (~1 s).
const SUMMON_SECONDS := 1.0
## LOTE 9: phase 2 has the shield nodes instead; minions come in phase 3 only.
const MINION_COOLDOWN := {State.PHASE_3: 12.0, State.PHASE_5: 10.0}
const MAX_MINIONS := {State.PHASE_3: 1, State.PHASE_5: 1}
## NOCHE 01: every ORGANIC_EVERY-th summon brings the purple one-eyed organism instead of a probe.
const ORGANIC_EVERY := 2
## [bob amplitude, bob period, cooldown, aimed telegraph, fan telegraph]. LOTE 9: shorter cooldowns, phase 4.
const PHASE_TUNING := {
	State.PHASE_1: [1.3, 4.6, 1.1, 0.45, 0.6],
	State.PHASE_2: [1.4, 4.4, 1.0, 0.5, 0.6],
	State.PHASE_3: [1.5, 3.4, 0.9, 0.45, 0.5],
	State.PHASE_4: [1.6, 3.0, 0.8, 0.42, 0.45],
	State.PHASE_5: [1.6, 2.7, 0.75, 0.42, 0.45],
}
const AIMED_SHOTS := 3
const AIMED_INTERVAL := 0.14
const AIMED_SPEED := 6.2 # Fallback; per phase see AIMED_SPEED_BY_PHASE.
## LOTE 9: faster, longer aimed bursts (phase 1 was 3 shots at 6.8 m/s, 0.14 s apart).
const AIMED_SPEED_BY_PHASE := {State.PHASE_1: 7.8, State.PHASE_2: 7.2, State.PHASE_3: 7.8, State.PHASE_4: 8.4, State.PHASE_5: 8.4}
const AIMED_SHOTS_BY_PHASE := {State.PHASE_1: 4, State.PHASE_2: 3, State.PHASE_3: 4, State.PHASE_4: 5, State.PHASE_5: 5}
const AIMED_INTERVAL_BY_PHASE := {State.PHASE_1: 0.11, State.PHASE_2: 0.14, State.PHASE_3: 0.12, State.PHASE_4: 0.1, State.PHASE_5: 0.1}
const FAN_SHOTS := 5
const FAN_STEP_DEGREES := 17.0 # 5 shots over 68°: gaps of ~1.7 m at Bee's distance.
const FAN_SPEED := 4.8
## LOTE 9 damage budget: a longer fight with denser bursts; a half-dodging player should lose ~40-60 HP on NORMAL
## (validate_bee_boss_fight_v04). Many small shots, heavier telegraphed mines / beam. BEFORE: shot 8, mine 12, beam 15, hull 12.
const SHOT_DAMAGE := 3
const CONTACT_DAMAGE := 10

const COLORS := {
	"hull": Color(0.56, 0.6, 0.66), "ring": Color(0.3, 0.33, 0.4), "panel": Color(0.2, 0.22, 0.27),
	"dome": Color(0.25, 0.85, 0.95), "emitter": Color(0.15, 0.95, 1.0), "core": Color(0.62, 0.22, 0.95),
}

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var contact: DamageHitbox3D = $ContactHitbox
@onready var visual_root: Node3D = $VisualRoot
@onready var hit_flash: HitFlash3D = $HitFlash3D

var state := State.APPROACH
var camera: Camera3D
var target: BeePlayer
var anchor := Vector3.ZERO
var fired_aimed := 0
var fired_fan := 0
var attacks_started := 0
var transitions := 0
var _next_state := State.PHASE_1
var _state_time := 0.0
var _bob_time := 0.0
var _attack_step := &"cooldown" # cooldown | telegraph | burst
var _attack_left := 0.6
var _pattern := &"aimed"
var _burst_left := 0
var _emitters: Array[MeshInstance3D] = []
var _core: MeshInstance3D
var _glow_materials: Array[ShaderMaterial] = []
var _hover: AudioStreamPlayer3D
var _bar_layer: CanvasLayer
var _bar: ProgressBar
var _death_tween: Tween
var _contact_refresh := 0.0
var minions_alive := 0 # Written by the level director every frame.
var summons := 0
var _summon_cooldown := 1.6
var beams := 0
var _beam_x := 0.0
var _beam_box: DamageHitbox3D
var _beam_visual: MeshInstance3D
var _beam_column: MeshInstance3D
var _beam_mark: MeshInstance3D
## BOSS v2
var side := 1.0 # +1 right of the camera centre, -1 left.
var entry_side := 1.0 # Set by the director before begin(): alternates between attempts.
var side_switches := 0
var mines_thrown := 0
var crossing := false
var hazards: Array[Dictionary] = [] # {"kind", "telegraph"} per damaging spawn (balance test).
var untelegraphed_damage := 0 # Damage dealt by sources without a telegraph (only the hull contact).
var _cross_from := 0.0
var _cross_t := 0.0
var _side_timer := 0.0
var _phase_label: Label
var _beam_tele_total := BEAM_TELEGRAPH
## LOTE 9 · ETAPA C
var phases_seen: Array[int] = [] # Phases entered in this fight (tests).
var shield_up := false
var shield_raises := 0
var shield_windows := 0 # Times the shield dropped after its nodes were broken.
var shield_nodes: Array[UfoShieldNode] = []
var _shield_step := &"off" # off | up | window | reform
var _shield_left := 0.0
var _shield_visual: MeshInstance3D
var _shield_area: DamageHurtbox3D
var _shield_health: HealthComponent
var shield_absorbed := 0
var bombs_taken := 0
var fight_seconds := 0.0 # From PHASE_1 to DEATH.
var _fury_material: StandardMaterial3D
var _hull_tokens := HULL_BURST
var assault: BeeUfoAssault
var honey_spawned := 0


func _ready() -> void:
	health.max_health = max_hp
	health.current_health = max_hp
	health.damage_blocked = true
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_die)
	hurtbox.monitorable = false
	contact.team_id = &"alien"
	contact.damage = CONTACT_DAMAGE
	contact.set_enabled(false)
	contact.hit_confirmed.connect(func(h: DamageHurtbox3D, applied: int): if h.owner_entity is BeePlayer: untelegraphed_damage += applied) # Props it brushes do not count.
	hurtbox.scale = Vector3.ONE * (VISUAL_SCALE / 0.8) # Collider authored for a 0.8 scale visual.
	contact.scale = Vector3.ONE * (VISUAL_SCALE / 0.8)
	_build_visual()
	_build_health_bar()
	_build_beam()
	_build_shield()
	assault = BeeUfoAssault.new()
	add_child(assault)
	_hover = AudioStreamPlayer3D.new()
	_hover.name = "HoverLoop"
	var source := load("res://audio/sfx/real/ufo_hover.wav") as AudioStreamWAV
	if source != null:
		var stream := source.duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
		_hover.stream = stream
	_hover.bus = &"SFX"
	_hover.volume_db = -60.0
	_hover.unit_size = 12.0
	_hover.max_distance = 60.0
	add_child(_hover)
	set_physics_process(false)


## Called by the level controller once the last encounter is cleared and the arena is locked.
func begin(stage_camera: Camera3D, bee: BeePlayer) -> void:
	camera = stage_camera
	target = bee
	side = signf(entry_side) if entry_side != 0.0 else 1.0
	anchor = Vector3(camera.global_position.x + side * ANCHOR_DX, CENTER_Y, 0.0)
	global_position = anchor + _start_offset()
	state = State.APPROACH
	_state_time = 0.0
	visual_root.scale = Vector3.ONE * VISUAL_SCALE
	_play_long("res://audio/sfx/real/ufo_sting.wav", "UfoSting", -12.0)
	if DisplayServer.get_name() != "headless" and _hover.stream != null:
		_hover.play()
	create_tween().tween_property(_hover, "volume_db", -22.0, APPROACH_SECONDS)
	set_physics_process(true)


func is_active() -> bool:
	return state in [State.PHASE_1, State.PHASE_2, State.PHASE_3, State.PHASE_4, State.PHASE_5, State.TRANSITION]


## LOTE 9: what the Alien Bomb does to the saucer (BeeAlienBomb asks the entity it hits).
func bomb_damage_for(_base: int) -> int:
	bombs_taken += 1
	return maxi(1, roundi(float(max_hp) * BOMB_FRACTION))


func is_defeated() -> bool:
	return state == State.DEATH or state == State.DONE


func is_vulnerable() -> bool:
	return is_active() and not health.damage_blocked


func live_projectiles() -> Array:
	return get_tree().get_nodes_in_group(PROJECTILE_GROUP).filter(func(p: Node): return not p.is_queued_for_deletion())


func _start_offset() -> Vector3:
	return Vector3(START_OFFSET.x * side, START_OFFSET.y, START_OFFSET.z)


## Bee defeated: everything stops in place (the scene is reloaded by R).
func freeze() -> void:
	for node in shield_nodes:
		if is_instance_valid(node):
			node.set_physics_process(false)
	set_physics_process(false)
	_cancel_beam()
	for mine in live_mines():
		mine.freeze()
	contact.set_enabled(false)
	_set_charge(0.0)
	if _hover != null:
		_hover.stop()


func _physics_process(delta: float) -> void:
	_hull_tokens = minf(HULL_BURST, _hull_tokens + max_hp * (EASY_HULL_DPS_RATIO if BeeGameSettings.difficulty == BeeGameSettings.EASY else HULL_DPS_RATIO) * delta)
	_state_time += delta
	match state:
		State.APPROACH:
			var t := clampf(_state_time / APPROACH_SECONDS, 0.0, 1.0)
			var eased := 1.0 - pow(1.0 - t, 3.0)
			global_position = (anchor + _start_offset()).lerp(anchor, eased)
			visual_root.rotation.y += delta * lerpf(2.6, 0.6, t)
			_set_glow(lerpf(3.0, 1.0, t))
			if t >= 1.0:
				_enter_fight()
		State.PHASE_1, State.PHASE_2, State.PHASE_3, State.PHASE_4, State.PHASE_5:
			fight_seconds += delta
			_move(delta)
			_attack(delta)
			_refresh_contact(delta)
			if state == State.PHASE_2:
				_update_shield(delta)
			if state in [State.PHASE_4, State.PHASE_5]:
				_fury_pulse()
		State.TRANSITION:
			fight_seconds += delta
			_move(delta) # BOSS v2: the phase change is a crossing to the other side (see _begin_cross).
			var pulse := sin(clampf(_state_time / CROSS_SECONDS, 0.0, 1.0) * PI)
			_core.scale = Vector3.ONE * (1.0 + 0.5 * pulse)
			_set_glow(1.0 + 2.5 * pulse)
			if _state_time >= maxf(TRANSITION_SECONDS, CROSS_SECONDS) and not crossing:
				_core.scale = Vector3.ONE
				_set_glow(1.0)
				_change_state(_next_state)
				_attack_step = &"cooldown"
				_attack_left = 0.5


func _enter_fight() -> void:
	global_position = anchor
	health.damage_blocked = false
	hurtbox.set_deferred("monitorable", true)
	add_to_group("bee_auto_aim_targets")
	contact.set_enabled(true)
	_bar_layer.visible = true
	_bob_time = 0.0
	_attack_step = &"cooldown"
	_attack_left = 0.8
	_change_state(State.PHASE_1)
	_update_phase_label()


func _change_state(value: int) -> void:
	state = value
	_state_time = 0.0
	if value in [State.PHASE_1, State.PHASE_2, State.PHASE_3, State.PHASE_4, State.PHASE_5] and not (value in phases_seen):
		phases_seen.append(value)
		if value == State.PHASE_2:
			_raise_shield() # LOTE 9: phase 2 opens with the shield up.
		elif value == State.PHASE_4:
			_enter_fury()
	if value in [State.PHASE_3, State.PHASE_5]:
		_drop_honey()
	if value == State.PHASE_5:
		var mat := _core.get_surface_override_material(0) as ShaderMaterial
		mat.set_shader_parameter("albedo", OVERLOAD_COLOR)
		mat.set_shader_parameter("emission", OVERLOAD_COLOR)
	phase_changed.emit(state)


func _tuning() -> Array:
	return PHASE_TUNING.get(state if state != State.TRANSITION else _next_state, PHASE_TUNING[State.PHASE_1])


func _move(delta: float) -> void:
	if assault != null and assault.busy and assault.kind == &"ram":
		return
	var tuning := _tuning()
	_bob_time += delta
	var phase: int = state if state != State.TRANSITION else _next_state
	var period := float(tuning[1])
	var y := CENTER_Y + sin(_bob_time * TAU / period) * float(tuning[0])
	var cam_x := camera.global_position.x if camera != null else anchor.x - side * ANCHOR_DX
	var half := 6.3
	if camera != null:
		half = BeeShmupFairness.visible_half_width(camera, Vector3(cam_x, y, 0.0), BeeLevel01Framing.view_aspect(get_viewport()))
	anchor.x = cam_x + side * ANCHOR_DX
	if crossing:
		_cross(delta, cam_x, y)
		return
	# Figure-eight: X runs at half the vertical frequency; from phase 2 a slow approach / retreat towards the centre.
	var rel := ANCHOR_DX + sin(_bob_time * PI / period) * float(MOVE_X.get(phase, 0.35)) \
			- maxf(0.0, sin(_bob_time * 0.42)) * float(APPROACH_X.get(phase, 0.0))
	rel = clampf(rel, X_MIN, half - X_EDGE)
	global_position = Vector3(cam_x + side * rel, y, 0.0)
	visual_root.rotation.y += delta * 0.6
	visual_root.rotation.z = lerpf(visual_root.rotation.z, cos(_bob_time * TAU / float(tuning[1])) * 0.08, delta * 3.0)


## BOSS v2: fly to the other side of the screen (high arc, harmless hull, no attacks).
func _begin_cross() -> void:
	var cam_x := camera.global_position.x if camera != null else anchor.x - side * ANCHOR_DX
	crossing = true
	_cross_from = global_position.x - cam_x
	_cross_t = 0.0
	side = -side
	side_switches += 1
	contact.set_enabled(false)
	BeeAudio.play(get_parent(), &"ufo_charge", global_position, 0.55)


func _cross(delta: float, cam_x: float, y: float) -> void:
	_cross_t += delta
	var k := smoothstep(0.0, 1.0, _cross_t / CROSS_SECONDS)
	var x := lerpf(_cross_from, side * ANCHOR_DX, k)
	var top := BeeLevel01Framing.top_y() - 1.5 # The dome stays inside the frame.
	global_position = Vector3(cam_x + x, minf(y + CROSS_LIFT * sin(k * PI), top), 0.0)
	visual_root.rotation.z = lerpf(visual_root.rotation.z, -side * 0.25 * sin(k * PI), delta * 6.0) # Banks into the turn.
	if _cross_t >= CROSS_SECONDS:
		crossing = false
		contact.set_enabled(true)
		_contact_refresh = 1.5


func _refresh_contact(delta: float) -> void:
	if assault != null and assault.busy:
		return
	if crossing:
		return
	# The contact hitbox hits once per enable; re-arm it so touching the hull keeps hurting.
	_contact_refresh -= delta
	if _contact_refresh <= 0.0:
		_contact_refresh = 1.5
		contact.set_enabled(true)


# --- attacks ----------------------------------------------------------------------------------

func _attack(delta: float) -> void:
	if assault != null and assault.busy:
		return
	if crossing:
		return # No attack while it changes side.
	if SIDE_SWITCH.has(state): # LOTE 9: phase 3 every 4.5 s, phase 4 every 3.5 s.
		_side_timer -= delta
		if _side_timer <= 0.0 and _attack_step == &"cooldown": # Never in the middle of a pattern.
			_side_timer = float(SIDE_SWITCH[state])
			_begin_cross()
			return
	_attack_left -= delta
	var tuning := _tuning()
	if state in [State.PHASE_3, State.PHASE_5]: # LOTE 10: line drones in phase 3 only (phase 2 has its shield nodes).
		_summon_cooldown -= delta
	match _attack_step:
		&"summon":
			# Pressure dip: no attack while the hatch opens (the core pulses), then the minions launch.
			var pulse := sin(clampf(1.0 - _attack_left / SUMMON_SECONDS, 0.0, 1.0) * PI)
			_core.scale = Vector3.ONE * (1.0 + 0.6 * pulse)
			_set_glow(1.0 + 2.0 * pulse)
			if _attack_left <= 0.0:
				_core.scale = Vector3.ONE
				_set_glow(1.0)
				var family := &"Probe"
				var count := maxi(int(MAX_MINIONS.get(state, 0)) - minions_alive, 0)

				summon_requested.emit(family, count)
				summons += 1
				_summon_cooldown = float(MINION_COOLDOWN.get(state, 12.0))
				_attack_step = &"cooldown"
				_attack_left = 0.8
		&"cooldown":
			if _attack_left <= 0.0 and _wants_summon():
				_attack_step = &"summon"
				_attack_left = SUMMON_SECONDS
				BeeAudio.play(get_parent(), &"ufo_charge", global_position, 0.7)
			elif _attack_left <= 0.0:
				_pattern = _choose_pattern()
				if _pattern == &"beam" and not live_mines().is_empty():
					_attack_left = 0.2 # LOTE 9: in phase 3 the beam never closes a lane while mines still hang (fury does it on purpose).
					return
				if _pattern == &"beam" or _pattern == &"combo":
					_start_beam()
					return
				if _pattern == &"mines":
					_attack_step = &"mine_tele"
					_attack_left = MINE_TELEGRAPH
					attacks_started += 1
					BeeAudio.play(get_parent(), &"ufo_charge", global_position, 0.7)
					return
				_attack_step = &"telegraph"
				_attack_left = float(tuning[3]) if _pattern == &"aimed" else float(tuning[4])
				attacks_started += 1
				BeeAudio.play(get_parent(), &"ufo_charge", global_position, 1.2 if _pattern == &"aimed" else 0.85)
		&"mine_tele":
			_set_charge(1.0 - _attack_left / MINE_TELEGRAPH)
			if _attack_left <= 0.0:
				_set_charge(0.0)
				_throw_mines()
				_attack_step = &"cooldown"
				_attack_left = float(tuning[2])
		&"beam_tele":
			_update_beam_telegraph()
			if _attack_left <= 0.0:
				_fire_beam()
		&"beam_on":
			if _attack_left <= 0.0:
				_end_beam()
				_attack_step = &"cooldown"
				_attack_left = float(tuning[2])
		&"telegraph":
			var total := float(tuning[3]) if _pattern == &"aimed" else float(tuning[4])
			_set_charge(1.0 - _attack_left / total)
			if _attack_left <= 0.0:
				_set_charge(0.0)
				hazards.append({"kind": _pattern, "telegraph": total})
				if _pattern == &"fan" or _pattern == &"fan_aimed":
					_fire_fan()
				if _pattern == &"aimed" or _pattern == &"fan_aimed":
					_attack_step = &"burst"
					_burst_left = int(AIMED_SHOTS_BY_PHASE.get(state, AIMED_SHOTS))
					_attack_left = 0.0 if _pattern == &"aimed" else 0.35
				else:
					_attack_step = &"cooldown"
					_attack_left = float(tuning[2])
		&"burst":
			if _attack_left <= 0.0:
				_fire_aimed()
				_burst_left -= 1
				_attack_left = float(AIMED_INTERVAL_BY_PHASE.get(state, AIMED_INTERVAL))
				if _burst_left <= 0:
					_attack_step = &"cooldown"
					_attack_left = float(tuning[2])


func _wants_summon() -> bool:
	var cap := int(MAX_MINIONS.get(state, 0))
	if cap <= 0 or _summon_cooldown > 0.0 or minions_alive > 0:
		return false
	if state == State.PHASE_3: # Only when the screen is clean enough: never a minion on top of a full pattern.
		return get_tree().get_nodes_in_group("alien_projectiles").size() <= 4
	return true


func _choose_pattern() -> StringName:
	match state:
		State.PHASE_1: # LOTE 9: fast aimed bursts, an aimed fan every third attack.
			return &"fan_aimed" if attacks_started % 3 == 2 else &"aimed"
		State.PHASE_2: # Mines alternate with aimed bursts while the shield nodes orbit.
			return &"mines" if attacks_started % 2 == 1 else &"aimed"
		State.PHASE_3: # LOTE 9: the tractor beam every other attack (was every third).
			return [&"beam", &"aimed", &"beam", &"mines"][attacks_started % 4]
		_: # PHASE 4 fury: beam + mines together, then fans and long bursts.
			return [&"combo", &"fan_aimed", &"aimed"][attacks_started % 3]


func _muzzle_for_aimed() -> Vector3:
	# The emitter closest to Bee fires; the visual and the origin match.
	var best := global_position
	var best_distance := INF
	for emitter in _emitters:
		var p := emitter.global_position
		var d := p.distance_to(target.global_position)
		if d < best_distance:
			best_distance = d
			best = p
	return Vector3(best.x, best.y, 0.0)


func _fire_aimed() -> void:
	if target == null or not BeeShmupFairness.can_fire(self):
		return
	var origin := _muzzle_for_aimed()
	var direction := target.global_position - origin # Bee's position at the moment of this shot.
	_spawn_projectile(origin, Vector3(direction.x, direction.y, 0.0).normalized(), float(AIMED_SPEED_BY_PHASE.get(state, AIMED_SPEED)), &"aimed")
	fired_aimed += 1


func _fire_fan() -> void:
	if target == null or not BeeShmupFairness.can_fire(self):
		return
	var origin := Vector3(_core.global_position.x, _core.global_position.y, 0.0)
	var to_bee := target.global_position - origin
	var base := atan2(to_bee.y, to_bee.x)
	for i in FAN_SHOTS:
		var angle := base + deg_to_rad(FAN_STEP_DEGREES) * (float(i) - float(FAN_SHOTS - 1) * 0.5)
		_spawn_projectile(origin, Vector3(cos(angle), sin(angle), 0.0), FAN_SPEED, &"fan")
		fired_fan += 1


func _spawn_projectile(origin: Vector3, direction: Vector3, speed: float, pattern: StringName) -> void:
	var projectile := PROJECTILE.instantiate() as AlienEnemyProjectile
	projectile.damage = SHOT_DAMAGE
	projectile.speed = speed
	projectile.add_to_group(PROJECTILE_GROUP)
	get_parent().add_child(projectile)
	projectile.global_position = origin
	projectile.rotation.z = atan2(direction.y, direction.x) # Trail points backwards.
	projectile.launch(direction, self)
	projectile_fired.emit(projectile, pattern)


func clear_projectiles() -> int:
	var cleared := 0
	for node in get_tree().get_nodes_in_group(PROJECTILE_GROUP):
		var projectile := node as AlienEnemyProjectile
		if projectile == null or projectile.is_queued_for_deletion():
			continue
		projectile.hitbox.set_enabled(false)
		projectile.queue_free()
		cleared += 1
	return cleared


# --- BOSS v2: mines -----------------------------------------------------------------------------

## One mine on Bee's spot at the moment of the throw, the others MINE_SPREAD m to the sides (alternating), all clamped
## inside the visible play area. The warning ring + drawn radius is the telegraph (TRAVEL + fuse seconds).
func _throw_mines() -> void:
	if target == null or not BeeShmupFairness.can_fire(self):
		return
	var count := int(MINE_COUNT.get(state, 2))
	var fuse := float(MINE_FUSE.get(state, 2.0))
	var cam_x := camera.global_position.x if camera != null else global_position.x
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport())) - MINE_RADIUS * 0.6
	var low := BeeLevel01Framing.bottom_y() + 0.9
	var high := BeeLevel01Framing.top_y() - 1.0
	var origin := Vector3(_core.global_position.x, _core.global_position.y, 0.0)
	for i in count:
		var offset := 0.0 if i == 0 else MINE_SPREAD * float((i + 1) / 2) * (1.0 if i % 2 == 1 else -1.0)
		var spot := Vector3(clampf(target.global_position.x + offset, cam_x - half, cam_x + half),
				clampf(target.global_position.y + (0.8 if i % 2 == 1 else -0.6) * float(i > 0), low, high), 0.0)
		var mine := UfoBossMine.new()
		mine.name = "UfoMine"
		mine.fuse = fuse
		mine.radius = MINE_RADIUS
		mine.damage = MINE_DAMAGE
		mine.attacker = self
		get_parent().add_child(mine)
		mine.throw(origin, spot)
		mines_thrown += 1
		hazards.append({"kind": &"mine", "telegraph": UfoBossMine.TRAVEL + fuse})
	BeeAudio.play(get_parent(), &"tech_hit", origin, 0.7)


func live_mines() -> Array:
	return get_tree().get_nodes_in_group("ufo_boss_mines").filter(func(m: Node): return not m.is_queued_for_deletion())


func clear_mines() -> void:
	for mine in live_mines():
		mine.defuse()


# --- BOSS v2: phase label on the bar ---------------------------------------------------------------

func current_phase_number() -> int:
	var phase: int = _next_state if state == State.TRANSITION else state
	return clampi(phase - State.PHASE_1 + 1, 1, 5)


func _update_phase_label() -> void:
	if _phase_label != null:
		_phase_label.text = "FASE %d / 5" % current_phase_number() if current_phase_number() < 5 else "FASE 5 / 5 · SOBRECARGA"


# --- tractor beam (phase 3) --------------------------------------------------------------------

func _unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _build_beam() -> void:
	var height := BEAM_TOP_Y - BEAM_GROUND_Y
	_beam_box = DamageHitbox3D.new()
	_beam_box.name = "BeamHitbox"
	_beam_box.team_id = &"alien"
	_beam_box.damage = BEAM_DAMAGE
	_beam_box.collision_layer = 0
	_beam_box.collision_mask = 2
	_beam_box.top_level = true # The column stays where it was marked while the saucer keeps moving.
	add_child(_beam_box)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(BEAM_WIDTH * 0.9, height, 1.2) # Slightly narrower than the drawn column.
	shape.shape = box
	_beam_box.add_child(shape)
	_beam_box.attacker = self
	_beam_visual = MeshInstance3D.new()
	_beam_visual.name = "BeamVisual"
	var column := BoxMesh.new()
	column.size = Vector3(BEAM_WIDTH, height, 0.5)
	column.material = _unshaded(Color(0.3, 1.0, 1.0, 0.55))
	_beam_visual.mesh = column
	_beam_visual.visible = false
	_beam_visual.top_level = true
	add_child(_beam_visual)
	# Telegraph: a faint column outline and a pulsing mark on the ground at the locked X.
	_beam_column = MeshInstance3D.new()
	_beam_column.name = "BeamWarningColumn"
	var faint := BoxMesh.new()
	faint.size = Vector3(BEAM_WIDTH, height, 0.5)
	faint.material = _unshaded(Color(1.0, 0.6, 0.2, 0.2))
	_beam_column.mesh = faint
	_beam_column.visible = false
	_beam_column.top_level = true
	add_child(_beam_column)
	_beam_mark = MeshInstance3D.new()
	_beam_mark.name = "BeamGroundMark"
	var disc := CylinderMesh.new()
	disc.top_radius = BEAM_WIDTH * 0.62
	disc.bottom_radius = BEAM_WIDTH * 0.62
	disc.height = 0.02
	disc.radial_segments = 20
	disc.material = _unshaded(Color(1.0, 0.55, 0.15, 0.8))
	_beam_mark.mesh = disc
	_beam_mark.visible = false
	_beam_mark.top_level = true
	add_child(_beam_mark)


func _start_beam() -> void:
	attacks_started += 1
	beams += 1
	var half := BeeShmupFairness.visible_half_width(camera, Vector3(camera.global_position.x, 3.0, 0.0), BeeLevel01Framing.view_aspect(get_viewport())) \
			if camera != null else 6.0
	var bee_x := target.global_position.x if target != null else global_position.x
	var cam_x := camera.global_position.x if camera != null else 0.0
	_beam_x = clampf(bee_x, cam_x - half + BEAM_WIDTH, cam_x + half - BEAM_WIDTH) # Locked here: moving away dodges it.
	var mid := Vector3(_beam_x, (BEAM_TOP_Y + BEAM_GROUND_Y) * 0.5, 0.0)
	_beam_column.global_position = mid
	_beam_column.visible = true
	_beam_mark.global_position = Vector3(_beam_x, BEAM_GROUND_Y + 0.04, 0.0)
	_beam_mark.scale = Vector3(0.3, 1.0, 0.3)
	_beam_mark.visible = true
	_attack_step = &"beam_tele"
	_beam_tele_total = float(BEAM_TELEGRAPH_BY_PHASE.get(state, BEAM_TELEGRAPH))
	_attack_left = _beam_tele_total
	BeeAudio.play(get_parent(), &"ufo_charge", global_position, 0.5)
	if _pattern == &"combo":
		_throw_mines() # LOTE 9 fury: mines (their own TRAVEL + fuse warning) while the beam column is marked.


func _update_beam_telegraph() -> void:
	var progress := clampf(1.0 - _attack_left / _beam_tele_total, 0.0, 1.0)
	_set_charge(progress)
	var s := lerpf(0.3, 1.0, progress)
	_beam_mark.scale = Vector3(s, 1.0, s)
	var blink := 0.5 + 0.5 * sin(progress * TAU * 3.0)
	((_beam_mark.mesh as CylinderMesh).material as StandardMaterial3D).albedo_color = Color(1.0, 0.35 + 0.4 * blink, 0.1, 0.65 + 0.3 * progress)


func _fire_beam() -> void:
	hazards.append({"kind": &"beam", "telegraph": _beam_tele_total})
	_set_charge(0.0)
	_beam_column.visible = false
	_beam_mark.visible = false
	_beam_visual.global_position = Vector3(_beam_x, (BEAM_TOP_Y + BEAM_GROUND_Y) * 0.5, 0.0)
	_beam_visual.visible = true
	_beam_box.global_position = _beam_visual.global_position
	_beam_box.set_enabled(true) # One hit per exposure: the hitbox ignores a target it already hit until re-enabled.
	_attack_step = &"beam_on"
	_attack_left = BEAM_ACTIVE
	BeeCameraShake.kick(self, 0.02, 0.2)


func _end_beam() -> void:
	_beam_box.set_enabled(false)
	_beam_visual.visible = false


func _cancel_beam() -> void:
	if _beam_box == null:
		return
	_beam_box.set_enabled(false)
	_beam_visual.visible = false
	_beam_column.visible = false
	_beam_mark.visible = false


func beam_active() -> bool:
	return _attack_step == &"beam_on" and is_physics_processing()


# --- health and phases ------------------------------------------------------------------------

func _on_health_changed(current: int, maximum: int, change: int) -> void:
	if _bar != null:
		_bar.value = float(current) / float(maximum) * 100.0
	if change < 0 and current > 0:
		var punch := create_tween()
		punch.tween_property(visual_root, "scale", Vector3.ONE * VISUAL_SCALE * 1.05, 0.05)
		punch.tween_property(visual_root, "scale", Vector3.ONE * VISUAL_SCALE, 0.08)
	if not (state in [State.PHASE_1, State.PHASE_2, State.PHASE_3, State.PHASE_4, State.PHASE_5]) or current <= 0:
		return
	var ratio := float(current) / float(maximum)
	var wanted: int = State.PHASE_1
	if ratio <= PHASE_5_RATIO:
		wanted = State.PHASE_5
	elif ratio <= PHASE_4_RATIO:
		wanted = State.PHASE_4
	elif ratio <= PHASE_3_RATIO:
		wanted = State.PHASE_3
	elif ratio <= PHASE_2_RATIO:
		wanted = State.PHASE_2
	wanted = mini(wanted, state + 1) # LOTE 9: one phase at a time (a big hit never skips a phase).
	if wanted > state:
		_next_state = wanted
		_summon_cooldown = 3.0
		if state == State.PHASE_2:
			_clear_shield() # LOTE 9: leaving phase 2 the shield and its nodes go.
		transitions += 1
		_set_charge(0.0)
		_cancel_beam()
		_attack_step = &"cooldown"
		_side_timer = SIDE_SWITCH_P3
		_change_state(State.TRANSITION)
		if not crossing:
			_begin_cross() # BOSS v2: every phase change moves the saucer to the other side.
		_update_phase_label()


## LOTE 9 · ETAPA C — death cinematic: DEATH_SPARKS chained blasts while it falls (DEATH_SPARK_GAP s apart) with a growing
## light, then a double main explosion with a white screen flash, and DEATH_AFTERGLOW s before SECTOR DESPEJADO.
## BEFORE: 4 sparks 0.3 s apart + one explosion (~2.3 s).
const DEATH_SPARKS := 8
const DEATH_SPARK_GAP := 0.22
const DEATH_AFTERGLOW := 1.3
const DEATH_FLASH := Color(1.0, 0.97, 0.85, 0.75)


func _die() -> void:
	if is_defeated():
		return
	_change_state(State.DEATH)
	health.damage_blocked = true
	contact.set_enabled(false)
	hurtbox.set_deferred("monitorable", false)
	remove_from_group("bee_auto_aim_targets")
	_cancel_beam()
	assault.cancel()
	_clear_shield()
	_set_charge(0.0)
	clear_projectiles() # No unfair hit after the win.
	clear_mines()
	crossing = false
	_bar_layer.visible = false
	set_physics_process(false)
	hit_flash.flash()
	BeeAudio.play(get_parent(), &"tech_death", global_position)
	var fall_seconds := DEATH_SPARKS * DEATH_SPARK_GAP + 0.4
	var fall := create_tween().set_parallel(true)
	fall.tween_property(self, "global_position", global_position + Vector3(0.6, -2.4, 0.0), fall_seconds).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(visual_root, "rotation:z", 0.75, fall_seconds)
	fall.tween_method(_set_glow, 2.5, 4.0, fall_seconds) # It burns brighter while it breaks apart.
	fall.tween_property(_hover, "volume_db", -60.0, 1.2)
	var light := OmniLight3D.new()
	light.name = "DeathLight"
	light.light_color = Color(0.6, 0.95, 1.0)
	light.omni_range = 9.0
	light.light_energy = 0.0
	light.shadow_enabled = false
	add_child(light)
	fall.tween_property(light, "light_energy", 6.0, fall_seconds)
	_death_tween = create_tween()
	for i in DEATH_SPARKS:
		_death_tween.tween_callback(_spark.bind(i))
		_death_tween.tween_interval(DEATH_SPARK_GAP)
	_death_tween.tween_callback(_main_explosion)
	_death_tween.tween_interval(0.35)
	_death_tween.tween_callback(_second_explosion)
	_death_tween.tween_interval(DEATH_AFTERGLOW)
	_death_tween.tween_callback(_finish)


## Seconds from the killing blow to `defeated` (tests).
static func death_seconds() -> float:
	return DEATH_SPARKS * DEATH_SPARK_GAP + 0.35 + DEATH_AFTERGLOW


func _spark(index: int) -> void:
	var angle := float(index) * 2.4
	var offset := Vector3(cos(angle) * (0.6 + 0.12 * index), sin(angle) * 0.4, 0.4)
	BeeCombatVFX.spawn(get_parent(), global_position + offset, &"tech_death", Vector3.RIGHT, 0.8 + 0.08 * index)
	BeeAudio.play(get_parent(), &"tech_hit", global_position + offset, 0.8)
	BeeCameraShake.kick(self, 0.03 + 0.005 * index, 0.15)


func _main_explosion() -> void:
	BeeCombatVFX.spawn(get_parent(), global_position, &"bomb", Vector3.RIGHT, 4.6)
	BeeCombatVFX.spawn(get_parent(), global_position, &"heavy_death", Vector3.RIGHT, 3.8) # REBUILD 03: layered blast.
	BeeCameraShake.kick(self, 0.14, 0.7)
	_play_long("res://audio/sfx/real/ufo_death.wav", "UfoDeath", -9.0)
	visual_root.hide()
	_screen_flash()
	var light := get_node_or_null("DeathLight") as OmniLight3D
	if light != null:
		light.light_energy = 12.0
		create_tween().tween_property(light, "light_energy", 0.0, DEATH_AFTERGLOW + 0.3)


func _second_explosion() -> void:
	for side in [-1.0, 1.0]:
		BeeCombatVFX.spawn(get_parent(), global_position + Vector3(side * 1.4, 0.3, 0.3), &"bomb", Vector3.RIGHT, 2.6)
	BeeCombatVFX.spawn(get_parent(), global_position, &"tech_death", Vector3.UP, 2.4)
	BeeCameraShake.kick(self, 0.08, 0.4)


## A short white flash over the whole screen (the brightest moment of the level).
func _screen_flash() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DeathFlash"
	layer.layer = 6
	get_parent().add_child(layer)
	var rect := ColorRect.new()
	rect.color = DEATH_FLASH
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	var fade := layer.create_tween()
	fade.tween_property(rect, "color:a", 0.0, 0.7)
	fade.tween_callback(layer.queue_free)


func _finish() -> void:
	_hover.stop()
	state = State.DONE
	defeated.emit(self)
	queue_free()


# --- visuals ----------------------------------------------------------------------------------

func _material(color: Color, emissive := false, energy := 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = energy
	return material


func _part(mesh: Mesh, material: StandardMaterial3D, label: String, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	if mesh is PrimitiveMesh:
		(mesh as PrimitiveMesh).material = material
	else:
		mesh.surface_set_material(0, material)
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	visual_root.add_child(node)
	return node


## Compact saucer: lower core, wide hull, outer ring, glass dome, 4 emitters, 4 small fins.
func _build_visual() -> void:
	var hull := GardenProps.loft([[-0.38, 0.45, 0.45, 0, 0], [-0.28, 0.95, 0.95, 0, 0], [-0.1, 1.42, 1.42, 0, 0], [0.0, 1.55, 1.55, 0, 0],
			[0.1, 1.45, 1.45, 0, 0], [0.22, 1.05, 1.05, 0, 0], [0.32, 0.64, 0.64, 0, 0]], 24, true, true, 0.0, true)
	_part(hull, _material(COLORS["hull"]), "Hull")
	var ring := TorusMesh.new()
	ring.inner_radius = 1.5
	ring.outer_radius = 1.7
	ring.rings = 28
	ring.ring_segments = 8
	_part(ring, _material(COLORS["ring"]), "OuterRing")
	var dome := SphereMesh.new()
	dome.radius = 0.62
	dome.height = 0.62
	dome.is_hemisphere = true
	dome.radial_segments = 20
	dome.rings = 6
	_part(dome, _material(COLORS["dome"], true, 0.9), "Dome", Vector3(0, 0.3, 0))
	var core := SphereMesh.new()
	core.radius = 0.34
	core.height = 0.5
	core.radial_segments = 16
	core.rings = 8
	_core = _part(core, _material(COLORS["core"], true, 1.2), "AlienCore", Vector3(0, -0.42, 0))
	for i in 4:
		var a := TAU * (float(i) + 0.5) / 4.0
		var emitter := SphereMesh.new()
		emitter.radius = 0.15
		emitter.height = 0.24
		emitter.radial_segments = 10
		emitter.rings = 5
		_emitters.append(_part(emitter, _material(COLORS["emitter"], true, 2.0), "Emitter%d" % i, Vector3(cos(a) * 1.08, -0.24, sin(a) * 1.08)))
		var fin := BoxMesh.new()
		fin.size = Vector3(0.38, 0.09, 0.2)
		var b := TAU * float(i) / 4.0
		_part(fin, _material(COLORS["panel"]), "Fin%d" % i, Vector3(cos(b) * 1.62, 0.06, sin(b) * 1.62), Vector3(0, -b, 0))
	BeeToonStyle.apply(visual_root, true, BeeToonStyle.OUTLINE_ACTOR)
	# Own copies of the glowing materials so telegraphs never touch other actors.
	var glowing: Array[MeshInstance3D] = [_core, visual_root.get_node("Dome") as MeshInstance3D]
	glowing.append_array(_emitters)
	for node: MeshInstance3D in glowing:
		var shared := node.get_surface_override_material(0) as ShaderMaterial
		var own := shared.duplicate() as ShaderMaterial
		own.set_meta("base_energy", own.get_shader_parameter("emission_energy"))
		node.set_surface_override_material(0, own)
		_glow_materials.append(own)


func _set_glow(multiplier: float) -> void:
	for material in _glow_materials:
		material.set_shader_parameter("emission_energy", float(material.get_meta("base_energy")) * multiplier)


## Telegraph: emitters (aimed) or the lower core (fan) swell and brighten while charging.
func _set_charge(progress: float) -> void:
	var fan := _pattern != &"aimed"
	for emitter in _emitters:
		emitter.scale = Vector3.ONE * (1.0 + (0.0 if fan else 0.7 * progress))
	if _core != null:
		_core.scale = Vector3.ONE * (1.0 + (0.6 * progress if fan else 0.0))
	for material in _glow_materials:
		material.set_shader_parameter("emission_energy", float(material.get_meta("base_energy")) * (1.0 + 2.2 * progress))


func _build_health_bar() -> void:
	_bar_layer = CanvasLayer.new()
	_bar_layer.name = "BossHealthBar"
	_bar_layer.layer = 5
	_bar_layer.visible = false
	add_child(_bar_layer)
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.offset_left = -220.0
	box.offset_right = 220.0
	box.offset_top = 14.0
	_bar_layer.add_child(box)
	var title := Label.new()
	title.text = DISPLAY_NAME
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 5)
	box.add_child(title)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(440, 14)
	_bar.show_percentage = false
	_bar.value = 100.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.72, 0.25, 1.0)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.08, 0.06, 0.12, 0.75)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", back)
	box.add_child(_bar)
	# BOSS v2: phase ticks at 66 % and 33 % and the current phase under the bar.
	for ratio in [PHASE_2_RATIO, PHASE_3_RATIO, PHASE_4_RATIO, PHASE_5_RATIO]:
		var tick := ColorRect.new()
		tick.color = Color(1.0, 1.0, 1.0, 0.85)
		tick.size = Vector2(2, 14)
		tick.position = Vector2(440.0 * ratio - 1.0, 0.0)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bar.add_child(tick)
	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 14)
	_phase_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_phase_label.add_theme_constant_override("outline_size", 4)
	box.add_child(_phase_label)
	_update_phase_label()


func health_bar_visible() -> bool:
	return _bar_layer != null and _bar_layer.visible


## Long one-shots (sting, final explosion) live under the level, not under the boss, so the
## explosion is not cut when the boss frees itself; a level reload frees them like any node.
func _play_long(path: String, label: String, volume_db: float) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = label
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = volume_db
	get_parent().add_child(player)
	player.finished.connect(player.queue_free)
	var lifetime := Timer.new() # Owned by the player: no callback can outlive it.
	lifetime.one_shot = true
	lifetime.wait_time = stream.get_length() + 0.2
	lifetime.autostart = true
	lifetime.timeout.connect(player.queue_free)
	player.add_child(lifetime)
	if DisplayServer.get_name() != "headless":
		player.play()


# --- LOTE 9 · ETAPA C: phase 2 shield ------------------------------------------------------------------------------

const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")


func _build_shield() -> void:
	_shield_visual = MeshInstance3D.new()
	_shield_visual.name = "ShieldBubble"
	var bubble := SphereMesh.new()
	bubble.radius = SHIELD_RADIUS
	bubble.height = SHIELD_RADIUS * 2.0
	bubble.radial_segments = 24
	bubble.rings = 12
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = SHIELD_COLOR
	material.emission_enabled = true
	material.emission = Color(SHIELD_COLOR, 1.0)
	material.emission_energy_multiplier = 0.6
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = 40
	bubble.material = material
	_shield_visual.mesh = bubble
	_shield_visual.scale = Vector3(1.0, 0.62, 1.0) # A flat dome around the flat saucer.
	_shield_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shield_visual.visible = false
	add_child(_shield_visual)
	# Shots on the shield are absorbed with a neutral puff (endless health that never drops).
	_shield_health = HEALTH_SCENE.instantiate() as HealthComponent
	_shield_health.name = "ShieldHealth"
	_shield_health.max_health = 1000000
	add_child(_shield_health)
	_shield_health.health_changed.connect(_on_shield_hit)
	_shield_area = HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	_shield_area.name = "ShieldHurtbox"
	_shield_area.team_id = &"alien"
	_shield_area.health_component_path = NodePath("../ShieldHealth")
	_shield_area.owner_entity_path = NodePath("..")
	_shield_area.set_meta("neutral_hit", true)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = SHIELD_RADIUS * 0.92
	shape.shape = sphere
	shape.scale = Vector3(1.0, 0.62, 1.0)
	_shield_area.add_child(shape)
	_shield_area.monitorable = false
	add_child(_shield_area)


func _on_shield_hit(_current: int, _maximum: int, change: int) -> void:
	if change >= 0:
		return
	shield_absorbed += 1
	_shield_health.current_health = _shield_health.max_health
	var material := (_shield_visual.mesh as SphereMesh).material as StandardMaterial3D
	material.albedo_color.a = 0.45
	create_tween().tween_property(material, "albedo_color:a", SHIELD_COLOR.a, 0.2)


func _raise_shield() -> void:
	shield_up = true
	shield_raises += 1
	_shield_step = &"up"
	health.damage_blocked = true
	health.damage_scale = 1.0
	_shield_visual.visible = true
	_shield_visual.scale = Vector3(0.2, 0.12, 0.2)
	create_tween().tween_property(_shield_visual, "scale", Vector3(1.0, 0.62, 1.0), 0.35).set_trans(Tween.TRANS_BACK)
	_shield_area.set_deferred("monitorable", true)
	var count := SHIELD_NODES if shield_raises == 1 else SHIELD_NODES_AGAIN
	for i in count:
		var node := UfoShieldNode.new()
		node.name = "UfoShieldNode%d" % i
		get_parent().add_child(node)
		var spread := SHIELD_ARC if count >= 3 else SHIELD_ARC * 0.6
		var offset := -spread * 0.5 + spread * float(i) / float(maxi(count - 1, 1)) # Slots on the arc facing Bee.
		node.setup(self, offset, BeeGameSettings.scaled_hp(SHIELD_NODE_HP))
		node.destroyed.connect(_on_node_destroyed)
		shield_nodes.append(node)
	BeeAudio.play(get_parent(), &"ufo_charge", global_position, 0.6)
	if _phase_label != null:
		_phase_label.text = "FASE 2 / 5 · ESCUDO: ROMPÉ LOS NODOS"


func _on_node_destroyed(node: UfoShieldNode) -> void:
	shield_nodes.erase(node)
	if shield_nodes.is_empty() and _shield_step == &"up" and state == State.PHASE_2:
		_drop_shield()


## Every node broken: the shield falls for SHIELD_WINDOW s and the saucer takes WINDOW_DAMAGE_SCALE damage.
func _drop_shield() -> void:
	shield_up = false
	shield_windows += 1
	_shield_step = &"window"
	_shield_left = SHIELD_WINDOW
	health.damage_blocked = false
	health.damage_scale = WINDOW_DAMAGE_SCALE
	_shield_area.set_deferred("monitorable", false)
	BeeLiberation.explode_tech(get_parent(), global_position, 1.2)
	BeeCameraShake.kick(self, 0.05, 0.25)
	var shrink := create_tween()
	shrink.tween_property(_shield_visual, "scale", Vector3(1.3, 0.8, 1.3), 0.12)
	shrink.tween_callback(func(): _shield_visual.visible = false)
	if _phase_label != null:
		_phase_label.text = "FASE 2 / 5 · ¡ESCUDO ABAJO!"


func _update_shield(delta: float) -> void:
	if shield_up and target != null:
		# Bee inside the bubble (hugging the saucer): her shots must still get out to the nodes.
		var rel := target.global_position - global_position
		var inside := pow(rel.x / SHIELD_RADIUS, 2.0) + pow(rel.y / (SHIELD_RADIUS * 0.62), 2.0) < 1.0
		if _shield_area.monitorable == inside:
			_shield_area.set_deferred("monitorable", not inside)
	match _shield_step:
		&"window":
			_shield_left -= delta
			if _shield_left <= 0.0:
				_shield_step = &"reform"
				_shield_left = SHIELD_REFORM
				health.damage_scale = 1.0
		&"reform":
			# Warning: the bubble flickers back before it closes again.
			_shield_left -= delta
			_shield_visual.visible = int(_shield_left * 12.0) % 2 == 0
			_shield_visual.scale = Vector3(1.0, 0.62, 1.0)
			if _shield_left <= 0.0:
				_raise_shield()


func _clear_shield() -> void:
	for node in shield_nodes:
		if is_instance_valid(node):
			node.dismiss()
	shield_nodes.clear()
	shield_up = false
	_shield_step = &"off"
	health.damage_blocked = state == State.DEATH or state == State.DONE
	health.damage_scale = 1.0
	if _shield_visual != null:
		_shield_visual.visible = false
	if _shield_area != null:
		_shield_area.set_deferred("monitorable", false)


func shield_window_open() -> bool:
	return _shield_step == &"window"


# --- LOTE 9 · ETAPA C: phase 4 fury ---------------------------------------------------------------------------------

func _enter_fury() -> void:
	for node: MeshInstance3D in [_core]:
		var material := node.get_surface_override_material(0) as ShaderMaterial
		if material != null:
			material.set_shader_parameter("albedo", FURY_COLOR)
			material.set_shader_parameter("emission", FURY_COLOR)
	BeeCameraShake.kick(self, 0.06, 0.4)
	BeeAudio.play(get_parent(), &"ufo_charge", global_position, 0.5)
	if _phase_label != null:
		_phase_label.text = "FASE 4 / 5 · FURIA"


func _fury_pulse() -> void:
	if _attack_step == &"cooldown":
		_core.scale = Vector3.ONE * (1.0 + 0.14 * absf(sin(fight_seconds * 7.0)))


func is_fury() -> bool:
	return state in [State.PHASE_4, State.PHASE_5]


func _exit_tree() -> void:
	for node in shield_nodes:
		if is_instance_valid(node):
			node.queue_free()
	shield_nodes.clear()


## Token budget applies after the shield-window multiplier. Bombs retain exactly 8%, outside the gun budget.
func limit_hull_damage(amount: int, source: DamageHitbox3D) -> int:
	if source is BeeAlienBomb:
		return roundi(float(amount) / health.damage_scale)
	if health.damage_blocked:
		return 0
	var permitted := mini(roundi(amount * health.damage_scale), floori(_hull_tokens))
	var raw := floori(permitted / health.damage_scale)
	_hull_tokens -= roundi(raw * health.damage_scale)
	return raw

func _drop_honey() -> void:
	var item := preload("res://scenes/items/toon/healing.tscn").instantiate() as Node3D
	get_parent().add_child(item)
	item.global_position = Vector3(camera.global_position.x - side * 3.8, 4.0, 0)
	honey_spawned += 1
