class_name TarantulaBoss01
extends Node3D
## LOTE 12 · ETAPA 3 — TARÁNTULA, final boss of Level 1 (the garden at dusk). Same structure as the UFO boss of Lote 10 (UfoBoss01):
## phase bar, `hazards` log with the warning of every damaging attack, sustained-DPS budget on the body (`limit_hull_damage`) so
## Spread does not trivialise it, bomb = BOMB_FRACTION of its life, honey between phases, boss checkpoint. It is an ANIMAL with an
## implant: it is never killed, breaking the implant FREES it (it calms down and walks away) and the level ends with
## "SECTOR DESPEJADO · LIBERADOS n/N".
## LOTE 15 · ETAPA 5.3 — DYNAMIC, not harder: it moves in every direction and hunts Bee (same damage per hit as before).
##   MOVES   on the GROUND it stalks towards Bee's zone; it JUMPS diagonally from one corner to the opposite one (band along the
##           path + landing shadow, JUMP_TELEGRAPH s) and CLIMBS along the top edge (upside down, crawling above Bee); from the
##           top it DROPS on a thread and swings as a PENDULUM (the thread is drawn first, HANG_TELEGRAPH s).
##   AIMED   every phase has attacks aimed at Bee: web fan from the mouth, the TRAPPING NET (TarantulaWebNet: warned 0.5 s; Bee is
##           stuck up to 2 s, can shoot but not move; shooting the net or mashing the movement keys frees her; then 1.5 s of grace
##           in which no net can trap her), small spiders dropping on Bee's column, the charge across the ground.
##   PHASE 1  100-75 %  ground: stalk, fan, net, stomp; first jump to the ceiling, spider rain, fan from above
##   PHASE 2   75-50 %  ceiling: crawl over Bee, spiders, pendulum swing (+ fan), net; the legs are ARMOURED from here on and after
##                      every big attack (stomp, charge, swing, jump) the implant is EXPOSED for EXPOSE_SECONDS (x2); flies
##   PHASE 3   50-20 %  everything mixed: charges, jumps corner to corner, swings, nets; honey when it starts
##   PHASE 4    <20 %   FURY: COMBOS of two dodgeable attacks (jump + fan, charge + spiders, swing + two fans) and the curtain
## Every attack is announced >= MIN_TELEGRAPH s before it can hurt. The stomp wave, the charge, the jump and the swing are not
## projectiles: the Lote 11 roll never destroys them (web shots and the flying net are common shots: the roll destroys them).
## Model: lvl01_boss_giant_spider_v01.glb (its implant group is a separate piece; the alien plates the roster contract does not
## want - flanks, thorax guard, sensor housing - are hidden at runtime; the leg bracers read as the armour of phase 2).

signal defeated(boss: TarantulaBoss01) # After the liberation walk-off (the level completes then).
signal liberated_now(boss: TarantulaBoss01) # The moment the implant breaks.
signal phase_changed(state: int)
signal summon_requested(family: StringName, count: int)

enum State { APPROACH, PHASE_1, PHASE_2, PHASE_3, PHASE_4, TRANSITION, FREED, DONE }

const MODEL := preload("res://assets/models/levels/level_01_garden/bosses/lvl01_boss_giant_spider_v01.glb")
const EXPOSED_OUTLINE := preload("res://assets/style/toon_outline.gdshader")
const PROJECTILE := preload("res://scenes/levels/ufo_boss_projectile.tscn")
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const PROJECTILE_GROUP := &"tarantula_projectiles"
const DISPLAY_NAME := "TARÁNTULA"
const HIDDEN_PLATES := ["implant_flank", "implant_thorax_guard", "implant_sensor_housing"]

@export var max_hp := 1200
const PHASE_2_RATIO := 0.75
const PHASE_3_RATIO := 0.50
const PHASE_4_RATIO := 0.20
## Sustained damage budget on the body (fraction of max HP per second) and its reserve; an exposed implant pays half.
const HULL_DPS_RATIO := 0.0095
const EASY_HULL_DPS_RATIO := 0.009
const HULL_BURST := 18.0
const BOMB_FRACTION := 0.08
const MIN_TELEGRAPH := 0.42
const CONTACT_DAMAGE := 8

const MODEL_SCALE := 0.8
const GROUND_Y := -0.1
const CEILING_MARGIN := 0.15 # The feet grip this far above the visible top edge.
const ANCHOR_DX := 3.3 # |x| of a corner (camera-relative) for jumps and charges.
const SCREEN_INSET := 2.2 # It never walks closer than this to a screen edge (camera-relative).
const APPROACH_SECONDS := 3.0
const TRANSITION_SECONDS := 1.1
## Model-space parts (forward -X, metres at scale 1): body box, implant, leg band, mouth, thread attachment (abdomen tip).
const BODY_CENTRE := Vector2(-0.03, 1.75)
const BODY_SIZE := Vector2(3.95, 1.8)
const IMPLANT_CENTRE := Vector2(0.55, 2.88)
const IMPLANT_RADIUS := 0.6
const LEGS_CENTRE := Vector2(0.3, 0.45)
const LEGS_SIZE := Vector2(5.2, 0.9)
const MOUTH := Vector2(-1.95, 1.0)
const ATTACH := Vector2(1.9, 1.9)

## Per phase: [cooldown between attacks, web fan shots, fan step (deg)].
const PHASE_TUNING := {
	State.PHASE_1: [1.2, 5, 15.0],
	State.PHASE_2: [1.1, 5, 15.0],
	State.PHASE_3: [1.0, 6, 13.0],
	State.PHASE_4: [0.9, 6, 13.0],
}
## The pattern of each phase. Moves that need the other surface insert a corner-to-corner JUMP first (see _start_attack).
const PATTERNS := {
	State.PHASE_1: [&"stalk", &"fan", &"net", &"stomp", &"stalk", &"fan", &"crawl", &"spiders", &"fan", &"net"],
	State.PHASE_2: [&"crawl", &"spiders", &"hang", &"net", &"crawl", &"fan", &"hang", &"stalk", &"charge", &"fan"],
	State.PHASE_3: [&"charge", &"net", &"crawl", &"hang", &"fan", &"stalk", &"charge", &"spiders", &"net", &"fan"],
	State.PHASE_4: [&"jump_fan", &"charge_spiders", &"net", &"hang_fan", &"jump_fan", &"curtain", &"charge_spiders", &"fan"],
}
const GROUND_MOVES := [&"stalk", &"stomp", &"charge", &"double_charge", &"charge_spiders"]
const CEILING_MOVES := [&"crawl", &"hang", &"hang_fan"]
const COMBOS := [&"jump_fan", &"charge_spiders", &"hang_fan"]
const BIG_ATTACKS := [&"stomp", &"hang", &"hang_fan", &"jump", &"jump_fan"] # Charges expose the implant when they land.

