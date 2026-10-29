class_name BeePlayer
extends CharacterBody3D
const SHOOTING := preload("res://scripts/game/bee_shooting_settings.gd")
const STING := preload("res://scripts/game/bee_sting_settings.gd")
const AIM_HELP := preload("res://scripts/bee_prototype/bee_aim_assist.gd")
const MOTION := preload("res://scripts/game/bee_motion_settings.gd")

signal health_changed(current: int, maximum: int)
signal auto_aim_changed(target: Node3D)
signal melee_started
signal defeated
signal weapon_state_changed
signal powerup_collected(kind: StringName)
signal roll_started
signal honey_changed
signal pollen_double_changed

@export_category("Flight")
@export var horizontal_speed := 7.0
@export var vertical_speed := 6.0
@export var acceleration := 32.0
@export var deceleration := 40.0
@export var flight_min := Vector2(-10.0, 0.7)
@export var flight_max := Vector2(10.0, 7.2)

@export_category("Ranged combat")
@export var projectile_scene: PackedScene
@export var auto_aim_range := 12.0
@export_range(1.0, 179.0, 1.0) var auto_aim_cone_degrees := 80.0
@export var muzzle_offset := Vector3(0.48, 0.0, 0.0)
## LOTE 7 — FREE AIM: the mouse (or set_aim_point) aims in any direction of the X/Y plane. Without aiming input for
## AIM_HOLD_SECONDS the weapon goes back to the usual auto-aim. Left click fires too (X still fires).
@export var mouse_aim_enabled := true
const AIM_HOLD_SECONDS := BeeGameSettings.MOUSE_AIM_IDLE_SEC

@export_category("Temporary powerups")
@export var spread_max_shots := 32 # CHALLENGE & BALANCE PASS 01: 24 -> 32 bursts (still 3 pellets, no stacking).
@export var spread_angle_degrees := 14.0
@export var spread_overcharge_bonus := 16 # ARCADE REBUILD 02: extra bursts from the pre-boss S+ capsule.
@export var spread_damage_ratio := 0.8 # CHALLENGE & BALANCE PASS 01: 0.6 -> 0.8 (6 -> 8 per pellet); vs the UFO at >=5 m Spread was 0.68x Base.
@export var starting_bomb_charges := 0
## LOTE 9: a bomb pickup gives bomb_pickup_charges bombs, up to max_bomb_charges (was +1 up to 3).
@export var max_bomb_charges := 5
@export var bomb_pickup_charges := 3
@export var bomb_radius := 3.0
@export var bomb_damage := 32
const BOMB_SCENE := preload("res://scenes/bee_prototype/bee_alien_bomb.tscn")

@export_category("Roll (LOTE 11)")
@export var roll_duration := 0.35 ## Invulnerable seconds of the Shift roll.
@export var roll_cooldown := BeeGameSettings.PIRUETA_COOLDOWN_SEC
@export var roll_enabled := true

@export_category("Honey mode (LOTE 11)")
@export var honey_seconds := 6.0 ## Double shot while it lasts; filled by pollen (BeeLevel01Juice).
@export var honey_shot_offset := 0.14 ## Half distance between the two parallel shots (m).
@export var honey_twin_damage_ratio := 0.5 ## The second shot does this share of the first one (honey = 1.5x damage, not 2x).

@export_category("Sustained fire (LOTE 14)")
## Tanda 4c: active weapon cadence, speed and damage are exclusively in SHOOTING.WEAPON_MODES.
## Historical burst/ratio exports remain for saved scenes; they no longer tune the primary weapon.
@export var base_shot_damage := 10 ## Damage of a base shot (the projectile scene default) the burst ratios start from.
@export var hold_fire_enabled := true
@export var hold_start_delay := 0.12 ## Seconds held before the first burst.
@export var burst_rate := 2.5 ## Bursts per second (a short pause between bursts).
@export var burst_size := 3 ## Shots per burst without a power-up.
@export var burst_shot_gap := 0.06 ## Seconds between the shots of one burst.
@export var spread_burst_size := 5 ## Pellets per burst with Spread (a fan, 1 Spread charge per burst).
@export var spread_burst_step_degrees := 11.0 ## Angle between neighbouring pellets of the fan.
@export var hold_damage_ratio := 0.4 ## Burst shot damage / base shot: 2.5 bursts/s x 3 x 0.4 = 3 taps/s x 1.0 (DPS parity).
@export var hold_spread_damage_ratio := 0.5 ## Burst pellet damage / spread pellet (fan pellets rarely all hit one target).

