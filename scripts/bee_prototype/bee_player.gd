class_name BeePlayer
extends CharacterBody3D

signal health_changed(current: int, maximum: int)
signal auto_aim_changed(target: Node3D)
signal melee_started
signal defeated
signal weapon_state_changed
signal powerup_collected(kind: StringName)
signal roll_started
signal honey_changed

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
const AIM_HOLD_SECONDS := 2.5

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
@export var roll_cooldown := 2.5 ## Seconds before the next roll (counted from the start of the roll).
@export var roll_enabled := true

@export_category("Honey mode (LOTE 11)")
@export var honey_seconds := 6.0 ## Double shot while it lasts; filled by pollen (BeeLevel01Juice).
@export var honey_shot_offset := 0.14 ## Half distance between the two parallel shots (m).
@export var honey_twin_damage_ratio := 0.5 ## The second shot does this share of the first one (honey = 1.5x damage, not 2x).

@export_category("Sustained fire (LOTE 14)")
## Holding fire (left click or X) past HOLD_START_DELAY shoots in bursts: BURST_SIZE shots in a row, or a SPREAD_BURST_SIZE fan with Spread.
## A quick tap still shoots one normal shot at once. Damage per shot is scaled so the sustained DPS matches the tap reference (3 taps/s).
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
@export var melee_lunge_time := 0.2 ## Seconds of the lunge towards the target (also the time the hit box is live).
@export var melee_lunge_stop := 0.6 ## Distance (m) from the target at which the lunge stops.
@export var melee_damage := 30 ## 3 x a base shot (10).
@export var melee_range := 0.85 ## Forward swing when nothing is in reach.
@export var melee_active_time := 0.2
@export var melee_cooldown := 0.9

@onready var visual_root: Node3D = $VisualRoot
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var target_indicator: Node3D = $TargetIndicator
@onready var melee_hitbox: DamageHitbox3D = $MeleeHitbox

var facing_x := 1.0
var current_auto_target: Node3D
var shots_fired := 0
var melee_count := 0
var is_defeated := false
var spread_ammo := 0
var bomb_charges := 0
var active_bomb: BeeAlienBomb
var _melee_active_left := 0.0
var is_rolling := false
var roll_count := 0
var roll_absorbed_shots := 0 ## Common enemy shots destroyed by touching Bee during a roll.
var honey_left := 0.0
var _roll_left := 0.0
var _roll_cooldown_left := 0.0
var _roll_tween: Tween
var _melee_cooldown_left := 0.0
var _melee_tween: Tween
var melee_target: Node3D ## LOTE 14: the enemy the current sting is going for (null = forward swing).
var melee_lunge_count := 0
var _lunge_left := 0.0
var _lunge_velocity := Vector3.ZERO
var stinger: Node3D ## Provisional chrome stinger (simple cone) shown during the lunge.
var _stinger_flash: Tween
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


