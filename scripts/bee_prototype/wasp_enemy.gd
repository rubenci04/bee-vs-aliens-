class_name WaspEnemy
extends CharacterBody3D
const COMMON_CUE := preload("res://scripts/vfx/bee_common_attack_cue.gd")

signal defeated(enemy: WaspEnemy)
## NOCHE 01: a Level 01 (implanted) Wasp is FREED, not killed: emitted when the implant breaks (it then flies off).
signal liberated_now(enemy: WaspEnemy)
const LEAVE_SECONDS := 3.0

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVERY, DEAD, STALK, DASH, EXIT, STING, OVERLOAD, KAMIKAZE }

@export var starts_active := false
@export var move_speed := 5.0
@export var acceleration := 20.0
@export var detection_range := 18.0
@export var melee_range := 1.0
@export var attack_damage := 10
@export var windup_time := 0.30
@export var active_time := 0.12
@export var recovery_time := 0.60

@export_category("Arcade mode (Level 01 only; off keeps the original chase)")
## ENTER -> STALK (hover in front of Bee) -> WINDUP (telegraph, direction locked) -> DASH (a pass, no homing)
## -> RECOVERY (backs off) -> second pass -> EXIT (flies past).
@export var arcade_mode := false
@export var stalk_distance := 4.5
@export var stalk_time := 2.2
@export var restalk_time := 0.9
@export var follow_speed := 2.6
@export var drift_amplitude := 0.45
@export var dash_windup := 0.55
@export var dash_speed := 10.5
@export var max_passes := 2
@export var exit_speed := 6.5
@export var arcade_recovery := 1.1 # Visible back-off after each pass (the original recovery_time is for the plain chase).
@export var stalk_lane := 0.0 # Vertical offset of the stalk so two Wasps hover on different lines.

@export_category("Threat rebuild 03 (Level 01 only; off by default)")
## IMPLANT STING: once per stalk the alien implant on its back charges (cyan) and fires `sting_shots` light aimed bolts.
@export var sting_shots := 0
@export var sting_windup := 0.45
@export var sting_gap := 0.16
@export var sting_speed := 6.2
@export var sting_damage := 6
## COMBAT VARIETY 01 (Level 01 only; 0 = the original aimed bolts): the sting is ONE short fan of `sting_fan_count`
## bolts, `STING_FAN_STEP` degrees apart, centred on Bee. Same cyan implant charge (`sting_windup`) as the telegraph.
@export var sting_fan_count := 0
const STING_FAN_STEP := 13.0
## OVERLOAD: at `overload_ratio` HP the implant overloads (red/orange, flashing faster, sparks): telegraph, the line
## locks `overload_lock` s before the end, then a straight kamikaze dash (no homing) that explodes at the end of its
## line. Destroying it during the telegraph cancels the threat (a harmless controlled blast).
@export var overload_enabled := false
@export var overload_ratio := 0.35
@export var overload_telegraph := 0.85
@export var overload_lock := 0.3
@export var overload_speed := 12.5
@export var overload_damage := 18
@export var overload_radius := 1.5
## T6e (Tanda C): Level 01 splits the wasps in two kinds. `kamikaze` rams in a locked straight pass after a 0.5 s warning (no needles);
## `shooter` stalks and fires a 3-bolt burst (0.5 s warning), repeating, and never dashes. Empty = the original behaviour (POCs, tests).
@export var variant: StringName = &""
const SHOOTER_FIRST_STALK := 0.6
const IMPLANT_OFFSET := Vector3(0.0, 0.34, -0.12) ## On the thorax, in VisualRoot space (follows the facing).
const STING_PROJECTILE := preload("res://scenes/bee_prototype/alien_enemy_projectile.tscn")

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var attack_hitbox: DamageHitbox3D = $AttackHitbox
@onready var visual_root: Node3D = $VisualRoot
@onready var telegraph: MeshInstance3D = $AttackTelegraph

var target: BeePlayer
var current_state := State.IDLE
var facing_x := -1.0
var attack_count := 0
var _active := false
var _state_left := 0.0
var passes_done := 0
var _clock := 0.0
var _stalk_cap := 0.0
var _dash_dir := Vector3.LEFT
var _dash_length := 6.0
var implant: WaspImplant
var liberated := false
var sting_count := 0
var overload_count := 0
var exploded := false
var overload_canceled := false
var explosion_hit_bee := false
var _sting_done := false
var _sting_fired := 0
var _stalk_resume := 0.0
var _overloaded := false
var _kamikaze_left := 0.0
var _kamikaze_dir := Vector3.LEFT
var _overload_line: MeshInstance3D


