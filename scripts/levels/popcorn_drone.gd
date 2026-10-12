class_name PopcornDrone
extends Node3D
## ARCADE CONTENT & SPECTACLE REBUILD 02 — popcorn: small alien "gnat" drones that cross the screen in formation.
## One Base shot destroys one. No AI: each unit follows a fixed path relative to the camera, so a group reads as a
## formation and is fair to dodge. Only `shooter` units fire, once, a slow aimed shot after a short eye flash.
## The Level 01 controller keeps them OUT of the threat cap (they are rhythm, not pressure on their own).
##   SINE        horizontal crossing with a wave
##   ARC_TOP     enters high, swoops down through the middle, climbs out
##   ARC_BOTTOM  mirror of ARC_TOP
##   DIVE        flies in, then bends towards Bee's height at that moment and keeps going
##   STRAIGHT    LOTE 11: no wobble, so V / pincer / from-behind formations keep their shape
##   KAMIKAZE    LOTE 11: flies in, stops, flashes for KAMIKAZE_WARNING s (a thin cyan line shows the dash), then dashes along
##               the line locked at the START of the warning (so a player that moves away dodges it)
##   `from_left` makes any path enter from behind the player (left edge) and travel right.

signal defeated(enemy: PopcornDrone)
signal projectile_fired(projectile: AlienEnemyProjectile)

enum PathKind { SINE, ARC_TOP, ARC_BOTTOM, DIVE, STRAIGHT, KAMIKAZE }
const PROJECTILE := preload("res://scenes/bee_prototype/alien_enemy_projectile.tscn")
const FLASH_TIME := 0.35
## LOTE 11 kamikaze: warning before the dash (never below the 0.4 s minimum telegraph), dash speed, camera-relative X where it
## stops to aim, contact damage (before the route damage scale) and the line colour.
const KAMIKAZE_WARNING := 0.5
const KAMIKAZE_SPEED := 9.0
const KAMIKAZE_AIM_X := 5.0
const KAMIKAZE_CONTACT_DAMAGE := 18
const KAMIKAZE_LINE_LENGTH := 14.0

@export var path := PathKind.SINE
@export var speed := 3.4 ## m/s leftwards, relative to the camera
@export var amplitude := 0.8
@export var frequency := 0.55 ## waves per second
@export var phase := 0.0
@export var shooter := false
@export var fire_at := 2.6 ## camera-relative X where a shooter fires (after entering the screen)
@export var shot_damage := 6
@export var shot_speed := 4.6
@export var contact_damage := 8
@export var from_left := false ## LOTE 11: enters from behind (left edge) and travels right.

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var contact: DamageHitbox3D = $ContactHitbox
@onready var visual_root: Node3D = $VisualRoot

var target: BeePlayer
var projectile_fire_count := 0
var suppressed_shot_count := 0
var escaped := false
var _active := false
var _dead := false
var _t := 0.0
var _rel_x := 0.0
var _start_rel := 0.0
var _anchor_y := 0.0
var _dive_y := INF
var _fired := false
var _flash_left := -1.0
var _dir := -1.0 ## -1 travels left (from the right edge), +1 travels right (from_left)
var _kz_state := 0 ## 0 approach, 1 warning, 2 dash
var _kz_left := 0.0
var _kz_vel := Vector2.ZERO
var _kz_line: MeshInstance3D
var warned_seconds := 0.0 ## Measured warning of the kamikaze dash (dev/tests).
var _eye: MeshInstance3D
var _wings: Array[Node3D] = []

static var _meshes: Dictionary = {}


func _ready() -> void:
	health.died.connect(_on_died)
	contact.damage = contact_damage
	contact.set_enabled(false)
	hurtbox.set_deferred("monitorable", false)
	_build_visual()
	hide()
	set_physics_process(false)


func activate(new_target: BeePlayer) -> bool:
	if _active or _dead or new_target == null:
		return false
	target = new_target
	var camera := get_viewport().get_camera_3d()
	_rel_x = global_position.x - (camera.global_position.x if camera != null else 0.0)
	_start_rel = _rel_x
	_anchor_y = global_position.y
	_dir = 1.0 if from_left else -1.0
	if path == PathKind.KAMIKAZE:
		contact.damage = KAMIKAZE_CONTACT_DAMAGE
	if from_left:
		visual_root.rotation.y = PI
	_active = true
	show()
	hurtbox.set_deferred("monitorable", true)
	contact.set_enabled(true)
	add_to_group("bee_auto_aim_targets")
	set_physics_process(true)
	return true


func is_active() -> bool:
	return _active and not _dead


