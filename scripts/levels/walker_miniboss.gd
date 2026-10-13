class_name WalkerMiniboss
extends GroundWalkerEnemy
## LOTE 12 · ETAPA 3 — the walking robot as the Level 1 MINI-BOSS (gate after checkpoint 2, with insect escorts in two waves).
## Same scene, model and animations as the GroundWalkerEnemy; its own short fight.
## LOTE 15 · ETAPA 5.2 — DYNAMIC, not harder: it walks across the WHOLE screen and jumps (warned) to Bee's column; every attack
## is aimed at Bee:
##   STRIDE   it walks from one side of the screen to the other (the attacks come from both sides).
##   CANNON   the dorsal cannon charges (cyan sphere + aim line, CANNON_TELEGRAPH s), locks the line on Bee and fires a burst of
##            CANNON_SHOTS along it (aimed at Bee's height). Weak point: the cannon has its own HP; breaking it ends the cannon
##            AND the mortars for good.
##   MORTARS  the cannon lobs MORTAR_COUNT shells high; their SHADOWS (ground disc + column) mark Bee's column and its neighbours
##            MORTAR_WARNING s before they fall straight down. Leave the column.
##   LASER    the yellow eye draws the two edges of a sector centred on Bee (LASER_WARNING s), then its beam sweeps the sector.
##   JUMP     it crouches, a landing shadow marks Bee's column (JUMP_TELEGRAPH s), it leaps there and lands with a small wave.
##   STOMP    it rears up (warning band on the ground, STOMP_TELEGRAPH s) and stamps: a wave runs along the ground to both
##            screen edges (BeeGroundShockwave, not a projectile: the roll never destroys it). Fly above it.
##   EYE      the yellow eye is a weak point inside the body hurtbox: a shot whose line passes within EYE_RADIUS does EYE_MULTIPLIER.
## At ESCORT_RATIO of its HP (or after ESCORT_FALLBACK s) it calls the second escort wave (the director spawns it).
## It explodes when it falls (technology, never freed). Target: 30-45 s with Base and Spread (validate_bee_walker_miniboss_v01).

signal escorts_requested
signal cannon_broken

const DISPLAY_NAME := "ROBOT CAMINANTE"
const CANNON_TELEGRAPH := 0.5
const CANNON_SHOTS := 3
const CANNON_GAP := 0.16
const CANNON_SPEED := 8.0
const CANNON_DAMAGE := 6
const STOMP_TELEGRAPH := 0.6
const STOMP_DAMAGE := 8
const STOMP_SPEED := 7.0
const STOMP_HEIGHT := 1.25
const MORTAR_COUNT := 3
const MORTAR_SPACING := 2.4
const MORTAR_WARNING := 0.85
const MORTAR_FALL := 0.5
const MORTAR_DAMAGE := 6
const LASER_WARNING := BeeGameSettings.ROBOT_LASER_WARNING_SEC
const LASER_SWEEP := 0.7
const LASER_HALF_ANGLE := 20.0 # degrees each side of Bee's direction.
const LASER_LENGTH := 16.0
const LASER_DAMAGE := 6
const JUMP_TELEGRAPH := 0.75
const JUMP_SECONDS := 0.8
const JUMP_APEX := 3.4
const JUMP_DAMAGE := 8
const JUMP_MIN_DISTANCE := 3.0
const STRIDE_SPEED := 3.0
const STRIDE_MAX_SECONDS := 4.0
const MIN_TELEGRAPH := 0.42
## Pattern while the cannon lives / after it broke (the cannon fires the burst and the mortars).
const PATTERN := [&"cannon", &"mortars", &"stride", &"laser", &"jump", &"cannon", &"mortars", &"stride", &"laser", &"stomp"]
const PATTERN_NO_CANNON := [&"stride", &"laser", &"jump", &"laser", &"stomp", &"stride", &"jump"]
const REST := 0.8
const REST_NO_CANNON := 0.7
const CANNON_HP := 110
const CANNON_BOX := Vector3(2.4, 0.6, 1.0)
const CANNON_CENTRE := Vector2(0.9, 2.72) # (forward, height) of the cannon box, mirrored with the facing.
const EYE_HEIGHT := 1.35
const EYE_RADIUS := 0.42
const EYE_MULTIPLIER := 2.0
const ESCORT_RATIO := 0.6
const ESCORT_FALLBACK := 14.0
## Sustained damage budget on the body (fraction of max HP per second, reserve): Spread cannot melt it.
const BODY_DPS_RATIO := 0.032
const BODY_BURST := 30.0
const FIRST_REST := 0.15 ## Rest after walking in, before the first attack.
const EDGE_INSET := 1.6 ## The stride goes from one side to this far from the other edge.
const ENTRY_INSET := 1.4 # LOTE 13: it starts attacking within ~1 s of entering the screen (the rule of the level).
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")

