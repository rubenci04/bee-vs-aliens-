class_name OrganicAlienEnemy
extends CharacterBody3D

signal defeated(enemy: OrganicAlienEnemy)

enum State { ENTER, HOVER, STALK, WINDUP, LUNGE, RECOVERY, DEAD, RANGED, REPOSITION }

@export var entry_speed := 3.2
@export var stalk_speed := 3.0
@export var lunge_speed := 7.2
@export var stalk_distance := 3.7
@export var entry_screen_x := 4.5
@export var windup_time := 0.65
@export var lunge_time := 0.38
@export var recovery_time := 0.75
@export var bite_damage := 13
## ARCADE REBUILD 02 (Level 01 only, off by default): after every lunge the creature stalks from the other height
## (above / below Bee), so it keeps repositioning instead of hovering in one spot. Presence through movement, not HP.
@export var vary_height := false
## THREAT REBUILD 03 (Level 01 only, off by default): a second language. HOVER -> RANGED (the core glows, then a
## fan of bio-orbs) -> REPOSITION -> STALK -> LUNGE -> RECOVERY -> RANGED... never both attacks at once.
@export var ranged_enabled := false
@export var ranged_windup := 0.6
@export var orb_count := 3
@export var orb_step_degrees := 16.0
@export var orb_speed := 4.4
@export var orb_damage := 7
@export var reposition_time := 0.9
const ORB := preload("res://scenes/bee_prototype/alien_enemy_projectile.tscn")
const ORB_COLOR := Color(0.62, 0.95, 0.25)
static var _orb_material: StandardMaterial3D
static var _glow_material: StandardMaterial3D

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var visual_root: Node3D = $VisualRoot
@onready var attack_hitbox: DamageHitbox3D = $BiteHitbox
@onready var telegraph: MeshInstance3D = $AttackTelegraph

var target: BeePlayer
var current_state := State.ENTER
var facing_x := -1.0
var lunge_direction := Vector3.LEFT
var attack_count := 0
var hit_count := 0
var last_clip := ""
var _active := false
var _state_left := 0.0
var _stalk_side := 1.0
var _stalk_height := 0.55
var _animation_player: AnimationPlayer
var ranged_count := 0
var orbs_fired := 0

func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	health.died.connect(_on_died)
	attack_hitbox.hit_confirmed.connect(func(_hurtbox: DamageHurtbox3D, _damage: int): hit_count += 1)
	attack_hitbox.damage = bite_damage
	attack_hitbox.set_enabled(false)
	telegraph.hide()
	var players := visual_root.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_animation_player = players[0] as AnimationPlayer
	_set_inactive()

func activate(new_target: BeePlayer) -> bool:
	if _active or is_defeated() or new_target == null:
		return false
	target = new_target
	_active = true
	current_state = State.ENTER
	show()
	hurtbox.set_deferred("monitorable", true)
	set_physics_process(true)
	_play_clip("Idle")
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
	if not _active or target == null or target.is_defeated:
		velocity = Vector3.ZERO
		attack_hitbox.set_enabled(false)
		return
	if current_state != State.LUNGE:
		_update_facing()
	match current_state:
		State.ENTER:
			velocity = Vector3(-entry_speed, 0.0, 0.0)
			var stage_camera := get_viewport().get_camera_3d()
			if stage_camera != null and global_position.x <= stage_camera.global_position.x + entry_screen_x:
				_begin_hover()
		State.HOVER:
			velocity = Vector3.ZERO
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_ranged() if ranged_enabled else _begin_stalk()
		State.STALK:
			_move_to_stalk_position(delta)
			_state_left -= delta
			if _state_left <= 0.0 and _distance_to_target() <= 5.3:
				if BeeAttackTokens.try_claim(self, windup_time + lunge_time + 0.2):
					_begin_windup()
				else:
					_state_left = 0.3 # Another heavy pattern is running: keep stalking a beat.
		State.RANGED:
			velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
			_state_left -= delta
			var charge := 1.0 - clampf(_state_left / ranged_windup, 0.0, 1.0)
			telegraph.scale = Vector3.ONE * lerpf(0.6, 1.1, charge)
			if _state_left <= 0.0:
				_fire_orbs()
				_begin_reposition()
		State.REPOSITION:
			_move_to_stalk_position(delta)
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_stalk()
		State.WINDUP:
			velocity = Vector3.ZERO
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_lunge()
		State.LUNGE:
			velocity = lunge_direction * lunge_speed
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_recovery()
		State.RECOVERY:
			velocity = -lunge_direction * 2.2
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_ranged() if ranged_enabled else _begin_stalk()
	move_and_slide()
	position.z = 0.0

func _begin_hover() -> void:
	current_state = State.HOVER
	_state_left = 0.35
	velocity = Vector3.ZERO
	_play_clip("Idle")

func _begin_stalk() -> void:
	current_state = State.STALK
	_state_left = 0.9
	_stalk_side = 1.0 if global_position.x >= target.global_position.x else -1.0
	_stalk_height = ([1.5, -0.8][attack_count % 2] if vary_height else 0.55)
	visual_root.scale = Vector3.ONE
	_play_clip("Walk")

func _move_to_stalk_position(delta: float) -> void:
	var desired := target.global_position + Vector3(_stalk_side * stalk_distance, _stalk_height, 0.0)
	desired.y = clampf(desired.y, 1.5, 6.4)
	var offset := desired - global_position
	velocity = velocity.move_toward(offset.normalized() * stalk_speed if offset.length() > 0.3 else Vector3.ZERO, 12.0 * delta)

