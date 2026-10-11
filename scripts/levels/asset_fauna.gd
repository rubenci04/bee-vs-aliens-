class_name AssetFauna
extends Node3D
## LOTE 6 — enemies built from the Codex GLB assets (scenes/art_labs/assets*/...). One data-driven class, one `mode` per species.
## Controlled fauna (mosquito, ladybird, dragonfly, moth, ant, stag beetle, snail, mushroom cannon) follows the Level 01 fauna rule:
## the animal is never the target, only the cyan IMPLANT on its back has health (a body shield absorbs shots on the shell).
## Breaking the implant LIBERATES the animal (no corpse). The seed carrier is a plain alien machine (no implant).
## Every attack: IDLE -> TELEGRAPH (>= MIN_TELEGRAPH, flare + warning shape) -> ATTACK -> RECOVER, then EXIT after `max_cycles`.
## Parameters live in KINDS (top of the file); the Level 01 director sets HP in LEVEL_HP.

signal defeated(enemy: AssetFauna)
signal liberated_now(enemy: AssetFauna)

enum State { IDLE, ENTER, WAIT, TELEGRAPH, ATTACK, RECOVER, EXIT, LIBERATED, DONE }

const MIN_TELEGRAPH := 0.4
const PROJECTILE := preload("res://scenes/bee_prototype/alien_enemy_projectile.tscn")
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const HITBOX_SCENE := preload("res://scenes/components/hitbox_3d.tscn")
const BOMB_MODEL := preload("res://scenes/art_labs/assets_v10/moth_stationary_bomb.tscn")
const WARN_COLOR := Color(1.0, 0.55, 0.15, 0.8)
const FACE_MIN_SPEED := 0.5 # m/s (screen-relative for flyers) before the body turns to its motion.
const FACE_SMOOTHING := 0.18 # s

## scene: art wrapper. mode: behaviour. ground: walks on the soil. scale: model scale. telegraph: warning seconds.
## damage: contact / shot damage. cycles: attacks before leaving. armored: extra shield below the implant.
const KINDS := {
	&"mosquito": {"scene": "res://scenes/art_labs/assets/controlled_mosquito.tscn", "mode": &"dash", "ground": false, "scale": 1.0,
			"telegraph": 0.5, "damage": 8, "cycles": 4, "speed": 7.0, "dash_speed": 14.0, "dash_range": 7.0, "label": "Mosquito"},
	&"ladybird": {"scene": "res://scenes/art_labs/assets_v03/controlled_flying_ladybird.tscn", "mode": &"sweep", "ground": false, "scale": 1.15,
			"telegraph": 0.8, "damage": 10, "cycles": 3, "speed": 2.2, "pass_time": 1.5, "label": "Ladybird"},
	&"dragonfly": {"scene": "res://scenes/art_labs/assets_v10/controlled_dragonfly.tscn", "mode": &"wave", "ground": false, "scale": 0.8,
			"telegraph": 0.65, "damage": 9, "cycles": 3, "speed": 6.0, "wave_speed": 10.0, "wave_amp": 1.1, "label": "WaveDragonfly"},
	&"moth": {"scene": "res://scenes/art_labs/assets_v10/controlled_bomb_moth.tscn", "mode": &"bomber", "ground": false, "scale": 0.85,
			"telegraph": 0.5, "damage": 10, "cycles": 4, "speed": 2.4, "fuse": 2.0, "radius": 1.4, "label": "Moth"},
	&"ant": {"scene": "res://scenes/art_labs/assets_v09/controlled_ant.tscn", "mode": &"lunge", "ground": true, "scale": 1.1,
			"telegraph": 0.5, "damage": 8, "cycles": 4, "speed": 2.6, "lunge_range": 3.2, "label": "Ant"},
	&"stag_beetle": {"scene": "res://scenes/art_labs/assets_v02/controlled_stag_beetle.tscn", "mode": &"charge", "ground": true, "scale": 1.0,
			"telegraph": 0.8, "damage": 12, "cycles": 3, "speed": 1.4, "charge_speed": 6.5, "charge_time": 1.3, "armored": true, "label": "StagBeetle"},
	&"snail": {"scene": "res://scenes/art_labs/assets_v02/controlled_woodland_snail.tscn", "mode": &"spitter", "ground": true, "scale": 1.0,
			"telegraph": 0.6, "damage": 7, "cycles": 5, "speed": 0.7, "shot_speed": 4.2, "armored": true, "label": "Snail"},
	&"mushroom": {"scene": "res://scenes/art_labs/assets_v10/controlled_mushroom_cannon.tscn", "mode": &"cannon", "ground": true, "scale": 1.0,
			"telegraph": 0.7, "damage": 9, "cycles": 99, "speed": 0.0, "shot_speed": 6.0, "label": "MushroomCannon"},
	&"seed_carrier": {"scene": "res://scenes/art_labs/assets_v02/alien_seed_carrier.tscn", "mode": &"seeder", "ground": false, "scale": 1.15,
			"telegraph": 0.8, "damage": 6, "cycles": 99, "speed": 2.0, "shot_speed": 3.6, "machine": true, "label": "SeedCarrier"},
}