var hazards: Array[Dictionary] = [] # {"kind", "telegraph"} per damaging attack (tests).
var fight_seconds := 0.0
var cannon_alive := true
var cannon_health: HealthComponent
var cannon_hurtbox: DamageHurtbox3D
var cannon_shots := 0
var stomps := 0
var strides := 0
var mortars := 0
var lasers := 0
var jumps := 0
var stride_span := 0.0 # Longest stride (m), tests.
var escorts_called := false
var attack_kind := &"none" # The attack in progress (bot / tests).
var attack_left := 0.0 # Warning left of the attack in progress.
var mortar_xs: Array[float] = [] # Columns of the last mortar volley (bot reads them).
var laser_origin := Vector3.ZERO
var laser_angles := Vector2.ZERO # (from, to) radians of the sweep.
var jump_to_x := 0.0
var _step := &"enter"
var _left := 0.0
var _attack_index := 0
var _locked_dir := Vector3.LEFT
var _shots_left := 0
var _aim_line: MeshInstance3D
var _stomp_band: MeshInstance3D
var _eye: Node3D
var _walk_goal := 0.0
var _stride_from := 0.0
var _bar_layer: CanvasLayer
var _bar: ProgressBar
var _body_tokens := BODY_BURST
var _warnings: Array[Node3D] = []
var _beam: MeshInstance3D
var _beam_box: DamageHitbox3D
var _beam_pivot: Node3D
var _ground_y := 0.0
var _jump_from := 0.0
var _land_box: DamageHitbox3D


func _ready() -> void:
	super._ready()
	# The body area stops under the cannon (the cannon is its own target on top).
	var capsule := (hurtbox.get_node("CollisionShape3D") as CollisionShape3D)
	var shape := (capsule.shape as CapsuleShape3D).duplicate() as CapsuleShape3D
	shape.height = 2.6
	capsule.shape = shape
	capsule.position = Vector3(0.0, -1.5, 0.0) # Centre at y ~1.1 (root at the ground), top ~2.4.
	_eye = Node3D.new()
	_eye.name = "EyeWeakPoint"
	add_child(_eye)
	hurtbox.weak_point = _eye
	hurtbox.weak_point_radius = EYE_RADIUS
	hurtbox.weak_point_multiplier = EYE_MULTIPLIER
	cannon_health = HEALTH_SCENE.instantiate() as HealthComponent
	cannon_health.name = "CannonHealth"
	cannon_health.max_health = BeeGameSettings.scaled_hp(CANNON_HP)
	add_child(cannon_health)
	cannon_health.current_health = cannon_health.max_health
	cannon_health.died.connect(_break_cannon)
	cannon_hurtbox = HURTBOX_SCENE.instantiate() as DamageHurtbox3D
	cannon_hurtbox.name = "CannonHurtbox"
	cannon_hurtbox.team_id = &"alien"
	cannon_hurtbox.health_component_path = NodePath("../CannonHealth")
	cannon_hurtbox.owner_entity_path = NodePath("..")
	var box := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = CANNON_BOX
	box.shape = cube
	cannon_hurtbox.add_child(box)
	cannon_hurtbox.monitorable = false
	add_child(cannon_hurtbox)
	_build_health_bar()
	health.health_changed.connect(_on_health_changed)