func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	attack_hitbox.hit_confirmed.connect(_on_attack_hit)
	attack_hitbox.damage = attack_damage
	attack_hitbox.set_enabled(false)
	telegraph.hide()
	_set_inactive()
	if starts_active:
		activate(get_tree().get_first_node_in_group("bee_player") as BeePlayer)


func activate(new_target: BeePlayer) -> bool:
	if _active or current_state == State.DEAD or new_target == null:
		return false
	target = new_target
	_active = true
	current_state = State.IDLE
	if arcade_mode and implant == null:
		# Level 01 Wasps are alien-controlled: the implant on the back is where sting and overload come from.
		implant = WaspImplant.new()
		implant.name = "Implant"
		implant.position = IMPLANT_OFFSET
		visual_root.add_child(implant)
		# LOTE 9: the whole Wasp damages the implant (1x); a shot lined up on the implant does 2x.
		hurtbox.weak_point = implant
		hurtbox.weak_point_radius = BeeLiberation.WEAK_POINT_RADIUS
		hurtbox.weak_point_multiplier = BeeLiberation.IMPLANT_MULTIPLIER
	show()
	hurtbox.set_deferred("monitorable", true)
	set_physics_process(true)
	return true


## LOTE 13: true while a warning shows (the sting charge, the dash windup, the overload): tests measure the time to the first one.
func is_telegraphing() -> bool:
	return current_state in [State.WINDUP, State.STING, State.OVERLOAD]


## The line of the dash the windup warns: [from, to, half_width] (tests and bots read it like the warning on screen).
func warned_line() -> Array:
	if current_state != State.WINDUP:
		return []
	return [global_position, global_position + _dash_dir * _dash_length, 0.9]


func is_active() -> bool:
	return _active and current_state != State.DEAD


func is_defeated() -> bool:
	return current_state == State.DEAD


func _set_inactive() -> void:
	_active = false
	target = null
	hide()
	hurtbox.set_deferred("monitorable", false)
	attack_hitbox.set_enabled(false)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not _active or target == null:
		return
	_clock += delta
	if current_state != State.DASH:
		_update_facing()
	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			if _distance_to_target() <= detection_range:
				if arcade_mode:
					_begin_stalk(stalk_time)
				else:
					current_state = State.CHASE
		State.CHASE:
			if _distance_to_target() <= melee_range:
				_begin_windup()
			else:
				var direction := (target.global_position - global_position).normalized()
				velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
				velocity.y = move_toward(velocity.y, direction.y * move_speed, acceleration * delta)
		State.WINDUP:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_dash() if arcade_mode else _begin_attack()
		State.ATTACK:
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_recovery()
		State.RECOVERY:
			var drift := Vector3(-facing_x * 1.2, 0, 0)
			if arcade_mode:
				drift = Vector3(-_dash_dir.x * 3.2, -_dash_dir.y * 1.5, 0.0) # Backs away along the pass, never stays on top of Bee.
			velocity = velocity.move_toward(drift, acceleration * delta)
			_state_left -= delta
			if _state_left <= 0.0:
				_finish_recovery()
		State.STALK:
			_stalk(delta)
		State.DASH:
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_recovery()
		State.EXIT:
			velocity.x = move_toward(velocity.x, -exit_speed, acceleration * delta)
			velocity.y = move_toward(velocity.y, 0.0, acceleration * delta)
		State.STING:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			_state_left -= delta
			if _state_left <= 0.0:
				if sting_fan_count > 0:
					_fire_sting_fan()
					_sting_fired = sting_shots
				else:
					_fire_sting()
					_sting_fired += 1
				_state_left = sting_gap
				if _sting_fired >= sting_shots:
					if implant != null:
						implant.set_mode(&"idle")
					BeeCommonSlots.release(self)
					current_state = State.STALK
					_state_left = _stalk_resume
		State.OVERLOAD:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			visual_root.position = Vector3(randf_range(-0.04, 0.04), randf_range(-0.04, 0.04), 0.0) # Shaking.
			_state_left -= delta
			if _state_left <= overload_lock and _overload_line == null:
				_lock_overload_line()
			if _state_left <= 0.0:
				if BeeAttackTokens.try_claim(self, 1.2) or _state_left <= -1.0: # Never with another heavy pattern; waits <= 1 s.
					_begin_kamikaze()
		State.KAMIKAZE:
			velocity = _kamikaze_dir * overload_speed
			_kamikaze_left -= delta
			if _kamikaze_left <= 0.0 or not BeeShmupFairness.is_on_screen(self, 1.0):
				if bool(get_meta("level_persistent",false)): _begin_recovery()
				else: _explode(true)
				return
	move_and_slide()
	position.z = 0.0