func _begin_windup() -> void:
	current_state = State.WINDUP
	_state_left = windup_time
	velocity = Vector3.ZERO
	telegraph.show()
	visual_root.scale = Vector3(0.86, 1.12, 0.86)
	_play_clip("Idle")

func _begin_lunge() -> void:
	current_state = State.LUNGE
	_state_left = lunge_time
	telegraph.hide()
	visual_root.scale = Vector3(1.13, 0.94, 1.0)
	var delta := target.global_position - global_position
	delta.z = 0.0
	lunge_direction = delta.normalized() if delta.length() > 0.01 else Vector3(facing_x, 0.0, 0.0)
	attack_hitbox.position = lunge_direction * 0.72
	attack_hitbox.damage = bite_damage
	attack_hitbox.set_enabled(true)
	attack_count += 1
	_play_clip("Bite_Front")

func _begin_recovery() -> void:
	current_state = State.RECOVERY
	_state_left = recovery_time
	attack_hitbox.set_enabled(false)
	telegraph.hide()
	BeeAttackTokens.release(self)
	visual_root.scale = Vector3.ONE
	_play_clip("Idle")

func _distance_to_target() -> float:
	return Vector2(target.global_position.x - global_position.x, target.global_position.y - global_position.y).length()

func _update_facing() -> void:
	if current_state == State.WINDUP:
		return
	var dx := target.global_position.x - global_position.x
	if absf(dx) > 0.18:
		facing_x = signf(dx)
		visual_root.rotation.y = facing_x * PI * 0.25

func _play_clip(fragment: String) -> bool:
	if _animation_player == null:
		return false
	for clip in _animation_player.get_animation_list():
		if str(clip).to_lower().contains(fragment.to_lower()):
			_animation_player.play(clip)
			last_clip = str(clip)
			return true
	return false

func _on_died() -> void:
	if current_state == State.DEAD:
		return
	BeeAttackTokens.release(self)
	current_state = State.DEAD
	_active = false
	velocity = Vector3.ZERO
	attack_hitbox.set_enabled(false)
	telegraph.hide()
	visual_root.scale = Vector3.ONE
	hurtbox.set_deferred("monitorable", false)
	remove_from_group("bee_auto_aim_targets")
	set_physics_process(false)
	_play_clip("Death")
	defeated.emit(self)
	var death_time := maxf(0.8, _animation_player.current_animation_length if _animation_player != null else 0.8)
	var fade := create_tween()
	fade.tween_interval(death_time)
	fade.tween_callback(hide)

# --- Threat rebuild 03: the ranged language ----------------------------------------------------------------

## The core glows green (a different colour from the lunge telegraph) for `ranged_windup`, then a fan of bio-orbs.
func _begin_ranged() -> void:
	current_state = State.RANGED
	_state_left = ranged_windup
	BeeAudio.play(get_parent(), &"organic_charge", global_position) # GARDEN IDENTITY 04: a wobbling bio charge.
	velocity = Vector3.ZERO
	telegraph.material_override = _bio_glow()
	telegraph.scale = Vector3.ONE * 0.6
	telegraph.show()
	visual_root.scale = Vector3(1.08, 0.94, 1.08)
	_play_clip("Idle")


func _fire_orbs() -> void:
	telegraph.hide()
	telegraph.material_override = null
	telegraph.scale = Vector3.ONE
	visual_root.scale = Vector3.ONE
	ranged_count += 1
	if target == null or not BeeShmupFairness.can_fire(self):
		return
	var origin := global_position + Vector3(facing_x * 0.35, 0.15, 0.0)
	var to_bee := target.global_position - origin
	var base := atan2(to_bee.y, to_bee.x)
	for i in orb_count:
		var angle := base + deg_to_rad(orb_step_degrees) * (float(i) - float(orb_count - 1) * 0.5)
		var orb := ORB.instantiate() as AlienEnemyProjectile
		orb.damage = orb_damage
		orb.speed = orb_speed
		get_parent().add_child(orb)
		orb.global_position = origin
		var visual := orb.get_node_or_null("Visual") as MeshInstance3D
		if visual != null:
			visual.material_override = _bio_orb() # Bio language: green-yellow orbs, not the tech magenta.
		orb.launch(Vector3(cos(angle), sin(angle), 0.0), self)
		orbs_fired += 1


## Short repositioning between the two attacks (to the other stalk height), so they never overlap.
func _begin_reposition() -> void:
	current_state = State.REPOSITION
	_state_left = reposition_time
	_stalk_side = 1.0 if global_position.x >= target.global_position.x else -1.0
	_stalk_height = -0.8 if _stalk_height > 0.5 else 1.5
	_play_clip("Walk")


static func _bio_orb() -> StandardMaterial3D:
	if _orb_material == null:
		_orb_material = StandardMaterial3D.new()
		_orb_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_orb_material.albedo_color = ORB_COLOR
		_orb_material.emission_enabled = true
		_orb_material.emission = ORB_COLOR
		_orb_material.emission_energy_multiplier = 1.6
		_orb_material.render_priority = 50
	return _orb_material


static func _bio_glow() -> StandardMaterial3D:
	if _glow_material == null:
		_glow_material = StandardMaterial3D.new()
		_glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glow_material.albedo_color = Color(ORB_COLOR, 0.45)
	return _glow_material
