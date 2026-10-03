class_name WaspEnemy
extends CharacterBody3D

signal defeated(enemy: WaspEnemy)

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVERY, DEAD, STALK, DASH, EXIT }

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

# --- Arcade mode (Level 01) ----------------------------------------------------------------------

func _begin_stalk(seconds: float) -> void:
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
	var want_y := clampf(target.global_position.y + sin(_clock * TAU / 2.4) * drift_amplitude, 1.2, 6.2)
	var to_x := want_x - global_position.x
	var to_y := want_y - global_position.y
	velocity.x = move_toward(velocity.x, clampf(to_x * 2.0, -move_speed, move_speed), acceleration * delta)
	velocity.y = move_toward(velocity.y, clampf(to_y * 2.0, -follow_speed, follow_speed), acceleration * delta)
	_stalk_cap -= delta
	if absf(to_x) < 2.0:
		_state_left -= delta
	if _state_left <= 0.0 or _stalk_cap <= 0.0:
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
	if arcade_mode and passes_done < max_passes:
		_begin_stalk(restalk_time)
	elif arcade_mode:
		current_state = State.EXIT
	else:
		current_state = State.CHASE
