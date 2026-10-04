class_name GroundWalkerEnemy
extends Node3D

signal defeated(enemy: GroundWalkerEnemy)
signal projectile_fired(projectile: AlienEnemyProjectile)

enum State { INACTIVE, ENTER, ADVANCE, AIM, WINDUP, SHOOT, RECOVERY, REPOSITION, DEAD }

@export var walk_speed := 1.9
@export var detection_range := 8.5
@export var aim_time := 0.18
@export var windup_time := 0.65
@export var shoot_delay := 0.14
@export var recovery_time := 1.0
@export var reposition_distance := 1.5
@export var projectile_damage := 9
@export var projectile_speed := 6.5
@export var muzzle_height := 3.0
@export var muzzle_forward := 1.05
@export var projectile_scene: PackedScene

@export_category("Heavy pressure (Level 01 only; 1 = the original single shot)")
## PASS 02: a slow burst; every shot re-aims at Bee when it leaves the barrel, then flies straight.
@export var burst_shots := 1
@export var burst_gap := 0.35
## ARCADE REBUILD 02 (Level 01): only stop to aim once readable on screen (otherwise keep walking in). Off by default.
@export var stay_on_screen := false
## With `stay_on_screen` it walks this far inside the edge before stopping to aim (the whole body reads on screen).
const SHOWCASE_INSET := 1.8
## THREAT REBUILD 03 (Level 01 only; 0 = off): every `sweep_every`-th attack is a SWEEP instead of the burst: a
## longer violet charge, then `sweep_shots` shots from high to low across Bee's line (locked at the end of the
## charge), forcing a height change. Never at the same time as another heavy pattern (BeeAttackTokens).
@export var sweep_every := 0
@export var sweep_shots := 5
@export var sweep_step_degrees := 11.0
@export var sweep_gap := 0.11
@export var sweep_windup := 0.85
const SWEEP_COLOR := Color(0.72, 0.3, 1.0)

@onready var visual_root: Node3D = $VisualRoot
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var body_collider: CollisionShape3D = $AnimatableBody3D/CollisionShape3D
@onready var aim_charge: MeshInstance3D = $AimCharge

var target: BeePlayer
var current_state := State.INACTIVE
var projectile_fire_count := 0
var suppressed_shot_count := 0 # Shots skipped by BeeShmupFairness (enemy outside the readable area).
var distance_walked := 0.0
var reposition_count := 0
var animation_player: AnimationPlayer
var _active := false
var _facing_x := -1.0
var _state_left := 0.0
var _shoot_elapsed := 0.0
var _shots_done := 0
var _reposition_left := 0.0
var _reposition_direction := -1.0
var _aim_point := Vector3.ZERO
var sweep_count := 0
var attacks_started := 0
var _sweeping := false
var _sweep_dirs: Array[Vector3] = []
static var _sweep_material: StandardMaterial3D

func _ready() -> void:
	visual_root.hide()
	aim_charge.hide()
	hurtbox.set_deferred("monitorable", false)
	body_collider.set_deferred("disabled", true)
	health.died.connect(_on_died)
	var players := visual_root.find_children("*", "AnimationPlayer", true, false)
	if players.size() != 1:
		push_error("Ground Walker requires exactly one AnimationPlayer")
		return
	animation_player = players[0] as AnimationPlayer
	for clip in [&"CharacterArmature|Idle", &"CharacterArmature|Walk"]:
		if not animation_player.has_animation(clip):
			push_error("Ground Walker missing animation: " + str(clip))
			return
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	for clip in [&"CharacterArmature|Shoot", &"CharacterArmature|Death"]:
		if not animation_player.has_animation(clip):
			push_error("Ground Walker missing animation: " + str(clip))
			return
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_NONE
	set_physics_process(false)

func activate(new_target: BeePlayer) -> bool:
	if _active or current_state == State.DEAD or new_target == null or animation_player == null:
		return false
	target = new_target
	_active = true
	current_state = State.ENTER
	_state_left = 0.55
	visual_root.show()
	hurtbox.set_deferred("monitorable", true)
	body_collider.set_deferred("disabled", false)
	add_to_group("bee_auto_aim_targets")
	_face_target()
	_play(&"Walk")
	set_physics_process(true)
	return true