func _begin_windup() -> void:
	current_state = State.WINDUP
	_state_left = dash_windup if arcade_mode else windup_time
	velocity = Vector3.ZERO
	if arcade_mode:
		# The pass is locked now (no homing): Bee has the whole telegraph to read the line and leave it.
		var to_bee := target.global_position - global_position
		_dash_dir = Vector3(to_bee.x, to_bee.y, 0.0).normalized()
		if _dash_dir == Vector3.ZERO:
			_dash_dir = Vector3.LEFT
		_dash_length = clampf(Vector2(to_bee.x, to_bee.y).length() + 2.5, 5.0, 8.5)
	telegraph.show()
	COMMON_CUE.suppress(telegraph)
	visual_root.scale = Vector3.ONE if COMMON_CUE.enabled else Vector3(0.82, 1.18, 0.82)
	BeeShotWarning.volley(self, &"wasp", visual_root, _state_left)


func _begin_attack() -> void:
	current_state = State.ATTACK
	_state_left = active_time
	telegraph.hide()
	visual_root.scale = Vector3(1.25, 0.82, 0.82)
	attack_hitbox.position.x = facing_x * 0.72
	attack_hitbox.set_enabled(true)
	attack_count += 1


func _begin_recovery() -> void:
	BeeCommonSlots.release(self)
	current_state = State.RECOVERY
	_state_left = arcade_recovery if arcade_mode else recovery_time
	attack_hitbox.set_enabled(false)
	telegraph.hide()
	visual_root.scale = Vector3.ONE


func _distance_to_target() -> float:
	return Vector2(target.global_position.x - global_position.x, target.global_position.y - global_position.y).length()


func _update_facing() -> void:
	var dx := target.global_position.x - global_position.x
	if absf(dx) > 0.08:
		facing_x = signf(dx)
		visual_root.rotation.y = -facing_x * PI * 0.5


func _on_died() -> void:
	if current_state == State.DEAD:
		return
	if current_state == State.OVERLOAD or current_state == State.KAMIKAZE:
		# Shot down mid-overload: the implant blows harmlessly where it is (the reward for prioritising it).
		overload_canceled = not exploded
		if not exploded:
			_blast_visual(false)
	_clear_overload_line()
	BeeAttackTokens.release(self)
	BeeCommonSlots.release(self)
	if implant != null:
		implant.set_mode(&"off")
	current_state = State.DEAD
	_active = false
	velocity = Vector3.ZERO
	attack_hitbox.set_enabled(false)
	telegraph.hide()
	hurtbox.set_deferred("monitorable", false)
	if implant != null:
		_liberate()
		return
	visual_root.hide()
	set_physics_process(false)
	defeated.emit(self)


## NOCHE 01 — the implant is shot out: the Wasp is freed (warm colours, "LIBERADO") and flies off relaxed, harmless.
func _liberate() -> void:
	liberated = true
	add_to_group("bee_liberated")
	set_physics_process(false)
	liberated_now.emit(self)
	BeeLiberation.free_animal(get_parent(), visual_root, implant, implant.global_position)
	preload("res://scripts/vfx/bee_release_animation.gd").start_release(self,visual_root,func():
		visual_root.hide()
		defeated.emit(self))

# --- Arcade mode (Level 01) ----------------------------------------------------------------------

func _begin_stalk(seconds: float) -> void:
	if variant == &"shooter" and sting_count == 0:
		seconds = minf(seconds, SHOOTER_FIRST_STALK) # the first burst comes within ~1 s of arriving
	add_to_group("arcade_wasps")
	_sting_done = false
	current_state = State.STALK
	_state_left = seconds
	_stalk_cap = seconds + 4.0
	visual_root.scale = Vector3.ONE