const FAN_TELEGRAPH := 0.6
const FAN_SPEED := 5.4
const SHOT_DAMAGE := 3
const STOMP_TELEGRAPH := 0.65
const STOMP_DAMAGE := 8
const STOMP_SPEED := 7.0
const STOMP_HEIGHT := 1.3
const SPIDERS_BY_PHASE := {State.PHASE_1: 2, State.PHASE_2: 3, State.PHASE_3: 2, State.PHASE_4: 3}
const THREAD_BOTTOM := 3.0 # (Lote 12 sweeping threads, no longer in the patterns.)
const THREAD_SPEED := 3.4
const THREAD_DAMAGE := 6
const THREAD_COUNT := 2
const THREAD_SPACING := 3.2
const CHARGE_TELEGRAPH := 0.8
const CHARGE_BACKUP := 1.3
const CHARGE_SPEED := 11.0
const CHARGE_DAMAGE := 10
const CHARGE_TOP := 2.5 # Top of the charge band (world Y): fly above it.
const CURTAIN_TELEGRAPH := 0.6
const CURTAIN_SPEED := 4.0
const CURTAIN_STEP := 0.55
const CURTAIN_GAP := 1.7
const STALK_SPEED := 2.6
const STALK_SECONDS := 1.6
const STALK_GAP := 3.2 # It stops this far from Bee's X (on its own side): Bee's zone, not her body.
const CRAWL_SPEED := 3.0
const CRAWL_SECONDS := 1.8
const JUMP_TELEGRAPH := 0.8
const JUMP_SECONDS := 0.75
const JUMP_DAMAGE := 10
const HANG_TELEGRAPH := 0.6
const HANG_DROP := 0.45
const HANG_SWING := 3.0
const HANG_UP := 0.45
const HANG_ROPE := 1.0 # Thread length to the abdomen tip at the bottom of the drop.
const HANG_AMPLITUDE := 0.5 # rad (~29 degrees).
const HANG_PERIOD := 2.2
const HANG_DAMAGE := 8
const HANG_FAN_AT := [1.0] # Swing seconds at which a fan leaves the mouth (hang_fan: two).
const HANG_COMBO_FAN_AT := [0.8, 2.2]
const NET_IN_PHASE_1 := true
const TRAP_FOLLOW_UP := 0.15 ## Seconds after a trap before the follow-up fan starts its warning.
const SPIT_EVERY := 0.9 ## While it stalks or crawls it spits a single aimed web shot this often...
const SPIT_WARNING := 0.45 ## ...after the mouth glows this long.
const EXPOSE_SECONDS := 1.8
const EXPOSE_MULTIPLIER := 2.0
const SUMMON_COOLDOWN := 14.0
const MAX_SUMMONS := 2 # Fly calls in phase 2.
const RNG_SEED := 1207
const MAX_MINIONS := 2
const SUMMON_FAMILY := &"FlyCommon"
const FREED_WALK_SECONDS := 3.4

@onready var health: HealthComponent = $HealthComponent
@onready var hit_flash: HitFlash3D = $HitFlash3D

var state := State.APPROACH
var camera: Camera3D
var target: BeePlayer
var side := 1.0 # +1: it stands right of Bee and faces left (towards her); -1: the other way.
var mode := &"ground" # &"ground", &"ceiling", &"hang", &"air" (jumping).
var visual_root: Node3D
var model: Node3D
var body_hurtbox: DamageHurtbox3D
var implant_hurtbox: DamageHurtbox3D
var legs_hurtbox: DamageHurtbox3D
var contact: DamageHitbox3D
var hazards: Array[Dictionary] = []
var untelegraphed_damage := 0
var phases_seen: Array[int] = []
var fight_seconds := 0.0
var attacks_started := 0
var attack_kind := &"none" # The attack in progress (tests / bot).
var attack_left := 0.0 # Seconds until the attack in progress can hurt (warning left).
var transitions := 0
var bombs_taken := 0
var honey_spawned := 0
var summons := 0
var minions_alive := 0 # Written by the level director.
var fired_fan := 0
var fans := 0
var stomps := 0
var threads := 0
var charges := 0
var curtains := 0
var spiders_dropped := 0
var exposures := 0
var exposed_damage := 0
var legs_absorbed := 0
var jumps := 0
var hangs := 0
var crawls := 0
var stalks := 0
var nets := 0
var traps := 0
var combos := 0
var modes_seen := {}
var implant_exposed := false
var legs_armoured := false
var thread_nodes: Array[Dictionary] = [] # {"line", "box", "x", "active"} (Lote 12 threads; bot reads x / active).
var curtain_gaps: Array[float] = [] # Gap centres (world Y) of the last curtain.
var charge_band: Vector2 = Vector2(GROUND_Y, CHARGE_TOP)
var charge_dir := -1.0
var jump_band := [Vector3.ZERO, Vector3.ZERO] # Body centre at take-off and landing (warning band; bot reads it).
var hang_pivot_x := 0.0 # X of the thread while it drops / swings (bot reads it).
var net_line := [Vector3.ZERO, Vector3.ZERO] # Mouth -> locked point of the net warning (bot reads it).
var web_net: TarantulaWebNet
var _web_immune_left := 0.0
var _next_state := State.PHASE_1
var _state_time := 0.0
var _step := &"cooldown"
var _left := 0.8
var _pattern_index := 0
var _bob := 0.0
var _goal_x := 0.0
var _charge_from := 0.0
var _charge_to := 0.0
var _charges_left := 0
var _expose_left := 0.0
var _summon_left := 6.0
var _hull_tokens := HULL_BURST
var _armour_health: HealthComponent
var _implant_node: Node3D
var _implant_core: MeshInstance3D
var _dorsal_shell: MeshInstance3D
var _mouth_glow: MeshInstance3D
var _warnings: Array[Node3D] = []
var _bar_layer: CanvasLayer
var _hint_label: Label
var _hint_token := 0
const BOSS_HINT_SECONDS := 5.0
var _bar: ProgressBar
var _phase_label: Label
var _anim: AnimationPlayer
var _contact_refresh := 0.0
var _freed_left := 0.0
var _rng := RandomNumberGenerator.new() # Seeded: every fight plays the same (bot measurements are reproducible).
var summons_this_phase := 0
var _tilt := 0.0
var _flip := 0.0 # 0 on the ground, PI upside down on the ceiling (lerped during a jump).
var _swing := 0.0
var _jump_from := Vector3.ZERO
var _jump_to := Vector3.ZERO
var _jump_to_mode := &"ground"
var _jump_fan := false
var _hang_t := 0.0
var _hang_rope := 0.0
var _hang_fans: Array = []
var _hang_line: MeshInstance3D
var _net_aim: MeshInstance3D
var _follow_up := false
var follow_ups := 0
var spits := 0
var _spit_clock := 0.0
var _saved_surface_materials: Dictionary = {}


func _ready() -> void:
	_rng.seed = RNG_SEED
	health.max_health = max_hp
	health.current_health = max_hp
	health.damage_blocked = true
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_free_tarantula)
	_build_visual()
	hit_flash.set_flash_color(BeeGameSettings.TARANTULA_HIT_FLASH_COLOR)
	_build_areas()
	_build_health_bar()
	set_physics_process(false)


## Called by the level director when the arena is locked: it walks in from the right edge.
func begin(stage_camera: Camera3D, bee: BeePlayer) -> void:
	camera = stage_camera
	target = bee
	side = 1.0
	mode = &"ground"
	global_position = Vector3(_cam_x() + _half_width() + 4.5, GROUND_Y, 0.0)
	_apply_pose()
	state = State.APPROACH
	_state_time = 0.0
	_play(&"walk")
	BeeAudio.play(get_parent(), &"walker_charge", global_position, 0.55)
	set_physics_process(true)


func is_active() -> bool:
	return state in [State.PHASE_1, State.PHASE_2, State.PHASE_3, State.PHASE_4, State.TRANSITION]


func is_defeated() -> bool:
	return state == State.FREED or state == State.DONE


func is_vulnerable() -> bool:
	return is_active() and not health.damage_blocked


func bomb_damage_for(_base: int) -> int:
	bombs_taken += 1
	return maxi(1, roundi(float(max_hp) * BOMB_FRACTION))


func current_phase_number() -> int:
	var phase: int = _next_state if state == State.TRANSITION else state
	return clampi(phase - State.PHASE_1 + 1, 1, 4)


func health_bar_visible() -> bool:
	return _bar_layer != null and _bar_layer.visible


## Bee defeated: everything stops in place.
func freeze() -> void:
	set_physics_process(false)
	contact.set_enabled(false)
	_charge_box.set_enabled(false)
	for thread in thread_nodes:
		(thread["box"] as DamageHitbox3D).set_enabled(false)
	for node in get_tree().get_nodes_in_group("tarantula_hazards"):
		if node is TarantulaWebNet:
			node.call("dismiss")
		else:
			node.set_physics_process(false)
	if _anim != null:
		_anim.pause()


## LOTE 15: no net can trap Bee while she is stuck or during the grace after it (nothing chains the trap).
func web_immune() -> bool:
	return _web_immune_left > 0.0 or (is_instance_valid(target) and target.web_locked)


func on_web_trapped(_net: TarantulaWebNet) -> void:
	traps += 1
	_web_immune_left = TarantulaWebNet.TRAP_SECONDS + TarantulaWebNet.GRACE_SECONDS
	if _step == &"cooldown" and is_active() and state != State.TRANSITION:
		_follow_up = true # The trap sets up an aimed fan right away: breaking free fast (shots + keys) dodges it.
		_left = minf(_left, TRAP_FOLLOW_UP)


