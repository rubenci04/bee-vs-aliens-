class_name BeeGardenTurtle
extends BeeAftermathTurtle
## LOTE 12 · ETAPA 2 — the garden turtle as a Level 1 ENEMY (slow ground TANK with a lot of life); LOTE 13 · ETAPA 3 — NEW BEHAVIOUR,
## ready for the new model (the current hexagonal-shell model is parked: the turtle is NOT in the Level 1 table until Rubén delivers one):
##   WALK     slow stroll towards Bee (WALK_SPEED), contact damage while Bee skims the ground
##   SPIT     the head rises and a ring marks where the spit will land (SPIT_WARN s, locked SPIT_LOCK_BEFORE s before the shot);
##            it spits UP in a high ARC that comes down on that spot (BeeEnemyPatterns.spawn_lob, never homing)
##   ROLL     it pulls head and legs into the shell (RETRACT_SECONDS), a ground line shows the path (ROLL_WARN s, never under 0.4 s) and
##            the shell is LAUNCHED along the soil towards Bee, spinning, bouncing off the screen edges (ROLL_BOUNCES times), hurting on
##            contact; the implant spins with it (not a target while rolling). Then head and legs come out again.
## Its HP is set by the level director (LEVEL_HP); breaking the implant frees it and it walks off.
## Interface expected by BeeLevel01Controller: activate(bee), is_active(), is_ground(), signals `defeated` / `liberated_now`.

signal defeated(turtle: BeeGardenTurtle)

enum Step { WALK, SPIT_WARN, ROLL_WARN, RETRACT, ROLLING, EMERGE }

const TURTLE_SCALE := 2.0
const WALK_SPEED := 0.45
const CONTACT_DAMAGE := 6
const WALK_SECONDS := 2.4
const ENTER_SPEED := 2.4
const ENTER_INSET := 0.6
const SPIT_WARN := 0.7
const SPIT_LOCK_BEFORE := 0.25
const SPIT_DAMAGE := 6
const SPIT_FLIGHT := 1.7
const SPIT_GRAVITY := 8.0
const SPIT_SHOTS := 2
const SPIT_GAP := 0.35
const ROLL_WARN := 0.9
const RETRACT_SECONDS := 0.4
const ROLL_SPEED := 7.0
const ROLL_DAMAGE := 10
const ROLL_BOUNCES := 2
const ROLL_MAX_SECONDS := 4.5
const SPIN_RATE := 16.0
const ROLL_RADIUS := 0.7
const EDGE_MARGIN := 0.8
const EMERGE_SECONDS := 0.4
const LEAVE_SECONDS := 3.0
const LEAVE_SPEED := 1.4
const WARN_COLOR := Color(1.0, 0.55, 0.15, 0.8)
const LOCK_COLOR := Color(1.0, 0.45, 0.12, 0.85)
const BOLT := preload("res://scenes/projectiles/toon/alien_bolt.tscn")

var target: BeePlayer
var step := Step.WALK
var spits := 0
var rolls := 0
var bounces := 0
var warnings: Array[float] = [] # Measured warnings (tests).
var _active := false
var _clock := 0.0
var _left := WALK_SECONDS
var _step_clock := 0.0
var _next_is_roll := false
var _contact: DamageHitbox3D
var _roll_box: DamageHitbox3D
var _warn_nodes: Array[Node] = []
var _lock_point := Vector3.ZERO
var _locked := false
var _spit_left := 0
var _spit_clock := 0.0
var _roll_dir := -1.0
var _roll_time := 0.0
var _head: Node3D
var _hideable: Array[Node3D] = []


func _ready() -> void:
	super._ready()
	scale = Vector3.ONE * TURTLE_SCALE
	rotation.y = PI # The shell model looks along +X; it walks towards -X.
	var contact_shape := SphereShape3D.new()
	contact_shape.radius = 0.55
	_contact = BeeAttackVisuals.hazard_area(self, self, CONTACT_DAMAGE, contact_shape)
	_contact.name = "ContactHitbox"
	_contact.position = Vector3(0.0, 0.4, 0.0)
	var roll_shape := SphereShape3D.new()
	roll_shape.radius = ROLL_RADIUS / TURTLE_SCALE
	_roll_box = BeeAttackVisuals.hazard_area(self, self, ROLL_DAMAGE, roll_shape)
	_roll_box.name = "RollHitbox"
	_roll_box.position = Vector3(0.0, 0.3, 0.0)
	_head = body.get_node_or_null("Head") as Node3D
	for part in ["Head", "Neck", "Tail"]:
		var node := body.get_node_or_null(part) as Node3D
		if node != null:
			_hideable.append(node)
	for leg in legs:
		_hideable.append(leg)
	hide()