func activate(new_target: BeePlayer) -> bool:
	if not super.activate(new_target):
		return false
	_step = &"enter"
	_ground_y = global_position.y
	cannon_hurtbox.set_deferred("monitorable", true)
	_bar_layer.visible = true
	_place_weak_points()
	return true


## Auto-aim (and its marker) goes to the body at eye height, not to the cannon on top: the cannon is a deliberate mouse shot.
func auto_aim_point() -> Vector3:
	return global_position + Vector3(_facing_x * 0.05, EYE_HEIGHT - 0.1, 0.0)


func is_miniboss() -> bool:
	return true


func _cam_x() -> float:
	var camera := get_viewport().get_camera_3d()
	return camera.global_position.x if camera != null else global_position.x


func _half_width() -> float:
	return BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))


func _physics_process(delta: float) -> void:
	if not _active or target == null or target.is_defeated:
		return
	fight_seconds += delta
	_body_tokens = minf(BODY_BURST, _body_tokens + health.max_health * BODY_DPS_RATIO * delta)
	if not (_step in [&"stride", &"jump_air", &"laser_sweep"]):
		_face_target()
	_place_weak_points()
	if not escorts_called and fight_seconds >= ESCORT_FALLBACK and health.current_health > 0:
		_call_escorts()
	_left -= delta
	attack_left = maxf(_left, 0.0)
	match _step:
		&"enter":
			if not BeeShmupFairness.is_inside_screen(self, ENTRY_INSET):
				var inward := signf(_cam_x() - global_position.x)
				global_position.x += inward * walk_speed * delta
				visual_root.rotation.y = inward * deg_to_rad(60.0)
				_play(&"Walk")
			else:
				_rest(FIRST_REST)
		&"rest":
			attack_kind = &"none"
			_play(&"Idle")
			if _left <= 0.0:
				_next_attack()
		&"stride":
			var step := minf(STRIDE_SPEED * delta, absf(_walk_goal - global_position.x))
			var dir := signf(_walk_goal - global_position.x)
			global_position.x += dir * step
			distance_walked += step
			if dir != 0.0:
				_facing_x = dir
				visual_root.rotation.y = dir * deg_to_rad(60.0)
			_play(&"Walk")
			if _left <= 0.0 or step <= 0.001:
				stride_span = maxf(stride_span, absf(global_position.x - _stride_from))
				_rest(REST_NO_CANNON if not cannon_alive else REST)
		&"cannon_tele":
			var progress := 1.0 - clampf(_left / CANNON_TELEGRAPH, 0.0, 1.0)
			aim_charge.scale = Vector3.ONE * lerpf(0.7, 1.7, progress)
			_locked_dir = _aim_direction()
			_place_aim_line(progress)
			if _left <= 0.0:
				aim_charge.hide()
				_free_line(&"aim")
				hazards.append({"kind": &"cannon", "telegraph": CANNON_TELEGRAPH})
				_step = &"cannon_fire"
				_shots_left = CANNON_SHOTS
				_left = 0.0
				_play(&"Shoot")
		&"cannon_fire":
			if _left <= 0.0 and _shots_left > 0:
				if cannon_alive:
					_fire_projectile(_locked_dir) # The line was locked at the end of the warning: moving off it dodges.
					cannon_shots += 1
				_shots_left -= 1
				_left = CANNON_GAP
			elif _shots_left <= 0 and _left <= 0.0:
				_rest(REST)
		&"mortar_tele":
			aim_charge.scale = Vector3.ONE * lerpf(0.7, 1.4, 1.0 - clampf(_left / MORTAR_WARNING, 0.0, 1.0))
			if _left <= 0.0 + MORTAR_FALL:
				aim_charge.hide()
				_drop_mortars()
				_rest(REST + MORTAR_FALL)
		&"stomp_tele":
			visual_root.position.y = 0.35 * sin(clampf(1.0 - _left / STOMP_TELEGRAPH, 0.0, 1.0) * PI * 0.5) # Rears up.
			if _left <= 0.0:
				visual_root.position.y = 0.0
				_free_line(&"stomp")
				_stamp(STOMP_TELEGRAPH, true)
				_rest(REST)
		&"laser_tele":
			if _left <= 0.0:
				_clear_warnings()
				hazards.append({"kind": &"laser", "telegraph": LASER_WARNING})
				lasers += 1
				_step = &"laser_sweep"
				_left = LASER_SWEEP
				_beam_box.set_enabled(true)
				_beam.show()
				BeeAudio.play(get_parent(), &"walker_charge", global_position, 1.6)
		&"laser_sweep":
			var t := clampf(1.0 - _left / LASER_SWEEP, 0.0, 1.0)
			_place_beam(lerpf(laser_angles.x, laser_angles.y, t))
			if _left <= 0.0:
				_beam_box.set_enabled(false)
				_beam.hide()
				_rest(REST)
		&"jump_tele":
			visual_root.position.y = -0.25 * smoothstep(0.0, 1.0, 1.0 - _left / JUMP_TELEGRAPH) # Crouches.
			if _left <= 0.0:
				visual_root.position.y = 0.0
				hazards.append({"kind": &"jump", "telegraph": JUMP_TELEGRAPH})
				jumps += 1
				_jump_from = global_position.x
				_step = &"jump_air"
				_left = JUMP_SECONDS
				_play(&"Idle")
				BeeAudio.play(get_parent(), &"human_step", global_position, 0.8)
		&"jump_air":
			var t := clampf(1.0 - _left / JUMP_SECONDS, 0.0, 1.0)
			global_position.x = lerpf(_jump_from, jump_to_x, t)
			global_position.y = _ground_y + JUMP_APEX * 4.0 * t * (1.0 - t)
			if _left <= 0.0:
				global_position.y = _ground_y
				_clear_warnings()
				_land()
				_rest(REST + 0.2)