func on_web_released(_net: TarantulaWebNet) -> void:
	_web_immune_left = TarantulaWebNet.GRACE_SECONDS


func _cam_x() -> float:
	return camera.global_position.x if camera != null else global_position.x - side * ANCHOR_DX


func _half_width() -> float:
	return BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))


func _ceiling_y() -> float:
	return BeeLevel01Framing.top_y() + CEILING_MARGIN


## World offset of a model-space X (forward -X) on the current side (ground pose).
func _mx(x: float) -> float:
	return x * side * MODEL_SCALE


## World position of a model-space point in the current pose (ground, upside down, hanging, mid-jump).
func _world(part: Vector2) -> Vector3:
	return global_position + visual_root.basis * Vector3(part.x * MODEL_SCALE, part.y * MODEL_SCALE, 0.0)


## The pose basis: facing (yaw), upside down (flip about X), roll (hanging head down + swing, rear-up tilt).
func _pose_basis(face: float, flip: float, roll: float) -> Basis:
	return Basis(Vector3.BACK, roll) * Basis(Vector3.RIGHT, flip) * Basis(Vector3.UP, 0.0 if face > 0.0 else PI)


func _apply_pose() -> void:
	var roll := _tilt * side
	if mode == &"hang":
		roll = side * PI * 0.5 + _swing
	visual_root.basis = _pose_basis(side, _flip if mode != &"hang" else 0.0, roll)
	_place_areas()


func _face() -> void:
	_apply_pose()


## Turns towards Bee (hysteresis: it does not flicker when she is right above or below it).
func _face_bee() -> void:
	if target == null:
		return
	var dx := global_position.x - target.global_position.x
	if absf(dx) > 1.2 and signf(dx) != side:
		side = signf(dx)


func _body_centre_at(root: Vector3, at_mode: StringName, face: float) -> Vector3:
	var flip := PI if at_mode == &"ceiling" else 0.0
	return root + _pose_basis(face, flip, 0.0) * Vector3(BODY_CENTRE.x * MODEL_SCALE, BODY_CENTRE.y * MODEL_SCALE, 0.0)


func _clamp_x(x: float) -> float:
	var half := _half_width() - SCREEN_INSET
	return clampf(x, _cam_x() - half, _cam_x() + half)


# --- main loop ----------------------------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var easy := BeeGameSettings.difficulty == BeeGameSettings.EASY
	_hull_tokens = minf(HULL_BURST, _hull_tokens + max_hp * (EASY_HULL_DPS_RATIO if easy else HULL_DPS_RATIO) * delta)
	_web_immune_left = maxf(0.0, _web_immune_left - delta)
	_state_time += delta
	match state:
		State.APPROACH:
			var t := clampf(_state_time / APPROACH_SECONDS, 0.0, 1.0)
			var start := _cam_x() + _half_width() + 4.5
			global_position.x = lerpf(start, _cam_x() + ANCHOR_DX, 1.0 - pow(1.0 - t, 2.0))
			if t >= 1.0:
				_enter_fight()
		State.PHASE_1, State.PHASE_2, State.PHASE_3, State.PHASE_4:
			fight_seconds += delta
			modes_seen[mode] = true
			_update_expose(delta)
			_update_threads(delta)
			_attack(delta)
			_refresh_contact(delta)
		State.TRANSITION:
			fight_seconds += delta
			_update_threads(delta)
			_tilt = 0.12 * sin(clampf(_state_time / TRANSITION_SECONDS, 0.0, 1.0) * PI) # Rears up.
			if _state_time >= TRANSITION_SECONDS:
				_tilt = 0.0
				_change_state(_next_state)
				_step = &"cooldown"
				_left = 0.6
		State.FREED:
			_freed_left -= delta
			global_position.x += signf(global_position.x - _cam_x() + 0.001) * 2.6 * delta # Calm walk away towards its edge.
			if _freed_left <= 0.0:
				_finish()
	_apply_pose()


func _enter_fight() -> void:
	health.damage_blocked = false
	for area in [body_hurtbox, implant_hurtbox, legs_hurtbox]:
		area.set_deferred("monitorable", true)
	add_to_group("bee_auto_aim_targets")
	contact.set_enabled(true)
	_bar_layer.visible = true
	_play(&"idle")
	BeeMusic.boss() # LOTE 14: the boss theme crossfades in (1.5 s) when the health bar appears.
	_change_state(State.PHASE_1)


func _change_state(value: int) -> void:
	state = value
	_state_time = 0.0
	if value in [State.PHASE_1, State.PHASE_2, State.PHASE_3, State.PHASE_4] and not (value in phases_seen):
		phases_seen.append(value)
		_pattern_index = 0 # Every phase opens with its signature move.
		if value == State.PHASE_2:
			_armour_legs()
		elif value == State.PHASE_3:
			_drop_honey() # Half of the fight: a honey jar between phases.
		elif value == State.PHASE_4:
			_enter_fury()
	_update_phase_label()
	phase_changed.emit(state)


func _tuning() -> Array:
	return PHASE_TUNING.get(state, PHASE_TUNING[State.PHASE_1])


## Between attacks it never stands still: on the ground it drifts towards Bee's zone, on the ceiling it follows her from above.
func _idle_move(delta: float) -> void:
	_bob += delta
	_face_bee()
	if target == null:
		return
	if mode == &"ceiling":
		var goal := _clamp_x(target.global_position.x + sin(_bob * 1.3) * 0.8)
		global_position.x = move_toward(global_position.x, goal, 1.4 * delta)
		global_position.y = _ceiling_y()
	else:
		var goal := _clamp_x(target.global_position.x + side * (STALK_GAP + 0.6) + sin(_bob * 0.9) * 0.7)
		global_position.x = move_toward(global_position.x, goal, 1.6 * delta)
		global_position.y = GROUND_Y
		_play(&"walk" if absf(goal - global_position.x) > 0.05 else &"idle")


func _refresh_contact(delta: float) -> void:
	if _step in [&"charge_run", &"jump_run", &"hang_drop", &"hang_swing", &"hang_up"]:
		contact.set_enabled(false)
		return
	_contact_refresh -= delta
	if _contact_refresh <= 0.0:
		_contact_refresh = 1.5
		contact.set_enabled(true)


# --- attacks ------------------------------------------------------------------------------------------------------------