func is_defeated() -> bool:
	return _dead


func _physics_process(delta: float) -> void:
	if not _active or target == null:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	_t += delta
	var y := _anchor_y
	var dashing := false
	if path == PathKind.KAMIKAZE:
		dashing = _kamikaze_step(delta, camera)
		y = _anchor_y
	else:
		_rel_x += _dir * speed * delta
	var travelled := absf(_start_rel - _rel_x)
	match path:
		PathKind.SINE:
			y = _anchor_y + amplitude * sin(TAU * frequency * _t + phase)
		PathKind.ARC_TOP, PathKind.ARC_BOTTOM:
			var span := maxf(absf(_start_rel) + 9.0, 1.0)
			var dip := sin(clampf(travelled / span, 0.0, 1.0) * PI) * amplitude * 3.2
			y = _anchor_y - dip if path == PathKind.ARC_TOP else _anchor_y + dip
		PathKind.DIVE:
			if absf(_rel_x) < 3.4 and _dive_y == INF:
				_dive_y = target.global_position.y
			if _dive_y != INF:
				_anchor_y = move_toward(_anchor_y, _dive_y, 2.4 * delta)
			y = _anchor_y
	var floor_y := -2.0 if dashing else 0.8 # A dashing kamikaze may leave the playfield; everything else stays inside it.
	global_position = Vector3(camera.global_position.x + _rel_x, clampf(y, floor_y, BeeLevel01Framing.max_entity_y() + (3.0 if dashing else 0.0)), 0.0)
	if path != PathKind.KAMIKAZE or _kz_state == 0:
		visual_root.rotation.z = sin(_t * 9.0) * 0.08
	for i in _wings.size():
		_wings[i].rotation.x = sin(_t * 46.0 + i * PI) * 0.7
	if shooter and not _fired and not from_left:
		if _flash_left < 0.0 and _rel_x <= fire_at + speed * FLASH_TIME:
			_flash_left = FLASH_TIME
			_eye.scale = Vector3.ONE * 1.6
		elif _flash_left >= 0.0:
			_flash_left -= delta
			if _flash_left <= 0.0:
				_fired = true
				_eye.scale = Vector3.ONE
				_fire()
	var limit := BeeLevel01Framing.spawn_offset_x(BeeLevel01Framing.DESIGN_ASPECT) + 1.0
	if (_dir < 0.0 and _rel_x < -limit) or (_dir > 0.0 and _rel_x > limit) or (dashing and _kz_state == 2 and (absf(_rel_x) > limit or _kz_left <= 0.0)):
		escaped = true
		_active = false
		contact.set_enabled(false)
		hurtbox.set_deferred("monitorable", false)
		remove_from_group("bee_auto_aim_targets")
		set_physics_process(false)
		hide()


func _fire() -> void:
	if not BeeShmupFairness.can_fire(self):
		suppressed_shot_count += 1
		return
	var projectile := PROJECTILE.instantiate() as AlienEnemyProjectile
	projectile.damage = shot_damage
	projectile.speed = shot_speed
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector3(-0.3, 0.0, 0.0)
	projectile.launch((target.global_position - global_position).normalized(), self)
	projectile_fire_count += 1
	projectile_fired.emit(projectile)


func _on_died() -> void:
	if _dead:
		return
	_dead = true
	_active = false
	contact.set_enabled(false)
	hurtbox.set_deferred("monitorable", false)
	remove_from_group("bee_auto_aim_targets")
	set_physics_process(false)
	visual_root.hide()
	defeated.emit(self)


# --- visual: a small alien gnat (shell disc + cyan eye + two buzzing fins), shared meshes ---------------------

func _build_visual() -> void:
	var shell := MeshInstance3D.new()
	shell.name = "Shell"
	shell.mesh = _mesh(&"shell")
	shell.scale = Vector3(1.0, 0.62, 1.0)
	visual_root.add_child(shell)
	var rim := MeshInstance3D.new()
	rim.name = "Rim"
	rim.mesh = _mesh(&"rim")
	rim.rotation.z = PI * 0.5
	visual_root.add_child(rim)
	_eye = MeshInstance3D.new()
	_eye.name = "Eye"
	_eye.mesh = _mesh(&"eye")
	_eye.position = Vector3(-0.2, 0.0, 0.12)
	visual_root.add_child(_eye)
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.name = "Fin"
		pivot.position = Vector3(0.05, 0.14, 0.0)
		visual_root.add_child(pivot)
		var fin := MeshInstance3D.new()
		fin.mesh = _mesh(&"fin")
		fin.position = Vector3(0.0, 0.0, side * 0.2)
		fin.rotation.x = side * 0.5
		pivot.add_child(fin)
		_wings.append(pivot)
	BeeToonStyle.apply(visual_root, true, BeeToonStyle.OUTLINE_ACTOR)


