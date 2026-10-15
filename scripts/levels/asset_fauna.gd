class_name AssetFauna
extends Node3D
const COMMON_CUE := preload("res://scripts/vfx/bee_common_attack_cue.gd")
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
## LOTE 13: a unit counts as arrived (and starts its first rest) once it is this far inside the screen edge, not only at its hover point.
const ARRIVAL_INSET := 0.6
const PROJECTILE := preload("res://scenes/projectiles/toon/alien_bolt.tscn") # NOCHE 01: Codex toon alien bolt.
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")
const HITBOX_SCENE := preload("res://scenes/components/hitbox_3d.tscn")
const BOMB_MODEL := preload("res://scenes/art_labs/assets_v10/moth_stationary_bomb.tscn")
const WARN_COLOR := Color(1.0, 0.55, 0.15, 0.8)
## LOTE 14 · ETAPA 3.3: the aim lines are thin (AIM_LINE_WIDTH, was 0.08) and vanish once Bee has stepped AIM_DODGE_CLEARANCE m off the locked line.
const AIM_LINE_WIDTH := 0.04
const AIM_DODGE_CLEARANCE := 0.9
const FACE_MIN_SPEED := 0.5 # m/s (screen-relative for flyers) before the body turns to its motion.
const FACE_SMOOTHING := 0.18 # s
## NOCHE 01 — liberation: a freed animal leaves relaxed for LEAVE_SECONDS (walking or flying off to the left).
const LEAVE_SECONDS := 3.0
## NOCHE 01 · ETAPA 3: emission energy of the cyan implant parts (Codex wrappers cap it at 0.65 for Compatibility).
const IMPLANT_GLOW := 1.6 # LOTE 9: 1.1 -> 1.6, the implant must read as hostile cyan at dusk too.
## LOTE 9: largest implant hit sphere (m).
const IMPLANT_RADIUS_MAX := 0.62
## LOTE 9: weak-point line radius on the body area (m), from the implant size; small animals (mosquito) need the low end.
const WEAK_RADIUS_RANGE := Vector2(0.22, 0.32)
## NOCHE 01 · ETAPA 4 — perch leap: depth under the water, half the horizontal span of the arc, water surface height.
const LEAP_DEPTH := -1.4
const LEAP_SPAN := 1.8
const WATER_SURFACE_Y := -0.15
## NOCHE 01 — smooth mosquito: slow sine drift (amplitude m, rate rad/s) and gradual acceleration (m/s²).
const MOSQUITO_SPEED := 3.6
const MOSQUITO_ACCEL := 6.0
const MOSQUITO_DRIFT := Vector2(1.1, 0.8)
const MOSQUITO_DRIFT_RATE := Vector2(0.9, 0.65)
const LEAVE_GROUND_SPEED := 1.8
const LEAVE_AIR_SPEED := 2.4
## LOTE 9 — FLAPPING: kinds whose Codex model has separate "FlightWing_*" nodes flap them about the body axis (the wings
## are modelled flat, so without this the side camera sees them edge-on and the moth looks rigid). Per kind:
## [beats per second, wing lift min (rad), wing lift max (rad), body sway (rad), body bob (m), bob waves per second].
const FLAP := {&"moth": [6.5, 0.25, 1.35, 0.1, 0.16, 0.8]}

