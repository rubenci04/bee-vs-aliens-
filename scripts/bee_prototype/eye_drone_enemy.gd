class_name EyeDroneEnemy
extends AlienProbeRanged

## Air-light pursuer. Reuses Bee's health, hurtbox, hit flash, and straight projectile.
## Base State.IDLE is the brief entry; State.POSITION is this unit's chase.
## ARCADE COMBAT PATTERN PASS 02 (Level 01 only; `fan_every` = 0 keeps the original single/burst fire):
##   PATTERN A  aimed burst (cyan telegraph, re-aims every shot);
##   PATTERN B  fan of `fan_count` shots centred on Bee (violet telegraph, longer warning).
## They alternate; the first attack is always aimed. A fan is only used when Bee is far enough for its
## lanes to be passable (`fan_min_distance`), otherwise the drone fires an aimed burst instead.

@export var shot_damage := 6
@export var enter_time := 0.22
@export var fan_every := 0
@export var fan_count := 5
@export var fan_min_distance := 3.0
@export var fan_windup := 0.6

## COMBAT VARIETY 01 (Level 01 only; 0 = off): every `laser_every`-th attack is a THIN LASER that sweeps vertically.
##   CHARGE (LASER_CHARGE s): a thin warning line shows where the sweep starts and a fainter one where it ends,
##   the eye glows; then the beam sweeps from above Bee's height to below it (angle locked at the start of the charge)
##   in LASER_SWEEP s. One hit per sweep. Dodge: leave the arc (change height by ~2 m or step out of its reach).
@export var laser_every := 0
const LASER_CHARGE := 0.7
const LASER_SWEEP := 0.75
const LASER_HALF_ARC := 20.0 # degrees above and below the locked aim
const LASER_LENGTH := 9.0
const LASER_WIDTH := 0.1
const LASER_DAMAGE := 10
const LASER_COLOR := Color(0.25, 1.0, 1.0, 0.95)
const LASER_WARNING := Color(1.0, 0.3, 0.3, 0.6)

const FAN_TELEGRAPH_COLOR := Color(0.72, 0.3, 1.0, 0.55)
static var _fan_material: StandardMaterial3D

var fan_shot_count := 0 # Fans fired (for tests and tuning).
var _attack_index := 0
var _fan_now := false
var laser_count := 0 # Sweeps fired (tests and tuning).
var _laser_now := false
var _lasering := false
var _laser_t := 0.0
var _laser_from := 0.0
var _laser_to := 0.0
var _laser_pivot: Node3D
var _laser_box: DamageHitbox3D
var _laser_beam: MeshInstance3D
var _laser_warnings: Array[MeshInstance3D] = []

func activate(new_target: BeePlayer) -> bool:
	if not super.activate(new_target):
		return false
	current_state = State.IDLE
	_state_left = enter_time
	return true

func _physics_process(delta: float) -> void:
	if not _active or target == null or target.is_defeated:
		velocity = Vector3.ZERO
		return
	_update_facing()
	if _lasering:
		velocity = Vector3.ZERO
		_update_laser(delta)
		return
	match current_state:
		State.IDLE:
			velocity = Vector3(-move_speed * 0.45, 0.0, 0.0)
			_state_left -= delta
			if _state_left <= 0.0:
				current_state = State.POSITION
		State.POSITION:
			_chase(delta)
		State.WINDUP:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			_state_left -= delta
			if _state_left <= 0.0:
				_shoot_at_bee()
		State.SHOOT:
			if _burst_left > 0:
				_state_left -= delta
				if _state_left <= 0.0:
					_burst_left -= 1
					_state_left = burst_gap
					_fire_drone_shot()
			else:
				current_state = State.COOLDOWN
				_state_left = cooldown_time
		State.COOLDOWN:
			var away := (global_position - target.global_position).normalized()
			velocity = velocity.move_toward(Vector3(away.x, away.y, 0.0) * move_speed * 0.35, acceleration * delta)
			_state_left -= delta
			if _state_left <= 0.0:
				current_state = State.POSITION
	move_and_slide()
	position.z = 0.0

