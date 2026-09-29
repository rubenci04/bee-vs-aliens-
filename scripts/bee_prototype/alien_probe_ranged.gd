class_name AlienProbeRanged
extends CharacterBody3D

signal defeated(enemy: AlienProbeRanged)
signal projectile_fired(projectile: AlienEnemyProjectile)

enum State { IDLE, POSITION, WINDUP, SHOOT, COOLDOWN, DEAD }

@export var starts_active := false
@export var move_speed := 2.2
@export var acceleration := 10.0
@export var detection_range := 18.0
@export var minimum_range := 5.0
@export var maximum_range := 7.0
@export var windup_time := 0.45
@export var cooldown_time := 1.25
@export var projectile_scene: PackedScene

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var visual_root: Node3D = $VisualRoot
@onready var telegraph: MeshInstance3D = $AttackTelegraph

var target: BeePlayer
var current_state := State.IDLE
var projectile_fire_count := 0
var _active := false
var _state_left := 0.0


func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	health.died.connect(_on_died)
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
	show()
	hurtbox.set_deferred("monitorable", true)
	set_physics_process(true)
	return true


func is_active() -> bool:
	return _active and current_state != State.DEAD


func is_defeated() -> bool:
	return current_state == State.DEAD


func _set_inactive() -> void:
	_active = false
	target = null
	hide()
	hurtbox.set_deferred("monitorable", false)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not _active or target == null:
		return
	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			if _distance_to_target() <= detection_range:
				current_state = State.POSITION
		State.POSITION:
			_update_position(delta)
		State.WINDUP:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			_state_left -= delta
			if _state_left <= 0.0:
				_shoot()
		State.SHOOT:
			_begin_cooldown()
		State.COOLDOWN:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			_state_left -= delta
			if _state_left <= 0.0:
				current_state = State.POSITION
	move_and_slide()
	position.z = 0.0


func _update_position(delta: float) -> void:
	var difference := target.global_position - global_position
	var distance := Vector2(difference.x, difference.y).length()
	var desired := Vector2.ZERO
	if distance > maximum_range:
		desired = Vector2(difference.x, difference.y).normalized()
	elif distance < minimum_range:
		desired = -Vector2(difference.x, difference.y).normalized()
	else:
		_begin_windup()
		return
	velocity.x = move_toward(velocity.x, desired.x * move_speed, acceleration * delta)
	velocity.y = move_toward(velocity.y, desired.y * move_speed, acceleration * delta)


func _begin_windup() -> void:
	current_state = State.WINDUP
	_state_left = windup_time
	velocity = Vector3.ZERO
	telegraph.show()
	visual_root.scale = Vector3(1.12, 0.88, 1.12)


func _shoot() -> void:
	current_state = State.SHOOT
	telegraph.hide()
	visual_root.scale = Vector3.ONE
	var projectile := projectile_scene.instantiate() as AlienEnemyProjectile
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.launch((target.global_position - global_position).normalized(), self)
	projectile_fire_count += 1
	projectile_fired.emit(projectile)


func _begin_cooldown() -> void:
	current_state = State.COOLDOWN
	_state_left = cooldown_time


func _distance_to_target() -> float:
	return Vector2(target.global_position.x - global_position.x, target.global_position.y - global_position.y).length()


func _on_died() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	_active = false
	velocity = Vector3.ZERO
	telegraph.hide()
	hurtbox.set_deferred("monitorable", false)
	visual_root.hide()
	set_physics_process(false)
	defeated.emit(self)