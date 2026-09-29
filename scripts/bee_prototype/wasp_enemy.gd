class_name WaspEnemy
extends CharacterBody3D

signal defeated(enemy: WaspEnemy)

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVERY, DEAD }

@export var starts_active := false
@export var move_speed := 5.0
@export var acceleration := 20.0
@export var detection_range := 18.0
@export var melee_range := 1.0
@export var attack_damage := 10
@export var windup_time := 0.30
@export var active_time := 0.12
@export var recovery_time := 0.60

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


func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	health.died.connect(_on_died)
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
	attack_hitbox.set_enabled(false)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not _active or target == null:
		return
	_update_facing()
	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			if _distance_to_target() <= detection_range:
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
				_begin_attack()
		State.ATTACK:
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_recovery()
		State.RECOVERY:
			velocity = velocity.move_toward(Vector3(-facing_x * 1.2, 0, 0), acceleration * delta)
			_state_left -= delta
			if _state_left <= 0.0:
				current_state = State.CHASE
	move_and_slide()
	position.z = 0.0


func _begin_windup() -> void:
	current_state = State.WINDUP
	_state_left = windup_time
	velocity = Vector3.ZERO
	telegraph.show()
	visual_root.scale = Vector3(0.82, 1.18, 0.82)


func _begin_attack() -> void:
	current_state = State.ATTACK
	_state_left = active_time
	telegraph.hide()
	visual_root.scale = Vector3(1.25, 0.82, 0.82)
	attack_hitbox.position.x = facing_x * 0.72
	attack_hitbox.set_enabled(true)
	attack_count += 1


func _begin_recovery() -> void:
	current_state = State.RECOVERY
	_state_left = recovery_time
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
	current_state = State.DEAD
	_active = false
	velocity = Vector3.ZERO
	attack_hitbox.set_enabled(false)
	telegraph.hide()
	hurtbox.set_deferred("monitorable", false)
	visual_root.hide()
	set_physics_process(false)
	defeated.emit(self)