## scene: art wrapper. mode: behaviour. ground: walks on the soil. scale: model scale. telegraph: warning seconds.
## damage: contact / shot damage. cycles: attacks before leaving. armored: extra shield below the implant.
const KINDS := {
	&"mosquito": {"scene": "res://scenes/art_labs/assets/controlled_mosquito.tscn", "mode": &"dash", "ground": false, "scale": 1.0,
			"telegraph": 0.5, "damage": 8, "cycles": 4, "speed": 7.0, "dash_speed": 14.0, "dash_range": 7.0, "label": "Mosquito"},
	&"ladybird": {"scene": "res://scenes/art_labs/assets_v03/controlled_flying_ladybird.tscn", "mode": &"sweep", "ground": false, "scale": 1.15,
			"telegraph": 0.8, "damage": 7, "cycles": 3, "speed": 2.2, "pass_time": 1.5, "label": "Ladybird"},
	&"dragonfly": {"scene": "res://scenes/art_labs/assets_v10/controlled_dragonfly.tscn", "mode": &"wave", "ground": false, "scale": 0.8,
			"telegraph": 0.65, "damage": 9, "cycles": 3, "speed": 6.0, "wave_speed": 10.0, "wave_amp": 1.1, "label": "WaveDragonfly"},
	&"moth": {"scene": "res://scenes/art_labs/assets_v10/controlled_bomb_moth.tscn", "mode": &"bomber", "ground": false, "scale": 0.85,
			"telegraph": 0.5, "damage": 10, "cycles": 4, "speed": 2.4, "fuse": 2.0, "radius": 1.4, "label": "Moth"},
	&"ant": {"scene": "res://scenes/art_labs/assets_v09/controlled_ant.tscn", "mode": &"lunge", "ground": true, "scale": 1.1,
			"telegraph": 0.5, "damage": 8, "cycles": 4, "speed": 2.6, "lunge_range": 3.2, "label": "Ant"},
	&"stag_beetle": {"scene": "res://scenes/art_labs/assets_v02/controlled_stag_beetle.tscn", "mode": &"charge", "ground": true, "scale": 1.0,
			"telegraph": 0.8, "damage": 12, "cycles": 3, "speed": 1.4, "charge_speed": 6.5, "charge_time": 1.3, "armored": true, "label": "StagBeetle",
			"gait": [0.9, 0.22, 0.16, 0.05, 0.04]}, # LOTE 13: walks (tripod gait synced to the ground speed), charges with a 0.8 s warning, lobs stones
	&"snail": {"scene": "res://scenes/art_labs/assets_v02/controlled_woodland_snail.tscn", "mode": &"spitter", "ground": true, "scale": 1.0,
			"telegraph": 0.6, "damage": 7, "shot_damage": 3, "cycles": 5, "speed": 0.7, "shot_speed": 4.2, "armored": true, "label": "Snail",
			"lob": true, "style": &"bubble", "lob_flight": 1.5, "lob_gravity": 6.0}, # LOTE 13: slime bubble in an arc
	&"mushroom": {"scene": "res://scenes/art_labs/assets_v10/controlled_mushroom_cannon.tscn", "mode": &"cannon", "ground": true, "scale": 1.0,
			"telegraph": 0.7, "damage": 9, "cycles": 99, "speed": 0.0, "shot_speed": 6.0, "label": "MushroomCannon", "style": &"spore"},
	# NOCHE 01 · ETAPA 2: the Codex alien interceptor (dusk enemy, technology: it explodes). Hovers high, warns with a line
	# for 0.6 s and fires a fan of 3 toon bolts, then strafes to another spot.
	&"fighter": {"scene": "res://scenes/art_labs/alien_ships_v02/alien_needle_interceptor.tscn", "mode": &"fighter", "ground": false, "scale": 0.62,
			"telegraph": 0.6, "damage": 8, "cycles": 99, "speed": 4.5, "shot_speed": 7.0, "machine": true, "label": "AlienFighter"},
	# NOCHE 01 · ETAPA 4 — Level 02 "Laguna" prototype fauna (animals: freed, never killed).
	&"strider": {"scene": "res://scenes/art_labs/lake_fauna_v01/controlled_water_strider.tscn", "mode": &"lunge", "ground": true, "scale": 1.0,
			"telegraph": 0.5, "damage": 8, "cycles": 99, "speed": 3.0, "lunge_range": 3.6, "label": "Strider"},
	&"nymph": {"scene": "res://scenes/art_labs/lake_fauna_v01/controlled_dragonfly_nymph.tscn", "mode": &"spitter", "ground": true, "scale": 1.0,
			"telegraph": 0.6, "damage": 7, "cycles": 99, "speed": 1.0, "shot_speed": 4.4, "label": "Nymph"},
	&"perch": {"scene": "res://scenes/art_labs/assets/controlled_perch.tscn", "mode": &"leaper", "ground": true, "scale": 1.0,
			"telegraph": 0.7, "damage": 10, "cycles": 99, "speed": 2.2, "leap_time": 1.0, "leap_height": 4.6, "label": "Perch"},
	&"seed_carrier": {"scene": "res://scenes/art_labs/assets_v02/alien_seed_carrier.tscn", "mode": &"seeder", "ground": false, "scale": 1.15,
			"telegraph": 0.8, "damage": 6, "cycles": 99, "speed": 2.0, "shot_speed": 3.6, "machine": true, "label": "SeedCarrier"},
	# LOTE 12 · ETAPA 2 — Level 1 roster species (Codex GLB: implant node `implant`, clips hover/attack/liberate or idle/crawl).
	# Common fly: erratic flight with a soft ram (mosquito logic). Green fly: zigzag + slow aimed drops. Fly cloud: one group unit
	# (the whole cloud is the target, one hurtbox over all of it). Worm A: burrows, the ground mark warns 1 s, then it erupts.
	# Worm B: low crawling lunge along the soil.
	&"fly_common": {"scene": "res://scenes/art_labs/fly_trio_v01/common.tscn", "mode": &"dash", "ground": false, "scale": 0.55,
			"telegraph": 0.5, "damage": 7, "shot_damage": 3, "cycles": 99, "speed": 6.0, "dash_speed": 12.0, "dash_range": 6.0, "label": "FlyCommon",
			"spit": {"shots": 2, "gap": 0.2, "style": &"pellet", "speed": 4.4, "every": 2}}, # LOTE 13: rams and SPITS (every second attack)
	&"fly_green": {"scene": "res://scenes/art_labs/fly_trio_v01/green.tscn", "mode": &"zigzag", "ground": false, "scale": 0.55,
			"telegraph": 0.5, "damage": 7, "shot_damage": 3, "cycles": 99, "speed": 5.0, "shot_speed": 3.8, "zig_amp": 1.5, "zig_rate": 3.4, "label": "FlyGreen",
			"burst": 3, "burst_gap": 0.17, "style": &"acid"}, # LOTE 13: acid burst
	&"fly_cloud": {"scene": "res://scenes/art_labs/fly_trio_v01/swarm.tscn", "mode": &"sweep", "ground": false, "scale": 0.8,
			"telegraph": 0.6, "damage": 5, "cycles": 99, "speed": 3.4, "pass_time": 1.5, "whole_body": true, "label": "FlyCloud", "chase": true}, # LOTE 13: chases Bee as a block
	&"worm_rose": {"scene": "res://scenes/art_labs/garden_floor_v01/worm_rose.tscn", "mode": &"burrow", "ground": true, "scale": 0.85,
			"telegraph": 1.0, "damage": 5, "cycles": 99, "speed": 0.0, "exposed": 2.6, "label": "WormA",
			"worm_a": true, "undulate": [0.07, 7.0, 0.55]}, # LOTE 13: own cycle (WormBehavior)
	&"worm_compost": {"scene": "res://scenes/art_labs/garden_floor_v01/worm_compost.tscn", "mode": &"lunge", "ground": true, "scale": 0.9,
			"telegraph": 0.6, "damage": 7, "shot_damage": 3, "cycles": 99, "speed": 1.8, "lunge_range": 3.6, "label": "WormB",
			"undulate": [0.06, 8.0, 0.6], "spit": {"fan": 3, "step": 16.0, "style": &"mud", "speed": 4.2, "every": 2}}, # LOTE 13: spits a mud fan and rams low
}

@export var kind: StringName = &"mosquito"
@export var idle_time := 1.2
@export var recovery_time := 0.9
## LOTE 13 · ETAPA 2: rest before the FIRST attack (rule: every enemy starts attacking within ~1 s of entering the screen). < 0 = use idle_time.
@export var first_idle_time := -1.0

var target: BeePlayer
var state := State.IDLE
var cycles_done := 0
var liberated := false
var health: HealthComponent
var hurtbox: DamageHurtbox3D
var body_hurtbox: DamageHurtbox3D # LOTE 9: body area (1x to the implant); null when the model has none.
var attack_hitbox: DamageHitbox3D
var rig: Node3D
var visual: Node3D
var config: Dictionary
var telegraphs: Array[float] = [] # Measured warning durations (tests).
var attacks_started := 0
var bombs_dropped := 0
var shots_fired := 0
var damage := 8
var shot_damage := 0 ## LOTE 14 · ETAPA 2.3: common bullets do 3-5 (config "shot_damage"); contact / eruption hits keep `damage`.
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
var _implant_center := Vector3.ZERO
var _has_implant := false
var _device: Node3D
var _token_held := false
var _activated := false # State.IDLE is also the between-attacks phase, so activation has its own flag.
var spent := false # NOCHE 01: mushroom cannon after its cannon blew up (stays, harmless).
var model_scale := 1.0 # Final scale of the model (BeeFaunaSizes for animals, KINDS "scale" for the rest).
var _velocity := Vector3.ZERO # Steering velocity (smooth mosquito).
var _leap_apex := 3.0
var _submerged := false
var _move_vx := 0.0
var _prev_rel_x := 0.0
var _has_prev := false
var wings: Array[Node3D] = [] # LOTE 9: flapping wing hinges (see FLAP).
var _wing_bases: Array[Basis] = []
var _wing_sides: Array[float] = []
var _aim_local := Vector3.ZERO # LOTE 9: rig-space point the auto-aim locks (see auto_aim_point).


func _ready() -> void:
	config = KINDS[kind]
	damage = int(config["damage"])
	shot_damage = int(config.get("shot_damage", 0))
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

## LOTE 12: true when the model carries a separate implant (the cloud does not use a weak point; tests).
func has_implant() -> bool:
	return _has_implant or _device != null


func activate(new_target: BeePlayer) -> bool:
	if _activated or new_target == null or health == null:
		return false
	target = new_target
	_activated = true
	state = State.ENTER
	show()
	set_physics_process(true)
	return true