func _rest(seconds: float) -> void:
	_step = &"rest"
	_left = seconds


func _next_attack() -> void:
	var pattern: Array = PATTERN if cannon_alive else PATTERN_NO_CANNON
	var kind: StringName = pattern[_attack_index % pattern.size()]
	_attack_index += 1
	attacks_started += 1
	attack_kind = kind
	match kind:
		&"cannon":
			_step = &"cannon_tele"
			_left = CANNON_TELEGRAPH
			aim_charge.position = Vector3(_facing_x * muzzle_forward, muzzle_height, 0.0)
			aim_charge.scale = Vector3.ONE * 0.7
			aim_charge.show()
			_aim_line = BeeAttackVisuals.line(self, _muzzle(), _muzzle() + _aim_direction() * 12.0, 0.08, Color(0.3, 0.95, 1.0, 0.3))
			BeeAudio.play(get_parent(), &"walker_charge", global_position)
		&"mortars":
			_step = &"mortar_tele"
			_left = MORTAR_WARNING + MORTAR_FALL
			aim_charge.position = Vector3(_facing_x * muzzle_forward, muzzle_height, 0.0)
			aim_charge.scale = Vector3.ONE * 0.7
			aim_charge.show()
			_mark_mortars()
			BeeAudio.play(get_parent(), &"walker_charge", global_position, 0.85)
		&"stomp":
			_step = &"stomp_tele"
			_left = STOMP_TELEGRAPH
			var half := _half_width()
			_stomp_band = BeeGroundShockwave.warning_band(get_parent(), _cam_x() - half - 1.0, _cam_x() + half + 1.0, STOMP_HEIGHT)
			_play(&"Idle")
			BeeAudio.play(get_parent(), &"walker_charge", global_position, 0.7)
		&"laser":
			_begin_laser()
		&"jump":
			_begin_jump()
		_:
			# Stride: to the other side of the screen (the side away from where it stands).
			var half := _half_width() - EDGE_INSET
			var other := -signf(global_position.x - _cam_x() + 0.001)
			_walk_goal = _cam_x() + other * half
			_stride_from = global_position.x
			strides += 1
			_step = &"stride"
			_left = STRIDE_MAX_SECONDS


# --- LOTE 15 attacks ----------------------------------------------------------------------------------------------------

