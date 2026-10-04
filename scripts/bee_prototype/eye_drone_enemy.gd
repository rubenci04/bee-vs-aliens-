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

const FAN_TELEGRAPH_COLOR := Color(0.72, 0.3, 1.0, 0.55)
static var _fan_material: StandardMaterial3D

var fan_shot_count := 0 # Fans fired (for tests and tuning).
var _attack_index := 0
var _fan_now := false

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
	_fan_now = fan_every > 0 and _attack_index % fan_every == fan_every - 1 and distance >= fan_min_distance \
			and BeeAttackTokens.try_claim(self, fan_windup + 0.4) # REBUILD 03: never with another heavy pattern.
	current_state = State.WINDUP
	_state_left = (fan_windup if _fan_now else windup_time) + (initial_delay if _attack_index == 0 else 0.0)
	velocity = Vector3.ZERO
	telegraph.material_override = _fan_telegraph_material() if _fan_now else null
	telegraph.show()
	visual_root.scale = Vector3(1.10, 0.90, 1.10)

static func _fan_telegraph_material() -> StandardMaterial3D:
	if _fan_material == null:
		_fan_material = StandardMaterial3D.new()
		_fan_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_fan_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_fan_material.albedo_color = FAN_TELEGRAPH_COLOR
	return _fan_material

func _shoot_at_bee() -> void:
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
