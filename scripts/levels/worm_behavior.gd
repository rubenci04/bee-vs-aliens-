class_name WormBehavior
extends Node
## LOTE 13 · ETAPA 3 — the Level 1 WORM A (rose worm) cycle, a child of its AssetFauna (kind worm_rose, config "worm_a"):
##   BURIED  nothing to see; REST_SECONDS later it picks a spot just ahead of Bee
##   MARK    a ground mark warns MARK_SECONDS (disc + ring at the spot)
##   ERUPT   a dirt burst and the worm rises out of the soil standing up (head first), ERUPT_SECONDS; the eruption itself hurts
##   PEEK    the head tilts towards Bee and a THIN LINE follows her; it LOCKS (turns orange) LOCK_BEFORE s before the shot (warning LASER_WARN s)
##   LASER   a thin beam along the locked line, LASER_ACTIVE s
##   CROUCH  a ring marks where it will land (LEAP_WARN s), then
##   LEAP    it jumps in an ARC to that spot (it never homes), LEAP_SECONDS, hurting on contact
##   LAND    lying on the soil, vulnerable, LAND_SECONDS; then it digs back in (BURY_SECONDS) with another burst
## The body is 16 segments that undulate with a travelling sine wave all the time (AssetFauna._undulate); the worm is only a target and a
## threat from the eruption on (while buried it is neither). Every warning is >= 0.4 s.

enum Step { BURIED, MARK, ERUPT, PEEK, LASER, CROUCH, LEAP, LAND, BURY }

const REST_SECONDS := 0.6
const FIRST_REST := 0.25
const MARK_SECONDS := 0.8
const ERUPT_SECONDS := 0.45
const ERUPT_DEPTH := 1.5
const STAND_ANGLE := 90.0 ## degrees: the worm stands up out of the soil
const LEAN_DEGREES := 22.0 ## ...and its head leans towards Bee
const LASER_WARN := 0.6
const LINE_WIDTH := 0.04 ## LOTE 14 · ETAPA 3.3: thin aim line (was 0.07)...
const LINE_DODGE_CLEARANCE := 0.9 ## ...that disappears once Bee is this far off the locked line.
const LOCK_BEFORE := 0.25
const LASER_ACTIVE := 0.2
const LASER_WIDTH := 0.14
const LASER_DAMAGE := 4
const LASER_LENGTH := 11.0
const LEAP_WARN := 0.5
const LEAP_SECONDS := 0.7
const LEAP_HEIGHT := 2.6
const LEAP_MIN_DISTANCE := 1.5 ## m: it never lands closer to the spot it left than this (it must travel)
const LAND_SECONDS := 0.5
const BURY_SECONDS := 0.4
const SPOT_AHEAD := 2.6
const WARN_COLOR := Color(1.0, 0.55, 0.15, 0.8)
const LOCK_COLOR := Color(1.0, 0.45, 0.12, 0.85)
const BEAM_COLOR := Color(0.35, 1.0, 1.0, 0.95)

var fauna: AssetFauna
var step := Step.BURIED
var left := FIRST_REST
var cycles := 0
var lasers := 0
var leaps := 0
var warnings: Array[float] = [] ## Measured warning lengths (tests).
var _line: MeshInstance3D
var _locked := false
var _lock_point := Vector3.ZERO
var _origin := Vector3.ZERO
var _land := Vector3.ZERO
var _leap_from := Vector3.ZERO
var _beam: MeshInstance3D
var _beam_box: DamageHitbox3D
var _step_started := 0.0
var _clock := 0.0


func setup(owner_fauna: AssetFauna) -> void:
	fauna = owner_fauna
	name = "WormBehavior"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, LASER_WIDTH, 1.0)
	_beam_box = BeeAttackVisuals.hazard_area(fauna, fauna, LASER_DAMAGE, shape)
	_beam_box.name = "LaserHitbox"
	_beam_box.top_level = true
	_beam_box.set_enabled(false)


func begin() -> void:
	step = Step.BURIED
	left = FIRST_REST
	fauna._set_buried(true)


func is_warning() -> bool:
	return step in [Step.MARK, Step.PEEK, Step.CROUCH]


## The line the current warning marks: [from, to, half_width] once it has locked (the bot reads it like the player reads the screen).
func warned_line() -> Array:
	if step == Step.PEEK and _locked:
		var from := _head()
		return [from, from + (_lock_point - from).normalized() * LASER_LENGTH, 0.7]
	if step == Step.CROUCH:
		return [_land, _land + Vector3(0.05, 0.0, 0.0), 1.3]
	return []