func _attack(delta: float) -> void:
	_left -= delta
	attack_left = maxf(_left, 0.0)
	if state in [State.PHASE_2, State.PHASE_3, State.PHASE_4]:
		_summon_left -= delta
	match _step:
		&"cooldown":
			attack_kind = &"none"
			_idle_move(delta)
			if _left <= 0.0:
				if state == State.PHASE_2 and _summon_left <= 0.0 and minions_alive == 0 and summons < MAX_SUMMONS: # Phase 2 calls the flies.
					_summon_left = SUMMON_COOLDOWN
					summons += 1
					summon_requested.emit(SUMMON_FAMILY, MAX_MINIONS - minions_alive)
					BeeAudio.play(get_parent(), &"walker_charge", global_position, 1.3)
				_start_attack()
		&"stalk", &"crawl":
			var speed := CRAWL_SPEED if _step == &"crawl" else STALK_SPEED
			_face_bee()
			_goal_x = _clamp_x(target.global_position.x + (0.0 if _step == &"crawl" else side * STALK_GAP))
			global_position.x = move_toward(global_position.x, _goal_x, speed * delta)
			_play(&"walk" if absf(global_position.x - _goal_x) > 0.05 else &"idle")
			_update_spit(delta)
			if _left <= 0.0:
				_mouth_glow.scale = Vector3.ONE * 0.01
				_end_attack(-0.5)
		&"fan_tele":
			_mouth_glow.scale = Vector3.ONE * lerpf(0.4, 1.6, 1.0 - _left / FAN_TELEGRAPH)
			_mouth_glow.global_position = _world(MOUTH)
			if _left <= 0.0:
				_mouth_glow.scale = Vector3.ONE * 0.01
				_fire_fan()
				_end_attack()
		&"net_tele":
			_mouth_glow.global_position = _world(MOUTH)
			_mouth_glow.scale = Vector3.ONE * lerpf(0.3, 1.1, 1.0 - _left / TarantulaWebNet.WARNING)
			net_line = [_world(MOUTH), target.global_position]
			if is_instance_valid(_net_aim):
				BeeAttackVisuals.place_line(_net_aim, net_line[0], net_line[0] + (net_line[1] - net_line[0]).normalized() * 14.0)
			if _left <= 0.0:
				_mouth_glow.scale = Vector3.ONE * 0.01
				_clear_warnings()
				_fire_net()
				_end_attack()
		&"stomp_tele":
			_tilt = 0.16 * sin(clampf(1.0 - _left / STOMP_TELEGRAPH, 0.0, 1.0) * PI * 0.5)
			if _left <= 0.0:
				_tilt = 0.0
				_clear_warnings()
				_stamp(STOMP_TELEGRAPH)
				_end_attack()
		&"threads_tele":
			if _left <= 0.0:
				_clear_warnings()
				_release_threads()
				_end_attack()
		&"charge_tele":
			# Charge-up: it backs up towards its edge while the band warns, then rushes across.
			var k := clampf(1.0 - _left / CHARGE_TELEGRAPH, 0.0, 1.0)
			global_position.x = _charge_from + side * CHARGE_BACKUP * smoothstep(0.0, 1.0, k)
			_play(&"walk")
			if _left <= 0.0:
				_clear_warnings()
				_charge_from = global_position.x
				_step = &"charge_run"
				hazards.append({"kind": &"charge", "telegraph": CHARGE_TELEGRAPH})
				charges += 1
				contact.set_enabled(false)
				_charge_box.set_enabled(true)
				BeeCameraShake.kick(self, 0.05, 0.3)
		&"charge_run":
			global_position.x = move_toward(global_position.x, _charge_to, CHARGE_SPEED * delta)
			_place_hazard_box()
			if is_equal_approx(global_position.x, _charge_to):
				_charge_box.set_enabled(false)
				side = -side # It ends on the other side, facing back into the screen.
				_charges_left -= 1
				_expose_implant()
				if _charges_left > 0:
					_begin_charge()
				else:
					_end_attack(0.3)
		&"curtain_tele":
			if _left <= 0.0:
				_clear_warnings()
				_fire_curtain()
				_end_attack()
		&"jump_tele":
			_tilt = -0.18 * smoothstep(0.0, 1.0, 1.0 - _left / JUMP_TELEGRAPH) # Crouches.
			if _jump_fan:
				_mouth_glow.global_position = _world(MOUTH)
				_mouth_glow.scale = Vector3.ONE * lerpf(0.4, 1.6, 1.0 - _left / JUMP_TELEGRAPH)
			if _left <= 0.0:
				_tilt = 0.0
				_clear_warnings()
				if _jump_fan:
					_mouth_glow.scale = Vector3.ONE * 0.01
					_fire_fan(JUMP_TELEGRAPH)
				hazards.append({"kind": &"jump", "telegraph": JUMP_TELEGRAPH})
				jumps += 1
				mode = &"air"
				_step = &"jump_run"
				_left = JUMP_SECONDS
				_charge_box.damage = JUMP_DAMAGE
				_charge_box.set_enabled(true)
				contact.set_enabled(false)
				BeeAudio.play(get_parent(), &"organic_charge", global_position, 0.8)
		&"jump_run":
			var t := clampf(1.0 - _left / JUMP_SECONDS, 0.0, 1.0)
			global_position = _jump_from.lerp(_jump_to, smoothstep(0.0, 1.0, t))
			_flip = lerpf(0.0 if _jump_to_mode == &"ceiling" else PI, PI if _jump_to_mode == &"ceiling" else 0.0, t)
			_apply_pose()
			_place_hazard_box()
			if _left <= 0.0:
				_charge_box.set_enabled(false)
				mode = _jump_to_mode
				_flip = PI if mode == &"ceiling" else 0.0
				global_position = _jump_to
				_face_bee()
				if mode == &"ground":
					_stamp(JUMP_TELEGRAPH) # The landing shakes the ground (warned by the landing shadow).
				else:
					BeeCombatVFX.spawn(get_parent(), _world(BODY_CENTRE), &"rock_break", Vector3.DOWN, 1.4)
				_end_attack(0.1)
		&"hang_tele":
			if _left <= 0.0:
				_clear_warnings()
				hazards.append({"kind": &"swing", "telegraph": HANG_TELEGRAPH})
				hangs += 1
				mode = &"hang"
				_swing = 0.0
				_hang_rope = 0.0
				_step = &"hang_drop"
				_left = HANG_DROP
				_charge_box.damage = HANG_DAMAGE
				_charge_box.set_enabled(true)
				_hang_line = BeeAttackVisuals.line(get_parent(), Vector3(hang_pivot_x, _ceiling_y() + 0.5, 0.0), Vector3(hang_pivot_x, _ceiling_y(), 0.0), 0.05, Color(0.96, 0.96, 0.9, 0.9))
				BeeAudio.play(get_parent(), &"spider_drop", global_position, 0.7)
		&"hang_drop", &"hang_swing", &"hang_up":
			_update_hang(delta)


## The next pattern move. If it needs the other surface, a corner-to-corner jump comes first (the move waits for it).
func _start_attack() -> void:
	BeeMusic.duck_for_explosion()
	var pattern: Array = PATTERNS.get(state, PATTERNS[State.PHASE_1])
	var kind: StringName = pattern[_pattern_index % pattern.size()]
	if _follow_up:
		_follow_up = false
		_start_follow_up()
		return
	var needs := &"ground" if kind in GROUND_MOVES else (&"ceiling" if kind in CEILING_MOVES else &"")
	if needs != &"" and needs != mode:
		kind = &"jump"
	else:
		_pattern_index += 1
	if kind == &"net" and (web_immune() or not (NET_IN_PHASE_1 or state != State.PHASE_1)):
		kind = &"fan" # Nothing chains the trap: no new net while Bee is stuck or in her grace.
	if not thread_nodes.is_empty() and kind in [&"stomp", &"charge", &"double_charge", &"curtain", &"charge_spiders"]:
		kind = &"fan"
	attacks_started += 1
	attack_kind = kind
	if kind in COMBOS:
		combos += 1
	_play(&"attack")
	match kind:
		&"stalk":
			stalks += 1
			_step = &"stalk"
			_left = STALK_SECONDS
			_spit_clock = 0.0
		&"crawl":
			crawls += 1
			_spit_clock = 0.0
			_step = &"crawl"
			_left = CRAWL_SECONDS
		&"fan":
			_step = &"fan_tele"
			_left = FAN_TELEGRAPH
			BeeAudio.play(get_parent(), &"spider_telegraph", global_position, 0.8)
		&"net":
			_step = &"net_tele"
			_left = TarantulaWebNet.WARNING
			net_line = [_world(MOUTH), target.global_position]
			_net_aim = BeeAttackVisuals.line(get_parent(), net_line[0], net_line[1], 0.05, Color(0.96, 0.96, 0.9, 0.45))
			_warnings.append(_net_aim)
			BeeAudio.play(get_parent(), &"spider_telegraph", global_position, 1.1)
		&"stomp":
			_step = &"stomp_tele"
			_left = STOMP_TELEGRAPH
			var half := _half_width()
			_warnings.append(BeeGroundShockwave.warning_band(get_parent(), _cam_x() - half - 1.0, _cam_x() + half + 1.0, STOMP_HEIGHT))
			BeeAudio.play(get_parent(), &"walker_charge", global_position, 0.6)
		&"spiders":
			_drop_spiders()
			_end_attack(0.4)
		&"threads":
			_step = &"threads_tele"
			_left = 0.75
			_prepare_threads()
		&"charge", &"double_charge":
			_charges_left = 2 if kind == &"double_charge" else 1
			_begin_charge()
		&"charge_spiders":
			_drop_spiders() # Spiders on Bee's column while the band below warns: fly above the band, beside the threads.
			_charges_left = 1
			_begin_charge()
		&"curtain":
			_step = &"curtain_tele"
			_left = CURTAIN_TELEGRAPH
			_prepare_curtain()
		&"jump", &"jump_fan":
			_begin_jump(kind == &"jump_fan")
		&"hang", &"hang_fan":
			_begin_hang(kind == &"hang_fan")