func is_ground() -> bool:
	return true


func is_active() -> bool:
	return _active and not liberated


func is_rolling() -> bool:
	return step == Step.ROLLING


func is_telegraphing() -> bool:
	return step in [Step.SPIT_WARN, Step.ROLL_WARN]


func activate(new_target: BeePlayer) -> bool:
	if _active or new_target == null:
		return false
	target = new_target
	_active = true
	show()
	_contact.set_enabled(true)
	return true


func _physics_process(delta: float) -> void:
	if not _active or liberated:
		return
	if target != null and target.is_defeated:
		_cancel()
		return
	_clock += delta
	_step_clock += delta
	_left -= delta
	match step:
		Step.WALK:
			if not BeeShmupFairness.is_inside_screen(self, ENTER_INSET):
				global_position.x -= ENTER_SPEED * delta # Walks in briskly until it is on screen, then slows to its stroll.
				_left = WALK_SECONDS * 0.3
				return
			if absf(target.global_position.x - global_position.x) > 2.5:
				global_position.x += signf(target.global_position.x - global_position.x) * WALK_SPEED * delta
			body.rotation.z = sin(_clock * 3.0) * 0.03 # Walking bob.
			if _left <= 0.0:
				if _next_is_roll:
					_begin_roll_warn()
				else:
					_begin_spit_warn()
				_next_is_roll = not _next_is_roll
		Step.SPIT_WARN:
			_update_spit_warning()
			if _left <= 0.0:
				_end_warning()
				_fire_spit()
				step = Step.WALK
				_left = WALK_SECONDS
		Step.ROLL_WARN:
			body.rotation.z = sin(_clock * 18.0) * 0.06 # Trembles as it gathers itself.
			if _left <= 0.0:
				_end_warning()
				_set_step(Step.RETRACT, RETRACT_SECONDS)
		Step.RETRACT:
			_pull_in(1.0 - clampf(_left / RETRACT_SECONDS, 0.0, 1.0))
			if _left <= 0.0:
				_begin_roll()
		Step.ROLLING:
			_roll(delta)
		Step.EMERGE:
			_pull_in(clampf(_left / EMERGE_SECONDS, 0.0, 1.0))
			if _left <= 0.0:
				_pull_in(0.0)
				_set_step(Step.WALK, WALK_SECONDS)
				_contact.set_enabled(true)
	if spits_pending():
		_spit_clock -= delta
		if _spit_clock <= 0.0:
			_spit_once()


func _set_step(next: Step, seconds: float) -> void:
	step = next
	_left = seconds
	_step_clock = 0.0


func spits_pending() -> bool:
	return _spit_left > 0


# --- spit: up in an arc ---------------------------------------------------------------------------------------------------------

func _begin_spit_warn() -> void:
	_locked = false
	_lock_point = target.global_position
	_warn_nodes.append(BeeAttackVisuals.ring(get_parent(), Vector3(_lock_point.x, 0.05, 0.0), 1.1, 0.08, WARN_COLOR))
	(_warn_nodes.back() as Node3D).rotation.x = 0.0
	(_warn_nodes.back() as Node3D).scale = Vector3(1.1, 1.0, 0.35)
	_set_step(Step.SPIT_WARN, SPIT_WARN)
	if _head != null:
		_head.rotation.z = 0.7 # The head tilts up.
	BeeAudio.play(get_parent(), &"spider_telegraph", global_position, 0.8)


func _update_spit_warning() -> void:
	if not _locked:
		_lock_point = Vector3(target.global_position.x, target.global_position.y, 0.0)
		if _left <= SPIT_LOCK_BEFORE:
			_locked = true
			if not _warn_nodes.is_empty() and _warn_nodes.back() is MeshInstance3D:
				((_warn_nodes.back() as MeshInstance3D).mesh as TorusMesh).material = BeeAttackVisuals.material(LOCK_COLOR)
	if not _warn_nodes.is_empty():
		(_warn_nodes.back() as Node3D).global_position = Vector3(_lock_point.x, 0.05, 0.0)


func _fire_spit() -> void:
	if _head != null:
		_head.rotation.z = 0.0
	_spit_left = SPIT_SHOTS
	_spit_clock = 0.0