@export_category("Sting melee (LOTE 14)")
## 360-degree stinger: hits the NEAREST enemy within MELEE_REACH_FACTOR x BEE_LENGTH (front or back) with a short lunge.
const BEE_LENGTH := 1.3 ## Measured from the model (m).
@export var melee_reach_factor := 1.6
@export var melee_lunge_time := STING.DASH_SECONDS ## Seconds of the lunge towards the target (also the time the hit box is live).
@export var melee_lunge_stop := STING.STOP_DISTANCE ## Distance (m) from the target at which the lunge stops.
@export var melee_damage := 30 ## 3 x a base shot (10).
@export var melee_range := 0.85 ## Forward swing when nothing is in reach.
@export var melee_active_time := 0.2
@export var melee_cooldown := 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
const BOSS_BURST_GUARD := preload("res://scripts/game/bee_boss_burst_guard.gd")
var boss_burst_guard = BOSS_BURST_GUARD.new()
var boss_burst_absorbed_hits := 0
@onready var target_indicator: Node3D = $TargetIndicator
@onready var melee_hitbox: DamageHitbox3D = $MeleeHitbox

var facing_x := 1.0
var current_auto_target: Node3D
var shots_fired := 0
var melee_count := 0
var is_defeated := false
## Legacy property name retained for checkpoint/bot compatibility; value is now SECONDS.
var spread_ammo := 0.0
var bomb_charges := 0
var active_bomb: BeeAlienBomb
var _melee_active_left := 0.0
var is_rolling := false
var roll_count := 0
var roll_absorbed_shots := 0 ## Common enemy shots destroyed by touching Bee during a roll.
var honey_left := 0.0
var pollen_double_left := 0.0
var _roll_left := 0.0
var _roll_cooldown_left := 0.0
var _roll_tween: Tween
var _melee_cooldown_left := 0.0
var _melee_tween: Tween
var melee_target: Node3D ## LOTE 14: the enemy the current sting is going for (null = forward swing).
var melee_lunge_count := 0
var _lunge_left := 0.0
var _lunge_velocity := Vector3.ZERO
var stinger: Node3D ## Compatibility handle, stays null: T4g uses the imported front legs.
var _stinger_flash: Tween # Compatibility handle used by the local hit-stop controller.
var _stinger_trail: CPUParticles3D
var _hold_time := 0.0
var _burst_cooldown := 0.0
var _burst_left := 0
var _burst_gap_left := 0.0
var burst_count := 0 ## Bursts started by holding fire.
var burst_shots := 0 ## Shots fired inside bursts.
var aim_point := Vector3.ZERO # World point under the crosshair (z = 0), valid while is_free_aiming().
var _aim_left := 0.0
var _aim_screen := Vector2.ZERO
var _aim_from_screen := false
## LOTE 15: web trap (the tarantula's net, BeeWebTrap). While locked Bee can shoot but cannot move, roll or lunge; every press of
## a movement key is a struggle (the trap reads `web_struggles`).
var web_locked := false
var web_struggles := 0
var web_roll_presses := 0 ## T7i: rolls attempted while trapped; one frees her from the net
var fire_trigger_count := 0 ## Taps + bursts started.
var _stick_aim := Vector2.RIGHT
var _roll_dash_left := 0.0
var _roll_dash_velocity := Vector3.ZERO
var _turn_left := 0.0
var _turn_tween: Tween
var _mouse_tap_handled := false
var _fire_cooldown := 0.0
var sting_dash: Node
var aim_assist_target: Node3D
var aim_debug_enabled := SHOOTING.AIM_DEBUG_DEFAULT