@export var kind: StringName = &"mosquito"
@export var idle_time := 1.2
@export var recovery_time := 0.9

var target: BeePlayer
var state := State.IDLE
var cycles_done := 0
var liberated := false
var health: HealthComponent
var hurtbox: DamageHurtbox3D
var attack_hitbox: DamageHitbox3D
var rig: Node3D
var visual: Node3D
var config: Dictionary
var telegraphs: Array[float] = [] # Measured warning durations (tests).
var attacks_started := 0
var bombs_dropped := 0
var shots_fired := 0
var damage := 8
var max_cycles := 3
var ground_y := -0.2

var _clock := 0.0
var _left := 0.0
var _facing := -1.0
var _hover := Vector3.ZERO
var _lock_from := Vector3.ZERO
var _lock_to := Vector3.ZERO
var _warn: Array[Node] = []
var _tele_started := 0.0
var _jitter_left := 0.0
var _jitter := Vector3.ZERO
var _implant_center := Vector3.ZERO
var _has_implant := false
var _device: Node3D
var _token_held := false
var _activated := false # State.IDLE is also the between-attacks phase, so activation has its own flag.
var _move_vx := 0.0
var _prev_rel_x := 0.0
var _has_prev := false


func _ready() -> void:
	config = KINDS[kind]
	damage = int(config["damage"])
	max_cycles = int(config["cycles"])
	add_to_group("bee_auto_aim_targets")
	add_to_group("asset_fauna")
	if not bool(config.get("machine", false)):
		add_to_group("controlled_fauna")
	_build()
	hide()
	set_physics_process(false)


func is_ground() -> bool:
	return bool(config.get("ground", false))


func activate(new_target: BeePlayer) -> bool:
	if _activated or new_target == null or health == null:
		return false
	target = new_target
	_activated = true
	state = State.ENTER
	show()
	set_physics_process(true)
	return true


func is_active() -> bool:
	return _activated and not liberated and state != State.DONE


func is_defeated() -> bool:
	return liberated


# --- build -----------------------------------------------------------------------------------------------------