func _end_attack(extra := 0.0) -> void:
	if attack_kind in BIG_ATTACKS:
		_expose_implant() # Charges expose it on landing (see charge_run).
	_step = &"cooldown"
	_left = maxf(0.2, float(_tuning()[0]) + extra)
	attack_kind = &"none"


# Web fan from the mouth, centred on Bee.
func _fire_fan(telegraph := FAN_TELEGRAPH) -> void:
	if target == null:
		return
	var origin := _world(MOUTH)
	origin.z = 0.0
	var to_bee := target.global_position - origin
	var base := atan2(to_bee.y, to_bee.x)
	var count := int(_tuning()[1])
	var step := deg_to_rad(float(_tuning()[2]))
	hazards.append({"kind": &"fan", "telegraph": telegraph})
	fans += 1
	for i in count:
		var angle := base + step * (float(i) - float(count - 1) * 0.5)
		_spawn_web(origin, Vector3(cos(angle), sin(angle), 0.0), FAN_SPEED)
		fired_fan += 1
	BeeAudio.play(get_parent(), &"spider_retract", origin, 1.3)


func _spawn_web(origin: Vector3, direction: Vector3, speed: float, lifetime := 3.0) -> AlienEnemyProjectile:
	var projectile := PROJECTILE.instantiate() as AlienEnemyProjectile
	projectile.damage = SHOT_DAMAGE
	projectile.speed = speed
	projectile.lifetime = lifetime
	projectile.add_to_group(PROJECTILE_GROUP) # Common shot: the Lote 11 roll still destroys it.
	get_parent().add_child(projectile)
	projectile.global_position = origin
	projectile.rotation.z = atan2(direction.y, direction.x)
	projectile.launch(direction, self)
	var ring := BeeAttackVisuals.ring(projectile, origin, 0.24, 0.25, Color(0.96, 0.96, 0.9, 0.85)) # A white silk knot on the cyan shot.
	ring.top_level = false
	ring.position = Vector3.ZERO
	return projectile


## LOTE 15: the trapping net leaves along the line locked at the end of its warning.
func _fire_net() -> void:
	nets += 1
	hazards.append({"kind": &"net", "telegraph": TarantulaWebNet.WARNING})
	var origin := Vector3(net_line[0].x, net_line[0].y, 0.0)
	var direction: Vector3 = net_line[1] - origin
	web_net = TarantulaWebNet.launch(get_parent(), self, target, origin, direction if direction.length() > 0.01 else Vector3(-side, 0.0, 0.0))
	BeeAudio.play(get_parent(), &"spider_retract", origin, 0.7)


func _stamp(telegraph: float) -> void:
	stomps += 1
	hazards.append({"kind": &"stomp", "telegraph": telegraph})
	var half := _half_width()
	var front := global_position.x - side * 1.6
	var back := global_position.x + side * 2.1
	BeeGroundShockwave.launch(get_parent(), self, front, _cam_x() - side * (half + 1.0), STOMP_DAMAGE, STOMP_SPEED, STOMP_HEIGHT)
	BeeGroundShockwave.launch(get_parent(), self, back, _cam_x() + side * (half + 1.0), STOMP_DAMAGE, STOMP_SPEED, STOMP_HEIGHT)
	BeeCombatVFX.spawn(get_parent(), Vector3(global_position.x - side * 1.3, 0.2, 0.4), &"rock_break", Vector3.UP, 2.0)
	BeeCameraShake.kick(self, 0.06, 0.3)
	BeeAudio.play(get_parent(), &"human_step", global_position, 1.1)


func _drop_spiders() -> void:
	var count := int(SPIDERS_BY_PHASE.get(state, 2))
	var half := _half_width()
	var top := BeeLevel01Framing.top_y() + 0.6
	for i in count:
		# The first one on Bee's column, the others beside it.
		var x := target.global_position.x + (0.0 if i == 0 else (2.4 * float((i + 1) / 2) * (1.0 if i % 2 == 1 else -1.0)))
		x = clampf(x, _cam_x() - half + 0.8, _cam_x() + half - 0.8)
		var hang := clampf(target.global_position.y + _rng.randf_range(-0.6, 0.6), 1.4, BeeLevel01Framing.top_y() - 1.2)
		var spider := TarantulaDropSpider.new()
		spider.name = "TarantulaDropSpider"
		spider.add_to_group("tarantula_hazards")
		get_parent().add_child(spider)
		spider.setup(self, x, hang, top)
		spiders_dropped += 1
		hazards.append({"kind": &"spider", "telegraph": TarantulaDropSpider.TELEGRAPH})


# --- LOTE 15: jumps, the pendulum ---------------------------------------------------------------------------------------

## Diagonal jump to the opposite corner (ground <-> ceiling): the band along the path and the landing shadow warn it.
func _begin_jump(with_fan: bool) -> void:
	BeeMusic.duck_for_explosion()
	_step = &"jump_tele"
	_left = JUMP_TELEGRAPH
	_jump_fan = with_fan
	_jump_from = global_position
	_jump_to_mode = &"ground" if mode == &"ceiling" else &"ceiling"
	var corner := -signf(global_position.x - _cam_x() + 0.001) # The opposite half of the screen.
	var to_x := _cam_x() + corner * ANCHOR_DX
	_jump_to = Vector3(to_x, GROUND_Y if _jump_to_mode == &"ground" else _ceiling_y(), 0.0)
	var land_face := signf(to_x - target.global_position.x) if target != null else -corner
	jump_band = [_world(BODY_CENTRE), _body_centre_at(_jump_to, _jump_to_mode, land_face if land_face != 0.0 else -corner)]
	_warnings.append(BeeAttackVisuals.line(get_parent(), jump_band[0], jump_band[1], BODY_SIZE.y * MODEL_SCALE, Color(1.0, 0.3, 0.2, 0.22)))
	if _jump_to_mode == &"ground":
		_warnings.append(BeeAttackVisuals.ground_disc(get_parent(), Vector3(to_x, 0.03, 0.0), 1.8, Color(0.05, 0.02, 0.02, 0.55)))
	else:
		var top := BeeLevel01Framing.top_y() - 0.15
		_warnings.append(BeeAttackVisuals.line(get_parent(), Vector3(to_x - 1.8, top, 0.0), Vector3(to_x + 1.8, top, 0.0), 0.3, Color(0.05, 0.02, 0.02, 0.6)))
	BeeAudio.play(get_parent(), &"walker_charge", global_position, 0.75)


## From the ceiling it drops on a thread (the thread is drawn first), swings as a pendulum and climbs back.
func _begin_hang(combo: bool) -> void:
	BeeMusic.duck_for_explosion()
	_step = &"hang_tele"
	_left = HANG_TELEGRAPH
	hang_pivot_x = _clamp_x(_world(ATTACH).x) # The abdomen tip, where the thread comes out.
	_hang_fans = (HANG_COMBO_FAN_AT if combo else HANG_FAN_AT).duplicate()
	_hang_t = 0.0
	var top := _ceiling_y()
	var bottom := top - HANG_ROPE - (ATTACH.x - MOUTH.x) * MODEL_SCALE
	var warn := BeeAttackVisuals.line(get_parent(), Vector3(hang_pivot_x, top, 0.0), Vector3(hang_pivot_x, bottom, 0.0), 0.08, Color(1.0, 0.62, 0.2, 0.5))
	_warnings.append(warn)
	BeeAudio.play(get_parent(), &"spider_telegraph", global_position, 0.6)


