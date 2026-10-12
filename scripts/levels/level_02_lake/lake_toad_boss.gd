class_name BeeLakeToadBoss
extends Node3D
## NOCHE 01 · ETAPA 4 — Level 02 "Laguna" mini-boss: a giant toad with an alien implant on its back (Codex visual
## `lake_toad_miniboss_visual`, driven here). It is an ANIMAL: breaking the implant FREES it (BeeLiberation), it never dies.
##   TONGUE  a red warning line from its mouth to where Bee is (TONGUE_TELEGRAPH s), then the tongue shoots out along that
##           line (TONGUE_REACH m) and back; only the tongue tip hurts.
##   JUMP    a ring on the water where it will land (JUMP_TELEGRAPH s), a high hop, and on landing a low SHOCKWAVE that runs
##           along the water both ways (hurts below WAVE_HEIGHT: fly up to dodge).
## It alternates TONGUE, TONGUE, JUMP and stays on its lily pads at the right of the screen (camera-relative).

signal defeated(boss: BeeLakeToadBoss)
signal liberated_now(boss: BeeLakeToadBoss)

enum State { IDLE, ENTER, WAIT, TONGUE_WARN, TONGUE, JUMP_WARN, JUMP, LAND, FREED, DONE }

const VISUAL := preload("res://scenes/levels/level_02_lake/lake_toad_miniboss_visual.tscn")
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const MODEL_SCALE := 2.1
const WATER_Y := -0.15
const REST_X := 4.2 # Camera-relative X of its pad (right side of the screen).
const PAD_SPREAD := 1.8 # It hops between REST_X - PAD_SPREAD and REST_X + PAD_SPREAD... (camera relative)
const WAIT_SECONDS := 1.1
const TONGUE_TELEGRAPH := 0.7
const TONGUE_REACH := 7.5
const TONGUE_OUT := 0.22
const TONGUE_HOLD := 0.15
const TONGUE_BACK := 0.3
const TONGUE_DAMAGE := 12
const JUMP_TELEGRAPH := 0.9
const JUMP_SECONDS := 0.8
const JUMP_HEIGHT := 3.0
const WAVE_SPEED := 6.0
const WAVE_SECONDS := 1.1
const WAVE_HEIGHT := 1.3
const WAVE_DAMAGE := 10
const IMPLANT_HP := 220

var target: BeePlayer
var state := State.IDLE
var health: HealthComponent
var hurtbox: DamageHurtbox3D
var visual: Node3D
var liberated := false
var telegraphs: Array[float] = []
var tongues := 0
var jumps := 0
var waves := 0
var _activated := false
var _left := 0.0
var _rel_x := REST_X
var _from_rel := REST_X
var _to_rel := REST_X
var _aim := Vector3.ZERO
var _warn: Array[Node] = []
var _warn_started := 0.0
var _tongue: MeshInstance3D
var _tongue_box: DamageHitbox3D
var _cycle := 0
var _waves: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	add_to_group("controlled_fauna")
	visual = VISUAL.instantiate() as Node3D
	visual.set("preview_motion", false)
	visual.scale = Vector3.ONE * MODEL_SCALE
	visual.rotation.y = 0.0 # The study faces -X: towards Bee.
	add_child(visual)
	health = HEALTH_SCENE.instantiate() as HealthComponent
	health.name = "HealthComponent"
	health.max_health = BeeGameSettings.scaled_hp(IMPLANT_HP)
	add_child(health)
	hurtbox = HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	hurtbox.name = "Hurtbox3D"
	hurtbox.team_id = &"alien"
	hurtbox.health_component_path = NodePath("../HealthComponent")
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	shape.shape = sphere
	hurtbox.add_child(shape)
	add_child(hurtbox)
	hurtbox.position = _implant_local() # The node itself sits on the implant (auto-aim aims at the Hurtbox3D node).
	health.died.connect(_liberate)
	_build_tongue()
	hide()
	set_physics_process(false)


func _implant_local() -> Vector3:
	var device := visual.find_child("AlienControlDevice", true, false) as Node3D
	if device == null:
		return Vector3(0.0, 1.6 * MODEL_SCALE * 0.5, 0.0)
	var first := true
	var box := AABB()
	for mesh: MeshInstance3D in device.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb() if is_inside_tree() else mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box.get_center()