func _ready() -> void:
	add_to_group("bee_player")
	bomb_charges = clampi(starting_bomb_charges, 0, max_bomb_charges)
	target_indicator.set_as_top_level(true)
	target_indicator.hide()
	melee_hitbox.damage = melee_damage
	melee_hitbox.set_enabled(false)
	melee_hitbox.hit_confirmed.connect(_on_melee_impact)
	_place_melee_hitbox()
	sting_dash = preload("res://scripts/bee_prototype/bee_sting_dash.gd").new()
	sting_dash.bee = self
	add_child(sting_dash)
	var flash := get_node_or_null("HitFlash3D") as HitFlash3D
	if flash != null:
		flash.duration = STING.DAMAGE_FLASH_SECONDS
		flash.set_flash_color(STING.DAMAGE_FLASH_COLOR)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_turn_left = maxf(0.0, _turn_left - delta)
	spread_ammo = maxf(0.0, spread_ammo - delta)
	_update_melee(delta)
	_update_roll(delta)
	_update_honey(delta)
	if pollen_double_left > 0.0:
		pollen_double_left = maxf(0.0, pollen_double_left - delta)
		if pollen_double_left == 0.0:
			pollen_double_changed.emit()
	if is_defeated:
		velocity = Vector3.ZERO
		return
	if sting_dash.active:
		sting_dash.step(delta)
	else:
		var input := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		if web_locked:
			for action in [&"move_left", &"move_right", &"move_back", &"move_forward"]:
				if Input.is_action_just_pressed(action):
					web_struggle()
			input = Vector2.ZERO
			velocity = Vector3.ZERO
			_lunge_left = 0.0
		var desired := Vector2(input.x * horizontal_speed, input.y * vertical_speed)
		if MOTION.enabled:
			var smooth := _flight_velocity_step(Vector2(velocity.x, velocity.y), desired, delta)
			velocity.x = smooth.x
			velocity.y = smooth.y
		else:
			var rate := acceleration if desired.length_squared() > 0.0 else deceleration
			velocity.x = move_toward(velocity.x, desired.x, rate * delta)
			velocity.y = move_toward(velocity.y, desired.y, rate * delta)
		velocity.z = 0.0
		if _lunge_left > 0.0: # LOTE 14: the sting lunge overrides the flight input.
			_lunge_left = maxf(0.0, _lunge_left - delta)
			velocity = _lunge_velocity
		if _roll_dash_left > 0.0:
			_roll_dash_left = maxf(0.0, _roll_dash_left - delta)
			velocity = _roll_dash_velocity
		if absf(input.x) > 0.05 and not is_free_aiming() and _lunge_left <= 0.0:
			_face_towards(input.x * BeeGameSettings.BEE_DEFAULT_AIM_DISTANCE)
		move_and_slide()
		position.x = clampf(position.x, flight_min.x, flight_max.x)
		position.y = clampf(position.y, flight_min.y, flight_max.y)
		position.z = 0.0

	_update_free_aim(delta)
	_update_joypad_aim(delta)
	refresh_auto_aim()
	if not is_free_aiming() and is_instance_valid(current_auto_target):
		_face_towards(_target_point(current_auto_target).x - global_position.x)
	if Input.is_action_just_pressed("throw_orange") and not _mouse_tap_handled:
		_try_input_fire()
	_mouse_tap_handled = false
	_update_sustained_fire(delta)
	if Input.is_action_just_pressed("debug_attack"):
		start_melee()
	if Input.is_action_just_pressed("bee_roll"):
		start_roll()
	if Input.is_action_just_pressed("bee_bomb"):
		if mouse_aim_enabled and is_free_aiming() and not BeeGameSettings.last_input_joypad and not is_instance_valid(active_bomb):
			_aim_at_screen(get_viewport().get_mouse_position())
		use_bomb()


func _flight_velocity_step(current: Vector2, desired: Vector2, delta: float) -> Vector2:
	var response: float = MOTION.ACCEL_RESPONSE_SECONDS if desired.length_squared() > 0.0 else MOTION.BRAKE_RESPONSE_SECONDS
	var weight := 1.0 - exp(-delta / response)
	var result := current.lerp(desired, weight)
	return Vector2(clampf(result.x, -horizontal_speed, horizontal_speed), clampf(result.y, -vertical_speed, vertical_speed))


func refresh_auto_aim() -> Node3D:
	if is_defeated:
		current_auto_target = null
		_update_target_indicator()
		return null
	var best: Node3D
	var best_score := INF
	var forward := Vector2(facing_x, 0.0)
	var half_cone := deg_to_rad(auto_aim_cone_degrees * 0.5)
	for candidate_node in get_tree().get_nodes_in_group("bee_auto_aim_targets"):
		var candidate := candidate_node as Node3D
		if not _is_valid_target(candidate):
			continue
		if SHOOTING.AIM_ASSIST_ENABLED and not AIM_HELP.eligible(self, candidate):
			continue
		var delta := Vector2(candidate.global_position.x - global_position.x, candidate.global_position.y - global_position.y)
		var distance := delta.length()
		if distance <= 0.001 or distance > auto_aim_range:
			continue
		var angle := absf(forward.angle_to(delta.normalized()))
		if angle > half_cone:
			continue
		var score := distance
		if SHOOTING.AIM_ASSIST_ENABLED and AIM_HELP.weak_point(candidate) == null:
			score += auto_aim_range # Vulnerable implant first, then nearest within the existing cone.
		if score < best_score:
			best_score = score
			best = candidate
	if best != current_auto_target:
		current_auto_target = best
		auto_aim_changed.emit(current_auto_target)
	_update_target_indicator()
	return current_auto_target


