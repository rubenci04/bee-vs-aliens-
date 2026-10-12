class_name WalkerMiniboss
extends GroundWalkerEnemy
## LOTE 12 · ETAPA 3 — the walking robot as the Level 1 MINI-BOSS (gate after checkpoint 2, with insect escorts in two waves).
## Same scene, model and animations as the GroundWalkerEnemy; its own short fight:
##   CANNON   the dorsal cannon charges (cyan sphere + aim line, CANNON_TELEGRAPH s), locks the line on Bee and fires a burst of
##            CANNON_SHOTS along it. Weak point: the cannon has its own HP; breaking it ends this attack for good.
##   STOMP    it rears up (warning band on the ground, STOMP_TELEGRAPH s) and stamps: a wave runs along the ground to both
##            screen edges (BeeGroundShockwave, not a projectile: the roll never destroys it). Fly above it.
##   EYE      the yellow eye is a weak point inside the body hurtbox: a shot whose line passes within EYE_RADIUS does EYE_MULTIPLIER.
## At ESCORT_RATIO of its HP (or after ESCORT_FALLBACK s) it calls the second escort wave (the director spawns it).
## It explodes when it falls (technology, never freed). Target: 25-40 s with Base (tests/levels/validate_bee_walker_miniboss_v01.gd).

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
const MIN_TELEGRAPH := 0.42
## Pattern while the cannon lives / after it broke (the robot then stamps more often).
const PATTERN := [&"cannon", &"stomp", &"walk", &"cannon", &"cannon", &"stomp", &"walk"]
const PATTERN_NO_CANNON := [&"stomp", &"walk", &"stomp"]
const REST := 0.9
const REST_NO_CANNON := 0.7
const WALK_SECONDS := 1.1
const CANNON_HP := 70
const CANNON_BOX := Vector3(2.4, 0.6, 1.0)
const CANNON_CENTRE := Vector2(0.9, 2.72) # (forward, height) of the cannon box, mirrored with the facing.
const EYE_HEIGHT := 1.35
const EYE_RADIUS := 0.42
const EYE_MULTIPLIER := 2.0
const ESCORT_RATIO := 0.6
const ESCORT_FALLBACK := 14.0
## Sustained damage budget on the body (fraction of max HP per second, reserve): Spread cannot melt it.
const BODY_DPS_RATIO := 0.039
const BODY_BURST := 30.0
## It stays on the right part of the screen (camera-relative X), the left is Bee's room.
const HOME_MIN := 0.8
const HOME_MAX := 3.8
const ENTRY_INSET := 2.6
const HEALTH_SCENE := preload("res://scenes/components/health_component.tscn")
const HURTBOX_SCENE := preload("res://scenes/components/hurtbox_3d.tscn")

var hazards: Array[Dictionary] = [] # {"kind", "telegraph"} per damaging attack (tests).
var fight_seconds := 0.0
var cannon_alive := true
var cannon_health: HealthComponent
var cannon_hurtbox: DamageHurtbox3D
var cannon_shots := 0
var stomps := 0
var escorts_called := false
var _step := &"enter"
var _left := 0.0
var _attack_index := 0
var _locked_dir := Vector3.LEFT
var _shots_left := 0
var _aim_line: MeshInstance3D
var _stomp_band: MeshInstance3D
var _eye: Node3D
var _walk_goal := 0.0
var _bar_layer: CanvasLayer
var _bar: ProgressBar
var _body_tokens := BODY_BURST


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
	cannon_hurtbox.set_deferred("monitorable", true)
	_bar_layer.visible = true
	_place_weak_points()
	return true


## Auto-aim (and its marker) goes to the body at eye height, not to the cannon on top: the cannon is a deliberate mouse shot.
func auto_aim_point() -> Vector3:
	return global_position + Vector3(_facing_x * 0.05, EYE_HEIGHT - 0.1, 0.0)


func is_miniboss() -> bool:
	return true