func _build_tongue() -> void:
	_tongue = MeshInstance3D.new()
	_tongue.name = "Tongue"
	var strip := BoxMesh.new() # Along X, length 1: BeeAttackVisuals.place_line stretches it from the mouth to the tip.
	strip.size = Vector3(1.0, 0.2, 0.2)
	strip.material = GardenProps.flat(Color(0.86, 0.36, 0.42))
	_tongue.mesh = strip
	_tongue.top_level = true
	_tongue.hide()
	add_child(_tongue)
	BeeToonStyle.apply(_tongue, true, BeeToonStyle.OUTLINE_ACTOR)
	var sphere := SphereShape3D.new()
	sphere.radius = 0.45
	_tongue_box = BeeAttackVisuals.hazard_area(self, self, TONGUE_DAMAGE, sphere)
	_tongue_box.name = "TongueHitbox"
	_tongue_box.top_level = true


func activate(new_target: BeePlayer) -> bool:
	if _activated or new_target == null:
		return false
	_activated = true
	target = new_target
	state = State.ENTER
	_left = 1.2
	show()
	set_physics_process(true)
	return true


func is_active() -> bool:
	return _activated and not liberated


func is_defeated() -> bool:
	return liberated


func mouth() -> Vector3:
	return global_position + Vector3(-1.1 * MODEL_SCALE, 0.55 * MODEL_SCALE, 0.0)


func _physics_process(delta: float) -> void:
	_update_waves(delta)
	if liberated:
		return
	var camera := get_viewport().get_camera_3d()
	var camera_x := camera.global_position.x if camera != null else global_position.x
	_left -= delta
	match state:
		State.ENTER:
			_rel_x = lerpf(REST_X + 6.0, REST_X, 1.0 - clampf(_left / 1.2, 0.0, 1.0))
			if _left <= 0.0:
				_begin(State.WAIT, WAIT_SECONDS)
		State.WAIT:
			if _left <= 0.0:
				_cycle += 1
				if _cycle % 3 == 0:
					_start_jump(camera_x)
				else:
					_start_tongue()
		State.TONGUE_WARN:
			if _left <= 0.0:
				telegraphs.append(BeeAttackTokens.now() - _warn_started)
				_clear_warn()
				tongues += 1
				_tongue.show()
				_tongue_box.set_enabled(true)
				_begin(State.TONGUE, TONGUE_OUT + TONGUE_HOLD + TONGUE_BACK)
		State.TONGUE:
			var total := TONGUE_OUT + TONGUE_HOLD + TONGUE_BACK
			var t := total - _left
			var reach := 0.0
			if t < TONGUE_OUT:
				reach = t / TONGUE_OUT
			elif t < TONGUE_OUT + TONGUE_HOLD:
				reach = 1.0
			else:
				reach = clampf(1.0 - (t - TONGUE_OUT - TONGUE_HOLD) / TONGUE_BACK, 0.0, 1.0)
			var from := mouth()
			var tip := from + _aim * TONGUE_REACH * reach
			BeeAttackVisuals.place_line(_tongue, from, tip)
			_tongue_box.global_position = tip
			if _left <= 0.0:
				_tongue.hide()
				_tongue_box.set_enabled(false)
				_begin(State.WAIT, WAIT_SECONDS)
		State.JUMP_WARN:
			if _left <= 0.0:
				telegraphs.append(BeeAttackTokens.now() - _warn_started)
				jumps += 1
				_begin(State.JUMP, JUMP_SECONDS)
		State.JUMP:
			var k := 1.0 - clampf(_left / JUMP_SECONDS, 0.0, 1.0)
			_rel_x = lerpf(_from_rel, _to_rel, k)
			visual.position.y = sin(k * PI) * JUMP_HEIGHT / MODEL_SCALE
			if _left <= 0.0:
				visual.position.y = 0.0
				_clear_warn()
				_land(camera_x)
				_begin(State.WAIT, WAIT_SECONDS + 0.4)
	global_position = Vector3(camera_x + _rel_x, WATER_Y, 0.0)
	visual.rotation.y = 0.0 if (state != State.JUMP or _to_rel <= _from_rel) else PI # Looks where it hops.