func _ready() -> void:
	add_to_group("bee_player")
	bomb_charges = clampi(starting_bomb_charges, 0, max_bomb_charges)
	target_indicator.set_as_top_level(true)
	target_indicator.hide()
	melee_hitbox.damage = melee_damage
	melee_hitbox.set_enabled(false)
	melee_hitbox.hit_confirmed.connect(_on_melee_impact)
	_place_melee_hitbox()
	_build_stinger()
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_update_melee(delta)
	_update_roll(delta)
	_update_honey(delta)
	if is_defeated:
		velocity = Vector3.ZERO
		return
	var input := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var desired := Vector2(input.x * horizontal_speed, input.y * vertical_speed)
	var rate := acceleration if desired.length_squared() > 0.0 else deceleration
	velocity.x = move_toward(velocity.x, desired.x, rate * delta)
	velocity.y = move_toward(velocity.y, desired.y, rate * delta)
	velocity.z = 0.0
	if _lunge_left > 0.0: # LOTE 14: the sting lunge overrides the flight input.
		_lunge_left = maxf(0.0, _lunge_left - delta)
		velocity = _lunge_velocity
	if absf(input.x) > 0.05 and not is_free_aiming() and _lunge_left <= 0.0:
		facing_x = signf(input.x)
		visual_root.rotation.y = -facing_x * PI * 0.5
		_place_melee_hitbox()
	move_and_slide()
	position.x = clampf(position.x, flight_min.x, flight_max.x)
	position.y = clampf(position.y, flight_min.y, flight_max.y)
	position.z = 0.0
	_update_free_aim(delta)
	refresh_auto_aim()
	if Input.is_action_just_pressed("throw_orange"):
		fire()
	_update_sustained_fire(delta)
	if Input.is_action_just_pressed("debug_attack"):
		start_melee()
	if Input.is_action_just_pressed("bee_roll"):
		start_roll()
	if Input.is_action_just_pressed("bee_bomb"):
		if mouse_aim_enabled and not is_instance_valid(active_bomb):
			_aim_at_screen(get_viewport().get_mouse_position())
		use_bomb()


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
		var delta := Vector2(candidate.global_position.x - global_position.x, candidate.global_position.y - global_position.y)
		var distance := delta.length()
		if distance <= 0.001 or distance > auto_aim_range:
			continue
		var angle := absf(forward.angle_to(delta.normalized()))
		if angle > half_cone:
			continue
		var score := distance + angle * 3.0
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
	var projectile := _spawn_projectile(direction)
	BeeAudio.play(get_parent(), &"spread" if spread_ammo > 0 else &"base")
	BeeCombatVFX.spawn(get_parent(), projectile.global_position, &"muzzle_spread" if spread_ammo > 0 else &"muzzle", direction)
	if spread_ammo > 0:
		projectile.set_spread_visual()
		var reduced_damage := maxi(1, roundi(projectile.damage * spread_damage_ratio))
		projectile.damage = reduced_damage
		projectile.hitbox.damage = reduced_damage
		for angle in [-spread_angle_degrees, spread_angle_degrees]:
			_spawn_projectile(direction.rotated(Vector3.BACK, deg_to_rad(angle)), reduced_damage).set_spread_visual()
		spread_ammo -= 1
		weapon_state_changed.emit()
	if honey_left > 0.0:
		_spawn_honey_twin(projectile, direction, spread_shot) # LOTE 11: honey mode = double shot.
	shots_fired += 1
	return projectile


func _spawn_projectile(direction: Vector3, damage_override := -1) -> BeeEnergyProjectile:
	var projectile := projectile_scene.instantiate() as BeeEnergyProjectile
	if damage_override >= 0:
		projectile.damage = damage_override
	get_parent().add_child(projectile)
	if is_free_aiming():
		projectile.global_position = global_position + direction.normalized() * absf(muzzle_offset.x) + Vector3(0.0, muzzle_offset.y, 0.0)
	else:
		projectile.global_position = global_position + Vector3(facing_x * absf(muzzle_offset.x), muzzle_offset.y, 0.0)
	projectile.launch(direction, self)
	return projectile


func collect_spread() -> bool:
	if is_defeated:
		return false
	spread_ammo = spread_max_shots
	weapon_state_changed.emit()
	powerup_collected.emit(&"spread")
	return true


## ARCADE REBUILD 02: the pre-boss power capsule. Base -> overcharged Spread (spread_max_shots + bonus); with Spread ->
## refill + extend. Never lowers the current ammo; bounded at twice the normal load.
func collect_spread_overcharge() -> bool:
	if is_defeated:
		return false
	spread_ammo = maxi(spread_ammo, mini(maxi(spread_ammo, spread_max_shots) + spread_overcharge_bonus, spread_max_shots * 2))
	weapon_state_changed.emit()
	powerup_collected.emit(&"spread")
	return true


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