func _update_hang(delta: float) -> void:
	_hang_t += delta
	var pivot := Vector3(hang_pivot_x, _ceiling_y(), 0.0)
	match _step:
		&"hang_drop":
			_hang_rope = HANG_ROPE * smoothstep(0.0, 1.0, 1.0 - _left / HANG_DROP)
			_swing = 0.0
			if _left <= 0.0:
				_step = &"hang_swing"
				_left = HANG_SWING
				_hang_t = 0.0
				_charge_box.set_enabled(false)
				_charge_box.set_enabled(true) # One more hit allowed for the swing itself.
		&"hang_swing":
			_hang_rope = HANG_ROPE
			_swing = HANG_AMPLITUDE * sin(_hang_t * TAU / HANG_PERIOD)
			if not _hang_fans.is_empty():
				var at := float(_hang_fans[0])
				var glow := clampf(1.0 - (at - _hang_t) / FAN_TELEGRAPH, 0.0, 1.0)
				_mouth_glow.scale = Vector3.ONE * (0.01 if _hang_t < at - FAN_TELEGRAPH else lerpf(0.4, 1.6, glow))
				if _hang_t >= at:
					_hang_fans.pop_front()
					_mouth_glow.scale = Vector3.ONE * 0.01
					_fire_fan(minf(FAN_TELEGRAPH, at))
			if _left <= 0.0:
				_step = &"hang_up"
				_left = HANG_UP
		&"hang_up":
			_swing = lerpf(_swing, 0.0, clampf(delta * 8.0, 0.0, 1.0))
			_hang_rope = HANG_ROPE * smoothstep(0.0, 1.0, _left / HANG_UP)
			if _left <= 0.0:
				_end_hang()
				_end_attack(-0.2)
				return
	_mouth_glow.global_position = _world(MOUTH)
	# The abdomen tip hangs from the pivot on the rope; the body follows the swing angle.
	var tip := pivot + Vector3(sin(_swing), -cos(_swing), 0.0) * _hang_rope
	_apply_pose()
	global_position = tip - visual_root.basis * Vector3(ATTACH.x * MODEL_SCALE, ATTACH.y * MODEL_SCALE, 0.0)
	_apply_pose()
	_place_hazard_box()
	if is_instance_valid(_hang_line):
		BeeAttackVisuals.place_line(_hang_line, pivot + Vector3(0.0, 0.5, 0.0), tip)


## Back on the ceiling (end of the swing, a phase change or the liberation).
func _end_hang() -> void:
	_charge_box.set_enabled(false)
	_mouth_glow.scale = Vector3.ONE * 0.01
	if is_instance_valid(_hang_line):
		_hang_line.queue_free()
	_hang_line = null
	if mode == &"hang":
		mode = &"ceiling"
		_swing = 0.0
		_flip = PI
		global_position = Vector3(_clamp_x(hang_pivot_x - _mx(ATTACH.x)), _ceiling_y(), 0.0)
		_apply_pose()


func _place_hazard_box() -> void:
	_charge_box.global_transform = Transform3D(visual_root.basis.orthonormalized(), _world(BODY_CENTRE))


# --- threads (Lote 12; kept for reference, not in the patterns) ---------------------------------------------------------

func _prepare_threads() -> void:
	_clear_threads()
	var top := BeeLevel01Framing.top_y() + 0.4
	for i in THREAD_COUNT:
		var x := _world(Vector2(-2.4, 0.0)).x - side * THREAD_SPACING * float(i)
		var line := BeeAttackVisuals.line(get_parent(), Vector3(x, top, 0.0), Vector3(x, THREAD_BOTTOM, 0.0), 0.06, Color(1.0, 0.62, 0.2, 0.4))
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.3, top - THREAD_BOTTOM, 1.2)
		var box := BeeAttackVisuals.hazard_area(get_parent(), self, THREAD_DAMAGE, shape)
		box.top_level = true
		box.global_position = Vector3(x, (top + THREAD_BOTTOM) * 0.5, 0.0)
		thread_nodes.append({"line": line, "box": box, "x": x, "top": top, "active": false})
	threads += 1


func _release_threads() -> void:
	hazards.append({"kind": &"threads", "telegraph": 0.75})
	for thread in thread_nodes:
		thread["active"] = true
		BeeAttackVisuals.restore_active_line(thread["line"], Color(0.95, 0.95, 0.9, 0.9), 0.06)
		(thread["box"] as DamageHitbox3D).set_enabled(true)


func _update_threads(delta: float) -> void:
	var edge := _cam_x() - side * (_half_width() + 1.5)
	for thread in thread_nodes.duplicate():
		if not bool(thread["active"]):
			continue
		var x := move_toward(float(thread["x"]), edge, THREAD_SPEED * delta)
		thread["x"] = x
		var top := float(thread["top"])
		BeeAttackVisuals.place_line(thread["line"], Vector3(x, top, 0.0), Vector3(x, THREAD_BOTTOM, 0.0))
		(thread["box"] as Node3D).global_position = Vector3(x, (top + THREAD_BOTTOM) * 0.5, 0.0)
		if is_equal_approx(x, edge):
			_free_thread(thread)


func _free_thread(thread: Dictionary) -> void:
	(thread["box"] as DamageHitbox3D).set_enabled(false)
	(thread["box"] as Node).queue_free()
	(thread["line"] as Node).queue_free()
	thread_nodes.erase(thread)


func _clear_threads() -> void:
	for thread in thread_nodes.duplicate():
		_free_thread(thread)


# --- charge ------------------------------------------------------------------------------------------------------------

var _charge_box: DamageHitbox3D


## Ground rush across Bee's zone to the far corner (the band shows the lane: fly above it).
func _begin_charge() -> void:
	BeeMusic.duck_for_explosion()
	_face_bee()
	_step = &"charge_tele"
	_left = CHARGE_TELEGRAPH
	_charge_from = global_position.x
	charge_dir = -side
	_charge_to = _cam_x() - side * ANCHOR_DX
	if absf(_charge_to - global_position.x) < 3.0:
		_charge_to = _cam_x() - side * (_half_width() - SCREEN_INSET + 0.8)
	_charge_box.damage = CHARGE_DAMAGE
	var half := _half_width()
	charge_band = Vector2(GROUND_Y, CHARGE_TOP)
	var band := BeeAttackVisuals.line(get_parent(), Vector3(_cam_x() - half - 1.0, (charge_band.x + charge_band.y) * 0.5, 0.0),
			Vector3(_cam_x() + half + 1.0, (charge_band.x + charge_band.y) * 0.5, 0.0), 1.0, Color(1.0, 0.3, 0.2, 0.25))
	band.scale.y = charge_band.y - charge_band.x
	_warnings.append(band)
	BeeAudio.play(get_parent(), &"organic_charge", global_position, 0.6)


# --- web curtain (phase 4) ---------------------------------------------------------------------------------------------

func _prepare_curtain() -> void:
	var low := BeeLevel01Framing.bottom_y() + 0.9
	var high := BeeLevel01Framing.top_y() - 0.6
	# Two safe gaps, never at the same height twice in a row; one is always near Bee's height.
	var first := clampf(target.global_position.y + _rng.randf_range(-1.2, 1.2), low + CURTAIN_GAP, high - CURTAIN_GAP)
	var second := low + CURTAIN_GAP * 0.6 if first > (low + high) * 0.5 else high - CURTAIN_GAP * 0.6
	curtain_gaps = [first, second]
	var x := _world(MOUTH).x
	var y := low
	while y <= high:
		if not _in_gap(y):
			var dot := BeeAttackVisuals.line(get_parent(), Vector3(x, y - 0.18, 0.0), Vector3(x, y + 0.18, 0.0), 0.1, Color(1.0, 0.62, 0.2, 0.55))
			_warnings.append(dot)
		y += CURTAIN_STEP
	curtains += 1


func _in_gap(y: float) -> bool:
	for gap in curtain_gaps:
		if absf(y - gap) < CURTAIN_GAP * 0.5:
			return true
	return false


func _fire_curtain() -> void:
	hazards.append({"kind": &"curtain", "telegraph": CURTAIN_TELEGRAPH})
	var low := BeeLevel01Framing.bottom_y() + 0.9
	var high := BeeLevel01Framing.top_y() - 0.6
	var x := _world(MOUTH).x
	var dir := signf(target.global_position.x - x) if target != null else -side
	var y := low
	while y <= high:
		if not _in_gap(y):
			_spawn_web(Vector3(x, y, 0.0), Vector3(dir if dir != 0.0 else -side, 0.0, 0.0), CURTAIN_SPEED, 4.2)
		y += CURTAIN_STEP
	BeeAudio.play(get_parent(), &"spider_retract", global_position, 0.9)


