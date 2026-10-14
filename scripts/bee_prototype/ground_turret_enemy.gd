class_name GroundTurretEnemy
extends Node3D
const COMMON_CUE := preload("res://scripts/vfx/bee_common_attack_cue.gd")

signal defeated(enemy: GroundTurretEnemy)
signal projectile_fired(projectile: AlienEnemyProjectile)

enum State { IDLE, TRACK, WINDUP, SHOOT, COOLDOWN, DEAD }

@export var detection_range := 9.0
@export var windup_time := 0.65
@export var cooldown_time := 1.6
@export var projectile_damage := 9
@export var projectile_speed := 6.5
@export var muzzle_height := 0.72
@export var muzzle_forward := 0.62
@export var projectile_scene: PackedScene

@export_category("Territory control (Level 01 only; 1 = the original single shot)")
## PASS 02: a vertical/diagonal fan centred on Bee that forces a change of height. Warning (windup) unchanged.
@export var fan_count := 1
@export var fan_step_degrees := 14.0

## COMBAT VARIETY 01 (Level 01 only; off by default): MORTAR. At the start of the charge a cyan ring marks the ground
## under Bee (locked); the shell flies a high arc to it (MORTAR_FLIGHT s) and leaves a short cyan energy puddle.
## Warning = charge (windup_time) + flight: the marker is visible ~1.5 s before the shell lands.
@export var mortar_mode := false
const MORTAR_FLIGHT := 0.9
const MORTAR_APEX := 2.8
const MORTAR_DAMAGE := 9
const PUDDLE_DAMAGE := 6
const PUDDLE_RADIUS := 1.0
const PUDDLE_SECONDS := 1.4
const MORTAR_MAX_REACH := 8.0
var mortar_count := 0
var _mortar_target := Vector3.ZERO
var _mortar_marker: MeshInstance3D

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var visual_root: Node3D = $VisualRoot
@onready var telegraph: Label3D = $AttackTelegraph
@onready var body_collider: CollisionShape3D = $StaticBody3D/CollisionShape3D

var target: BeePlayer
var current_state := State.IDLE
var projectile_fire_count := 0
var suppressed_shot_count := 0 # Shots skipped by BeeShmupFairness (enemy outside the readable area).
var _active := false
var _state_left := 0.0
var _facing_x := -1.0

func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	health.died.connect(_on_died)
	telegraph.hide()
	hurtbox.set_deferred("monitorable", false)
	set_physics_process(false)

func activate(new_target: BeePlayer) -> bool:
	if _active or current_state == State.DEAD or new_target == null:
		return false
	target = new_target
	_active = true
	current_state = State.TRACK
	hurtbox.set_deferred("monitorable", true)
	set_physics_process(true)
	return true

func deactivate() -> void:
	if not _active or current_state == State.DEAD:
		return
	_active = false
	target = null
	telegraph.hide()
	hurtbox.set_deferred("monitorable", false)
	set_physics_process(false)
func is_active() -> bool:
	return _active and current_state != State.DEAD

func is_defeated() -> bool:
	return current_state == State.DEAD

func _physics_process(delta: float) -> void:
	if not _active or target == null or target.is_defeated:
		return
	match current_state:
		State.TRACK:
			if _target_in_range():
				_update_facing()
				current_state = State.WINDUP
				_state_left = windup_time
				telegraph.show()
				COMMON_CUE.suppress(telegraph)
				BeeShotWarning.volley(self, &"machine", visual_root, windup_time)
				if mortar_mode:
					_mark_mortar()
		State.WINDUP:
			_state_left -= delta
			if _state_left <= 0.0:
				_shoot()
		State.SHOOT:
			current_state = State.COOLDOWN
			_state_left = cooldown_time
		State.COOLDOWN:
			_state_left -= delta
			if _state_left <= 0.0:
				current_state = State.TRACK

func _target_in_range() -> bool:
	return Vector2(target.global_position.x - global_position.x, target.global_position.y - global_position.y).length() <= detection_range

func _update_facing() -> void:
	var dx := target.global_position.x - global_position.x
	if absf(dx) > 0.2:
		_facing_x = signf(dx)
		visual_root.rotation.y = -_facing_x * PI * 0.5
		telegraph.position.x = _facing_x * 0.8

func _shoot() -> void:
	current_state = State.SHOOT
	telegraph.hide()
	if not BeeShmupFairness.can_fire(self):
		suppressed_shot_count += 1
		_clear_marker()
		return
	if projectile_scene == null or target == null:
		return
	var origin := global_position + Vector3(_facing_x * muzzle_forward, muzzle_height, 0.0)
	if mortar_mode:
		_fire_mortar(origin)
		return
	var aim := target.global_position - origin
	for direction in BeeEnemyPatterns.fan_directions(aim, maxi(fan_count, 1), fan_step_degrees if fan_count > 1 else 0.0):
		var projectile := BeeEnemyPatterns.spawn_shot(get_parent(), projectile_scene, origin, direction, projectile_damage, projectile_speed, self)
		projectile_fire_count += 1
		projectile_fired.emit(projectile)

func _on_died() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	_clear_marker()
	_active = false
	target = null
	telegraph.hide()
	visual_root.hide()
	hurtbox.set_deferred("monitorable", false)
	body_collider.set_deferred("disabled", true)
	set_physics_process(false)
	defeated.emit(self)




# --- COMBAT VARIETY 01: mortar --------------------------------------------------------------------------------

func _mark_mortar() -> void:
	var dx := clampf(target.global_position.x - global_position.x, -MORTAR_MAX_REACH, MORTAR_MAX_REACH)
	_mortar_target = Vector3(global_position.x + dx, -0.2, 0.0)
	_clear_marker()
	_mortar_marker = BeeAttackVisuals.ring(get_parent(), _mortar_target + Vector3(0, 0.08, 0), PUDDLE_RADIUS, 0.18, Color(0.2, 0.95, 1.0, 0.8), true)
	if COMMON_CUE.enabled:
		_mortar_marker.queue_free()
		_mortar_marker = COMMON_CUE.ring(get_parent(), _mortar_target + Vector3(0,.08,0), PUDDLE_RADIUS, Color(0.2,.95,1))
	_mortar_marker.rotation.x = 0.0 # Flat on the ground.
	_mortar_marker.scale = Vector3(PUDDLE_RADIUS,1,PUDDLE_RADIUS) if COMMON_CUE.enabled else Vector3(PUDDLE_RADIUS, 1.0, PUDDLE_RADIUS * 0.6)


func _fire_mortar(origin: Vector3) -> void:
	var shell := AlienMortarShell.new()
	shell.name = "MortarShell"
	shell.attacker = self
	shell.flight_time = MORTAR_FLIGHT
	shell.apex = MORTAR_APEX
	shell.damage = MORTAR_DAMAGE
	shell.puddle_damage = PUDDLE_DAMAGE
	shell.puddle_radius = PUDDLE_RADIUS
	shell.puddle_seconds = PUDDLE_SECONDS
	get_parent().add_child(shell)
	shell.launch(origin, _mortar_target, _mortar_marker)
	_mortar_marker = null
	mortar_count += 1
	projectile_fire_count += 1
	BeeAudio.play(get_parent(), &"tech_hit", origin, 0.6)


func _clear_marker() -> void:
	if _mortar_marker != null and is_instance_valid(_mortar_marker):
		_mortar_marker.queue_free()
	_mortar_marker = null


func _exit_tree() -> void:
	_clear_marker()