static func _mesh(kind: StringName) -> Mesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var mesh: Mesh
	match kind:
		&"shell":
			var sphere := SphereMesh.new()
			sphere.radius = 0.24
			sphere.height = 0.48
			sphere.radial_segments = 10
			sphere.rings = 5
			sphere.material = _flat(BeeAlienPalette.SHELL.lightened(0.18))
			mesh = sphere
		&"rim":
			var torus := TorusMesh.new()
			torus.inner_radius = 0.2
			torus.outer_radius = 0.27
			torus.rings = 10
			torus.ring_segments = 4
			torus.material = _flat(BeeAlienPalette.VIOLET.darkened(0.25))
			mesh = torus
		&"eye":
			var eye := SphereMesh.new()
			eye.radius = 0.1
			eye.height = 0.2
			eye.radial_segments = 8
			eye.rings = 4
			var glow := _flat(BeeAlienPalette.CYAN)
			glow.emission_enabled = true
			glow.emission = BeeAlienPalette.CYAN
			glow.emission_energy_multiplier = BeeAlienPalette.MAX_EMISSION
			eye.material = glow
			mesh = eye
		_:
			var fin := BoxMesh.new()
			fin.size = Vector3(0.26, 0.02, 0.2)
			var wing := _flat(Color(0.75, 0.95, 1.0, 0.45))
			wing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			wing.resource_name = "Wing"
			fin.material = wing
			mesh = fin
	_meshes[kind] = mesh
	return mesh


static func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material


# --- LOTE 11: kamikaze ------------------------------------------------------------------------------------------

## Longest dash (s) before a missed kamikaze is simply gone.
const KAMIKAZE_DASH_MAX := 2.2

## One step of the kamikaze: approach -> warning (KAMIKAZE_WARNING s, line along the locked direction) -> dash.
## Returns true while dashing. `_rel_x` / `_anchor_y` are updated here; the caller positions the node.
func _kamikaze_step(delta: float, _camera: Camera3D) -> bool:
	match _kz_state:
		0:
			_rel_x += _dir * speed * delta
			if absf(_rel_x) <= KAMIKAZE_AIM_X:
				_kz_state = 1
				_kz_left = KAMIKAZE_WARNING
				warned_seconds = 0.0
				var camera := get_viewport().get_camera_3d()
				var target_rel := target.global_position.x - (camera.global_position.x if camera != null else 0.0)
				var aim := Vector2(target_rel - _rel_x, target.global_position.y - _anchor_y)
				if aim.length() < 0.5:
					aim = Vector2(_dir, 0.0)
				_kz_vel = aim.normalized() * KAMIKAZE_SPEED
				_show_kamikaze_line()
		1:
			_kz_left -= delta
			warned_seconds += delta
			var pulse := 1.0 + 0.35 * sin(_t * 40.0)
			_eye.scale = Vector3.ONE * 2.2
			visual_root.scale = Vector3.ONE * pulse
			_face(_kz_vel)
			if _kz_left <= 0.0:
				_kz_state = 2
				_kz_left = KAMIKAZE_DASH_MAX
				_eye.scale = Vector3.ONE
				visual_root.scale = Vector3.ONE
				if _kz_line != null:
					_kz_line.hide()
		_:
			_rel_x += _kz_vel.x * delta
			_anchor_y += _kz_vel.y * delta
			_kz_left -= delta
			_face(_kz_vel)
	return _kz_state == 2


func _face(velocity: Vector2) -> void:
	var angle := atan2(velocity.y, velocity.x)
	visual_root.rotation.z = -angle if from_left else angle + PI


func _show_kamikaze_line() -> void:
	if _kz_line == null:
		_kz_line = MeshInstance3D.new()
		_kz_line.name = "KamikazeLine"
		var box := BoxMesh.new()
		box.size = Vector3(KAMIKAZE_LINE_LENGTH, 0.07, 0.02)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(BeeAlienPalette.CYAN, 0.7)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		box.material = material
		_kz_line.mesh = box
		_kz_line.top_level = true
		add_child(_kz_line)
	var direction := _kz_vel.normalized()
	_kz_line.global_position = global_position + Vector3(direction.x, direction.y, 0.0) * KAMIKAZE_LINE_LENGTH * 0.5
	_kz_line.global_rotation = Vector3(0.0, 0.0, atan2(direction.y, direction.x))
	_kz_line.show()
