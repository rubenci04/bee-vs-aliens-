class_name BeetleCannon
extends Node
## Tanda E: the stag beetle lobs heavy grenades from its dorsal implant as soon as it has walked on screen (first one <= 1.5 s later),
## then reloads slowly (4-5 s from launch to launch). Two weapons ALTERNATE: a QUAKE grenade (lands on Bee's X and explodes into a big
## ground shockwave) and a FAN grenade (bursts near Bee and sheds 3 aimed shots). Its ram (AssetFauna) stays the third action: it
## interrupts the walk, and a warning that a ram pre-empts is retried. 0.5 s pulse (COMMON_CUE) first, one common attack slot while committed.
const COMMON_CUE := preload("res://scripts/vfx/bee_common_attack_cue.gd")
const FIRST_DELAY := 0.2 ## s on screen before the first warning (launch = FIRST_DELAY + WARNING after it materialises)
const FIRST_RAM_AFTER := 2.5 ## its first ram waits this long after it walks in
const RECHARGE_MIN := 4.0 ## s from one launch to the next
const RECHARGE_MAX := 5.0
const WARNING := 0.5
const RETRY := 0.6
const FAN_AIR_MIN_Y := 2.4
const FAN_AIR_MAX_Y := 4.8
const FAN_LEAD := 0.6 ## the fan grenade bursts this fraction of the way from the beetle to Bee
const SCREEN_MARGIN := 0.5 ## it counts as on screen when its X is within the half width minus this
var beetle: AssetFauna
var target: Node3D
var clock := 0.0
var wait := FIRST_DELAY
var warning_left := -1.0
var shots := 0
var warnings: Array[float] = []
var launches: Array[Dictionary] = [] ## {kind, time} - tests read it
var on_screen_time := -1.0 ## seconds the beetle has been active on screen when the first shot left (tests)
var _seen := false
var _age := 0.0

func _ready() -> void:
	if is_instance_valid(beetle):
		beetle.first_idle_time = maxf(beetle.first_idle_time, FIRST_RAM_AFTER) # The first grenade leaves before its first ram.

func _physics_process(delta: float) -> void:
	if not is_instance_valid(beetle) or not beetle.is_inside_tree() or not is_instance_valid(target) or beetle.liberated:
		return
	if not beetle.is_active() or bool(beetle.get_meta("teleporting", false)) or beetle.stunned or not _on_screen():
		_abort()
		return
	_seen = true
	_age += delta
	if warning_left >= 0.0:
		if beetle.state in [AssetFauna.State.TELEGRAPH, AssetFauna.State.ATTACK, AssetFauna.State.RECOVER]:
			_abort() # Its ram started first: the ram wins.
			return
		warning_left -= delta
		if warning_left <= 0.0:
			warning_left = -1.0
			_fire()
		return
	clock += delta # Counts in every state: its ram is an extra action, not a pause in the reload.
	if not beetle.state in [AssetFauna.State.IDLE, AssetFauna.State.ENTER]:
		return
	if clock < wait:
		return
	if not BeeCommonSlots.try_take(beetle):
		wait = clock + RETRY
		return
	warning_left = WARNING
	warnings.append(WARNING)
	COMMON_CUE.begin(beetle, &"stag_beetle", beetle.visual, WARNING)

func _on_screen() -> bool:
	var camera := beetle.get_viewport().get_camera_3d()
	if camera == null:
		return true
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(beetle.get_viewport()))
	return absf(beetle.global_position.x - camera.global_position.x) <= half - SCREEN_MARGIN

func _abort() -> void:
	if warning_left >= 0.0:
		warning_left = -1.0
		BeeCommonSlots.release(beetle)
		COMMON_CUE.cancel(beetle.visual)
		wait = clock + RETRY

func _fire() -> void:
	var kind := BeetleGrenade.KIND_QUAKE if shots % 2 == 0 else BeetleGrenade.KIND_FAN
	shots += 1
	clock = 0.0
	wait = randf_range(RECHARGE_MIN, RECHARGE_MAX) - WARNING
	var origin := beetle._muzzle()
	var grenade := BeetleGrenade.new()
	grenade.kind = kind
	grenade.attacker = beetle
	grenade.target = target
	beetle.get_parent().add_child(grenade)
	var goal: Vector3
	if kind == BeetleGrenade.KIND_QUAKE:
		goal = Vector3(_clamp_x(target.global_position.x), BeetleGrenade.GROUND_Y, 0.0)
	else:
		var x := lerpf(beetle.global_position.x, target.global_position.x, FAN_LEAD)
		goal = Vector3(x, clampf(target.global_position.y, FAN_AIR_MIN_Y, FAN_AIR_MAX_Y), 0.0)
	grenade.launch(origin, goal)
	if on_screen_time < 0.0:
		on_screen_time = _age
	launches.append({"kind": kind, "age": _age})
	BeeCommonSlots.release(beetle)

func _clamp_x(x: float) -> float:
	var camera := beetle.get_viewport().get_camera_3d()
	if camera == null:
		return x
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(beetle.get_viewport()))
	return clampf(x, camera.global_position.x - half + 1.0, camera.global_position.x + half - 1.0)