## LOTE 14: the Sting (Z) is a 360-degree strike. The NEAREST enemy within `melee_reach()` (in front OR behind) is hit after a short
## lunge (`melee_lunge_time`); with nothing in reach it is the old forward swing. `melee_damage` = 3 base shots, `melee_cooldown` 0.9 s.
func melee_reach() -> float:
	return BEE_LENGTH * melee_reach_factor


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
	if is_defeated or _melee_cooldown_left > 0.0:
		return false
	melee_target = nearest_melee_target()
	var chrome_dir := Vector3(facing_x, 0.0, 0.0)
	if melee_target != null:
		var to_target := _target_point(melee_target) - global_position
		to_target.z = 0.0
		var dist := to_target.length()
		chrome_dir = to_target.normalized() if dist > 0.01 else chrome_dir
		if absf(to_target.x) > 0.15:
			facing_x = signf(to_target.x) # Front or back: Bee turns to the target.
			visual_root.rotation.y = -facing_x * PI * 0.5
		var travel := maxf(0.0, dist - melee_lunge_stop)
		_lunge_velocity = chrome_dir * (travel / maxf(melee_lunge_time, 0.01))
		_lunge_left = melee_lunge_time if travel > 0.0 else 0.0
		melee_lunge_count += 1
		melee_hitbox.global_position = _target_point(melee_target)
	else:
		_place_melee_hitbox()
	melee_hitbox.damage = melee_damage
	melee_hitbox.set_enabled(true)
	_melee_active_left = melee_active_time
	_melee_cooldown_left = melee_cooldown
	melee_count += 1
	if _melee_tween != null:
		_melee_tween.kill()
	visual_root.scale = Vector3(1.22, 0.82, 0.82)
	_melee_tween = create_tween()
	_melee_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.14)
	_show_stinger(chrome_dir)
	melee_started.emit()
	return true


func _update_melee(delta: float) -> void:
	_melee_cooldown_left = maxf(0.0, _melee_cooldown_left - delta)
	if _melee_active_left <= 0.0:
		return
	if melee_target != null and is_instance_valid(melee_target):
		melee_hitbox.global_position = _target_point(melee_target) # The strike follows the target through the lunge.
	_melee_active_left = maxf(0.0, _melee_active_left - delta)
	if _melee_active_left == 0.0:
		melee_hitbox.set_enabled(false)
		melee_target = null
		_lunge_left = 0.0
		_place_melee_hitbox()
		_hide_stinger()


## 0..1 recharge progress of the sting (1 = ready); the HUD reads it ("AGUIJÓN LISTO").
func melee_ready_ratio() -> float:
	return 1.0 - clampf(_melee_cooldown_left / maxf(melee_cooldown, 0.001), 0.0, 1.0)


func _on_melee_impact(hurt: DamageHurtbox3D, _amount: int) -> void:
	BeeAudio.play(get_parent(), &"melee", hurt.global_position)
	BeeCombatVFX.spawn(get_parent(), hurt.global_position, &"melee", Vector3(facing_x, 0, 0))
	BeeCombatVFX.spawn(get_parent(), hurt.global_position, &"impact", Vector3(facing_x, 0, 0), 1.6) # Chrome flash on the strike.
	if stinger != null:
		if _stinger_flash != null:
			_stinger_flash.kill()
		stinger.scale = Vector3(1.5, 1.5, 1.5)
		_stinger_flash = create_tween()
		_stinger_flash.tween_property(stinger, "scale", Vector3.ONE, 0.18)


func _place_melee_hitbox() -> void:
	if is_instance_valid(melee_hitbox) and melee_target == null:
		melee_hitbox.position = Vector3(facing_x * melee_range, 0.0, 0.0)


## PROVISIONAL (the Bee model has no separate stinger): a simple chrome cone + a silver trail, shown while the sting is live.
const STINGER_LENGTH := 0.8
const STINGER_COLOR := Color(0.86, 0.9, 0.96)