func _physics_process(delta: float) -> void:
	if not _active or target == null or target.is_defeated:
		return
	fight_seconds += delta
	_body_tokens = minf(BODY_BURST, _body_tokens + health.max_health * BODY_DPS_RATIO * delta)
	_face_target()
	_place_weak_points()
	if not escorts_called and fight_seconds >= ESCORT_FALLBACK and health.current_health > 0:
		_call_escorts()
	_left -= delta
	match _step:
		&"enter":
			var camera := get_viewport().get_camera_3d()
			if camera != null and not BeeShmupFairness.is_inside_screen(self, ENTRY_INSET):
				var inward := signf(camera.global_position.x - global_position.x)
				global_position.x += inward * walk_speed * delta
				visual_root.rotation.y = inward * deg_to_rad(60.0)
				_play(&"Walk")
			else:
				_rest(0.6)
		&"rest":
			_play(&"Idle")
			if _left <= 0.0:
				_next_attack()
		&"walk":
			var step := minf(walk_speed * delta, absf(_walk_goal - global_position.x))
			global_position.x += signf(_walk_goal - global_position.x) * step
			distance_walked += step
			_play(&"Walk")
			if _left <= 0.0 or step <= 0.001:
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
		&"stomp_tele":
			visual_root.position.y = 0.35 * sin(clampf(1.0 - _left / STOMP_TELEGRAPH, 0.0, 1.0) * PI * 0.5) # Rears up.
			if _left <= 0.0:
				visual_root.position.y = 0.0
				_free_line(&"stomp")
				_stamp()
				_rest(REST)


func _rest(seconds: float) -> void:
	_step = &"rest"
	_left = seconds


func _next_attack() -> void:
	var pattern: Array = PATTERN if cannon_alive else PATTERN_NO_CANNON
	var kind: StringName = pattern[_attack_index % pattern.size()]
	_attack_index += 1
	attacks_started += 1
	match kind:
		&"cannon":
			_step = &"cannon_tele"
			_left = CANNON_TELEGRAPH
			aim_charge.position = Vector3(_facing_x * muzzle_forward, muzzle_height, 0.0)
			aim_charge.scale = Vector3.ONE * 0.7
			aim_charge.show()
			_aim_line = BeeAttackVisuals.line(self, _muzzle(), _muzzle() + _aim_direction() * 12.0, 0.08, Color(0.3, 0.95, 1.0, 0.3))
			BeeAudio.play(get_parent(), &"walker_charge", global_position)
		&"stomp":
			_step = &"stomp_tele"
			_left = STOMP_TELEGRAPH
			var camera := get_viewport().get_camera_3d()
			var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))
			var cam_x := camera.global_position.x if camera != null else global_position.x
			_stomp_band = BeeGroundShockwave.warning_band(get_parent(), cam_x - half - 1.0, cam_x + half + 1.0, STOMP_HEIGHT)
			_play(&"Idle")
			BeeAudio.play(get_parent(), &"walker_charge", global_position, 0.7)
		_:
			var camera := get_viewport().get_camera_3d()
			var cam_x := camera.global_position.x if camera != null else global_position.x
			_walk_goal = cam_x + clampf(global_position.x - cam_x + (1.5 if _attack_index % 2 == 0 else -1.5), HOME_MIN, HOME_MAX) # Alternating steps (reproducible).
			_step = &"walk"
			_left = WALK_SECONDS


func _stamp() -> void:
	stomps += 1
	hazards.append({"kind": &"stomp", "telegraph": STOMP_TELEGRAPH})
	var camera := get_viewport().get_camera_3d()
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(get_viewport()))
	var cam_x := camera.global_position.x if camera != null else global_position.x
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
	if _step == &"cannon_tele" or _step == &"cannon_fire":
		_rest(REST_NO_CANNON)
	for gun: MeshInstance3D in visual_root.find_children("Cylinder", "MeshInstance3D", true, false):
		gun.hide()
	var at := global_position + Vector3(_facing_x * CANNON_CENTRE.x, CANNON_CENTRE.y, 0.3)
	BeeLiberation.explode_tech(get_parent(), at, 1.1)
	BeeCameraShake.kick(self, 0.05, 0.25)
	cannon_broken.emit()


func _on_health_changed(current: int, maximum: int, change: int) -> void:
	if _bar != null:
		_bar.value = float(current) / float(maxi(maximum, 1)) * 100.0
	if change < 0 and current > 0 and not escorts_called and float(current) <= float(maximum) * ESCORT_RATIO:
		_call_escorts()


func _call_escorts() -> void:
	escorts_called = true
	escorts_requested.emit()


## It falls and explodes (technology): chained blasts, then the big one.
func _on_died() -> void:
	if current_state == State.DEAD:
		return
	_free_line(&"aim")
	_free_line(&"stomp")
	visual_root.position.y = 0.0
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