func deactivate() -> void:
	if not _active or current_state == State.DEAD:
		return
	_active = false
	target = null
	current_state = State.INACTIVE
	aim_charge.hide()
	visual_root.hide()
	hurtbox.set_deferred("monitorable", false)
	body_collider.set_deferred("disabled", true)
	remove_from_group("bee_auto_aim_targets")
	set_physics_process(false)

func is_active() -> bool:
	return _active and current_state != State.DEAD

func is_defeated() -> bool:
	return current_state == State.DEAD

func _physics_process(delta: float) -> void:
	if not _active or target == null or target.is_defeated:
		return
	match current_state:
		State.ENTER:
			_advance(delta)
			_state_left -= delta
			if _state_left <= 0.0:
				current_state = State.ADVANCE
		State.ADVANCE:
			_face_target()
			if _target_distance() <= detection_range and (not stay_on_screen or BeeShmupFairness.is_inside_screen(self, SHOWCASE_INSET)):
				current_state = State.AIM
				_state_left = aim_time
				_play(&"Idle")
			else:
				_advance(delta)
		State.AIM:
			_face_target()
			_state_left -= delta
			if _state_left <= 0.0:
				_aim_point = target.global_position
				current_state = State.WINDUP
				attacks_started += 1
				_sweeping = sweep_every > 0 and attacks_started % sweep_every == 0 \
						and BeeAttackTokens.try_claim(self, sweep_windup + sweep_gap * float(sweep_shots) + 0.4)
				_state_left = sweep_windup if _sweeping else windup_time
				aim_charge.material_override = _sweep_charge_material() if _sweeping else null
				if _sweeping:
					BeeAudio.play(get_parent(), &"walker_charge", global_position) # GARDEN IDENTITY 04: servo whine of the violet sweep.
				aim_charge.show()
		State.WINDUP:
			_state_left -= delta
			var charge_progress := 1.0 - _state_left / (sweep_windup if _sweeping else windup_time)
			aim_charge.scale = Vector3.ONE * lerpf(0.7, 1.8 if _sweeping else 1.4, charge_progress)
			if _state_left <= 0.0:
				current_state = State.SHOOT
				_shoot_elapsed = 0.0
				_shots_done = 0
				aim_charge.hide()
				if _sweeping:
					_lock_sweep()
				_play(&"Shoot")
		State.SHOOT:
			_shoot_elapsed += delta
			var count := sweep_shots if _sweeping else burst_shots
			var gap := sweep_gap if _sweeping else burst_gap
			while _shots_done < count and _shoot_elapsed >= shoot_delay + gap * float(_shots_done):
				if _sweeping:
					_fire_projectile(_sweep_dirs[_shots_done])
				else:
					if _shots_done > 0:
						_aim_point = target.global_position # Later shots of the burst re-aim; each one then flies straight.
					_fire_projectile()
				_shots_done += 1
			var burst_end := shoot_delay + gap * float(count - 1) + 0.25
			if _shoot_elapsed >= maxf(animation_player.get_animation(&"CharacterArmature|Shoot").length, burst_end):
				if _sweeping:
					sweep_count += 1
					BeeAttackTokens.release(self)
				current_state = State.RECOVERY
				_state_left = recovery_time
				_play(&"Idle")
		State.RECOVERY:
			_state_left -= delta
			if _state_left <= 0.0:
				current_state = State.REPOSITION
				_reposition_left = reposition_distance
				var dx := target.global_position.x - global_position.x
				_reposition_direction = signf(dx) if absf(dx) >= 2.2 else -_facing_x
				_facing_x = _reposition_direction
				visual_root.rotation.y = _facing_x * deg_to_rad(60.0)
				reposition_count += 1
				_play(&"Walk")
		State.REPOSITION:
			var step := minf(walk_speed * delta, _reposition_left)
			global_position.x += _reposition_direction * step
			distance_walked += step
			_reposition_left -= step
			if _reposition_left <= 0.0:
				current_state = State.ADVANCE