func _build() -> void:
	rig = Node3D.new()
	rig.name = "Rig"
	add_child(rig)
	visual = (load(str(config["scene"])) as PackedScene).instantiate() as Node3D
	visual.scale = Vector3.ONE * float(config["scale"])
	rig.add_child(visual)
	_device = visual.find_child("AlienControlDevice", true, false) as Node3D
	var bounds := _bounds(visual, rig)
	var center := bounds.get_center()
	var radius := 0.5 * float(config["scale"])
	if _device != null:
		_has_implant = true
		var device_bounds := _bounds(_device, rig)
		_implant_center = device_bounds.get_center()
		radius = maxf(device_bounds.size.x, maxf(device_bounds.size.y, device_bounds.size.z)) * 0.5 + 0.22
	else:
		_implant_center = center
		radius = maxf(bounds.size.y, bounds.size.x * 0.5) * 0.5
	health = HEALTH_SCENE.instantiate() as HealthComponent
	health.name = "HealthComponent"
	health.max_health = 60
	add_child(health)
	hurtbox = _hurtbox("Hurtbox3D", health, SphereShape3D.new(), _implant_center)
	(hurtbox.get_child(0) as CollisionShape3D).shape.set("radius", radius)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	if _has_implant:
		var body_health := HEALTH_SCENE.instantiate() as HealthComponent
		body_health.name = "BodyHealth"
		body_health.max_health = 1000000
		add_child(body_health)
		# The shell below the implant absorbs shots with a neutral puff; the implant stays reachable above it.
		var low := bounds.position.y
		var high := _implant_center.y - radius * 0.7
		if high - low > 0.15:
			var box := BoxShape3D.new()
			box.size = Vector3(bounds.size.x, high - low, 1.0)
			var shield := _hurtbox("BodyShield", body_health, box, Vector3(center.x, (low + high) * 0.5, 0.0))
			shield.set_meta("neutral_hit", true)
		body_health.health_changed.connect(func(_c: int, _m: int, change: int): if change < 0: body_health.current_health = body_health.max_health)
	attack_hitbox = HITBOX_SCENE.instantiate() as DamageHitbox3D
	attack_hitbox.name = "AttackHitbox"
	attack_hitbox.team_id = &"alien"
	attack_hitbox.damage = damage
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5 if not is_ground() else 0.7
	shape.shape = sphere
	attack_hitbox.add_child(shape)
	attack_hitbox.position = Vector3(0.0, center.y, 0.0)
	add_child(attack_hitbox)
	attack_hitbox.set_enabled(false)


func _hurtbox(label: String, source: HealthComponent, shape: Shape3D, at: Vector3) -> DamageHurtbox3D:
	var area := HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	area.name = label
	area.team_id = &"alien"
	area.health_component_path = NodePath("../../" + str(source.name))
	area.owner_entity_path = NodePath("../..")
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	collider.shape = shape
	collider.position = at
	area.add_child(collider)
	rig.add_child(area)
	return area