## Hovers in front of Bee (to her right), following her height slowly with a gentle drift. The timer only
## runs once the Wasp has settled, so it always spends a readable moment on screen; a cap prevents stalling.
func _stalk(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var camera_x := camera.global_position.x if camera != null else target.global_position.x
	var want_x := minf(target.global_position.x + stalk_distance, camera_x + 5.6)
	var want_y := clampf(target.global_position.y + stalk_lane + sin(_clock * TAU / 2.4) * drift_amplitude, 1.2, 6.2)
	var to_x := want_x - global_position.x
	var to_y := want_y - global_position.y
	velocity.x = move_toward(velocity.x, clampf(to_x * 2.0, -move_speed, move_speed), acceleration * delta)
	velocity.y = move_toward(velocity.y, clampf(to_y * 2.0, -follow_speed, follow_speed), acceleration * delta)
	_stalk_cap -= delta
	if absf(to_x) < 2.0:
		_state_left -= delta
		if variant == &"shooter":
			if _state_left <= 0.0 and BeeShmupFairness.is_readable(self) and BeeCommonSlots.try_take(self):
				_begin_sting()
			return
		if sting_shots > 0 and not _sting_done and BeeShmupFairness.is_readable(self):
			_begin_sting()
			return
	if variant == &"shooter":
		return
	if (_state_left <= 0.0 and not _another_wasp_attacking()) or _stalk_cap <= 0.0:
		if variant != &"" and not BeeCommonSlots.try_take(self):
			_state_left = 0.35 # T6e: two common enemies are already attacking.
			_stalk_cap = maxf(_stalk_cap, 0.6)
			return
		_begin_windup()


func _begin_dash() -> void:
	current_state = State.DASH
	_state_left = _dash_length / dash_speed
	telegraph.hide()
	visual_root.scale = Vector3(1.25, 0.82, 0.82)
	facing_x = signf(_dash_dir.x) if absf(_dash_dir.x) > 0.05 else facing_x
	visual_root.rotation.y = -facing_x * PI * 0.5
	attack_hitbox.position.x = facing_x * 0.72
	attack_hitbox.set_enabled(true)
	velocity = _dash_dir * dash_speed
	attack_count += 1
	passes_done += 1


func _finish_recovery() -> void:
	if arcade_mode and (passes_done < max_passes or bool(get_meta("level_persistent",false))):
		_begin_stalk(restalk_time)
	elif arcade_mode:
		current_state = State.EXIT
	else:
		current_state = State.CHASE


## Two Wasps never run the same telegraph or pass together: one stalks while the other attacks.
func _another_wasp_attacking() -> bool:
	for other in get_tree().get_nodes_in_group("arcade_wasps"):
		if other != self and other is WaspEnemy and other.is_active() and other.current_state in [State.WINDUP, State.DASH, State.KAMIKAZE]:
			return true
	return false


# --- Threat rebuild 03: implant sting and overload -----------------------------------------------------------

func _begin_sting() -> void:
	BeeShotWarning.volley(self, &"wasp", visual_root, sting_windup, 1 if sting_fan_count > 0 else sting_shots, sting_gap)
	_sting_done = true
	_sting_fired = 0
	_stalk_resume = stalk_time if variant == &"shooter" else _state_left # COMBAT VARIETY 01 fix: the sting no longer eats the stalk timer (the hover kept its length).
	current_state = State.STING
	_state_left = sting_windup # The implant charges (cyan) before the first bolt.
	if implant != null:
		implant.set_mode(&"sting")


func _fire_sting() -> void:
	if target == null or not BeeShmupFairness.can_fire(self):
		return
	var origin := implant.global_position if implant != null else global_position
	origin.z = 0.0
	var projectile := BeeEnemyPatterns.spawn_styled(get_parent(), STING_PROJECTILE, origin, (target.global_position - origin).normalized(), sting_damage, sting_speed, self, &"stinger") # Re-aims per bolt, then flies straight.
	projectile.scale = Vector3.ONE * 0.75 # A light bolt: smaller than a Probe shot.
	sting_count += 1


func _on_health_changed(current: int, maximum: int, _change: int) -> void:
	if not overload_enabled or _overloaded or current <= 0 or not _active:
		return
	if float(current) / float(maximum) <= overload_ratio and current_state not in [State.DEAD, State.EXIT, State.KAMIKAZE]:
		_begin_overload()


func _begin_overload() -> void:
	_overloaded = true
	overload_count += 1
	attack_hitbox.set_enabled(false)
	telegraph.hide()
	current_state = State.OVERLOAD
	_state_left = overload_telegraph
	visual_root.scale = Vector3.ONE if COMMON_CUE.enabled else Vector3(1.12, 1.12, 1.12)
	if implant != null:
		implant.set_mode(&"overload")
	BeeAudio.play(get_parent(), &"wasp_overload", global_position) # GARDEN IDENTITY 04: an insect tremble from the implant (was ufo_charge x1.7).


## The dash line locks a moment before the dash: aimed at where Bee is heading (a short lead), then fixed.
func _lock_overload_line() -> void:
	var predicted := target.global_position + target.velocity * 0.3
	var to_bee := predicted - global_position
	to_bee.z = 0.0
	_kamikaze_dir = to_bee.normalized() if to_bee.length() > 0.05 else Vector3(facing_x, 0.0, 0.0)
	_kamikaze_left = (to_bee.length() + 3.0) / overload_speed # Passes the point and blows up beyond it.
	_overload_line = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(to_bee.length() + 3.0, 0.07, 0.07)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.3, 0.1, 0.45)
	bar.material = material
	_overload_line.mesh = bar
	BeeAttackVisuals.WARNING_STYLE.dress(_overload_line, Color(1, 0.3, 0.1), 3.0, overload_telegraph)
	_overload_line.top_level = true
	_overload_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_overload_line)
	_overload_line.global_position = global_position + _kamikaze_dir * (bar.size.x * 0.5)
	_overload_line.rotation.z = atan2(_kamikaze_dir.y, _kamikaze_dir.x)
	COMMON_CUE.suppress(_overload_line)
	BeeShotWarning.volley(self, &"wasp", visual_root, overload_telegraph)