func step_frame(delta: float) -> void:
	_clock += delta
	left -= delta
	match step:
		Step.BURIED:
			if left <= 0.0:
				_begin_mark()
		Step.MARK:
			if left <= 0.0:
				_end_warning()
				_begin_erupt()
		Step.ERUPT:
			var t := 1.0 - clampf(left / ERUPT_SECONDS, 0.0, 1.0)
			fauna.rig.position.y = lerpf(-ERUPT_DEPTH, 0.0, ease(t, 0.35))
			_stand(t)
			if left <= 0.0:
				fauna.attack_hitbox.set_enabled(false)
				_begin_peek()
		Step.PEEK:
			_stand(1.0)
			_update_aim()
			if left <= 0.0:
				_end_warning()
				_fire_laser()
		Step.LASER:
			if left <= 0.0:
				_beam_box.set_enabled(false)
				if is_instance_valid(_beam):
					_beam.queue_free()
				_begin_crouch()
		Step.CROUCH:
			_stand(1.0)
			if left <= 0.0:
				_end_warning()
				_begin_leap()
		Step.LEAP:
			var t := 1.0 - clampf(left / LEAP_SECONDS, 0.0, 1.0)
			var p := _leap_from.lerp(_land, t)
			p.y = fauna.ground_y + sin(t * PI) * LEAP_HEIGHT
			fauna.global_position = p
			fauna.rig.rotation.z = lerpf(-0.7, 0.7, t) * (-1.0 if fauna.forward_x() > 0.0 else 1.0) # Nose up, then down.
			if left <= 0.0:
				fauna.global_position = Vector3(_land.x, fauna.ground_y, 0.0)
				fauna.attack_hitbox.set_enabled(false)
				_dirt(fauna.global_position, 0.8)
				_set_step(Step.LAND, LAND_SECONDS)
				fauna.rig.rotation.z = 0.0
		Step.LAND:
			if left <= 0.0:
				_set_step(Step.BURY, BURY_SECONDS)
				_dirt(fauna.global_position, 0.9)
		Step.BURY:
			var t := 1.0 - clampf(left / BURY_SECONDS, 0.0, 1.0)
			fauna.rig.position.y = lerpf(0.0, -ERUPT_DEPTH, t)
			if left <= 0.0:
				cycles += 1
				fauna.cycles_done = cycles
				fauna.rig.position.y = 0.0
				fauna.rig.rotation.z = 0.0
				fauna._set_buried(true)
				_set_step(Step.BURIED, REST_SECONDS)
				if cycles >= fauna.max_cycles:
					fauna.state = AssetFauna.State.EXIT


func cancel() -> void:
	_end_warning()
	_beam_box.set_enabled(false)
	if is_instance_valid(_beam):
		_beam.queue_free()
	fauna.attack_hitbox.set_enabled(false)


func _set_step(next: Step, seconds: float) -> void:
	step = next
	left = seconds
	_step_started = _clock


func _head() -> Vector3:
	var segment := fauna.visual.find_child("Segment_00", true, false) as Node3D
	return segment.global_position if segment != null else fauna.global_position + Vector3(0.0, 1.0, 0.0)


func _stand(amount: float) -> void:
	# The model lies along X with its head at -X. Standing up (rotation.z) with the head leaning towards Bee (rig.rotation.y mirrors it).
	var lean := LEAN_DEGREES * amount
	fauna.rig.rotation.z = -deg_to_rad(lerpf(0.0, STAND_ANGLE, amount) - lean * amount)


func _dirt(at: Vector3, size: float) -> void:
	BeeCombatVFX.spawn(fauna.get_parent(), at + Vector3(0.0, 0.1, 0.4), &"rock_break", Vector3.UP, size)
	BeeAudio.play(fauna.get_parent(), &"crate", at, 0.8)


func _begin_mark() -> void:
	var camera := fauna.get_viewport().get_camera_3d()
	var bee := fauna.target.global_position
	var spot := minf(bee.x + SPOT_AHEAD, camera.global_position.x + 5.0) if camera != null else bee.x + SPOT_AHEAD
	fauna.global_position = Vector3(spot, fauna.ground_y, 0.0)
	fauna.rig.position.y = -ERUPT_DEPTH
	_origin = fauna.global_position
	fauna.attacks_started += 1
	if fauna.first_telegraph_clock < 0.0:
		fauna.first_telegraph_clock = fauna._clock
	fauna._warn.append(BeeAttackVisuals.ground_disc(fauna.get_parent(), Vector3(spot, fauna.ground_y + 0.05, 0.0), 1.5, WARN_COLOR))
	fauna._warn.append(BeeAttackVisuals.ring(fauna.get_parent(), Vector3(spot, fauna.ground_y + 0.2, 0.0), 1.1, 0.06, WARN_COLOR))
	if BeeAttackVisuals.WARNING_STYLE.enabled:
		fauna._warn.append(BeeAttackVisuals.warning_dome(fauna.get_parent(), Vector3(spot, fauna.ground_y, 0), 1.5))
	_set_step(Step.MARK, MARK_SECONDS)