func _begin(next: int, seconds: float) -> void:
	state = next
	_left = seconds


func _start_tongue() -> void:
	var from := mouth()
	var aim := target.global_position - from
	aim.z = 0.0
	_aim = aim.normalized() if aim.length() > 0.1 else Vector3.LEFT
	_warn_started = BeeAttackTokens.now()
	_warn.append(BeeAttackVisuals.line(get_parent(), from, from + _aim * TONGUE_REACH, 0.12, Color(1.0, 0.3, 0.3, 0.75)))
	_begin(State.TONGUE_WARN, TONGUE_TELEGRAPH)


func _start_jump(camera_x: float) -> void:
	_from_rel = _rel_x
	_to_rel = REST_X - PAD_SPREAD if _rel_x >= REST_X else REST_X + PAD_SPREAD
	var landing := Vector3(camera_x + _to_rel, WATER_Y + 0.05, 0.0)
	_warn_started = BeeAttackTokens.now()
	var ring := BeeAttackVisuals.ring(get_parent(), landing, 1.6, 0.08, Color(1.0, 0.55, 0.15, 0.85))
	ring.rotation.x = 0.0
	ring.scale = Vector3(1.6, 1.0, 0.7)
	_warn.append(ring)
	_begin(State.JUMP_WARN, JUMP_TELEGRAPH)


## Landing: a low shockwave runs along the water both ways (two hazards moving at WAVE_SPEED for WAVE_SECONDS).
func _land(_camera_x: float) -> void:
	BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0, 0.2, 0), &"rock_break", Vector3.UP, 1.6)
	BeeCameraShake.kick(self, 0.05, 0.25)
	for side in [-1.0, 1.0]:
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, WAVE_HEIGHT, 1.0)
		var hazard := BeeAttackVisuals.hazard_area(get_parent(), self, WAVE_DAMAGE, box)
		hazard.name = "ShockWave"
		hazard.top_level = true
		hazard.global_position = global_position + Vector3(0, WAVE_HEIGHT * 0.5, 0)
		hazard.set_enabled(true)
		var crest := BeeAttackVisuals.sphere(get_parent(), global_position + Vector3(0, 0.25, 0), 0.45, Color(0.7, 0.9, 1.0, 0.85), false)
		crest.scale = Vector3(1.2, 0.6, 1.0)
		_waves.append({"hazard": hazard, "crest": crest, "dir": side, "left": WAVE_SECONDS})
	waves += 1


func _update_waves(delta: float) -> void:
	for wave in _waves.duplicate():
		var hazard := wave["hazard"] as DamageHitbox3D
		var crest := wave["crest"] as Node3D
		wave["left"] = float(wave["left"]) - delta
		if not is_instance_valid(hazard) or float(wave["left"]) <= 0.0:
			if is_instance_valid(hazard):
				hazard.queue_free()
			if is_instance_valid(crest):
				crest.queue_free()
			_waves.erase(wave)
			continue
		var step := Vector3(float(wave["dir"]) * WAVE_SPEED * delta, 0, 0)
		hazard.global_position += step
		crest.global_position += step


func _clear_warn() -> void:
	for node in _warn:
		if is_instance_valid(node):
			node.queue_free()
	_warn.clear()


func _liberate() -> void:
	if liberated:
		return
	liberated = true
	state = State.FREED
	_clear_warn()
	_tongue.hide()
	_tongue_box.set_enabled(false)
	remove_from_group("bee_auto_aim_targets")
	hurtbox.set_deferred("monitorable", false)
	add_to_group("bee_liberated")
	var device := visual.find_child("AlienControlDevice", true, false) as Node3D
	var at := device.global_position if device != null else global_position + Vector3(0, 2, 0)
	if visual.has_method("release_control"):
		visual.call("release_control")
	BeeLiberation.free_animal(get_parent(), visual, device, at)
	visual.rotation.y = PI # It hops away to the right: it looks where it goes.
	liberated_now.emit(self)
	var away := create_tween()
	away.tween_interval(0.8)
	away.tween_property(self, "global_position", global_position + Vector3(9.0, 1.0, 0.0), 2.2).set_trans(Tween.TRANS_SINE)
	away.tween_callback(func():
		state = State.DONE
		hide()
		defeated.emit(self))