## Shadows on Bee's column and its neighbours; the shells fall when the warning is over.
func _mark_mortars() -> void:
	mortar_xs.clear()
	var half := _half_width() - 0.6
	for i in MORTAR_COUNT:
		var offset := 0.0 if i == 0 else MORTAR_SPACING * float((i + 1) / 2) * (1.0 if i % 2 == 1 else -1.0)
		var x := clampf(target.global_position.x + offset, _cam_x() - half, _cam_x() + half)
		mortar_xs.append(x)
		_warnings.append(BeeAttackVisuals.ground_disc(get_parent(), Vector3(x, 0.03, 0.0), 0.7, Color(0.05, 0.03, 0.02, 0.6)))
		_warnings.append(BeeAttackVisuals.line(get_parent(), Vector3(x, BeeLevel01Framing.top_y(), 0.0), Vector3(x, 0.0, 0.0), 0.06, Color(1.0, 0.62, 0.2, 0.3)))


func _drop_mortars() -> void:
	mortars += 1
	hazards.append({"kind": &"mortar", "telegraph": MORTAR_WARNING})
	var top := BeeLevel01Framing.top_y() + 1.0
	for i in mortar_xs.size():
		var shell := AlienMortarShell.new()
		shell.name = "RobotMortar"
		shell.attacker = self
		shell.damage = MORTAR_DAMAGE
		shell.puddle_damage = 4
		shell.puddle_seconds = 0.6
		shell.puddle_radius = 0.7
		shell.flight_time = MORTAR_FALL
		shell.apex = 0.0
		get_parent().add_child(shell)
		var marker: MeshInstance3D = _warnings[i * 2] if i * 2 < _warnings.size() else null
		shell.launch(Vector3(mortar_xs[i], top, 0.0), Vector3(mortar_xs[i], 0.0, 0.0), marker)
	for node in _warnings.slice(0, mortar_xs.size() * 2):
		if node is MeshInstance3D and (node as MeshInstance3D).mesh is BoxMesh:
			node.queue_free() # The columns go; the shadows stay until each shell lands (the shell owns them).
	_warnings.clear()
	BeeCombatVFX.spawn(get_parent(), _muzzle(), &"muzzle", Vector3.UP, 1.4)


## The yellow eye: the sector edges (centred on Bee) first, then the beam sweeps it.
func _begin_laser() -> void:
	_step = &"laser_tele"
	_left = LASER_WARNING
	laser_origin = global_position + Vector3(_facing_x * 0.35, EYE_HEIGHT, 0.0)
	var to_bee := target.global_position - laser_origin
	var centre := atan2(to_bee.y, to_bee.x)
	var half := deg_to_rad(LASER_HALF_ANGLE)
	var down_first := lasers % 2 == 0
	laser_angles = Vector2(centre + half, centre - half) if down_first else Vector2(centre - half, centre + half)
	for angle in [laser_angles.x, laser_angles.y]:
		var tip := laser_origin + Vector3(cos(angle), sin(angle), 0.0) * LASER_LENGTH
		_warnings.append(BeeAttackVisuals.line(get_parent(), laser_origin, tip, 0.05, BeeGameSettings.HOSTILE_CYAN))
	if _beam == null:
		_beam_pivot = Node3D.new()
		_beam_pivot.top_level = true
		add_child(_beam_pivot)
		_beam = BeeAttackVisuals.line(_beam_pivot, Vector3.ZERO, Vector3(LASER_LENGTH, 0.0, 0.0), 0.2, BeeGameSettings.ROBOT_LASER_COLOR)
		_beam.top_level = false
		_beam.position = Vector3(LASER_LENGTH * 0.5, 0.0, 0.0)
		_beam.rotation = Vector3.ZERO
		var shape := BoxShape3D.new()
		shape.size = Vector3(LASER_LENGTH, 0.3, 1.2)
		_beam_box = BeeAttackVisuals.hazard_area(_beam_pivot, self, LASER_DAMAGE, shape)
		_beam_box.position = Vector3(LASER_LENGTH * 0.5, 0.0, 0.0)
	_beam.hide()
	_place_beam(laser_angles.x)
	BeeAudio.play(get_parent(), &"walker_charge", global_position, 1.3)


