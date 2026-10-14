class_name BeeGardenToadEncounter
extends BeeLakeToadBoss
## Reuses the lake animal, implant, tongue mesh and liberation; garden movement is independent.
const GARDEN_HP := 210 # Seven seconds of accurate Base taps at 3/s.
const TIMEOUT_SECONDS := 50.0
const SCROLL_FACTOR := 0.05
const HOP_DISTANCE := 3.6
const HOP_DURATION := 0.65
const HOP_LIFT := 1.4
const GROUND_Y := 0.05
const REST_SECONDS := 0.22
const WARN_SECONDS := 0.6
const REACH_RATIO := 0.60
const MODERATE_DAMAGE := 8
const EXIT_SECONDS := 3.0
const MOUTH_OPEN_SCALE := Vector3(1.0, 1.18, 1.0)
signal landing
var crossings := 0
var variants: Array[int] = []
var locked_directions: Array[Vector3] = []
var expired := false
var exiting := false
var elapsed := 0.0
var _move_sign := -1.0
var _hop_from := 0.0
var _hop_to := 0.0
var _hops := 0
var _variant := 0
var _double_left := 0
var _reach := 0.0
var _exit_left := EXIT_SECONDS
var _mouth_pose: MeshInstance3D

func _ready() -> void:
	super._ready()
	health.max_health = BeeGameSettings.scaled_hp(GARDEN_HP)
	health.current_health = health.max_health
	_tongue_box.damage = MODERATE_DAMAGE
	_mouth_pose = BeeAttackVisuals.sphere(self, Vector3.ZERO, 0.25, Color(0.22, 0.12, 0.08), false)
	_mouth_pose.name = "OpenMouth"
	_mouth_pose.top_level = true
	_mouth_pose.hide()

func activate(new_target: BeePlayer) -> bool:
	if not super.activate(new_target):
		return false
	_rel_x = _half() + 2.8
	global_position = Vector3(_camera_x() + _rel_x, GROUND_Y, 0)
	_start_hop()
	return true

func _half() -> float:
	return BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))

func _camera_x() -> float:
	var camera := get_viewport().get_camera_3d()
	return camera.global_position.x if camera != null else 0.0

func mouth() -> Vector3:
	return global_position + Vector3(_move_sign * 1.1 * MODEL_SCALE, 0.55 * MODEL_SCALE, 0)

func is_active() -> bool:
	return _activated and not liberated and not exiting

