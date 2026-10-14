class_name AlienProbeRanged
extends CharacterBody3D
const COMMON_CUE := preload("res://scripts/vfx/bee_common_attack_cue.gd")

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

@export_category("Arcade mode (Level 01 only; defaults keep the single shot)")
## HOLD at range, SLOW ADVANCE between attacks, FIRE a short burst (each shot re-aims, so it stays dodgeable).
@export var burst_shots := 1
@export var burst_gap := 0.3
@export var advance_speed := 0.0
## PASS 02: AIMED BURST -> SHORT RECOVERY -> AIMED BURST -> LONG cooldown with ADVANCE + vertical reposition.
@export var short_recovery := 0.0 # 0 = off (every burst is followed by `cooldown_time`).
@export var bursts_per_cycle := 2
@export var reposition_speed := 0.0 # Vertical m/s towards Bee's height during the long cooldown.
@export var initial_delay := 0.0 # Extra first windup so two Probes never fire on the same frame.
## ARCADE REBUILD 02 (Level 01): never hold position or wind up outside the readable screen area; step back in
## first. Off by default (POCs keep their behaviour). Before, a Probe could park past the right edge and lose
## whole bursts to the off-screen fairness rule.
@export var stay_on_screen := false

## COMBAT VARIETY 01 (Level 01 only; off by default): SPLIT ORB. One big slow orb per attack (after the usual windup
## telegraph); after ORB_SPLIT_DISTANCE m it swells for ORB_SPLIT_WARN s and splits into two shots at +-ORB_SPLIT_ANGLE.
@export var split_orb := false
const ORB_SPEED := 3.2
const ORB_SCALE := 1.8
const ORB_DAMAGE := 9
const ORB_SPLIT_DISTANCE := 4.0
const ORB_SPLIT_ANGLE := 24.0
const ORB_SPLIT_SPEED := 5.6
const ORB_SPLIT_DAMAGE := 6
const ORB_SPLIT_WARN := 0.45
var orb_count := 0

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var visual_root: Node3D = $VisualRoot
@onready var telegraph: MeshInstance3D = $AttackTelegraph

var target: BeePlayer
var current_state := State.IDLE
var projectile_fire_count := 0
var suppressed_shot_count := 0 # Shots skipped by BeeShmupFairness (enemy outside the readable area).
var _active := false
var _state_left := 0.0
var _burst_left := 0
var _cycle := 0
var _long_cooldown := true


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
			if _burst_left > 0:
				_state_left -= delta
				if _state_left <= 0.0:
					_burst_left -= 1
					_state_left = burst_gap
					_fire_one()
			else:
				_begin_cooldown()
		State.COOLDOWN:
			var rest := Vector3.ZERO
			if _long_cooldown and advance_speed > 0.0 and _distance_to_target() > minimum_range + 0.3:
				rest.x = signf(target.global_position.x - global_position.x) * advance_speed
			if _long_cooldown and reposition_speed > 0.0:
				rest.y = clampf((target.global_position.y - global_position.y) * 1.5, -reposition_speed, reposition_speed)
			velocity = velocity.move_toward(rest, acceleration * delta)
			_state_left -= delta
			if _state_left <= 0.0:
				current_state = State.POSITION
	move_and_slide()
	position.z = 0.0


func _update_position(delta: float) -> void:
	var difference := target.global_position - global_position
	var distance := Vector2(difference.x, difference.y).length()
	var desired := Vector2.ZERO
	var back_in := _back_on_screen_direction()
	if back_in != 0.0:
		desired = Vector2(back_in, 0.0)
	elif distance > maximum_range:
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
	_state_left = windup_time + (initial_delay if _cycle == 0 else 0.0)
	velocity = Vector3.ZERO
	telegraph.show()
	COMMON_CUE.suppress(telegraph)
	BeeShotWarning.volley(self, &"machine", visual_root, _state_left)
	visual_root.scale = Vector3.ONE if COMMON_CUE.enabled else Vector3(1.12, 0.88, 1.12)


func _shoot() -> void:
	current_state = State.SHOOT
	_cycle += 1
	telegraph.hide()
	visual_root.scale = Vector3.ONE
	_burst_left = burst_shots - 1
	_state_left = burst_gap
	_fire_one()


func _fire_one() -> void:
	if not BeeShmupFairness.can_fire(self):
		suppressed_shot_count += 1
		return
	if split_orb:
		_fire_split_orb()
		return
	var projectile := projectile_scene.instantiate() as AlienEnemyProjectile
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.launch((target.global_position - global_position).normalized(), self)
	projectile_fire_count += 1
	projectile_fired.emit(projectile)


func _begin_cooldown() -> void:
	current_state = State.COOLDOWN
	_long_cooldown = short_recovery <= 0.0 or _cycle % maxi(bursts_per_cycle, 1) == 0
	_state_left = cooldown_time if _long_cooldown else short_recovery


## 0 when on screen (or the rule is off); otherwise -1/+1: the way back into the readable area.
func _back_on_screen_direction() -> float:
	if not stay_on_screen or BeeShmupFairness.is_readable(self):
		return 0.0
	var camera := get_viewport().get_camera_3d()
	return signf(camera.global_position.x - global_position.x) if camera != null else 0.0


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

# --- COMBAT VARIETY 01: split orb -----------------------------------------------------------------------------

func _fire_split_orb() -> void:
	var orb := projectile_scene.instantiate() as AlienEnemyProjectile
	orb.speed = ORB_SPEED
	orb.damage = ORB_DAMAGE
	orb.lifetime = 4.0
	orb.add_to_group("alien_split_orbs")
	get_parent().add_child(orb)
	orb.global_position = global_position
	orb.scale = Vector3.ONE * ORB_SCALE
	orb.launch((target.global_position - global_position).normalized(), self)
	var splitter := AlienOrbSplitter.new()
	splitter.name = "Splitter"
	splitter.projectile_scene = projectile_scene
	splitter.split_distance = ORB_SPLIT_DISTANCE
	splitter.split_angle = ORB_SPLIT_ANGLE
	splitter.split_speed = ORB_SPLIT_SPEED
	splitter.split_damage = ORB_SPLIT_DAMAGE
	splitter.warn_seconds = ORB_SPLIT_WARN
	splitter.attacker = self
	orb.add_child(splitter)
	orb_count += 1
	projectile_fire_count += 1
	projectile_fired.emit(orb)