func fire() -> BeeEnergyProjectile:
	if is_defeated or projectile_scene == null:
		return null
	refresh_auto_aim()
	var direction := aim_direction() # LOTE 7: free aim (mouse) first, then auto-aim, then straight ahead.
	var spread_shot := spread_ammo > 0
	var profile := weapon_profile()
	var damages: Array = profile["damage"]
	var projectile := _spawn_projectile(direction, int(damages[0]))
	var pollen_mains: Array[BeeEnergyProjectile] = [projectile]
	BeeAudio.play(get_parent(), &"spread" if spread_ammo > 0 else &"base")
	var bee_visual := $VisualRoot/BeeVisual as Node3D
	bee_visual.call("play_muzzle_effect", projectile.global_position, direction, spread_shot)
	if spread_ammo > 0:
		projectile.set_spread_visual()
		for i in 2:
			var angle: float = -SHOOTING.SPREAD_ANGLE if i == 0 else SHOOTING.SPREAD_ANGLE
			var side_projectile := _spawn_projectile(direction.rotated(Vector3.BACK, deg_to_rad(angle)), int(damages[i + 1]))
			side_projectile.set_spread_visual()
			pollen_mains.append(side_projectile)
		weapon_state_changed.emit()
	if pollen_double_left > 0.0:
		_spawn_pollen_twins(pollen_mains, spread_shot)
	elif honey_left > 0.0:
		_spawn_honey_twin(projectile, direction, spread_shot) # LOTE 11: honey mode = double shot.
	shots_fired += 1
	fire_trigger_count += 1
	return projectile


func weapon_mode() -> StringName:
	if spread_ammo > 0.0:
		return &"triple_double" if honey_left > 0.0 and pollen_double_left <= 0.0 else &"triple"
	return &"double" if honey_left > 0.0 and pollen_double_left <= 0.0 else &"base"


func weapon_profile() -> Dictionary:
	return SHOOTING.WEAPON_MODES[weapon_mode()]


func _spawn_projectile(direction: Vector3, damage_override := -1) -> BeeEnergyProjectile:
	var projectile := projectile_scene.instantiate() as BeeEnergyProjectile
	projectile.configured_weapon_damage = true
	projectile.speed = float(weapon_profile()["speed"])
	if damage_override >= 0:
		projectile.damage = damage_override
	get_parent().add_child(projectile)
	var visual := $VisualRoot/BeeVisual as Node3D
	if visual != null and visual.get("muzzle") != null:
		projectile.global_position = visual.call("firing_origin", global_position)
	elif is_free_aiming():
		projectile.global_position = global_position + direction.normalized() * absf(muzzle_offset.x) + Vector3(0.0, muzzle_offset.y, 0.0)
	else:
		projectile.global_position = global_position + Vector3(facing_x * absf(muzzle_offset.x), muzzle_offset.y, 0.0)
	projectile.launch(direction, self)
	return projectile


func collect_spread() -> bool:
	if is_defeated:
		return false
	spread_ammo = minf(BeeGameSettings.SPREAD_MAX_DURATION_SEC, spread_ammo + BeeGameSettings.SPREAD_EXTEND_SEC) if spread_ammo > 0.0 else BeeGameSettings.SPREAD_DURATION_SEC
	weapon_state_changed.emit()
	powerup_collected.emit(&"spread")
	return true


## ARCADE REBUILD 02: the pre-boss power capsule. Base -> overcharged Spread (spread_max_shots + bonus); with Spread ->
## refill + extend. Never lowers the current ammo; bounded at twice the normal load.
func collect_spread_overcharge() -> bool:
	return collect_spread()


func collect_bomb() -> bool:
	if is_defeated or bomb_charges >= max_bomb_charges:
		return false
	bomb_charges = mini(bomb_charges + bomb_pickup_charges, max_bomb_charges)
	weapon_state_changed.emit()
	powerup_collected.emit(&"bomb")
	return true