# --- implant window, armour, phases ------------------------------------------------------------------------------------

func _expose_implant() -> void:
	if state == State.PHASE_1 or not is_active():
		return
	exposures += 1
	implant_exposed = true
	_expose_left = EXPOSE_SECONDS
	implant_hurtbox.damage_multiplier = EXPOSE_MULTIPLIER
	_dorsal_shell.visible = false # The shell opens: the core is bare.
	_implant_core.scale = Vector3.ONE * 1.35
	_set_exposed_outline(true)


func _update_expose(delta: float) -> void:
	if not implant_exposed:
		return
	_expose_left -= delta
	_implant_core.scale = Vector3.ONE * (1.35 + 0.15 * sin(_expose_left * 18.0))
	if _expose_left <= 0.0:
		_close_implant()


func _close_implant() -> void:
	implant_exposed = false
	implant_hurtbox.damage_multiplier = 1.0
	_dorsal_shell.visible = true
	_implant_core.scale = Vector3.ONE
	_set_exposed_outline(false)


func _set_exposed_outline(enabled: bool) -> void:
	if enabled:
		_saved_surface_materials.clear()
		for mesh: MeshInstance3D in visual_root.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null:
				continue
			var original_materials: Array[Material] = []
			for surface in mesh.mesh.get_surface_count():
				var original := mesh.get_surface_override_material(surface)
				if original == null:
					original = mesh.mesh.surface_get_material(surface)
				original_materials.append(original)
				var styled := original as ShaderMaterial
				if styled == null or styled.next_pass == null:
					continue
				var local_body := styled.duplicate(true) as ShaderMaterial
				var gold_outline := (styled.next_pass as ShaderMaterial).duplicate(true) as ShaderMaterial
				gold_outline.shader = EXPOSED_OUTLINE
				gold_outline.set_shader_parameter("width", BeeGameSettings.TARANTULA_EXPOSED_OUTLINE_WIDTH)
				gold_outline.set_shader_parameter("outline_color", BeeGameSettings.TARANTULA_EXPOSED_OUTLINE_COLOR)
				local_body.next_pass = gold_outline
				mesh.set_surface_override_material(surface, local_body)
			_saved_surface_materials[mesh] = original_materials
	else:
		for mesh: MeshInstance3D in _saved_surface_materials:
			if not is_instance_valid(mesh):
				continue
			var materials: Array = _saved_surface_materials[mesh]
			for surface in mini(materials.size(), mesh.mesh.get_surface_count() if mesh.mesh != null else 0):
				mesh.set_surface_override_material(surface, materials[surface])
		_saved_surface_materials.clear()


func _armour_legs() -> void:
	legs_armoured = true
	legs_hurtbox.health_component = _armour_health
	legs_hurtbox.set_meta("neutral_hit", true)
	_boss_hint("PATAS BLINDADAS: APUNTÁ AL IMPLANTE")


func _on_armour_hit(_current: int, _maximum: int, change: int) -> void:
	if change >= 0:
		return
	legs_absorbed += 1
	_armour_health.current_health = _armour_health.max_health


func _enter_fury() -> void:
	BeeCameraShake.kick(self, 0.06, 0.4)
	BeeAudio.play(get_parent(), &"walker_charge", global_position, 0.5)
	_phase_label_text("FASE 4 / 4 · FURIA")


func _on_health_changed(current: int, maximum: int, change: int) -> void:
	if _bar != null:
		_bar.value = float(current) / float(maximum) * 100.0
	if change < 0 and implant_exposed:
		exposed_damage += -change
	if not (state in [State.PHASE_1, State.PHASE_2, State.PHASE_3, State.PHASE_4]) or current <= 0:
		return
	var ratio := float(current) / float(maximum)
	var wanted: int = State.PHASE_1
	if ratio <= PHASE_4_RATIO:
		wanted = State.PHASE_4
	elif ratio <= PHASE_3_RATIO:
		wanted = State.PHASE_3
	elif ratio <= PHASE_2_RATIO:
		wanted = State.PHASE_2
	wanted = mini(wanted, state + 1) # One phase at a time.
	if wanted > state:
		if _step == &"charge_run" or _step == &"jump_run":
			return # Never stops in the middle of a rush or a jump; the phase changes when it lands.
		_next_state = wanted
		transitions += 1
		_cancel_attack()
		_change_state(State.TRANSITION)
		_update_phase_label()


func _cancel_attack() -> void:
	_clear_warnings()
	_mouth_glow.scale = Vector3.ONE * 0.01
	_tilt = 0.0
	if _charge_box != null:
		_charge_box.set_enabled(false)
	if mode == &"hang":
		_end_hang()
	elif mode == &"air":
		mode = _jump_to_mode
		_flip = PI if mode == &"ceiling" else 0.0
		global_position = _jump_to
	_charges_left = 0
	_step = &"cooldown"
	attack_kind = &"none"
	# A charge that was only warned leaves it where it backed up to: it walks on normally.


func _clear_warnings() -> void:
	for node in _warnings:
		if is_instance_valid(node):
			node.queue_free()
	_warnings.clear()


func _update_phase_label() -> void:
	if _phase_label == null:
		return
	var n := current_phase_number()
	if n == 4:
		_phase_label.text = "FASE 4 / 4 · FURIA"
	else:
		_phase_label.text = "FASE %d / 4" % n


func _phase_label_text(text: String) -> void:
	if _phase_label != null:
		_phase_label.text = text


## TANDA 1 · H-05: a one-line instruction under the phase, visible for HINT_SECONDS only.
func _boss_hint(text: String) -> void:
	if _hint_label == null:
		return
	_hint_label.text = text
	_hint_label.visible = true
	_hint_token += 1
	var token := _hint_token
	get_tree().create_timer(BOSS_HINT_SECONDS, false).timeout.connect(func():
		if token == _hint_token and is_instance_valid(_hint_label):
			_hint_label.visible = false)


func _drop_honey() -> void:
	var item := preload("res://scenes/items/toon/pollen_cluster.tscn").instantiate() as Node3D
	get_parent().add_child(item)
	item.global_position = Vector3(_cam_x() - side * 3.8, 4.0, 0.0)
	honey_spawned += 1


## Sustained-DPS budget (same rule as the UFO hull). Bombs keep their BOMB_FRACTION outside it; a hit on the EXPOSED implant
## pays half (its x2 is real even when the budget binds, so the window is always worth it).
func limit_hull_damage(amount: int, source: DamageHitbox3D) -> int:
	if source is BeeAlienBomb:
		return amount
	if health.damage_blocked:
		return 0
	var weak := implant_hurtbox.last_hit_weak
	implant_hurtbox.last_hit_weak = false
	var cost_scale := 1.0 / EXPOSE_MULTIPLIER if weak else 1.0
	var permitted := mini(amount, floori(_hull_tokens / cost_scale))
	_hull_tokens -= float(permitted) * cost_scale
	return maxi(permitted, 0)


# --- liberation ----------------------------------------------------------------------------------------------------------

## The implant breaks: the tarantula is FREED (never killed). It calms down and walks away; then `defeated` ends the level.
func _free_tarantula() -> void:
	if is_defeated():
		return
	_cancel_attack()
	state = State.FREED
	_close_implant()
	_clear_threads()
	health.damage_blocked = true
	contact.set_enabled(false)
	for area in [body_hurtbox, implant_hurtbox, legs_hurtbox]:
		area.set_deferred("monitorable", false)
	remove_from_group("bee_auto_aim_targets")
	clear_projectiles()
	for node in get_tree().get_nodes_in_group("tarantula_hazards"):
		if node.has_method("dismiss"):
			node.call("dismiss")
	_bar_layer.visible = false
	hit_flash.flash()
	var at := _world(IMPLANT_CENTRE)
	BeeLiberation.free_animal(get_parent(), model, _implant_node, at)
	for mesh: Node3D in model.find_children("implant_*", "MeshInstance3D", true, false):
		mesh.hide() # Bracers and every plate go with the device.
	BeeCombatVFX.spawn(get_parent(), at, &"tech_death", Vector3.UP, 1.4)
	BeeCameraShake.kick(self, 0.08, 0.4)
	_freed_left = FREED_WALK_SECONDS
	side = -signf(global_position.x - _cam_x() + 0.001) # Faces the edge it walks to.
	_play(&"walk")
	liberated_now.emit(self)
	phase_changed.emit(state)


