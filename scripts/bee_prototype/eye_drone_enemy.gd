class_name EyeDroneEnemy
extends AlienProbeRanged

## Air-light pursuer. Reuses Bee's health, hurtbox, hit flash, and straight projectile.
## Base State.IDLE is the brief entry; State.POSITION is this unit's chase.

@export var shot_damage := 6
@export var enter_time := 0.22

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
	if distance > maximum_range:
		direction = Vector2(to_bee.x, to_bee.y).normalized()
	elif distance < minimum_range:
		direction = -Vector2(to_bee.x, to_bee.y).normalized()
	else:
		current_state = State.WINDUP
		_state_left = windup_time
		velocity = Vector3.ZERO
		telegraph.show()
		visual_root.scale = Vector3(1.10, 0.90, 1.10)
		return
	velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
	velocity.y = move_toward(velocity.y, direction.y * move_speed, acceleration * delta)

func _shoot_at_bee() -> void:
	current_state = State.SHOOT
	telegraph.hide()
	visual_root.scale = Vector3.ONE
	var projectile := projectile_scene.instantiate() as AlienEnemyProjectile
	projectile.damage = shot_damage
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.launch((target.global_position - global_position).normalized(), self)
	projectile_fire_count += 1
	projectile_fired.emit(projectile)

func _update_facing() -> void:
	var horizontal := target.global_position.x - global_position.x
	if absf(horizontal) > 0.2:
		visual_root.rotation.y = -signf(horizontal) * PI * 0.5