## LOTE 9: where Bee's auto-aim points: a controlled animal's body (1x), a machine's centre.
func auto_aim_point() -> Vector3:
	return rig.to_global(_aim_local)


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
	visual.scale = Vector3.ONE
	rig.add_child(visual)
	model_scale = float(config["scale"])
	if BeeFaunaSizes.SIZE.has(kind):
		# NOCHE 01: size relative to Bee (BeeFaunaSizes), from the model's own measured length.
		model_scale = BeeFaunaSizes.target_length(kind) / maxf(_bounds(visual, rig).size.x, 0.01)
	visual.scale = Vector3.ONE * model_scale
	if FLAP.has(kind):
		for hinge: Node3D in visual.find_children("FlightWing_*", "Node3D", true, false):
			if str(hinge.name).ends_with("Geometry"):
				continue
			wings.append(hinge)
			_wing_bases.append(hinge.transform.basis)
			_wing_sides.append(-1.0 if str(hinge.name).begins_with("FlightWing_-1") else 1.0) # _-1 wings sit on +Z.
	_device = visual.find_child("AlienControlDevice", true, false) as Node3D
	if _device == null:
		_device = visual.find_child("implant", true, false) as Node3D # LOTE 12: the Codex roster models name it `implant`.
	if _device != null:
		# NOCHE 01 · ETAPA 3: a brighter cyan implant (the shot target) reads against every light of the level.
		for mesh: MeshInstance3D in _device.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var glow := mesh.get_active_material(surface) as ShaderMaterial
				if glow != null and glow.get_shader_parameter("emission_energy") != null and float(glow.get_shader_parameter("emission_energy")) > 0.0:
					var own := glow.duplicate() as ShaderMaterial
					own.set_shader_parameter("emission_energy", IMPLANT_GLOW)
					mesh.set_surface_override_material(surface, own)
	var bounds := _bounds(visual, rig)
	var center := bounds.get_center()
	var radius := 0.5 * model_scale
	if _device != null:
		_has_implant = true
		var device_bounds := _bounds(_device, rig)
		_implant_center = device_bounds.get_center()
		radius = maxf(device_bounds.size.x, maxf(device_bounds.size.y, device_bounds.size.z)) * 0.5 + 0.22
		# LOTE 9: the body now damages the implant too, so the implant area can be precise: capped (the moth bomb
		# magazine made it a 1.4 m sphere that swallowed the whole animal).
		radius = minf(radius, IMPLANT_RADIUS_MAX)
	else:
		_implant_center = center
		radius = maxf(bounds.size.y, bounds.size.x * 0.5) * 0.5
	health = HEALTH_SCENE.instantiate() as HealthComponent
	health.name = "HealthComponent"
	health.max_health = 60
	add_child(health)
	if bool(config.get("whole_body", false)):
		# LOTE 12: a group unit (the fly cloud): anywhere on the cloud is a 1x hit; the bomb clears it. No implant weak point.
		var cloud := BoxShape3D.new()
		cloud.size = Vector3(bounds.size.x, bounds.size.y, 1.0)
		hurtbox = _hurtbox("Hurtbox3D", health, cloud, center)
		_has_implant = false
	else:
		hurtbox = _hurtbox("Hurtbox3D", health, SphereShape3D.new(), _implant_center)
		(hurtbox.get_child(0) as CollisionShape3D).shape.set("radius", radius)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	var hit_flash := HitFlash3D.new()
	hit_flash.name = "HitFlash3D"
	hit_flash.visual_root_path = ^"../Rig"
	add_child(hit_flash)
	if _has_implant:
		# LOTE 9: the implant takes 2x; the body below it (shell, legs, wings) also damages the implant at 1x (it was a
		# neutral shield). Body and implant share `health`; one shot hits one area.
		hurtbox.damage_multiplier = BeeLiberation.IMPLANT_MULTIPLIER
		# The body area covers the whole model (some implants are as tall as the animal, e.g. the ant). A shot lined up
		# on the implant that touches the body first still counts as a direct implant hit (weak-point line, see
		# DamageHurtbox3D), so aiming at the implant is always rewarded.
		var box := BoxShape3D.new()
		box.size = Vector3(bounds.size.x, bounds.size.y, 1.0)
		body_hurtbox = _hurtbox("BodyShield", health, box, Vector3(center.x, center.y, 0.0))
		body_hurtbox.damage_multiplier = BeeLiberation.BODY_MULTIPLIER
		body_hurtbox.set_meta("body_hit", true)
		var implant_point := Node3D.new()
		implant_point.name = "ImplantPoint"
		implant_point.position = _implant_center
		rig.add_child(implant_point)
		body_hurtbox.weak_point = implant_point
		body_hurtbox.weak_point_radius = clampf(radius - 0.22, WEAK_RADIUS_RANGE.x, WEAK_RADIUS_RANGE.y)
		body_hurtbox.weak_point_multiplier = BeeLiberation.IMPLANT_MULTIPLIER
		# Auto-aim point: the middle of the body under the implant (1x); never the implant itself.
		var aim_y := minf(lerpf(bounds.position.y, _implant_center.y - body_hurtbox.weak_point_radius, 0.5), _implant_center.y - body_hurtbox.weak_point_radius - 0.12)
		_aim_local = Vector3(center.x, maxf(aim_y, bounds.position.y + 0.05), 0.0)
	else:
		_aim_local = _implant_center
	attack_hitbox = HITBOX_SCENE.instantiate() as DamageHitbox3D
	attack_hitbox.name = "AttackHitbox"
	attack_hitbox.team_id = &"alien"
	attack_hitbox.damage = damage
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = clampf(bounds.size.x * 0.3, 0.3, 0.75) # NOCHE 01: follows the animal size (BeeFaunaSizes).
	shape.shape = sphere
	attack_hitbox.add_child(shape)
	attack_hitbox.position = Vector3(0.0, center.y, 0.0)
	add_child(attack_hitbox)
	attack_hitbox.set_enabled(false)
	# LOTE 13 · ETAPA 3: worm A has its own cycle (eruption, thin laser, arc leap, burying); both worms undulate their 16 segments.
	for node in visual.find_children("Segment_*", "Node3D", true, false):
		if (node as Node3D).get_child_count() >= 0 and str(node.name).length() == 10:
			segments.append(node as Node3D)
			_segment_bases.append((node as Node3D).position)
	if not segments.is_empty(): # The code undulates the body: the model idle clip would overwrite it every frame.
		var clip_player := visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if clip_player != null:
			clip_player.stop()
			clip_player.active = false
	_setup_gait()
	if bool(config.get("worm_a", false)):
		_worm = WormBehavior.new()
		add_child(_worm)
		_worm.setup(self)


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
	_flap()
	_undulate()
	_animate_gait(delta)
	if spent:
		var cam := get_viewport().get_camera_3d()
		if cam != null and global_position.x < cam.global_position.x - 11.0:
			spent = false
			_finish() # Out of the screen: the harmless mushroom leaves play.
		return
	if liberated or target == null:
		return
	if target.is_defeated and state != State.EXIT:
		_cancel_attack()
		state = State.EXIT
	var camera := get_viewport().get_camera_3d()
	var camera_x := camera.global_position.x if camera != null else global_position.x
	if _ground_worm != null and state != State.EXIT:
		_ground_worm.step_frame(delta)
		_face(delta,camera_x)
		return
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
	if _worm != null:
		state = State.IDLE
		_worm.begin()
		return
	if config["mode"] == &"leaper":
		_leaper_swim(delta, camera_x)
		_begin(State.IDLE, _start_idle())
		return
	if config["mode"] == &"cannon":
		_begin(State.IDLE, _start_idle()) # Planted in the garden: it never walks.
		return
	if config["mode"] == &"burrow":
		global_position = Vector3(camera_x + 5.0, ground_y, 0.0)
		_set_buried(true) # LOTE 12: underground until the ground mark has warned.
		_begin(State.IDLE, _start_idle())
		return
	_hover = _hover_point(camera_x)
	if is_ground():
		var arrived := _walk_to(_hover.x, float(config["speed"]) if float(config["speed"]) > 0.0 else 2.0, delta)
		if arrived or global_position.x < camera_x + 5.5 or BeeShmupFairness.is_inside_screen(self, 0.0): # Ground units: on screen = arrived (the snail crawls at 0.7 m/s).
			_begin(State.IDLE, _start_idle())
	elif config["mode"] == &"dash":
		_steer(_hover, MOSQUITO_SPEED, delta) # NOCHE 01: smooth entry too.
		if global_position.distance_to(_hover) < 0.6 or BeeShmupFairness.is_inside_screen(self, ARRIVAL_INSET):
			_begin(State.IDLE, _start_idle())
	else:
		global_position = global_position.move_toward(_hover, 5.5 * delta)
		if global_position.distance_to(_hover) < 0.4 or BeeShmupFairness.is_inside_screen(self, ARRIVAL_INSET):
			_begin(State.IDLE, _start_idle())