func _finish() -> void:
	state = State.DONE
	set_physics_process(false)
	defeated.emit(self)
	queue_free()


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


func live_spiders() -> Array:
	return get_tree().get_nodes_in_group("tarantula_hazards").filter(func(n: Node): return n is TarantulaDropSpider and not n.is_queued_for_deletion())


func _exit_tree() -> void:
	_clear_warnings()
	_clear_threads()
	if is_instance_valid(_hang_line):
		_hang_line.queue_free()


# --- building ------------------------------------------------------------------------------------------------------------

func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	model = MODEL.instantiate() as Node3D
	model.scale = Vector3.ONE * MODEL_SCALE
	visual_root.add_child(model)
	BeeToonStyle.apply(visual_root, true, BeeToonStyle.OUTLINE_ACTOR)
	for mesh: Node3D in model.find_children("implant_*", "MeshInstance3D", true, false):
		for plate in HIDDEN_PLATES:
			if str(mesh.name).begins_with(plate):
				mesh.hide()
	_implant_node = model.find_child("implant", true, false) as Node3D
	_implant_core = model.find_child("implant_core", true, false) as MeshInstance3D
	_dorsal_shell = model.find_child("implant_dorsal_shell", true, false) as MeshInstance3D
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0] as AnimationPlayer
		for clip in [&"idle", &"walk"]:
			if _anim.has_animation(clip):
				_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_mouth_glow = BeeAttackVisuals.sphere(self, global_position, 0.28, Color(0.3, 0.95, 1.0))
	_mouth_glow.top_level = true
	_mouth_glow.scale = Vector3.ONE * 0.01


func _build_areas() -> void:
	body_hurtbox = $Hurtbox3D as DamageHurtbox3D
	(body_hurtbox.get_node("CollisionShape3D") as CollisionShape3D).shape = _box(BODY_SIZE * MODEL_SCALE)
	body_hurtbox.monitorable = false
	implant_hurtbox = _hurtbox("ImplantHurtbox", "../HealthComponent")
	var sphere := SphereShape3D.new()
	sphere.radius = IMPLANT_RADIUS * MODEL_SCALE
	(implant_hurtbox.get_node("CollisionShape3D") as CollisionShape3D).shape = sphere
	_armour_health = HEALTH_SCENE.instantiate() as HealthComponent
	_armour_health.name = "ArmourHealth"
	_armour_health.max_health = 1000000
	add_child(_armour_health)
	_armour_health.health_changed.connect(_on_armour_hit)
	legs_hurtbox = _hurtbox("LegsHurtbox", "../HealthComponent")
	(legs_hurtbox.get_node("CollisionShape3D") as CollisionShape3D).shape = _box(LEGS_SIZE * MODEL_SCALE)
	contact = $ContactHitbox as DamageHitbox3D
	contact.team_id = &"alien"
	contact.damage = CONTACT_DAMAGE
	(contact.get_node("CollisionShape3D") as CollisionShape3D).shape = _box(Vector2(BODY_SIZE.x * 0.8, BODY_SIZE.y * 0.7) * MODEL_SCALE)
	contact.set_enabled(false)
	contact.hit_confirmed.connect(func(h: DamageHurtbox3D, applied: int): if h.owner_entity is BeePlayer: untelegraphed_damage += applied)
	var shape := BoxShape3D.new()
	shape.size = Vector3(BODY_SIZE.x * MODEL_SCALE, BODY_SIZE.y * MODEL_SCALE * 1.1, 1.2)
	_charge_box = BeeAttackVisuals.hazard_area(self, self, CHARGE_DAMAGE, shape)
	_charge_box.top_level = true
	_place_areas()


func _hurtbox(label: String, health_path: String) -> DamageHurtbox3D:
	var area := HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	area.name = label
	area.team_id = &"alien"
	area.health_component_path = NodePath(health_path)
	area.owner_entity_path = NodePath("..")
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	area.add_child(collider)
	area.monitorable = false
	add_child(area)
	return area


func _box(size: Vector2) -> BoxShape3D:
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, size.y, 1.4)
	return box


## Hurtboxes and the contact box follow the pose (on the ground, upside down on the ceiling, head down on the thread).
func _place_areas() -> void:
	if body_hurtbox == null:
		return
	var basis := visual_root.basis.orthonormalized()
	body_hurtbox.global_transform = Transform3D(basis, _world(BODY_CENTRE))
	implant_hurtbox.global_transform = Transform3D(basis, _world(IMPLANT_CENTRE))
	legs_hurtbox.global_transform = Transform3D(basis, _world(LEGS_CENTRE))
	contact.global_transform = body_hurtbox.global_transform


func _play(clip: StringName) -> void:
	if _anim == null or not _anim.has_animation(clip):
		return
	if _anim.current_animation != clip or not _anim.is_playing():
		_anim.play(clip)


func _build_health_bar() -> void:
	_bar_layer = CanvasLayer.new()
	_bar_layer.name = "BossHealthBar"
	_bar_layer.layer = 5
	_bar_layer.visible = false
	add_child(_bar_layer)
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.offset_left = -200.0
	box.offset_right = 200.0
	box.offset_top = 46.0 # TANDA 1 · H-05: top centre, between the player HUD (left) and the combo panel (right).
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_layer.add_child(box)
	var title := Label.new()
	title.text = DISPLAY_NAME
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 5)
	box.add_child(title)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(400, 14)
	_bar.show_percentage = false
	_bar.value = 100.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.25, 0.9, 1.0) # Cyan: the implant's control, not the animal.
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.08, 0.06, 0.12, 0.75)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", back)
	box.add_child(_bar)
	for ratio in [PHASE_2_RATIO, PHASE_3_RATIO, PHASE_4_RATIO]:
		var tick := ColorRect.new()
		tick.color = Color(1.0, 1.0, 1.0, 0.85)
		tick.size = Vector2(2, 14)
		tick.position = Vector2(400.0 * ratio - 1.0, 0.0)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bar.add_child(tick)
	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 16)
	_phase_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_phase_label.add_theme_constant_override("outline_size", 4)
	box.add_child(_phase_label)
	_hint_label = Label.new() # Short instruction, shown for a few seconds only.
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	_hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint_label.add_theme_constant_override("outline_size", 5)
	_hint_label.visible = false
	box.add_child(_hint_label)
	_update_phase_label()


## LOTE 15: right after a trap, an aimed fan (normal warning). Not a pattern step: the pattern goes on after it.
func _start_follow_up() -> void:
	follow_ups += 1
	attacks_started += 1
	attack_kind = &"fan"
	_play(&"attack")
	_step = &"fan_tele"
	_left = FAN_TELEGRAPH
	BeeAudio.play(get_parent(), &"spider_telegraph", global_position, 0.8)


## LOTE 15: moving is not resting: a single aimed web shot every SPIT_EVERY s while it stalks or crawls (mouth glow first).
func _update_spit(delta: float) -> void:
	_spit_clock += delta
	var glow := clampf(1.0 - (SPIT_EVERY - _spit_clock) / SPIT_WARNING, 0.0, 1.0)
	_mouth_glow.global_position = _world(MOUTH)
	_mouth_glow.scale = Vector3.ONE * (0.01 if glow <= 0.0 else lerpf(0.3, 1.0, glow))
	if _spit_clock >= SPIT_EVERY and target != null:
		_spit_clock = 0.0
		spits += 1
		hazards.append({"kind": &"spit", "telegraph": SPIT_WARNING})
		var origin := _world(MOUTH)
		origin.z = 0.0
		_spawn_web(origin, (target.global_position - origin).normalized(), FAN_SPEED)
		_mouth_glow.scale = Vector3.ONE * 0.01