func use_bomb() -> BeeAlienBomb:
	if is_defeated:
		return null
	if is_instance_valid(active_bomb):
		active_bomb.detonate()
		return active_bomb
	if is_defeated or bomb_charges <= 0:
		return null
	var bomb := BOMB_SCENE.instantiate() as BeeAlienBomb
	get_parent().add_child(bomb)
	bomb.global_position = global_position
	active_bomb = bomb
	bomb.activate(self, bomb_radius, bomb_damage)
	bomb_charges -= 1
	weapon_state_changed.emit()
	return bomb


## T4b: move toward the nearest enemy in 360 degrees, hit on arrival, then recoil.
## With no target, dash along aim without damage. No charge or cooldown.
func melee_reach() -> float:
	return STING.REACH


func nearest_melee_target() -> Node3D:
	var best: Node3D
	var best_d := melee_reach()
	for candidate_node in get_tree().get_nodes_in_group("bee_auto_aim_targets"):
		var candidate := candidate_node as Node3D
		if not _is_valid_target(candidate):
			continue
		var d := (_target_point(candidate) - global_position).length()
		if d <= best_d:
			best_d = d
			best = candidate
	return best


func start_melee() -> bool:
	if is_defeated or web_locked: return false
	return sting_dash.begin()

func _update_melee(_delta: float) -> void:
	_melee_cooldown_left = 0 # Always available once the current move finishes; no charge.
	if sting_dash != null and sting_dash.queued_sting and not is_rolling and not sting_dash.active:
		sting_dash.queued_sting = false
		start_melee()
	if sting_dash != null and sting_dash.queued_roll and not sting_dash.active and not is_rolling and _roll_cooldown_left <= 0.0:
		if start_roll(): sting_dash.queued_roll = false

func melee_ready_ratio() -> float:
	return 1.0


func _on_melee_impact(hurt: DamageHurtbox3D, _amount: int) -> void:
	if sting_dash != null and sting_dash.active:
		BeeJuice.key_event(self,&"sting",hurt.owner_entity as Node3D,Vector2(sting_dash.direction.x,sting_dash.direction.y))
	BeeAudio.play(get_parent(), &"melee", hurt.global_position)
	($VisualRoot/BeeVisual as Node3D).call("sting_impact_effect", melee_hitbox.global_position)


func _place_melee_hitbox() -> void:
	if is_instance_valid(melee_hitbox) and melee_target == null:
		melee_hitbox.position = Vector3(facing_x * melee_range, 0.0, 0.0)


func _is_valid_target(candidate: Node3D) -> bool:
	if candidate == null or not is_instance_valid(candidate) or not candidate.is_inside_tree():
		return false
	if not candidate.visible or not candidate.is_visible_in_tree():
		return false
	if candidate.has_method("is_active") and not bool(candidate.call("is_active")):
		return false
	if candidate.has_method("is_defeated") and bool(candidate.call("is_defeated")):
		return false
	if BeeShmupFairness.screen_bound_combat and not BeeShmupFairness.is_on_screen(candidate, -0.2):
		return false # REBUILD 02 (Level 01): never lock onto an enemy that has not entered the screen.
	return true


func _target_point(candidate: Node3D) -> Vector3:
	# LOTE 9: a controlled animal offers its BODY to the auto-aim (1x); the 2x implant hit is a deliberate mouse shot.
	if candidate.has_method("auto_aim_point"):
		return candidate.call("auto_aim_point")
	var hurtbox := candidate.get_node_or_null("Hurtbox3D") as Node3D
	return hurtbox.global_position if hurtbox != null else candidate.global_position


func _update_target_indicator() -> void:
	if is_free_aiming():
		target_indicator.hide() # The crosshair replaces the auto-aim marker while the player aims.
		return
	if current_auto_target == null:
		target_indicator.hide()
		return
	target_indicator.global_position = _target_point(current_auto_target) + Vector3(0.0, 0.55, 0.0)
	target_indicator.show()


func _on_health_changed(current: int, maximum: int, change: int) -> void:
	if change < 0 and current > 0:
		BeeAudio.play(get_parent(), &"bee_damage")
		if BeeGameSettings.vibration_enabled and BeeGameSettings.last_joypad_device in Input.get_connected_joypads():
			Input.start_joy_vibration(BeeGameSettings.last_joypad_device, BeeGameSettings.JOYPAD_VIBRATION_STRENGTH, 0.0, BeeGameSettings.JOYPAD_VIBRATION_SEC)
	health_changed.emit(current, maximum)