static func _bounds(root: Node3D, space: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	var inverse := space.global_transform.affine_inverse()
	for node: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if node.mesh == null:
			continue
		var local: AABB = (inverse * node.global_transform) * node.get_aabb()
		merged = local if first else merged.merge(local)
		first = false
	if root is MeshInstance3D and first:
		merged = (root as MeshInstance3D).get_aabb()
	return merged


# --- loop ------------------------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_clock += delta
	if liberated or target == null:
		return
	if target.is_defeated and state != State.EXIT:
		_cancel_attack()
		state = State.EXIT
	var camera := get_viewport().get_camera_3d()
	var camera_x := camera.global_position.x if camera != null else global_position.x
	match state:
		State.ENTER:
			_enter(delta, camera_x)
		State.IDLE:
			_idle(delta, camera_x)
		State.TELEGRAPH:
			_telegraph(delta)
		State.ATTACK:
			_attack(delta, camera_x)
		State.RECOVER:
			_recover(delta, camera_x)
		State.EXIT:
			global_position += Vector3(-6.0 if not is_ground() else -3.0, 2.0 if not is_ground() else 0.0, 0.0) * delta
	_face(delta, camera_x)


func _enter(delta: float, camera_x: float) -> void:
	if config["mode"] == &"cannon":
		_begin(State.IDLE, idle_time) # Planted in the garden: it never walks.
		return
	_hover = _hover_point(camera_x)
	if is_ground():
		var arrived := _walk_to(_hover.x, float(config["speed"]) if float(config["speed"]) > 0.0 else 2.0, delta)
		if arrived or global_position.x < camera_x + 5.5:
			_begin(State.IDLE, idle_time)
	else:
		global_position = global_position.move_toward(_hover, 5.5 * delta)
		if global_position.distance_to(_hover) < 0.4:
			_begin(State.IDLE, idle_time)


func _hover_point(camera_x: float) -> Vector3:
	var bee := target.global_position
	match config["mode"]:
		&"dash":
			return Vector3(minf(bee.x + 3.5, camera_x + 5.0), clampf(bee.y + 0.6, 1.8, 5.6), 0.0)
		&"sweep":
			return Vector3(minf(bee.x + 4.4, camera_x + 5.0), clampf(bee.y + 0.8, 2.0, 5.6), 0.0)
		&"wave":
			return Vector3(camera_x + 5.4, clampf(bee.y, 1.6, 5.4), 0.0)
		&"bomber":
			return Vector3(minf(bee.x + 3.0, camera_x + 4.6), 4.6 + 0.5 * sin(_clock * 0.9), 0.0)
		&"seeder":
			return Vector3(minf(bee.x + 4.6, camera_x + 4.8), clampf(bee.y + 1.0, 3.2, 5.6), 0.0)
		_:
			return Vector3(bee.x + 3.0, ground_y, 0.0)


func _idle(delta: float, camera_x: float) -> void:
	_hover = _hover_point(camera_x)
	var speed := float(config["speed"])
	match config["mode"]:
		&"dash":
			# Erratic: a new random hover point every ~0.3 s, reached fast.
			_jitter_left -= delta
			if _jitter_left <= 0.0:
				_jitter_left = 0.3
				_jitter = Vector3(randf_range(-1.6, 1.6), randf_range(-1.4, 1.4), 0.0)
			global_position = global_position.move_toward(_hover + _jitter, speed * delta)
		&"cannon":
			pass # Static: its position is part of the garden.
		_:
			if is_ground():
				_walk_to(_hover.x, speed, delta)
			else:
				global_position = global_position.move_toward(_hover, speed * delta)
	_left -= delta
	if _left <= 0.0:
		_start_telegraph()


func _walk_to(x: float, speed: float, delta: float) -> bool:
	# A ground walker keeps a standoff distance in front of Bee (never walks through it).
	var stand := 2.4 if config["mode"] == &"lunge" else 3.2
	var goal := x
	if absf(global_position.x - target.global_position.x) < stand:
		return true
	global_position.x = move_toward(global_position.x, goal, speed * delta)
	return absf(global_position.x - goal) < 0.2


func _start_telegraph() -> void:
	var mode: StringName = config["mode"]
	if mode in [&"charge", &"wave", &"sweep"] and not BeeAttackTokens.try_claim(self, float(config["telegraph"]) + 1.8):
		_left = 0.5 # Another heavy pattern is running: wait a beat.
		return
	_token_held = mode in [&"charge", &"wave", &"sweep"]
	attacks_started += 1
	state = State.TELEGRAPH
	_left = maxf(float(config["telegraph"]), MIN_TELEGRAPH)
	_tele_started = BeeAttackTokens.now()
	_lock_from = global_position
	var bee := target.global_position
	match mode:
		&"dash":
			var dir := (bee - global_position)
			dir.z = 0.0
			dir = dir.normalized() if dir.length() > 0.1 else Vector3.LEFT
			_lock_to = global_position + dir * float(config["dash_range"])
			_add_line(_lock_from, _lock_to, 0.12)
		&"sweep":
			var dir2 := (bee - global_position)
			dir2.z = 0.0
			dir2 = dir2.normalized() if dir2.length() > 0.1 else Vector3.LEFT
			_lock_to = bee + dir2 * 3.0
			_lock_to.y = clampf(_lock_to.y, 1.0, 6.2)
			_add_line(_lock_from, _lock_to, 0.2)
		&"wave":
			_lock_from = Vector3(global_position.x, global_position.y, 0.0)
			_lock_to = Vector3(global_position.x - 17.0, global_position.y, 0.0)
			_add_line(_lock_from, _lock_to, float(config["wave_amp"]) * 2.0, Color(1.0, 0.55, 0.15, 0.16))
		&"lunge":
			var dirx := signf(bee.x - global_position.x) if absf(bee.x - global_position.x) > 0.1 else _facing
			_lock_to = global_position + Vector3(dirx * float(config["lunge_range"]), 0.0, 0.0)
			_add_line(global_position + Vector3(0, 0.5, 0), _lock_to + Vector3(0, 0.5, 0), 0.14)
		&"charge":
			var dirc := signf(bee.x - global_position.x) if absf(bee.x - global_position.x) > 0.1 else _facing
			_lock_to = global_position + Vector3(dirc * float(config["charge_speed"]) * float(config["charge_time"]), 0.0, 0.0)
			_add_line(global_position + Vector3(0, 0.4, 0), _lock_to + Vector3(0, 0.4, 0), 0.5, Color(1.0, 0.55, 0.15, 0.25))
		&"bomber":
			_add_ring(global_position + Vector3(0, -0.8, 0), float(config["radius"]))
		_:
			_lock_to = bee # Shooters re-aim at the moment of firing; the glow is the warning.


func _telegraph(delta: float) -> void:
	_left -= delta
	var progress := 1.0 - clampf(_left / maxf(float(config["telegraph"]), MIN_TELEGRAPH), 0.0, 1.0)
	var flare := 1.0 + 0.12 * sin(progress * PI * 3.0) + 0.1 * progress
	visual.scale = Vector3.ONE * float(config["scale"]) * flare # Whole animal swells: readable on any silhouette.
	if config["mode"] == &"lunge" or config["mode"] == &"charge":
		rig.rotation.z = (0.25 if config["mode"] == &"lunge" else -0.12) * progress * -_facing # Rears up / lowers its head.
	if _left <= 0.0:
		telegraphs.append(BeeAttackTokens.now() - _tele_started)
		visual.scale = Vector3.ONE * float(config["scale"])
		rig.rotation.z = 0.0
		_clear_warn()
		_start_attack()


func _start_attack() -> void:
	state = State.ATTACK
	var mode: StringName = config["mode"]
	match mode:
		&"dash":
			_left = float(config["dash_range"]) / float(config["dash_speed"])
			attack_hitbox.set_enabled(true)
		&"sweep":
			_left = float(config["pass_time"])
			attack_hitbox.set_enabled(true)
		&"wave":
			_left = 17.0 / float(config["wave_speed"])
			attack_hitbox.set_enabled(true)
		&"lunge":
			_left = 0.35
			attack_hitbox.set_enabled(true)
		&"charge":
			_left = float(config["charge_time"])
			attack_hitbox.set_enabled(true)
		&"bomber":
			_drop_bomb()
			_left = 0.2
		&"spitter", &"cannon", &"seeder":
			_fire()
			_left = 0.25
		_:
			_left = 0.2


func _attack(delta: float, _camera_x: float) -> void:
	_left -= delta
	var mode: StringName = config["mode"]
	match mode:
		&"dash":
			global_position = global_position.move_toward(_lock_to, float(config["dash_speed"]) * delta)
		&"sweep":
			var t := clampf(1.0 - _left / float(config["pass_time"]), 0.0, 1.0)
			var eased := t * t * (3.0 - 2.0 * t)
			global_position = _lock_from.lerp(_lock_to, eased) + Vector3(0, sin(t * PI) * -0.9, 0)
		&"wave":
			var travelled := float(config["wave_speed"]) * delta
			global_position.x -= travelled
			global_position.y = _lock_from.y + sin((global_position.x - _lock_from.x) * 1.6) * float(config["wave_amp"])
		&"lunge", &"charge":
			var speed := float(config["lunge_range"]) / 0.35 if mode == &"lunge" else float(config["charge_speed"])
			global_position = global_position.move_toward(_lock_to, speed * delta)

	if _left <= 0.0:
		attack_hitbox.set_enabled(false)
		_release_token()
		cycles_done += 1
		state = State.RECOVER
		_left = recovery_time if mode != &"charge" else 1.4
		if cycles_done >= max_cycles:
			state = State.EXIT


func _recover(delta: float, camera_x: float) -> void:
	_hover = _hover_point(camera_x)
	if not is_ground():
		var back := _hover
		if config["mode"] == &"wave":
			back.x = camera_x + 5.4
		global_position = global_position.move_toward(back, maxf(float(config["speed"]), 3.0) * 1.4 * delta)
	_left -= delta
	if _left <= 0.0:
		_begin(State.IDLE, idle_time)


func _begin(next: int, seconds: float) -> void:
	state = next
	_left = seconds


func _cancel_attack() -> void:
	attack_hitbox.set_enabled(false)
	_clear_warn()
	_release_token()
	visual.scale = Vector3.ONE * float(config["scale"])
	rig.rotation.z = 0.0


func _release_token() -> void:
	if _token_held:
		BeeAttackTokens.release(self)
		_token_held = false


# --- attacks that spawn something ------------------------------------------------------------------------------


func _muzzle() -> Vector3:
	var local := _implant_center
	return rig.to_global(local)


func _fire() -> void:
	if not BeeShmupFairness.can_fire(self):
		return
	var mode: StringName = config["mode"]
	var aim := target.global_position - _muzzle()
	var count := 1
	var step := 14.0
	if mode == &"cannon":
		count = 3
	elif mode == &"seeder":
		count = 3
		step = 20.0
	for direction in BeeEnemyPatterns.fan_directions(aim, count, step):
		var shot := BeeEnemyPatterns.spawn_shot(get_parent(), PROJECTILE, _muzzle(), direction, damage, float(config["shot_speed"]), self)
		shots_fired += 1
		if mode == &"seeder":
			shot.scale = Vector3.ONE * 1.5
			var splitter := AlienOrbSplitter.new()
			splitter.name = "OrbSplitter"
			splitter.projectile_scene = PROJECTILE
			splitter.attacker = self
			splitter.split_distance = 3.2
			splitter.split_speed = 4.4
			shot.add_child(splitter)
	BeeCombatVFX.spawn(get_parent(), _muzzle(), &"tech_hit", Vector3.UP, 0.5)


func _drop_bomb() -> void:
	var live := 0
	for mine in get_tree().get_nodes_in_group("asset_mines"):
		if is_instance_valid(mine) and not bool(mine.get("exploded")):
			live += 1
	if live >= 3:
		return
	var mine := UfoBossMine.new()
	mine.name = "MothBomb"
	mine.fuse = float(config["fuse"])
	mine.radius = float(config["radius"])
	mine.damage = damage
	mine.attacker = self
	mine.model = BOMB_MODEL
	mine.watch = target
	get_parent().add_child(mine)
	mine.add_to_group("asset_mines")
	var from := global_position + Vector3(0, -0.5, 0)
	mine.throw(from, from + Vector3(0.0, -0.6, 0.0)) # It stays where it is dropped.
	bombs_dropped += 1


# --- warning shapes --------------------------------------------------------------------------------------------

func _add_line(from: Vector3, to: Vector3, width: float, color: Color = WARN_COLOR) -> void:
	var line := BeeAttackVisuals.line(get_parent(), from, to, width, color)
	_warn.append(line)


func _add_ring(at: Vector3, radius: float) -> void:
	var ring := BeeAttackVisuals.ring(get_parent(), at, radius, 0.06, WARN_COLOR)
	_warn.append(ring)


func _clear_warn() -> void:
	for node in _warn:
		if is_instance_valid(node):
			node.queue_free()
	_warn.clear()


func _exit_tree() -> void:
	_clear_warn()
	_release_token()


# --- facing / feedback -----------------------------------------------------------------------------------------

## LOTE 7 — ORIENTATION: every model looks along -X at yaw 0. It now faces WHERE IT MOVES: the screen-relative velocity for
## flyers (what the player sees), the ground velocity for walkers, smoothed over FACE_SMOOTHING s so an erratic mosquito
## does not flicker. Below FACE_MIN_SPEED (hovering, telegraph, static cannon) it faces its attack / Bee.
func _face(delta: float, camera_x: float) -> void:
	var reference_x := camera_x if not is_ground() else 0.0
	var position_rel := global_position.x - reference_x
	if _has_prev and delta > 0.0:
		var raw := (position_rel - _prev_rel_x) / delta
		_move_vx = lerpf(_move_vx, raw, clampf(delta / FACE_SMOOTHING, 0.0, 1.0))
	_prev_rel_x = position_rel
	_has_prev = true
	var dx := 0.0
	if absf(_move_vx) >= FACE_MIN_SPEED and config["mode"] != &"cannon":
		dx = _move_vx
	elif state == State.TELEGRAPH and config["mode"] != &"cannon":
		dx = _lock_to.x - _lock_from.x
	elif target != null:
		dx = target.global_position.x - global_position.x
	if absf(dx) > 0.15:
		_facing = signf(dx)
	rig.rotation.y = 0.0 if _facing < 0.0 else PI


## +1 when the model looks towards +X, -1 towards -X (tests).
func forward_x() -> float:
	return -1.0 if is_zero_approx(rig.rotation.y) else 1.0


## Screen-relative (flyers) / ground (walkers) horizontal speed used for the facing (tests).
func move_vx() -> float:
	return _move_vx

func _on_health_changed(_current: int, _maximum: int, change: int) -> void:
	if change < 0 and not liberated:
		var tween := create_tween()
		tween.tween_property(visual, "scale", Vector3.ONE * float(config["scale"]) * 1.08, 0.05)
		tween.tween_property(visual, "scale", Vector3.ONE * float(config["scale"]), 0.08)


func _on_died() -> void:
	if liberated:
		return
	liberated = true
	state = State.LIBERATED
	_cancel_attack()
	remove_from_group("bee_auto_aim_targets")
	hurtbox.set_deferred("monitorable", false)
	for area: Area3D in find_children("*", "Area3D", true, false):
		if area is DamageHitbox3D:
			(area as DamageHitbox3D).set_enabled(false)
	liberated_now.emit(self)
	_facing = -1.0
	rig.rotation.y = 0.0 # It leaves towards -X (see the tweens below): it looks where it goes.
	var at := _muzzle()
	BeeCombatVFX.spawn(get_parent(), at, &"tech_death", Vector3.UP, 0.7)
	BeeAudio.play(get_parent(), &"tech_death", at)
	if bool(config.get("machine", false)):
		var boom := create_tween()
		boom.tween_property(self, "scale", Vector3.ONE * 0.1, 0.35)
		boom.tween_callback(_finish)
		return
	if visual.has_method("release_control"):
		visual.call("release_control")
	BeeAudio.play(get_parent(), &"pollen", at, 1.1)
	BeeCombatVFX.spawn(get_parent(), global_position, &"pollen", Vector3.UP, 1.0)
	var away := create_tween()
	if is_ground():
		away.tween_property(self, "global_position", global_position + Vector3(-5.0, 0.0, 0.0), 1.8).set_trans(Tween.TRANS_SINE)
	else:
		away.tween_property(self, "global_position", global_position + Vector3(-6.0, 4.0, 0.0), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	away.tween_callback(_finish)


func _finish() -> void:
	state = State.DONE
	hide()
	set_physics_process(false)
	defeated.emit(self)