func _hover_point(camera_x: float) -> Vector3:
	var bee := target.global_position
	match config["mode"]:
		&"dash":
			return Vector3(minf(bee.x + 3.5, camera_x + 5.0), clampf(bee.y + 0.6, 1.8, 5.6), 0.0)
		&"sweep":
			if bool(config.get("chase", false)): # LOTE 13: the fly cloud follows Bee as a block, right on her tail.
				return Vector3(minf(bee.x + 2.2, camera_x + 5.0), clampf(bee.y + 0.3, 1.6, 5.6), 0.0)
			return Vector3(minf(bee.x + 4.4, camera_x + 5.0), clampf(bee.y + 0.8, 2.0, 5.6), 0.0)
		&"wave":
			return Vector3(camera_x + 5.4, clampf(bee.y, 1.6, 5.4), 0.0)
		&"bomber":
			return Vector3(minf(bee.x + 3.0, camera_x + 4.6), 4.6 + 0.5 * sin(_clock * 0.9), 0.0)
		&"seeder":
			return Vector3(minf(bee.x + 4.6, camera_x + 4.8), clampf(bee.y + 1.0, 3.2, 5.6), 0.0)
		&"zigzag":
			# LOTE 12: the green fly zigzags up and down around Bee's height, always a little ahead.
			return Vector3(minf(bee.x + 4.0, camera_x + 5.0), clampf(bee.y + float(config["zig_amp"]) * sin(_clock * float(config["zig_rate"])), 1.6, 5.6), 0.0)
		&"fighter":
			# Strafes along the top of the right half (a slow sine), always ahead of Bee.
			return Vector3(camera_x + 3.4 + 1.4 * sin(_clock * 0.7), 5.0 + 0.7 * sin(_clock * 1.1), 0.0)
		_:
			return Vector3(bee.x + 3.0, ground_y, 0.0)


func _idle(delta: float, camera_x: float) -> void:
	if _worm != null:
		_worm.step_frame(delta)
		return
	if config["mode"] == &"leaper":
		_leaper_swim(delta, camera_x)
		_left -= delta
		if _left <= 0.0:
			_start_telegraph()
		return
	_hover = _hover_point(camera_x)
	var speed := float(config["speed"])
	match config["mode"]:
		&"dash":
			# NOCHE 01: smooth flight - a slow sine drift around its hover point, reached with gradual acceleration.
			_steer(_hover + _mosquito_drift(), MOSQUITO_SPEED, delta)
		&"cannon":
			pass # Static: its position is part of the garden.
		&"burrow":
			pass # Underground: nothing to steer until it picks the spot to erupt.
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
	_variant = _pick_variant()
	if first_telegraph_clock < 0.0:
		first_telegraph_clock = _clock
	_left = maxf(float(config["telegraph"]), MIN_TELEGRAPH)
	var warning_count := int(config.get("burst", 1))
	var warning_gap := float(config.get("burst_gap", 0.0))
	if _variant == &"spit" and config.has("spit"):
		warning_count = int(config["spit"].get("shots", 1))
		warning_gap = float(config["spit"].get("gap", 0.0))
	BeeShotWarning.volley(self, kind, visual, _left, warning_count, warning_gap)
	_tele_started = BeeAttackTokens.now()
	_lock_from = global_position
	var bee := target.global_position
	match mode:
		&"dash":
			if _variant == &"spit":
				_lock_to = bee # LOTE 13: the spit variant of the common fly: thin aim line, then aimed pellets.
			else:
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
			if _variant == &"spit":
				_lock_to = bee # Worm B spit: the aim line (added below) locks, then a mud fan.
			else:
				var dirx := signf(bee.x - global_position.x) if absf(bee.x - global_position.x) > 0.1 else _facing
				_lock_to = global_position + Vector3(dirx * float(config["lunge_range"]), 0.0, 0.0)
				_add_line(global_position + Vector3(0, 0.5, 0), _lock_to + Vector3(0, 0.5, 0), 0.14)
		&"charge":
			var dirc := signf(bee.x - global_position.x) if absf(bee.x - global_position.x) > 0.1 else _facing
			_lock_to = global_position + Vector3(dirc * float(config["charge_speed"]) * float(config["charge_time"]), 0.0, 0.0)
			_add_line(global_position + Vector3(0, 0.4, 0), _lock_to + Vector3(0, 0.4, 0), 0.5, Color(1.0, 0.55, 0.15, 0.25))
		&"fighter":
			_lock_to = bee
		&"leaper":
			var lock_x := bee.x
			_lock_from = Vector3(lock_x + LEAP_SPAN, LEAP_DEPTH, 0.0)
			_lock_to = Vector3(lock_x - LEAP_SPAN, LEAP_DEPTH, 0.0)
			_leap_apex = clampf(bee.y + 0.4, 2.2, float(config["leap_height"]))
			var ripple := COMMON_CUE.ring(get_parent(), Vector3(lock_x, WATER_SURFACE_Y + 0.05, 0.0), attack_hitbox.get_node("CollisionShape3D").shape.radius, WARN_COLOR)
			ripple.rotation.x = 0.0
			if not COMMON_CUE.enabled:
				ripple.scale = Vector3(1.4, 1.0, 0.6)
			_warn.append(ripple)
			_warn.append(BeeAttackVisuals.line(get_parent(), Vector3(lock_x, WATER_SURFACE_Y, 0.0), Vector3(lock_x, _leap_apex, 0.0), 0.06, Color(1.0, 0.55, 0.15, 0.35)))
			COMMON_CUE.suppress(_warn.back())
		&"bomber":
			_add_ring(global_position + Vector3(0, -0.8, 0), float(config["radius"]))
		&"burrow":
			# LOTE 12: it picks a spot just ahead of Bee, inside the screen, and marks it on the ground for the whole warning.
			var spot := minf(bee.x + 2.6, get_viewport().get_camera_3d().global_position.x + 5.0)
			global_position = Vector3(spot, ground_y, 0.0)
			_lock_from = global_position
			_lock_to = global_position
			if not COMMON_CUE.enabled:
				_warn.append(BeeAttackVisuals.ground_disc(get_parent(), Vector3(spot, ground_y + 0.05, 0.0), 1.5, WARN_COLOR))
			_add_ring(Vector3(spot, ground_y + 0.05, 0.0), attack_hitbox.get_node("CollisionShape3D").shape.radius)
		_:
			_lock_to = bee # Shooters: the aim line below and the glow are the warning.
	# LOTE 13: aimed attacks show a thin line to Bee that follows her and LOCKS (turns orange) AIM_LOCK_BEFORE s before the first shot:
	# the whole burst / fan / lob then goes along the locked line, so leaving it after the lock is a clean dodge.
	_aim_locked = false
	_aim_line = null
	if _is_aimed_attack():
		_aim_lock_point = bee
		_aim_line = BeeAttackVisuals.line(get_parent(), _muzzle(), bee, AIM_LINE_WIDTH, WARN_COLOR)
		_warn.append(_aim_line)
		COMMON_CUE.suppress(_aim_line)