func take_boss_burst_damage(amount: int, source: Node) -> int:
	if not BOSS_BURST_GUARD.is_tarantula_source(source) or health.damage_blocked or health.invulnerable or health.pollen_protected or health.current_health <= 0:
		return health.take_damage(amount)
	var allowed: int = boss_burst_guard.allowed(amount)
	var applied := health.take_damage(allowed)
	if applied > 0:
		boss_burst_guard.record(applied)
	elif amount > 0 and allowed == 0:
		show_boss_burst_absorb()
	return applied

func show_boss_burst_absorb() -> void:
	boss_burst_absorbed_hits += 1
	var flash := get_node_or_null("HitFlash3D") as HitFlash3D
	if flash != null:
		flash.flash_absorbed_boss_hit()
	BeeAudio.play(get_parent(), &"bee_damage")
	BeeCameraShake.kick(self, BeeGameSettings.BOSS_BURST_FEEDBACK_SHAKE_AMPLITUDE, BeeGameSettings.BOSS_BURST_FEEDBACK_SHAKE_SECONDS)


func _on_died() -> void:
	if is_defeated:
		return
	is_defeated = true
	if is_instance_valid(active_bomb):
		active_bomb.queue_free()
		active_bomb = null
		weapon_state_changed.emit()
	BeeAudio.play(get_parent(), &"bee_defeat")
	velocity = Vector3.ZERO
	current_auto_target = null
	target_indicator.hide()
	if sting_dash != null and sting_dash.active: sting_dash.finish()
	melee_hitbox.set_enabled(false)
	melee_target = null
	_melee_active_left = 0.0
	if _melee_tween != null:
		_melee_tween.kill()
	visual_root.scale = Vector3(1.0, 0.45, 1.0)
	health_changed.emit(0, health.max_health)
	defeated.emit()