func _chase(delta: float) -> void:
	var to_bee := target.global_position - global_position
	var distance := Vector2(to_bee.x, to_bee.y).length()
	var direction := Vector2.ZERO
	var back_in := _back_on_screen_direction()
	if back_in != 0.0:
		direction = Vector2(back_in, 0.0) # REBUILD 02 (Level 01): never attack from outside the screen.
	elif distance > maximum_range:
		direction = Vector2(to_bee.x, to_bee.y).normalized()
	elif distance < minimum_range:
		direction = -Vector2(to_bee.x, to_bee.y).normalized()
	else:
		_begin_attack(distance)
		return
	velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
	velocity.y = move_toward(velocity.y, direction.y * move_speed, acceleration * delta)

func _begin_attack(distance: float) -> void:
	_laser_now = laser_every > 0 and _attack_index % laser_every == laser_every - 1 and BeeShmupFairness.is_readable(self) \
			and BeeAttackTokens.try_claim(self, LASER_CHARGE + LASER_SWEEP + 0.3)
	if _laser_now:
		_begin_laser_charge()
		return
	_fan_now = fan_every > 0 and _attack_index % fan_every == fan_every - 1 and distance >= fan_min_distance \
			and BeeAttackTokens.try_claim(self, fan_windup + 0.4) # REBUILD 03: never with another heavy pattern.
	current_state = State.WINDUP
	_state_left = (fan_windup if _fan_now else windup_time) + (initial_delay if _attack_index == 0 else 0.0)
	velocity = Vector3.ZERO
	telegraph.material_override = _fan_telegraph_material() if _fan_now else null
	telegraph.show()
	COMMON_CUE.suppress(telegraph)
	BeeShotWarning.volley(self, &"machine", visual_root, _state_left)
	visual_root.scale = Vector3.ONE if COMMON_CUE.enabled else Vector3(1.10, 0.90, 1.10)

static func _fan_telegraph_material() -> StandardMaterial3D:
	if _fan_material == null:
		_fan_material = StandardMaterial3D.new()
		_fan_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_fan_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_fan_material.albedo_color = FAN_TELEGRAPH_COLOR
	return _fan_material

func _shoot_at_bee() -> void:
	if _laser_now:
		_start_laser_sweep()
		return
	current_state = State.SHOOT
	telegraph.hide()
	telegraph.material_override = null
	visual_root.scale = Vector3.ONE
	_attack_index += 1
	if _fan_now:
		_burst_left = 0
		_fire_fan()
		return
	_burst_left = burst_shots - 1
	_state_left = burst_gap
	_fire_drone_shot()


func _fire_drone_shot() -> void:
	if not BeeShmupFairness.can_fire(self):
		suppressed_shot_count += 1
		return
	var projectile := projectile_scene.instantiate() as AlienEnemyProjectile
	projectile.damage = shot_damage
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.launch((target.global_position - global_position).normalized(), self)
	projectile_fire_count += 1
	projectile_fired.emit(projectile)


## One volley: `fan_count` shots centred on Bee at the moment of firing, each on a fixed straight path.
func _fire_fan() -> void:
	if not BeeShmupFairness.can_fire(self):
		suppressed_shot_count += 1
		return
	var to_bee := target.global_position - global_position
	var distance := Vector2(to_bee.x, to_bee.y).length()
	var step := BeeEnemyPatterns.fan_step_degrees(distance)
	for direction in BeeEnemyPatterns.fan_directions(to_bee, fan_count, step):
		var projectile := BeeEnemyPatterns.spawn_shot(get_parent(), projectile_scene, global_position, direction, shot_damage, 0.0, self)
		projectile_fire_count += 1
		projectile_fired.emit(projectile)
	fan_shot_count += 1

func _update_facing() -> void:
	var horizontal := target.global_position.x - global_position.x
	if absf(horizontal) > 0.2:
		visual_root.rotation.y = -signf(horizontal) * PI * 0.5


# --- COMBAT VARIETY 01: vertical laser sweep -------------------------------------------------------------------