func _physics_process(delta: float) -> void:
	if target != null and target.is_defeated:
		_tongue_box.set_enabled(false)
		_clear_warn()
		set_physics_process(false)
		return
	elapsed += delta
	if elapsed >= TIMEOUT_SECONDS and not exiting:
		expired = not liberated
		_leave()
	if exiting:
		_exit_left -= delta
		_rel_x += HOP_DISTANCE / HOP_DURATION * delta
		global_position = Vector3(_camera_x() + _rel_x, GROUND_Y + absf(sin(_exit_left * PI / HOP_DURATION)) * HOP_LIFT, 0)
		if _exit_left <= 0.0:
			state = State.DONE
			hide()
			set_physics_process(false)
			defeated.emit(self)
		return
	_left -= delta
	match state:
		State.JUMP:
			var k := 1.0 - clampf(_left / HOP_DURATION, 0, 1)
			_rel_x = lerpf(_hop_from, _hop_to, k)
			global_position = Vector3(_camera_x() + _rel_x, GROUND_Y + sin(k * PI) * HOP_LIFT, 0)
			if _left <= 0:
				_hops += 1
				landing.emit()
				if _rel_x * _move_sign >= _half() + 1.0:
					crossings += 1
					_move_sign *= -1.0
				_begin(State.WAIT, REST_SECONDS)
		State.WAIT:
			global_position = Vector3(_camera_x() + _rel_x, GROUND_Y, 0)
			if _left <= 0:
				if _hops % 2 == 0 and absf(_rel_x) < _half() - 1.5:
					_start_tongue()
				else:
					_start_hop()
		State.TONGUE_WARN:
			_update_warning()
			if _left <= 0:
				# Sample Bee NOW. Once launched this direction never follows her.
				_aim = _direction_to_bee()
				locked_directions.append(_aim)
				telegraphs.append(WARN_SECONDS)
				_clear_warn()
				_mouth_pose.hide()
				visual.scale = Vector3.ONE * MODEL_SCALE
				tongues += 1
				_tongue.show()
				_tongue_box.set_enabled(true)
				_begin(State.TONGUE, TONGUE_OUT + TONGUE_HOLD + TONGUE_BACK)
		State.TONGUE:
			var t := TONGUE_OUT + TONGUE_HOLD + TONGUE_BACK - _left
			var extension := clampf(t / TONGUE_OUT, 0, 1) if t < TONGUE_OUT + TONGUE_HOLD else clampf(_left / TONGUE_BACK, 0, 1)
			var tip := mouth() + _aim * _reach * extension
			BeeAttackVisuals.place_line(_tongue, mouth(), tip)
			_tongue_box.global_position = tip
			if _left <= 0:
				_tongue.hide()
				_tongue_box.set_enabled(false)
				if _double_left > 0:
					_double_left -= 1
					_prepare_warning()
				else:
					_start_hop()
	visual.rotation.y = 0.0 if _move_sign < 0 else PI

func _start_hop() -> void:
	_hop_from = _rel_x
	_hop_to = _rel_x + _move_sign * HOP_DISTANCE
	_begin(State.JUMP, HOP_DURATION)

func _direction_to_bee() -> Vector3:
	var aim := target.global_position - mouth()
	var horizontal := signf(aim.x) if absf(aim.x) > 0.1 else _move_sign
	if _variant == 0:
		return Vector3(horizontal, 0, 0)
	if _variant == 1:
		aim.y = maxf(aim.y, absf(aim.x) * 0.25)
	return Vector3(aim.x, aim.y, 0).normalized()

func _start_tongue() -> void:
	_variant = variants.size() % 3
	variants.append(_variant)
	_double_left = 1 if _variant == 2 else 0
	_prepare_warning()

func _prepare_warning() -> void:
	_reach = _half() * 2.0 * REACH_RATIO
	_warn.append(BeeAttackVisuals.line(self, mouth(), mouth() + _direction_to_bee() * _reach, 0.12, Color(0.2, 0.95, 1.0, 0.75)))
	BeeAttackVisuals.WARNING_STYLE.dress(_warn.back(), Color(0.2, 0.95, 1), 3.0, WARN_SECONDS)
	visual.scale = Vector3.ONE * MODEL_SCALE * MOUTH_OPEN_SCALE
	_mouth_pose.global_position = mouth()
	_mouth_pose.show()
	_begin(State.TONGUE_WARN, WARN_SECONDS)

func _update_warning() -> void:
	if not _warn.is_empty():
		BeeAttackVisuals.place_line(_warn[0], mouth(), mouth() + _direction_to_bee() * _reach)

func _liberate() -> void:
	if liberated:
		return
	liberated = true
	add_to_group("bee_liberated")
	visual.call("release_control")
	var device := visual.find_child("AlienControlDevice", true, false) as Node3D
	BeeLiberation.free_animal(get_parent(), visual, device, global_position + Vector3(0, 2, 0))
	liberated_now.emit(self)
	_leave()

func _leave() -> void:
	exiting = true
	_clear_warn()
	_tongue.hide()
	_mouth_pose.hide()
	_tongue_box.set_enabled(false)
	hurtbox.set_deferred("monitorable", false)
	remove_from_group("bee_auto_aim_targets")
	visual.scale = Vector3.ONE * MODEL_SCALE
	visual.rotation.y = PI