func _telegraph(delta: float) -> void:
	_left -= delta
	if config["mode"] == &"dash":
		_steer(global_position if _variant == &"spit" else _lock_from, MOSQUITO_SPEED, delta) # Brakes softly onto the start of its warning line.
	var progress := 1.0 - clampf(_left / maxf(float(config["telegraph"]), MIN_TELEGRAPH), 0.0, 1.0)
	var flare := 1.0 + 0.12 * sin(progress * PI * 3.0) + 0.1 * progress
	if not COMMON_CUE.enabled:
		visual.scale = Vector3.ONE * model_scale * flare # Whole animal swells: readable on any silhouette.
	if _aim_line != null and is_instance_valid(_aim_line):
		if not _aim_locked:
			_aim_lock_point = target.global_position # Follows Bee...
			if _left <= AIM_LOCK_BEFORE:
				_aim_locked = true # ...until the lock: it turns orange and stops.
				(_aim_line.mesh as BoxMesh).material = BeeAttackVisuals.material(LOCK_COLOR)
		BeeAttackVisuals.place_line(_aim_line, _muzzle(), _aim_lock_point)
		if _aim_locked:
			BeeAttackVisuals.hide_when_dodged(_aim_line, _muzzle(), _aim_lock_point, target.global_position, AIM_DODGE_CLEARANCE)
	if config["mode"] == &"lunge" or config["mode"] == &"charge":
		rig.rotation.z = (0.25 if config["mode"] == &"lunge" else -0.12) * progress * -_facing # Retain the original rig/hurtbox transform.
		if kind == &"Ant" and COMMON_CUE.enabled:
			visual.rotation.z = COMMON_CUE.ANT_CROUCH_TILT * progress * -_facing # Crouch only the model, never its sibling hurtboxes.
	if _left <= 0.0:
		telegraphs.append(BeeAttackTokens.now() - _tele_started)
		visual.scale = Vector3.ONE * model_scale
		if kind == &"Ant": visual.rotation.z = 0.0
		rig.rotation.z = 0.0
		_clear_warn()
		_start_attack()


func _start_attack() -> void:
	state = State.ATTACK
	_play("attack")
	var mode: StringName = config["mode"]
	if mode == &"leaper":
		_left = float(config["leap_time"])
		global_position = _lock_from
		attack_hitbox.set_enabled(true)
		return
	if mode == &"burrow":
		_surface()
		_left = 0.5
		attack_hitbox.set_enabled(true)
		return
	match mode:
		&"dash":
			if _variant == &"spit":
				var spit: Dictionary = config["spit"]
				_arm_burst(int(spit["shots"]), float(spit["gap"]), StringName(spit["style"]), float(spit["speed"]))
				_left = float(spit["gap"]) * float(int(spit["shots"]) - 1) + 0.3
			else:
				_left = float(config["dash_range"]) / float(config["dash_speed"])
				attack_hitbox.set_enabled(true)
		&"sweep":
			_left = float(config["pass_time"])
			attack_hitbox.set_enabled(true)
		&"wave":
			_left = 17.0 / float(config["wave_speed"])
			attack_hitbox.set_enabled(true)
		&"lunge":
			if _variant == &"spit":
				_fire_fan_style() # Worm B: a mud fan from the soil
				_left = 0.45
			else:
				_left = 0.35
				attack_hitbox.set_enabled(true)
		&"charge":
			_left = float(config["charge_time"])
			attack_hitbox.set_enabled(true)
		&"bomber":
			_drop_bomb()
			_left = 0.2
		&"spitter", &"cannon", &"seeder", &"fighter", &"zigzag":
			var burst := int(config.get("burst", 1))
			if burst > 1: # LOTE 13: the green fly spits acid in a burst, aimed again at every drop.
				_arm_burst(burst, float(config.get("burst_gap", 0.17)), StringName(config.get("style", &"")), float(config["shot_speed"]))
				_left = float(config.get("burst_gap", 0.17)) * float(burst - 1) + 0.3
			else:
				_fire()
				_left = 0.25
		_:
			_left = 0.2


func _attack(delta: float, _camera_x: float) -> void:
	if config["mode"] == &"leaper":
		_leaper_leap(delta)
		return
	_left -= delta
	_update_burst(delta)
	var mode: StringName = config["mode"]
	match mode:
		&"dash":
			if _variant != &"spit":
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
			if not (mode == &"lunge" and _variant == &"spit"): # Worm B spitting stays put
				global_position = global_position.move_toward(_lock_to, speed * delta)

	if _left <= 0.0:
		if mode == &"dash" and _variant != &"spit":
			_velocity = (_lock_to - _lock_from).normalized() * MOSQUITO_SPEED # Glides out of the dash.
		_burst_left = 0
		_variant = &""
		attack_hitbox.set_enabled(false)
		_release_token()
		cycles_done += 1
		state = State.RECOVER
		_left = recovery_time if mode != &"charge" else 1.4
		if mode == &"burrow":
			_left = float(config["exposed"]) # Surfaced and vulnerable for this long, then it digs back in.
		if cycles_done >= max_cycles:
			state = State.EXIT