func _begin_laser_charge() -> void:
	current_state = State.WINDUP
	_state_left = LASER_CHARGE
	velocity = Vector3.ZERO
	var to_bee := target.global_position - global_position
	var aim := atan2(to_bee.y, to_bee.x)
	# Sweep from the side of Bee farther from the ground to the other one: from above when Bee is low and vice versa.
	var from_above := target.global_position.y < 4.0
	var half := deg_to_rad(LASER_HALF_ARC)
	_laser_from = aim + (half if from_above == (to_bee.x < 0.0) else -half)
	_laser_to = aim - (_laser_from - aim)
	_clear_laser()
	var origin := Vector3(global_position.x, global_position.y, 0.0)
	_laser_warnings.append(BeeAttackVisuals.line(get_parent(), origin, origin + Vector3(cos(_laser_from), sin(_laser_from), 0) * LASER_LENGTH, 0.05, LASER_WARNING))
	_laser_warnings.append(BeeAttackVisuals.line(get_parent(), origin, origin + Vector3(cos(_laser_to), sin(_laser_to), 0) * LASER_LENGTH, 0.025, Color(LASER_WARNING, 0.3)))
	for line in _laser_warnings:
		BeeAttackVisuals.WARNING_STYLE.dress(line, LASER_WARNING, 1.0, LASER_CHARGE)
		COMMON_CUE.suppress(line)
	telegraph.material_override = null
	telegraph.show()
	COMMON_CUE.suppress(telegraph)
	BeeShotWarning.volley(self, &"machine", visual_root, _state_left)
	visual_root.scale = Vector3.ONE if COMMON_CUE.enabled else Vector3(1.12, 0.88, 1.12)


func _start_laser_sweep() -> void:
	telegraph.hide()
	visual_root.scale = Vector3.ONE
	_attack_index += 1
	for w in _laser_warnings:
		if is_instance_valid(w):
			w.queue_free()
	_laser_warnings.clear()
	if not BeeShmupFairness.can_fire(self):
		suppressed_shot_count += 1
		BeeAttackTokens.release(self)
		current_state = State.COOLDOWN
		_state_left = cooldown_time
		return
	_laser_pivot = Node3D.new()
	_laser_pivot.top_level = true
	get_parent().add_child(_laser_pivot)
	_laser_pivot.global_position = Vector3(global_position.x, global_position.y, 0.0)
	var box := BoxShape3D.new()
	box.size = Vector3(LASER_LENGTH, LASER_WIDTH * 1.4, 0.8)
	_laser_box = BeeAttackVisuals.hazard_area(_laser_pivot, self, LASER_DAMAGE, box)
	_laser_box.position.x = LASER_LENGTH * 0.5
	_laser_beam = MeshInstance3D.new()
	var beam := BoxMesh.new()
	beam.size = Vector3(LASER_LENGTH, LASER_WIDTH, 0.06)
	beam.material = BeeAttackVisuals.material(LASER_COLOR)
	_laser_beam.mesh = beam
	_laser_beam.position.x = LASER_LENGTH * 0.5
	_laser_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_laser_pivot.add_child(_laser_beam)
	_laser_pivot.rotation.z = _laser_from
	_laser_box.set_enabled(true)
	_lasering = true
	_laser_t = 0.0
	laser_count += 1
	BeeAudio.play(get_parent(), &"tech_hit", global_position, 1.6)


func _update_laser(delta: float) -> void:
	_laser_t += delta
	if _laser_pivot != null and is_instance_valid(_laser_pivot):
		_laser_pivot.rotation.z = lerp_angle(_laser_from, _laser_to, clampf(_laser_t / LASER_SWEEP, 0.0, 1.0))
	if _laser_t >= LASER_SWEEP:
		_lasering = false
		_clear_laser()
		BeeAttackTokens.release(self)
		current_state = State.COOLDOWN
		_state_left = cooldown_time


func laser_active() -> bool:
	return _lasering


func _clear_laser() -> void:
	if _laser_pivot != null and is_instance_valid(_laser_pivot):
		_laser_pivot.queue_free()
	_laser_pivot = null
	_laser_box = null
	for w in _laser_warnings:
		if is_instance_valid(w):
			w.queue_free()
	_laser_warnings.clear()


func _on_died() -> void:
	_lasering = false
	_clear_laser()
	super._on_died()


func _exit_tree() -> void:
	_clear_laser()