func _place_beam(angle: float) -> void:
	_beam_pivot.global_position = laser_origin
	_beam_pivot.rotation = Vector3(0.0, 0.0, angle)


## Crouch + landing shadow on Bee's column (or the far side when Bee is right above it), then the leap.
func _begin_jump() -> void:
	_step = &"jump_tele"
	_left = JUMP_TELEGRAPH
	var half := _half_width() - EDGE_INSET
	jump_to_x = clampf(target.global_position.x, _cam_x() - half, _cam_x() + half)
	if absf(jump_to_x - global_position.x) < JUMP_MIN_DISTANCE:
		jump_to_x = _cam_x() - signf(global_position.x - _cam_x() + 0.001) * half
	_warnings.append(BeeAttackVisuals.ground_disc(get_parent(), Vector3(jump_to_x, 0.03, 0.0), 1.3, Color(0.05, 0.03, 0.02, 0.6)))
	var column := BeeAttackVisuals.line(get_parent(), Vector3(jump_to_x, 0.0, 0.0), Vector3(jump_to_x, 2.8, 0.0), 2.2, Color(1.0, 0.3, 0.2, 0.18))
	_warnings.append(column)
	BeeAudio.play(get_parent(), &"walker_charge", global_position, 0.6)


func _land() -> void:
	if _land_box == null:
		var shape := BoxShape3D.new()
		shape.size = Vector3(2.2, 2.8, 1.2)
		_land_box = BeeAttackVisuals.hazard_area(get_parent(), self, JUMP_DAMAGE, shape)
		_land_box.top_level = true
	_land_box.global_position = Vector3(global_position.x, 1.4, 0.0)
	_land_box.set_enabled(true)
	get_tree().create_timer(0.15, false, true).timeout.connect(func():
		if is_instance_valid(_land_box):
			_land_box.set_enabled(false))
	_stamp(JUMP_TELEGRAPH, false)


func _stamp(telegraph: float, count_stomp: bool) -> void:
	if count_stomp:
		stomps += 1
	hazards.append({"kind": &"stomp", "telegraph": telegraph})
	var half := _half_width()
	var cam_x := _cam_x()
	for edge in [cam_x - half - 1.0, cam_x + half + 1.0]:
		BeeGroundShockwave.launch(get_parent(), self, global_position.x, edge, STOMP_DAMAGE, STOMP_SPEED, STOMP_HEIGHT)
	BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0, 0.2, 0.3), &"rock_break", Vector3.UP, 1.6)
	BeeCameraShake.kick(self, 0.05, 0.25)
	BeeAudio.play(get_parent(), &"human_step", global_position, 1.3)


func _muzzle() -> Vector3:
	return global_position + Vector3(_facing_x * muzzle_forward, muzzle_height, 0.0)


func _aim_direction() -> Vector3:
	var d := target.global_position - _muzzle()
	d.z = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3(_facing_x, 0.0, 0.0)


func _place_aim_line(progress: float) -> void:
	if is_instance_valid(_aim_line):
		BeeAttackVisuals.place_line(_aim_line, _muzzle(), _muzzle() + _locked_dir * 12.0)
		_aim_line.scale.y = lerpf(1.0, 2.2, progress)


func _free_line(which: StringName) -> void:
	if which == &"aim" and is_instance_valid(_aim_line):
		_aim_line.queue_free()
		_aim_line = null
	if which == &"stomp" and is_instance_valid(_stomp_band):
		_stomp_band.queue_free()
		_stomp_band = null


func _clear_warnings() -> void:
	for node in _warnings:
		if is_instance_valid(node):
			node.queue_free()
	_warnings.clear()


## The cannon box and the eye follow the facing (the model turns 60 degrees towards Bee).
func _place_weak_points() -> void:
	cannon_hurtbox.position = Vector3(_facing_x * CANNON_CENTRE.x, CANNON_CENTRE.y, 0.0)
	_eye.position = Vector3(_facing_x * 0.05, EYE_HEIGHT, 0.0)