func _begin_kamikaze() -> void:
	current_state = State.KAMIKAZE
	_clear_overload_line()
	visual_root.position = Vector3.ZERO
	facing_x = signf(_kamikaze_dir.x) if absf(_kamikaze_dir.x) > 0.05 else facing_x
	visual_root.rotation.y = -facing_x * PI * 0.5
	attack_hitbox.damage = overload_damage
	attack_hitbox.set_enabled(true)
	attack_count += 1


func _on_attack_hit(_hurtbox: DamageHurtbox3D, _damage: int) -> void:
	if current_state == State.KAMIKAZE:
		explosion_hit_bee = true
		_explode(false) # Already hit by the body: the blast adds no second damage.


## End of the kamikaze line (or a direct hit): a clearly visible blast; Bee only takes damage inside the radius.
func _explode(radius_damage: bool) -> void:
	if exploded or current_state == State.DEAD:
		return
	exploded = true
	attack_hitbox.set_enabled(false)
	if radius_damage and target != null and not target.is_defeated and target.hurtbox.monitorable \
			and target.global_position.distance_to(global_position) <= overload_radius:
		explosion_hit_bee = true
		target.take_boss_burst_damage(overload_damage, self)
	_blast_visual(true)
	health.take_damage(health.current_health) # Dies through the normal path (feedback, controller release).


func _blast_visual(live: bool) -> void:
	BeeCombatVFX.spawn(get_parent(), global_position, &"bomb", Vector3.RIGHT, overload_radius if live else overload_radius * 0.7)
	BeeAudio.play(get_parent(), &"bomb", global_position, 1.35)
	BeeCameraShake.kick(self, 0.05 if live else 0.03, 0.18)


func _clear_overload_line() -> void:
	if _overload_line != null and is_instance_valid(_overload_line):
		_overload_line.queue_free()
	_overload_line = null


## COMBAT VARIETY 01: one volley of `sting_fan_count` light bolts in a short fan centred on Bee (fixed straight paths).
func _fire_sting_fan() -> void:
	if target == null or not BeeShmupFairness.can_fire(self):
		return
	var origin := implant.global_position if implant != null else global_position
	origin.z = 0.0
	for direction in BeeEnemyPatterns.fan_directions(target.global_position - origin, sting_fan_count, STING_FAN_STEP):
		var projectile := BeeEnemyPatterns.spawn_styled(get_parent(), STING_PROJECTILE, origin, direction, sting_damage, sting_speed, self, &"stinger") # LOTE 13: the violet needle
		projectile.scale = Vector3.ONE * 0.75
		sting_count += 1