func _target_distance() -> float:
	return Vector2(target.global_position.x - global_position.x, target.global_position.y - (global_position.y + muzzle_height)).length()

func _advance(delta: float) -> void:
	_face_target()
	if stay_on_screen and not BeeShmupFairness.is_inside_screen(self, SHOWCASE_INSET):
		# Walk in towards the middle of the screen first (even under Bee's column), then the usual approach.
		var camera := get_viewport().get_camera_3d()
		if camera != null:
			var inward := signf(camera.global_position.x - global_position.x)
			visual_root.rotation.y = inward * deg_to_rad(60.0)
			global_position.x += inward * walk_speed * delta
			distance_walked += walk_speed * delta
			_play(&"Walk")
			return
	var dx := target.global_position.x - global_position.x
	if absf(dx) <= 2.2:
		return
	var step := minf(walk_speed * delta, absf(dx) - 2.2)
	global_position.x += _facing_x * step
	distance_walked += step
	_play(&"Walk")

func _face_target() -> void:
	var dx := target.global_position.x - global_position.x
	if absf(dx) < 0.25:
		return
	_facing_x = signf(dx)
	visual_root.rotation.y = _facing_x * deg_to_rad(60.0)
	aim_charge.position.x = _facing_x * muzzle_forward

func _fire_projectile(direction := Vector3.ZERO) -> void:
	if not BeeShmupFairness.can_fire(self):
		suppressed_shot_count += 1
		return
	if projectile_scene == null:
		return
	var projectile := projectile_scene.instantiate() as AlienEnemyProjectile
	projectile.damage = projectile_damage
	projectile.speed = projectile_speed
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector3(_facing_x * muzzle_forward, muzzle_height, 0)
	projectile.launch(direction if direction != Vector3.ZERO else (_aim_point - projectile.global_position).normalized(), self)
	projectile_fire_count += 1
	projectile_fired.emit(projectile)

func _play(clip: StringName) -> void:
	var full_name := StringName("CharacterArmature|" + str(clip))
	if animation_player.current_animation != full_name or not animation_player.is_playing():
		animation_player.play(full_name)

func _on_died() -> void:
	if current_state == State.DEAD:
		return
	BeeAttackTokens.release(self)
	current_state = State.DEAD
	_active = false
	target = null
	aim_charge.hide()
	hurtbox.set_deferred("monitorable", false)
	body_collider.set_deferred("disabled", true)
	remove_from_group("bee_auto_aim_targets")
	set_physics_process(false)
	_play(&"Death")
	defeated.emit(self)
	get_tree().create_timer(animation_player.get_animation(&"CharacterArmature|Death").length + 0.15).timeout.connect(func():
		if is_instance_valid(self):
			visual_root.hide()
	)


## SWEEP: the line to Bee is locked at the end of the charge; shots fan across it from the highest to the lowest.
func _lock_sweep() -> void:
	var muzzle := global_position + Vector3(_facing_x * muzzle_forward, muzzle_height, 0.0)
	var base := target.global_position - muzzle
	base.z = 0.0
	base = base.normalized() if base.length() > 0.01 else Vector3(_facing_x, 0.0, 0.0)
	_sweep_dirs.clear()
	for i in sweep_shots:
		var angle := deg_to_rad(sweep_step_degrees) * (float(i) - float(sweep_shots - 1) * 0.5)
		_sweep_dirs.append(base.rotated(Vector3.BACK, angle))
	_sweep_dirs.sort_custom(func(a: Vector3, b: Vector3): return a.y > b.y) # High to low.


static func _sweep_charge_material() -> StandardMaterial3D:
	if _sweep_material == null:
		_sweep_material = StandardMaterial3D.new()
		_sweep_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_sweep_material.albedo_color = SWEEP_COLOR
		_sweep_material.emission_enabled = true
		_sweep_material.emission = SWEEP_COLOR
		_sweep_material.emission_energy_multiplier = 2.0
	return _sweep_material
