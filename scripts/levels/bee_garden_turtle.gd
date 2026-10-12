class_name BeeGardenTurtle
extends BeeAftermathTurtle
## LOTE 12 · ETAPA 2 — the garden turtle as a Level 1 ENEMY (slow ground TANK with a lot of life). It reuses the rebuilt turtle
## (hexagonal shell, implant, liberation) of the "human aftermath" moment, scaled up, and adds a level role:
##   walks slowly towards -X (WALK_SPEED against the soil), contact damage while Bee skims the ground, and every SLAM_EVERY s a
##   SHELL SLAM: a ground ring warns SLAM_WARN s (never under the 0.4 s minimum) and then a shock hitbox of SLAM_RADIUS m is live
##   for SLAM_ACTIVE s. Its HP is set by the level director (LEVEL_HP); breaking the implant frees it and it walks off.
## Interface expected by BeeLevel01Controller: activate(bee), is_active(), is_ground(), signals `defeated` / `liberated_now`.

signal defeated(turtle: BeeGardenTurtle)

const TURTLE_SCALE := 2.0
const WALK_SPEED := 0.45
const CONTACT_DAMAGE := 8
const SLAM_EVERY := 5.0
const SLAM_WARN := 0.9
const SLAM_ACTIVE := 0.25
const SLAM_RADIUS := 2.1
const SLAM_DAMAGE := 10
const LEAVE_SECONDS := 3.0
const LEAVE_SPEED := 1.4

var target: BeePlayer
var slams := 0
var slam_warnings: Array[float] = [] # Measured warnings (tests).
var _active := false
var _clock := 0.0
var _slam_in := SLAM_EVERY
var _warn_left := -1.0
var _active_left := -1.0
var _warn_nodes: Array[Node] = []
var _contact: DamageHitbox3D
var _slam_box: DamageHitbox3D


func _ready() -> void:
	super._ready()
	scale = Vector3.ONE * TURTLE_SCALE
	rotation.y = PI # The shell model looks along +X; it walks towards -X.
	var contact_shape := SphereShape3D.new()
	contact_shape.radius = 0.55
	_contact = BeeAttackVisuals.hazard_area(self, self, CONTACT_DAMAGE, contact_shape)
	_contact.name = "ContactHitbox"
	_contact.position = Vector3(0.0, 0.4, 0.0)
	var slam_shape := SphereShape3D.new()
	slam_shape.radius = SLAM_RADIUS / TURTLE_SCALE
	_slam_box = BeeAttackVisuals.hazard_area(self, self, SLAM_DAMAGE, slam_shape)
	_slam_box.name = "SlamHitbox"
	_slam_box.position = Vector3(0.0, 0.2, 0.0)
	hide()


func is_ground() -> bool:
	return true


func is_active() -> bool:
	return _active and not liberated


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
		_cancel_slam()
		return
	_clock += delta
	global_position.x -= WALK_SPEED * delta
	# Walking bob: the shell rocks a little with each step.
	body.rotation.z = sin(_clock * 3.0) * 0.03
	if _warn_left >= 0.0:
		_warn_left -= delta
		if _warn_left <= 0.0:
			slam_warnings.append(SLAM_WARN)
			_clear_warning()
			_active_left = SLAM_ACTIVE
			_slam_box.set_enabled(true)
			BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0.0, 0.3, 0.0), &"bomb", Vector3.UP, SLAM_RADIUS)
			slams += 1
		return
	if _active_left >= 0.0:
		_active_left -= delta
		if _active_left <= 0.0:
			_slam_box.set_enabled(false)
			_active_left = -1.0
			_slam_in = SLAM_EVERY
		return
	_slam_in -= delta
	if _slam_in <= 0.0:
		_warn_left = SLAM_WARN
		_warn_nodes.append(BeeAttackVisuals.ring(get_parent(), Vector3(global_position.x, 0.05, 0.0), SLAM_RADIUS, 0.08, Color(1.0, 0.55, 0.15, 0.8)))
		_warn_nodes.back().rotation.x = 0.0 # Lying on the ground, seen edge-on by the side camera: a thin ellipse.
		(_warn_nodes.back() as Node3D).scale = Vector3(SLAM_RADIUS, 1.0, SLAM_RADIUS * 0.3)


func _cancel_slam() -> void:
	_clear_warning()
	_slam_box.set_enabled(false)
	_warn_left = -1.0


func _clear_warning() -> void:
	for node in _warn_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_warn_nodes.clear()


func _liberate() -> void:
	if liberated:
		return
	_cancel_slam()
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