func _end_warning() -> void:
	if is_warning():
		warnings.append(_clock - _step_started)
		fauna.telegraphs.append(_clock - _step_started)
	fauna._clear_warn()
	if is_instance_valid(_line):
		_line.queue_free()
	_line = null


func _begin_erupt() -> void:
	fauna._set_buried(false)
	fauna.rig.position.y = -ERUPT_DEPTH
	_dirt(_origin, 1.5)
	BeeCameraShake.kick(fauna, 0.02, 0.15)
	fauna.attack_hitbox.position = Vector3(0.0, 0.8, 0.0)
	fauna.attack_hitbox.set_enabled(true) # The eruption hurts whoever is on the spot.
	fauna._play("attack")
	_set_step(Step.ERUPT, ERUPT_SECONDS)


func _begin_peek() -> void:
	BeeShotWarning.volley(fauna, &"worm", fauna.visual, LASER_WARN)
	_locked = false
	_lock_point = fauna.target.global_position
	_line = BeeAttackVisuals.line(fauna.get_parent(), _head(), _lock_point, LINE_WIDTH, WARN_COLOR)
	BeeAttackVisuals.WARNING_STYLE.dress(_line, WARN_COLOR, 1.0, LASER_WARN)
	_set_step(Step.PEEK, LASER_WARN)


func _update_aim() -> void:
	if not is_instance_valid(_line):
		return
	if not _locked:
		_lock_point = fauna.target.global_position # The line follows Bee...
		if left <= LOCK_BEFORE:
			_locked = true # ...and locks (orange) a moment before the shot.
			(_line.mesh as BoxMesh).material = BeeAttackVisuals.material(LOCK_COLOR)
	BeeAttackVisuals.place_line(_line, _head(), _lock_point)
	if _locked:
		BeeAttackVisuals.hide_when_dodged(_line, _head(), _lock_point, fauna.target.global_position, LINE_DODGE_CLEARANCE, LASER_LENGTH)
	# The head looks along the line: the model faces its horizontal side.
	fauna._facing = signf(_lock_point.x - fauna.global_position.x) if absf(_lock_point.x - fauna.global_position.x) > 0.15 else fauna._facing


func _fire_laser() -> void:
	lasers += 1
	var from := _head()
	var direction := (_lock_point - from)
	direction.z = 0.0
	direction = direction.normalized() if direction.length() > 0.05 else Vector3.LEFT
	var to := from + direction * LASER_LENGTH
	_beam = BeeAttackVisuals.line(fauna.get_parent(), from, to, LASER_WIDTH * 1.4, BEAM_COLOR)
	var box := (_beam_box.get_child(0) as CollisionShape3D).shape as BoxShape3D
	box.size = Vector3(LASER_LENGTH, LASER_WIDTH, 1.0)
	_beam_box.global_position = (from + to) * 0.5
	_beam_box.global_rotation = Vector3(0.0, 0.0, atan2(direction.y, direction.x))
	_beam_box.set_enabled(true)
	BeeAudio.play(fauna.get_parent(), &"ufo_charge", from, 1.6)
	_land = Vector3(_lock_point.x, fauna.ground_y, 0.0)
	_set_step(Step.LASER, LASER_ACTIVE)


func _begin_crouch() -> void:
	# Lands on the spot where Bee was at the lock, but never closer than LEAP_MIN_DISTANCE to where it came out.
	var camera := fauna.get_viewport().get_camera_3d()
	var landing_x := _land.x
	if absf(landing_x - _origin.x) < LEAP_MIN_DISTANCE:
		landing_x = _origin.x + LEAP_MIN_DISTANCE * (-1.0 if fauna._facing < 0.0 else 1.0)
	if camera != null:
		landing_x = clampf(landing_x, camera.global_position.x - 5.0, camera.global_position.x + 5.0)
	_land = Vector3(landing_x, fauna.ground_y, 0.0)
	fauna._warn.append(BeeAttackVisuals.ground_disc(fauna.get_parent(), Vector3(_land.x, fauna.ground_y + 0.05, 0.0), 1.2, WARN_COLOR))
	fauna._warn.append(BeeAttackVisuals.ring(fauna.get_parent(), Vector3(_land.x, fauna.ground_y + 0.2, 0.0), 1.0, 0.06, LOCK_COLOR))
	_set_step(Step.CROUCH, LEAP_WARN)


func _begin_leap() -> void:
	leaps += 1
	_leap_from = fauna.global_position
	fauna.rig.position.y = 0.0
	fauna.attack_hitbox.position = Vector3(0.0, 0.4, 0.0)
	fauna.attack_hitbox.set_enabled(true)
	fauna._facing = signf(_land.x - _leap_from.x) if absf(_land.x - _leap_from.x) > 0.1 else fauna._facing
	fauna._play("attack")
	_set_step(Step.LEAP, LEAP_SECONDS)