func _build_stinger() -> void:
	stinger = Node3D.new()
	stinger.name = "ChromeStinger"
	stinger.visible = false
	add_child(stinger)
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.11
	mesh.height = STINGER_LENGTH
	mesh.radial_segments = 8
	cone.mesh = mesh
	cone.rotation.z = -PI * 0.5 # The cone's tip (+Y) points along +X.
	cone.position = Vector3(STINGER_LENGTH * 0.5 + 0.35, 0.0, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = STINGER_COLOR
	material.metallic = 1.0
	material.roughness = 0.12
	material.emission_enabled = true
	material.emission = Color(0.75, 0.88, 1.0)
	material.emission_energy_multiplier = 0.8
	cone.material_override = material
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stinger.add_child(cone)
	_stinger_trail = CPUParticles3D.new()
	_stinger_trail.amount = 14
	_stinger_trail.lifetime = 0.25
	_stinger_trail.local_coords = false
	_stinger_trail.gravity = Vector3.ZERO
	_stinger_trail.emitting = false
	var dot := SphereMesh.new()
	dot.radius = 0.05
	dot.height = 0.1
	dot.radial_segments = 6
	dot.rings = 3
	var dot_material := StandardMaterial3D.new()
	dot_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_material.albedo_color = Color(0.85, 0.93, 1.0, 0.8)
	dot_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot.material = dot_material
	_stinger_trail.mesh = dot
	_stinger_trail.position = Vector3(STINGER_LENGTH + 0.2, 0.0, 0.0)
	stinger.add_child(_stinger_trail)


func _show_stinger(direction: Vector3) -> void:
	if stinger == null:
		return
	stinger.rotation.z = atan2(direction.y, direction.x)
	stinger.scale = Vector3.ONE
	stinger.visible = true
	_stinger_trail.restart()
	_stinger_trail.emitting = true


func _hide_stinger() -> void:
	if stinger == null:
		return
	stinger.visible = false
	_stinger_trail.emitting = false


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
	health_changed.emit(current, maximum)


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
	melee_hitbox.set_enabled(false)
	melee_target = null
	_hide_stinger()
	_melee_active_left = 0.0
	if _melee_tween != null:
		_melee_tween.kill()
	visual_root.scale = Vector3(1.0, 0.45, 1.0)
	health_changed.emit(0, health.max_health)
	defeated.emit()


# --- LOTE 7: free aim -------------------------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not mouse_aim_enabled or is_defeated:
		return
	if event is InputEventMouseMotion:
		_aim_at_screen((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_aim_at_screen((event as InputEventMouseButton).position)
		fire()


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


func is_free_aiming() -> bool:
	return _aim_left > 0.0


## Direction of the next shot: free aim if active, else the auto-aim target, else straight ahead.
func aim_direction() -> Vector3:
	if is_free_aiming():
		var delta := Vector3(aim_point.x - global_position.x, aim_point.y - global_position.y, 0.0)
		if delta.length() > 0.05:
			return delta.normalized()
	if current_auto_target != null:
		return (_target_point(current_auto_target) - global_position).normalized()
	return Vector3(facing_x, 0.0, 0.0)


func _update_free_aim(delta: float) -> void:
	if _aim_left <= 0.0:
		return
	_aim_left = maxf(0.0, _aim_left - delta)
	if _aim_from_screen:
		_refresh_screen_aim()
	var dx := aim_point.x - global_position.x
	if absf(dx) > 0.3:
		facing_x = signf(dx) # Bee looks where it aims.
		visual_root.rotation.y = -facing_x * PI * 0.5
		_place_melee_hitbox()


# --- LOTE 11: roll (Shift) and honey mode ---------------------------------------------------------------------------

## Barrel roll: `roll_duration` s of invulnerability (HealthComponent.invulnerable; common enemy shots that touch Bee are
## destroyed, see DamageHurtbox3D), then `roll_cooldown` s until the next one.
func start_roll() -> bool:
	if is_defeated or not roll_enabled or is_rolling or _roll_cooldown_left > 0.0:
		return false
	is_rolling = true
	roll_count += 1
	_roll_left = roll_duration
	_roll_cooldown_left = roll_cooldown
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


func absorb_shot() -> void:
	roll_absorbed_shots += 1
	BeeCombatVFX.spawn(get_parent(), global_position + Vector3(0.0, 0.2, 0.0), &"impact")


func activate_honey(seconds := -1.0) -> void:
	honey_left = honey_seconds if seconds < 0.0 else seconds
	honey_changed.emit()
	weapon_state_changed.emit()


func _update_honey(delta: float) -> void:
	if honey_left <= 0.0:
		return
	honey_left = maxf(0.0, honey_left - delta)
	if honey_left == 0.0:
		honey_changed.emit()


## The second parallel shot of honey mode (same damage and look as `main`).
func _spawn_honey_twin(main: BeeEnergyProjectile, direction: Vector3, spread_look: bool) -> void:
	var twin := _spawn_projectile(direction, maxi(1, roundi(float(main.damage) * honey_twin_damage_ratio)))
	var side := Vector3(-direction.y, direction.x, 0.0).normalized() * honey_shot_offset
	main.global_position += side
	twin.global_position -= side
	if spread_look:
		twin.set_spread_visual()


# --- LOTE 14: sustained fire ----------------------------------------------------------------------------------------------

func is_fire_held() -> bool:
	return Input.is_action_pressed("throw_orange") or (mouse_aim_enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))


## Holding fire (past `hold_start_delay`) shoots bursts at `burst_rate`; releasing stops it at once. Taps keep their single shot.
func _update_sustained_fire(delta: float) -> void:
	_burst_cooldown = maxf(0.0, _burst_cooldown - delta)
	var held := hold_fire_enabled and is_fire_held()
	if not held:
		_hold_time = 0.0
		_burst_left = 0
		return
	if mouse_aim_enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_aim_at_screen(get_viewport().get_mouse_position()) # Keeps the free aim alive while the button is held.
	_hold_time += delta
	if _burst_left > 0:
		_burst_gap_left -= delta
		if _burst_gap_left <= 0.0:
			_burst_left -= 1
			_burst_gap_left = burst_shot_gap
			_fire_burst_shot()
	elif _hold_time >= hold_start_delay and _burst_cooldown <= 0.0:
		start_burst()


## One burst: `burst_size` quick shots (Base) or a `spread_burst_size` fan (Spread, 1 charge).
func start_burst() -> bool:
	if is_defeated or projectile_scene == null:
		return false
	_burst_cooldown = 1.0 / maxf(burst_rate, 0.1)
	burst_count += 1
	if spread_ammo > 0:
		_fire_spread_burst()
	else:
		_burst_left = burst_size - 1
		_burst_gap_left = burst_shot_gap
		_fire_burst_shot()
	return true


func _scaled_damage(ratio: float, base: int) -> int:
	return maxi(1, roundi(float(base) * ratio))


func _fire_burst_shot() -> void:
	if is_defeated:
		return
	refresh_auto_aim()
	var direction := aim_direction()
	var projectile := _spawn_projectile(direction, _scaled_damage(hold_damage_ratio, base_shot_damage))
	BeeAudio.play(get_parent(), &"base")
	BeeCombatVFX.spawn(get_parent(), projectile.global_position, &"muzzle", direction)
	if honey_left > 0.0:
		_spawn_honey_twin(projectile, direction, false)
	shots_fired += 1
	burst_shots += 1


func _fire_spread_burst() -> void:
	refresh_auto_aim()
	var direction := aim_direction()
	var pellet_damage := _scaled_damage(hold_spread_damage_ratio, _scaled_damage(spread_damage_ratio, base_shot_damage))
	var first: BeeEnergyProjectile
	for i in spread_burst_size:
		var angle := (float(i) - float(spread_burst_size - 1) * 0.5) * spread_burst_step_degrees
		var pellet := _spawn_projectile(direction.rotated(Vector3.BACK, deg_to_rad(angle)), pellet_damage)
		pellet.set_spread_visual()
		if first == null:
			first = pellet
	BeeAudio.play(get_parent(), &"spread")
	BeeCombatVFX.spawn(get_parent(), first.global_position, &"muzzle_spread", direction)
	spread_ammo -= 1
	weapon_state_changed.emit()
	if honey_left > 0.0:
		_spawn_honey_twin(first, direction, true)
	shots_fired += 1
	burst_shots += spread_burst_size
