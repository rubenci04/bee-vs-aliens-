class_name OrganicAlienEnemy
extends CharacterBody3D

signal defeated(enemy: OrganicAlienEnemy)

enum State { ENTER, HOVER, STALK, WINDUP, LUNGE, RECOVERY, DEAD }

@export var entry_speed := 3.2
@export var stalk_speed := 3.0
@export var lunge_speed := 7.2
@export var stalk_distance := 3.7
@export var entry_screen_x := 4.5
@export var windup_time := 0.65
@export var lunge_time := 0.38
@export var recovery_time := 0.75
@export var bite_damage := 13

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var visual_root: Node3D = $VisualRoot
@onready var attack_hitbox: DamageHitbox3D = $BiteHitbox
@onready var telegraph: Node3D = $AttackTelegraph

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
var _animation_player: AnimationPlayer

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
				_begin_stalk()
		State.STALK:
			_move_to_stalk_position(delta)
			_state_left -= delta
			if _state_left <= 0.0 and _distance_to_target() <= 5.3:
				_begin_windup()
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
				_begin_stalk()
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
	visual_root.scale = Vector3.ONE
	_play_clip("Walk")

func _move_to_stalk_position(delta: float) -> void:
	var desired := target.global_position + Vector3(_stalk_side * stalk_distance, 0.55, 0.0)
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