func _recover(delta: float, camera_x: float) -> void:
	if config["mode"] == &"burrow":
		_left -= delta
		if _left <= 0.0:
			_set_buried(true)
			_begin(State.IDLE, idle_time)
		return
	if config["mode"] == &"leaper":
		_leaper_swim(delta, camera_x)
		_left -= delta
		if _left <= 0.0:
			_begin(State.IDLE, idle_time)
		return
	_hover = _hover_point(camera_x)
	if not is_ground():
		var back := _hover
		if config["mode"] == &"wave":
			back.x = camera_x + 5.4
		if config["mode"] == &"dash":
			_steer(back + _mosquito_drift(), MOSQUITO_SPEED, delta) # Eases out of its dash instead of snapping back.
		else:
			global_position = global_position.move_toward(back, maxf(float(config["speed"]), 3.0) * 1.4 * delta)
	_left -= delta
	if _left <= 0.0:
		_begin(State.IDLE, idle_time)


func _play(clip: String) -> void:
	# LOTE 12: the Codex flies carry hover/attack/liberate clips (their wrapper loops "hover").
	if visual != null and visual.has_method("play_clip") and str(kind).begins_with("fly_"):
		visual.call("play_clip", clip)


func _begin(next: int, seconds: float) -> void:
	if next == State.IDLE:
		_play("hover")
	state = next
	_left = seconds


func _cancel_attack() -> void:
	if _ground_worm != null: _ground_worm.cancel()
	COMMON_CUE.cancel(visual)
	if kind == &"Ant": visual.rotation.z = 0.0
	attack_hitbox.set_enabled(false)
	if _worm != null:
		_worm.cancel()
	_clear_warn()
	_release_token()
	visual.scale = Vector3.ONE * model_scale
	rig.rotation.z = 0.0


func _release_token() -> void:
	if _token_held:
		BeeAttackTokens.release(self)
		_token_held = false


# --- LOTE 12: burrowing worm ----------------------------------------------------------------------------------------

var buried := false

## Underground: invisible, not targetable and harmless. `false` brings it back (see `_surface`).
func _set_buried(value: bool) -> void:
	buried = value
	visual.visible = not value
	hurtbox.set_deferred("monitorable", not value)
	if body_hurtbox != null:
		body_hurtbox.set_deferred("monitorable", not value)
	if value:
		remove_from_group("bee_auto_aim_targets")
	elif not is_in_group("bee_auto_aim_targets"):
		add_to_group("bee_auto_aim_targets")