# --- LOTE 7: free aim -------------------------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == SHOOTING.AIM_DEBUG_KEY:
		aim_debug_enabled = not aim_debug_enabled
	if not mouse_aim_enabled or is_defeated:
		return
	if event is InputEventMouseMotion:
		_aim_at_screen((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton and event.is_action_pressed("throw_orange"):
		_aim_at_screen((event as InputEventMouseButton).position)
		_try_input_fire()
		_mouse_tap_handled = true


func _aim_at_screen(screen: Vector2) -> void:
	_aim_screen = screen
	_aim_from_screen = true
	_aim_left = AIM_HOLD_SECONDS
	_refresh_screen_aim()


## The crosshair stays on the same screen spot while the camera scrolls: its world point is recomputed every frame.
func _refresh_screen_aim() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var origin := camera.project_ray_origin(_aim_screen)
	var normal := camera.project_ray_normal(_aim_screen)
	if absf(normal.z) < 0.0001:
		return
	var t := -origin.z / normal.z # Flight plane z = 0.
	aim_point = origin + normal * t


## Aims at a world point (bot / tests / future gamepad). Counts as aiming input for AIM_HOLD_SECONDS.
func set_aim_point(point: Vector3) -> void:
	aim_point = Vector3(point.x, point.y, 0.0)
	_aim_from_screen = false
	_aim_left = AIM_HOLD_SECONDS


func clear_aim() -> void:
	_aim_left = 0.0

func _update_joypad_aim(delta: float) -> void:
	if not InputMap.has_action("aim_left"):
		return
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", BeeGameSettings.JOYPAD_DEADZONE)
	if stick.length_squared() > 0.0:
		var desired := Vector2(stick.x, -stick.y).normalized()
		_stick_aim = Vector2.from_angle(lerp_angle(_stick_aim.angle(), desired.angle(), 1.0 - exp(-delta / BeeGameSettings.JOYPAD_AIM_SMOOTH_SEC)))
		set_aim_point(global_position + Vector3(_stick_aim.x, _stick_aim.y, 0.0) * BeeGameSettings.BEE_DEFAULT_AIM_DISTANCE)
	elif BeeGameSettings.last_input_joypad:
		clear_aim()


func is_free_aiming() -> bool:
	return _aim_left > 0.0


## Direction of the next shot: free aim if active, else the auto-aim target, else straight ahead.
func raw_aim_direction() -> Vector3:
	if not is_free_aiming() and not is_instance_valid(current_auto_target):
		return Vector3(facing_x, 0.0, 0.0)
	var target_point := global_position + Vector3(facing_x * BeeGameSettings.BEE_DEFAULT_AIM_DISTANCE, 0.0, 0.0)
	if is_free_aiming():
		if Vector2(aim_point.x - global_position.x, aim_point.y - global_position.y).length() > 0.05:
			target_point = Vector3(aim_point.x, aim_point.y, global_position.z)
	elif current_auto_target != null:
		target_point = _target_point(current_auto_target)
	var firing_point := global_position
	var visual := $VisualRoot/BeeVisual as Node3D
	if visual != null and visual.get("muzzle") != null:
		firing_point = visual.call("firing_origin", global_position)
	var delta := target_point - firing_point
	return delta.normalized() if delta.length() > 0.05 else Vector3(facing_x, 0.0, 0.0)


func firing_origin() -> Vector3:
	var visual := $VisualRoot/BeeVisual as Node3D
	return visual.call("firing_origin", global_position) if visual != null and visual.get("muzzle") != null else global_position


func aim_direction() -> Vector3:
	var intended := raw_aim_direction()
	aim_assist_target = null
	if not SHOOTING.AIM_ASSIST_ENABLED:
		return intended
	var origin := firing_origin()
	aim_assist_target = AIM_HELP.choose(self, origin, intended)
	if aim_assist_target == null:
		return intended
	var desired := AIM_HELP.point(self, aim_assist_target) - origin
	desired.z = 0.0
	var angle := lerp_angle(atan2(intended.y, intended.x), atan2(desired.y, desired.x), clampf(SHOOTING.AIM_ASSIST_STRENGTH, 0.0, 1.0))
	return Vector3(cos(angle), sin(angle), 0.0)


func _update_free_aim(delta: float) -> void:
	if _aim_left <= 0.0:
		return
	_aim_left = maxf(0.0, _aim_left - delta)
	if _aim_from_screen:
		_refresh_screen_aim()
	var dx := aim_point.x - global_position.x
	_face_towards(dx)

func _face_towards(dx: float) -> void:
	if sting_dash != null and sting_dash.active: return
	if absf(dx) <= BeeGameSettings.BEE_TURN_HYSTERESIS_METERS or _turn_left > 0.0 or signf(dx) == facing_x:
		return
	facing_x = signf(dx)
	_turn_left = BeeGameSettings.BEE_TURN_MIN_INTERVAL_SEC
	_place_melee_hitbox()
	if _turn_tween != null:
		_turn_tween.kill()
	_turn_tween = create_tween().set_parallel(true)
	_turn_tween.tween_property(visual_root, "rotation:y", -facing_x * PI * 0.5, BeeGameSettings.BEE_TURN_DURATION_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not is_rolling:
		_turn_tween.tween_property(visual_root, "rotation:z", facing_x * BeeGameSettings.BEE_TURN_ROLL, BeeGameSettings.BEE_TURN_DURATION_SEC * 0.5)
		_turn_tween.chain().tween_property(visual_root, "rotation:z", 0.0, BeeGameSettings.BEE_TURN_DURATION_SEC * 0.5)


# --- LOTE 11: roll (Shift) and honey mode ---------------------------------------------------------------------------

## Barrel roll: `roll_duration` s of invulnerability (HealthComponent.invulnerable; common enemy shots that touch Bee are
## destroyed, see DamageHurtbox3D), then `roll_cooldown` s until the next one.
func start_roll() -> bool:
	if sting_dash != null and sting_dash.active:
		sting_dash.queued_roll = true
		return false
	if web_locked and not is_defeated:
		web_roll_presses += 1 # T7i: the pirueta tears the trapping net (the trap reads this counter)
		return false
	if is_defeated or web_locked or not roll_enabled or is_rolling or _roll_cooldown_left > 0.0:
		return false
	is_rolling = true
	roll_count += 1
	_roll_left = roll_duration
	_roll_cooldown_left = roll_cooldown
	var movement := Input.get_vector("move_left", "move_right", "move_back", "move_forward", BeeGameSettings.JOYPAD_DEADZONE)
	_roll_dash_left = BeeGameSettings.PIRUETA_DASH_SEC if movement.length_squared() > 0.0 else 0.0
	_roll_dash_velocity = Vector3(movement.x, movement.y, 0.0).normalized() * BeeGameSettings.PIRUETA_DASH_DISTANCE / BeeGameSettings.PIRUETA_DASH_SEC
	health.invulnerable = true
	if _roll_tween != null:
		_roll_tween.kill()
	visual_root.rotation.z = 0.0
	_roll_tween = create_tween()
	_roll_tween.tween_property(visual_root, "rotation:z", -facing_x * TAU, roll_duration).from(0.0)
	_roll_tween.tween_callback(func(): visual_root.rotation.z = 0.0)
	roll_started.emit()
	weapon_state_changed.emit()
	return true


func _update_roll(delta: float) -> void:
	if _roll_cooldown_left > 0.0:
		_roll_cooldown_left = maxf(0.0, _roll_cooldown_left - delta)
	if is_rolling:
		_roll_left -= delta
		if _roll_left <= 0.0:
			is_rolling = false
			health.invulnerable = false
			visual_root.rotation.z = 0.0
			weapon_state_changed.emit()


## 0..1 recharge progress of the roll (1 = ready); the HUD reads it.
func roll_ready_ratio() -> float:
	if not roll_enabled:
		return 0.0
	if is_rolling:
		return 0.0
	return 1.0 - clampf(_roll_cooldown_left / maxf(roll_cooldown, 0.001), 0.0, 1.0)


## LOTE 15: one tug against the web (a movement key pressed while trapped; bots call it directly).
func web_struggle() -> void:
	if web_locked:
		web_struggles += 1


## LOTE 15: fire triggers so far (a tap or a whole burst counts once): the web trap tears one piece per trigger.
func fire_triggers() -> int:
	return fire_trigger_count


func absorb_shot() -> void:
	roll_absorbed_shots += 1
	if is_rolling: BeeJuice.key_event(self,&"roll_shot",null,Vector2(facing_x,0))
	BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0.0, 0.2, 0.0), &"bee_impact")


func activate_honey(seconds := -1.0) -> void:
	honey_left = honey_seconds if seconds < 0.0 else seconds
	honey_changed.emit()
	weapon_state_changed.emit()

func add_pollen_double(seconds: float, maximum: float) -> void:
	pollen_double_left = minf(maximum, pollen_double_left + seconds)
	pollen_double_changed.emit()
	weapon_state_changed.emit()

func _spawn_pollen_twins(mains: Array[BeeEnergyProjectile], spread_look: bool) -> void:
	for main in mains:
		var direction := main.travel_direction
		var side := Vector3(-direction.y, direction.x, 0.0).normalized() * SHOOTING.DOUBLE_OFFSET
		var twin := _spawn_projectile(direction, main.damage)
		main.global_position += side
		twin.global_position -= side
		if spread_look:
			twin.set_spread_visual()


func _update_honey(delta: float) -> void:
	if honey_left <= 0.0:
		return
	honey_left = maxf(0.0, honey_left - delta)
	if honey_left == 0.0:
		honey_changed.emit()


## The second parallel shot of honey mode (same damage and look as `main`).
func _spawn_honey_twin(main: BeeEnergyProjectile, direction: Vector3, spread_look: bool) -> void:
	var twin := _spawn_projectile(direction, int(weapon_profile()["damage"].back()))
	var side := Vector3(-direction.y, direction.x, 0.0).normalized() * SHOOTING.DOUBLE_OFFSET
	main.global_position += side
	twin.global_position -= side
	if spread_look:
		twin.set_spread_visual()


# --- LOTE 14: sustained fire ----------------------------------------------------------------------------------------------

func is_fire_held() -> bool:
	return Input.is_action_pressed("throw_orange")


## Uniform fire while held; no catch-up volleys or queued rounds after release.
func _update_sustained_fire(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	var held := hold_fire_enabled and is_fire_held()
	_burst_left = 0 # No queued rounds: releasing never completes an old burst.
	if not held:
		_hold_time = 0.0
		return
	_hold_time += delta
	if _fire_cooldown <= 0.00001:
		fire()
		burst_shots += weapon_profile()["damage"].size() # Historical telemetry: automatic projectiles.
		_fire_cooldown = float(weapon_profile()["interval"])


func _try_input_fire() -> void:
	if _fire_cooldown > 0.00001:
		return
	fire() # Identical per-shot damage for taps and sustained input.
	_fire_cooldown = float(weapon_profile()["interval"])


## Compatibility entry point for older bots: now requests one ordinary input shot.
func start_burst() -> bool:
	if is_defeated or projectile_scene == null:
		return false
	var before := shots_fired
	_try_input_fire()
	return shots_fired > before


func _scaled_damage(ratio: float, base: int) -> int:
	return maxi(1, roundi(float(base) * ratio))


func _fire_burst_shot() -> void:
	fire() # Legacy bot entry point; use the same configured weapon as live input.


func _fire_spread_burst() -> void:
	fire() # Triple/Spread never switches to a slower five-pellet cadence.