func _break_cannon() -> void:
	if not cannon_alive:
		return
	cannon_alive = false
	cannon_hurtbox.set_deferred("monitorable", false)
	aim_charge.hide()
	_free_line(&"aim")
	if _step in [&"cannon_tele", &"cannon_fire", &"mortar_tele"]:
		_clear_warnings()
		_rest(REST_NO_CANNON)
	for gun: MeshInstance3D in visual_root.find_children("Cylinder", "MeshInstance3D", true, false):
		gun.hide()
	var at := global_position + Vector3(_facing_x * CANNON_CENTRE.x, CANNON_CENTRE.y, 0.3)
	BeeLiberation.explode_tech(get_parent(), at, 1.1)
	BeeCameraShake.kick(self, 0.05, 0.25)
	_attack_index = 0
	cannon_broken.emit()


func _on_health_changed(current: int, maximum: int, change: int) -> void:
	if _bar != null:
		_bar.value = float(current) / float(maxi(maximum, 1)) * 100.0
	if change < 0 and current > 0 and not escorts_called and float(current) <= float(maximum) * ESCORT_RATIO:
		_call_escorts()


func _call_escorts() -> void:
	escorts_called = true
	escorts_requested.emit()


func _stop_attacks() -> void:
	_free_line(&"aim")
	_free_line(&"stomp")
	_clear_warnings()
	if _beam_box != null:
		_beam_box.set_enabled(false)
		_beam.hide()
	visual_root.position.y = 0.0
	if _ground_y != 0.0 or global_position.y != _ground_y:
		global_position.y = _ground_y


## It falls and explodes (technology): chained blasts, then the big one.
func _on_died() -> void:
	if current_state == State.DEAD:
		return
	_stop_attacks()
	cannon_hurtbox.set_deferred("monitorable", false)
	_bar_layer.visible = false
	super._on_died()
	var tween := create_tween()
	for i in 4:
		tween.tween_callback(func():
			if is_instance_valid(self):
				BeeLiberation.explode_tech(get_parent(), global_position + Vector3(randf_range(-0.8, 0.8), randf_range(0.8, 2.6), 0.4), 0.7))
		tween.tween_interval(0.18)
	tween.tween_callback(func():
		if is_instance_valid(self):
			BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0, 1.4, 0.3), &"heavy_death", Vector3.UP, 2.6)
			BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0, 1.0, 0.3), &"bomb", Vector3.UP, 2.4)
			BeeCameraShake.kick(self, 0.1, 0.5)
			visual_root.hide())


func _exit_tree() -> void:
	_free_line(&"aim")
	_free_line(&"stomp")
	_clear_warnings()
	if is_instance_valid(_land_box):
		_land_box.queue_free()


func _build_health_bar() -> void:
	_bar_layer = CanvasLayer.new()
	_bar_layer.name = "MinibossHealthBar"
	_bar_layer.layer = 5
	_bar_layer.visible = false
	add_child(_bar_layer)
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.offset_left = -160.0
	box.offset_right = 160.0
	box.offset_top = 14.0
	_bar_layer.add_child(box)
	var title := Label.new()
	title.text = DISPLAY_NAME
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 5)
	box.add_child(title)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(320, 10)
	_bar.show_percentage = false
	_bar.value = 100.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.25, 0.9, 1.0)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.06, 0.08, 0.1, 0.75)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", back)
	box.add_child(_bar)


func health_bar_visible() -> bool:
	return _bar_layer != null and _bar_layer.visible


## Same rule as the UFO hull and the tarantula: a sustained-DPS budget on the body (the bomb stays outside it).
func limit_hull_damage(amount: int, source: DamageHitbox3D) -> int:
	if source is BeeAlienBomb:
		return amount
	var cost_scale := 1.0 # The eye x2 counts in full: below the budget (Base) it is a real shortcut, Spread is capped either way.
	var permitted := mini(amount, floori(_body_tokens / cost_scale))
	_body_tokens -= float(permitted) * cost_scale
	return maxi(permitted, 0)