## Erupts: the model rises out of the soil in 0.3 s; the eruption hitbox is live for 0.5 s (see `_start_attack`).
func _surface() -> void:
	_set_buried(false)
	rig.position.y = -1.2
	var rise := create_tween()
	rise.tween_property(rig, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- attacks that spawn something ------------------------------------------------------------------------------


func _muzzle() -> Vector3:
	var local := _implant_center
	return rig.to_global(local)


## Damage of a bullet of this unit (3-5 on the roster, see KINDS "shot_damage").
func _shot_damage() -> int:
	return shot_damage if shot_damage > 0 else damage

func _fire() -> void:
	if not BeeShmupFairness.can_fire(self):
		return
	var mode: StringName = config["mode"]
	var style: StringName = StringName(config.get("style", &""))
	var aim := _aim_target() - _muzzle()
	if bool(config.get("lob", false)): # LOTE 13: the snail lobs a slime bubble in an arc to where Bee is.
		BeeEnemyPatterns.spawn_lob(get_parent(), PROJECTILE, _muzzle(), _aim_target(), _shot_damage(), float(config.get("lob_flight", 1.3)), float(config.get("lob_gravity", 7.0)), self, style)
		shots_fired += 1
		BeeCombatVFX.spawn(get_parent(), _muzzle(), &"tech_hit", Vector3.UP, 0.5)
		return
	var count := 1
	var step := 14.0
	if mode == &"cannon":
		count = 3
	elif mode == &"fighter":
		count = 3
		step = 10.0
	elif mode == &"seeder":
		count = 3
		step = 20.0
	for direction in BeeEnemyPatterns.fan_directions(aim, count, step):
		var shot: AlienEnemyProjectile
		if style != &"":
			shot = BeeEnemyPatterns.spawn_styled(get_parent(), PROJECTILE, _muzzle(), direction, _shot_damage(), float(config["shot_speed"]), self, style)
		else:
			shot = BeeEnemyPatterns.spawn_shot(get_parent(), PROJECTILE, _muzzle(), direction, _shot_damage(), float(config["shot_speed"]), self)
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
	BeeAttackVisuals.WARNING_STYLE.dress(line, color, 0.0 if width >= 0.12 else 3.0, _left)
	_warn.append(line)
	COMMON_CUE.suppress(line)


func _add_ring(at: Vector3, radius: float) -> void:
	var ring := COMMON_CUE.ring(get_parent(), at, radius, WARN_COLOR)
	_warn.append(ring)
	if config["mode"] == &"bomber":
		COMMON_CUE.suppress(ring)


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
		tween.tween_property(visual, "scale", Vector3.ONE * model_scale * 1.08, 0.05)
		tween.tween_property(visual, "scale", Vector3.ONE * model_scale, 0.08)


func _on_died() -> void:
	if liberated:
		return
	liberated = true
	state = State.LIBERATED
	_cancel_attack()
	if _worm != null: # A freed worm lies down on the soil (never stays standing or buried).
		rig.rotation.z = 0.0
		rig.position.y = 0.0
		visual.visible = true
		global_position.y = ground_y
	remove_from_group("bee_auto_aim_targets")
	hurtbox.set_deferred("monitorable", false)
	for area: Area3D in find_children("*", "Area3D", true, false):
		if area is DamageHitbox3D:
			(area as DamageHitbox3D).set_enabled(false)
		area.set_deferred("monitorable", false) # No contact damage and no more hits after the implant breaks.
	liberated_now.emit(self)
	var at := _muzzle()
	if bool(config.get("machine", false)):
		# Technology explodes (NOCHE 01: unchanged rule).
		BeeLiberation.explode_tech(get_parent(), at, 1.0)
		var boom := create_tween()
		boom.tween_property(self, "scale", Vector3.ONE * 0.1, 0.35)
		boom.tween_callback(_finish)
		return
	if config["mode"] == &"cannon":
		# NOCHE 01: only the alien cannon blows up; the mushroom stays where it grows, intact and harmless.
		BeeLiberation.explode_tech(get_parent(), at, 0.6)
		if visual.has_method("release_control"):
			visual.call("release_control")
		BeeLiberation.warm_colours(visual)
		spent = true
		return # Leaves play (defeated) once the scroll has left it behind: see _physics_process.
	add_to_group("bee_liberated")
	_play("liberate")
	if visual.has_method("release_control"):
		visual.call("release_control")
	BeeLiberation.free_animal(get_parent(), visual, _device, at)
	preload("res://scripts/vfx/bee_release_animation.gd").start_release(self,visual,_finish)


func _finish() -> void:
	state = State.DONE
	hide()
	set_physics_process(false)
	defeated.emit(self)


# --- LOTE 9: flapping wings, body sway and a soft wavy bob ------------------------------------------------------------

func _flap() -> void:
	if wings.is_empty():
		return
	var spec: Array = FLAP[kind]
	var beat := 0.5 + 0.5 * sin(_clock * TAU * float(spec[0])) # 0 = wings down, 1 = wings up.
	var lift := lerpf(float(spec[1]), float(spec[2]), beat)
	for i in wings.size():
		# Rotate about the body axis (X) in the hinge's parent space: the wing sweeps up through the camera's view.
		wings[i].transform.basis = Basis(Vector3.RIGHT, _wing_sides[i] * lift) * _wing_bases[i]
	# The body rides each beat (rises on the downstroke) and sways slowly: never a rigid, still silhouette.
	var wave := TAU * float(spec[5]) * _clock
	visual.position.y = float(spec[4]) * (sin(wave) + 0.35 * (1.0 - beat))
	visual.rotation.z = float(spec[3]) * sin(wave * 0.7 + 0.6)
	visual.rotation.x = 0.5 * float(spec[3]) * sin(wave * 1.3)


## Current wing lift (rad) of the first wing (tests).
func wing_lift() -> float:
	if wings.is_empty():
		return 0.0
	return (wings[0].transform.basis * _wing_bases[0].inverse()).get_euler().x * _wing_sides[0]


# --- NOCHE 01: smooth mosquito flight -------------------------------------------------------------------------------

func _mosquito_drift() -> Vector3:
	return Vector3(sin(_clock * MOSQUITO_DRIFT_RATE.x) * MOSQUITO_DRIFT.x, sin(_clock * MOSQUITO_DRIFT_RATE.y + 1.3) * MOSQUITO_DRIFT.y, 0.0)


## Velocity steering: accelerates gradually (MOSQUITO_ACCEL) towards `goal`, never faster than `max_speed`.
func _steer(goal: Vector3, max_speed: float, delta: float) -> void:
	var desired := (goal - global_position) * 1.6
	desired.z = 0.0
	desired = desired.limit_length(max_speed)
	_velocity = _velocity.move_toward(desired, MOSQUITO_ACCEL * delta)
	global_position += _velocity * delta


# --- NOCHE 01 · ETAPA 4: the perch (leaper) ------------------------------------------------------------------------
# Swims under the surface (no hurtbox, not targetable) a little ahead of Bee; the warning is a ring on the water + a faint
# column at Bee's X; then it leaps out in an arc through that X (hurts while in the air) and dives back.

func _leaper_swim(delta: float, camera_x: float) -> void:
	var goal_x := minf(target.global_position.x + 1.5, camera_x + 4.5)
	global_position.x = move_toward(global_position.x, goal_x, float(config["speed"]) * delta)
	global_position.y = move_toward(global_position.y, LEAP_DEPTH, 3.0 * delta)
	_set_submerged(true)


func _leaper_leap(delta: float) -> void:
	_left -= delta
	var t := 1.0 - clampf(_left / float(config["leap_time"]), 0.0, 1.0)
	var p := _lock_from.lerp(_lock_to, t)
	p.y = LEAP_DEPTH + (_leap_apex - LEAP_DEPTH) * 4.0 * t * (1.0 - t)
	global_position = p
	rig.rotation.z = lerpf(0.5, -0.5, t) * (-_facing) # Nose up on the way out, down on the way in.
	_set_submerged(p.y < WATER_SURFACE_Y - 0.3)
	if _left <= 0.0:
		rig.rotation.z = 0.0
		attack_hitbox.set_enabled(false)
		cycles_done += 1
		state = State.RECOVER
		_left = recovery_time + 0.6
		if cycles_done >= max_cycles:
			state = State.EXIT


func _set_submerged(value: bool) -> void:
	if value == _submerged:
		return
	_submerged = value
	hurtbox.set_deferred("monitorable", not value)
	if body_hurtbox != null:
		body_hurtbox.set_deferred("monitorable", not value)
	if value:
		remove_from_group("bee_auto_aim_targets")
	elif not liberated:
		add_to_group("bee_auto_aim_targets")


func is_submerged() -> bool:
	return _submerged


# --- LOTE 13 · ETAPA 2: first attack soon, spit / burst patterns with their own shot looks, chasing cloud ----------------------------

## Seconds of rest after arriving: the short first rest only before the first attack.
func _start_idle() -> float:
	return first_idle_time if first_idle_time >= 0.0 and attacks_started == 0 else idle_time


## True while a warning is showing (tests: time from entering the screen to the first warning).
func is_telegraphing() -> bool:
	if _ground_worm != null: return _ground_worm.is_warning()
	return state == State.TELEGRAPH or (_worm != null and _worm.is_warning())


var _variant := &"" # &"spit" = a flying fly's alternate attack: aimed pellets instead of the ram.
var _burst_left := 0
var _burst_clock := 0.0
var _burst_gap := 0.17
var _burst_style: StringName = &""
var _burst_speed := 5.5
var first_telegraph_clock := -1.0 ## `_clock` at the first warning (tests).


## The attack variant of this cycle: the common fly alternates ram and spit (config "spit").
func _pick_variant() -> StringName:
	var spit: Dictionary = config.get("spit", {})
	if not spit.is_empty() and attacks_started % int(spit.get("every", 2)) == 0:
		return &"spit"
	return &""


## Arms the shot burst of this attack (`count` shots `gap` s apart, the first one now).
func _arm_burst(count: int, gap: float, style: StringName, speed: float) -> void:
	_burst_left = count
	_burst_clock = 0.0
	_burst_gap = gap
	_burst_style = style
	_burst_speed = speed


## One pellet / drop aimed at Bee's position at this very moment, then it flies straight.
func _fire_aimed_style(style: StringName, speed: float) -> void:
	if not BeeShmupFairness.can_fire(self):
		return
	var aim := _aim_target() - _muzzle()
	aim.z = 0.0
	var shot := BeeEnemyPatterns.spawn_styled(get_parent(), PROJECTILE, _muzzle(), aim.normalized(), _shot_damage(), speed, self, style)
	shots_fired += 1
	BeeCombatVFX.spawn(get_parent(), shot.global_position, &"tech_hit", Vector3.UP, 0.35)


func _update_burst(delta: float) -> void:
	if _burst_left <= 0:
		return
	_burst_clock -= delta
	if _burst_clock <= 0.0:
		_burst_left -= 1
		_burst_clock = _burst_gap
		_fire_aimed_style(_burst_style, _burst_speed)


## The line the current warning marks: [from, to, half_width] while a ram / lunge / charge / sweep / aimed spit is being warned, else [].
## Tests and bots read it the way a player reads the warning line on screen.
func warned_line() -> Array:
	if _worm != null:
		return _worm.warned_line()
	if state != State.TELEGRAPH:
		return []
	if _aim_line != null and is_instance_valid(_aim_line):
		if not _aim_locked:
			return [] # The aim line still follows Bee: nothing to dodge yet.
		if bool(config.get("lob", false)):
			return [_aim_lock_point, _aim_lock_point + Vector3(0.05, 0.0, 0.0), 1.6] # Where the arc lands.
		var from := _muzzle()
		return [from, from + (_aim_lock_point - from).normalized() * 14.0, 0.8]
	match config["mode"]:
		&"dash":
			return [global_position, _lock_to, 0.9]
		&"lunge", &"charge", &"sweep":
			return [_lock_from, _lock_to, 0.9]
	return []


## LOTE 13: the aimed attacks (shooters and the common fly's spit variant) show an aim line that locks before the burst.
const AIMED_MODES := [&"zigzag", &"spitter", &"cannon", &"fighter", &"seeder"]
const AIM_LOCK_BEFORE := 0.3 ## Seconds before the first shot at which the aim line stops following Bee (it turns orange).
const LOCK_COLOR := Color(1.0, 0.45, 0.12, 0.8)
var _aim_line: MeshInstance3D
var _aim_locked := false
var _aim_lock_point := Vector3.ZERO


func _is_aimed_attack() -> bool:
	return config["mode"] in AIMED_MODES or (config["mode"] in [&"dash", &"lunge"] and _variant == &"spit")


## Where the volley goes: the locked point once the aim line has locked, Bee's position before.
func _aim_target() -> Vector3:
	return _aim_lock_point if _aim_locked else target.global_position


# --- LOTE 13 · ETAPA 3: worms -------------------------------------------------------------------------------------------------------

var _worm: WormBehavior
var _ground_worm: Node
var segments: Array[Node3D] = [] # The 16 body segments (worms): they undulate with a travelling sine wave.
var _segment_bases: Array[Vector3] = []


## Travelling sine wave along the body (config "undulate": [amplitude m, speed rad/s, phase per segment rad]). Faster crawling = bigger waves.
func _undulate() -> void:
	if segments.is_empty():
		return
	var spec: Array = config.get("undulate", [0.07, 7.0, 0.55])
	var amplitude := float(spec[0]) * (1.0 + clampf(absf(_move_vx) * 0.25, 0.0, 0.8))
	for i in segments.size():
		var wave := _clock * float(spec[1]) - float(i) * float(spec[2])
		segments[i].position = _segment_bases[i] + Vector3(0.0, amplitude * sin(wave), amplitude * 0.8 * cos(wave * 0.7))


## A fan of `fan` shots of the spit variant along the locked aim (worm B: mud from the soil).
func _fire_fan_style() -> void:
	if not BeeShmupFairness.can_fire(self):
		return
	var spit: Dictionary = config.get("spit", {})
	var origin := _muzzle()
	var aim := _aim_target() - origin
	for direction in BeeEnemyPatterns.fan_directions(aim, int(spit.get("fan", 3)), float(spit.get("step", 16.0))):
		BeeEnemyPatterns.spawn_styled(get_parent(), PROJECTILE, origin, direction, _shot_damage(), float(spit.get("speed", 4.2)), self, StringName(spit.get("style", &"mud")))
		shots_fired += 1
	BeeCombatVFX.spawn(get_parent(), origin, &"rock_break", Vector3.UP, 0.5)


# --- LOTE 13 · ETAPA 3: the stag beetle WALKS (no more ice skating) -----------------------------------------------------------------
## Config "gait": [stride m, leg swing m, leg lift m, body bounce m, body sway rad]. Tripod gait: legs 1_0, -1_1, 1_2 against -1_0, 1_1, -1_2.
## The step phase advances with the REAL ground speed (stride metres per step), so the feet match the soil; at rest the legs settle.

var _legs: Array[Node3D] = []
var _leg_groups: Array[float] = [] # +1 / -1: which tripod the leg belongs to.
var _leg_bases: Array[Vector3] = []
var _mandibles: Array[Node3D] = []
var _mandible_sides: Array[float] = []
var _gait_phase := 0.0
var gait_steps := 0 ## Half-cycles walked (tests).
var _visual_base_y := 0.0


func _setup_gait() -> void:
	if not config.has("gait"):
		return
	_visual_base_y = visual.position.y
	for node in visual.find_children("Leg_*", "Node3D", true, false):
		var leg := node as Node3D
		_legs.append(leg)
		_leg_bases.append(leg.position)
		var parts := str(leg.name).split("_") # Leg_<side>_<index>: tripod = parity of (side + index).
		var side := 1 if parts[1] == "1" else 0
		_leg_groups.append(1.0 if (side + int(parts[2])) % 2 == 0 else -1.0)
	for node in visual.find_children("Mandible*", "Node3D", true, false):
		_mandibles.append(node as Node3D)
		_mandible_sides.append(-1.0 if str(node.name).ends_with("_001") or str(node.name).ends_with("_R") else 1.0)


func _animate_gait(delta: float) -> void:
	if _legs.is_empty():
		return
	var spec: Array = config["gait"]
	var speed := absf(_move_vx)
	var walking := speed > 0.15 and state != State.TELEGRAPH
	if walking:
		var before := int(floorf(_gait_phase / PI))
		_gait_phase += minf(speed / float(spec[0]) * PI, GAIT_MAX_RATE) * delta
		gait_steps += int(floorf(_gait_phase / PI)) - before
	var amount := 1.0 if walking else 0.0
	_gait_blend = move_toward(_gait_blend, amount, delta * 5.0)
	for i in _legs.size():
		var phase := _gait_phase + (0.0 if _leg_groups[i] > 0.0 else PI)
		var swing := float(spec[1]) * sin(phase) * _gait_blend
		var lift := float(spec[2]) * maxf(0.0, cos(phase)) * _gait_blend
		_legs[i].position = _leg_bases[i] + Vector3(swing, lift, 0.0)
	visual.position.y = _visual_base_y + float(spec[3]) * absf(sin(_gait_phase)) * _gait_blend
	visual.rotation.z = float(spec[4]) * sin(_gait_phase) * _gait_blend


var _gait_blend := 0.0
const GAIT_MAX_RATE := 14.0 ## rad/s: even a full charge flutters no faster than this.


## 0..1: how far the pincers are open (the stone throw warning opens them; 0 = closed).
func set_pincers(open: float) -> void:
	for i in _mandibles.size():
		_mandibles[i].rotation.y = _mandible_sides[i] * open * PINCER_OPEN_RAD


const PINCER_OPEN_RAD := 0.38


## Where the beetle's stones leave from: between its open pincers, in front of the head.
func pincer_point() -> Vector3:
	var head := visual.find_child("Head", true, false) as Node3D
	if head == null:
		return _muzzle()
	return head.global_position + visual.global_transform.basis * Vector3(-0.35, 0.0, 0.0)