func _spit_once() -> void:
	_spit_left -= 1
	_spit_clock = SPIT_GAP
	spits += 1
	if not BeeShmupFairness.can_fire(self):
		return
	var mouth := global_position + Vector3(-0.8 * TURTLE_SCALE, 0.6 * TURTLE_SCALE, 0.0) # In front of the head (it walks towards -X).
	var landing := Vector3(_lock_point.x + (0.9 if _spit_left == 0 else 0.0), maxf(_lock_point.y, 0.3), 0.0)
	BeeEnemyPatterns.spawn_lob(get_parent(), BOLT, mouth, landing, SPIT_DAMAGE, SPIT_FLIGHT, SPIT_GRAVITY, self, &"bile")
	BeeCombatVFX.spawn(get_parent(), mouth, &"tech_hit", Vector3.UP, 0.5)


# --- roll: head in, shell launched along the soil -------------------------------------------------------------------------------

func _begin_roll_warn() -> void:
	var dir := signf(target.global_position.x - global_position.x)
	_roll_dir = dir if dir != 0.0 else -1.0
	var camera := get_viewport().get_camera_3d()
	var edge := (camera.global_position.x + _roll_dir * (BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport())) - EDGE_MARGIN)) if camera != null else global_position.x + _roll_dir * 6.0
	_warn_nodes.append(BeeAttackVisuals.line(get_parent(), Vector3(global_position.x, 0.4, 0.0), Vector3(edge, 0.4, 0.0), 0.5, Color(1.0, 0.55, 0.15, 0.3)))
	_contact.set_enabled(false)
	_set_step(Step.ROLL_WARN, ROLL_WARN)
	BeeAudio.play(get_parent(), &"walker_charge", global_position, 0.7)


func _pull_in(amount: float) -> void:
	# amount 1 = head, tail and legs fully inside the shell (scaled away); 0 = out.
	for node in _hideable:
		node.scale = Vector3.ONE * maxf(1.0 - amount, 0.01)


func _begin_roll() -> void:
	rolls += 1
	bounces = 0
	_roll_time = 0.0
	_roll_box.set_enabled(true)
	hurtbox.set_deferred("monitorable", false) # The implant spins with the shell: not a target meanwhile.
	remove_from_group("bee_auto_aim_targets")
	_set_step(Step.ROLLING, ROLL_MAX_SECONDS)
	BeeAudio.play(get_parent(), &"human_step", global_position, 1.3)


func _roll(delta: float) -> void:
	_roll_time += delta
	global_position.x += _roll_dir * ROLL_SPEED * delta
	body.rotation.y += _roll_dir * SPIN_RATE * delta # Spins like a top while it travels.
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport())) - EDGE_MARGIN
		var rel := global_position.x - camera.global_position.x
		if (_roll_dir > 0.0 and rel >= half) or (_roll_dir < 0.0 and rel <= -half):
			bounces += 1
			_roll_dir = -_roll_dir # Bounces off the edge of the screen.
			BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0.0, 0.3, 0.3), &"rock_hit", Vector3.UP, 0.8)
			BeeCameraShake.kick(self, 0.02, 0.1)
	if bounces > ROLL_BOUNCES or _roll_time >= ROLL_MAX_SECONDS:
		_end_roll()


func _end_roll() -> void:
	_roll_box.set_enabled(false)
	body.rotation = Vector3.ZERO
	hurtbox.set_deferred("monitorable", true)
	if not is_in_group("bee_auto_aim_targets"):
		add_to_group("bee_auto_aim_targets")
	_set_step(Step.EMERGE, EMERGE_SECONDS)


# --- shared ----------------------------------------------------------------------------------------------------------------------

func _end_warning() -> void:
	if step in [Step.SPIT_WARN, Step.ROLL_WARN]:
		warnings.append(_step_clock)
	_clear_warning()


func _cancel() -> void:
	_clear_warning()
	_roll_box.set_enabled(false)
	_spit_left = 0


func _clear_warning() -> void:
	for node in _warn_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_warn_nodes.clear()


func _liberate() -> void:
	if liberated:
		return
	_cancel()
	_pull_in(0.0)
	body.rotation = Vector3.ZERO
	_contact.set_enabled(false)
	super._liberate()
	var away := create_tween()
	away.tween_property(self, "global_position", global_position + Vector3(-LEAVE_SPEED * LEAVE_SECONDS, 0.0, 0.0), LEAVE_SECONDS)
	away.tween_callback(_finish)


func _finish() -> void:
	hide()
	set_physics_process(false)
	defeated.emit(self)


func _exit_tree() -> void:
	_clear_warning()
