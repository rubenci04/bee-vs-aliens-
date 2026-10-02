class_name SpeederEnemy
extends CharacterBody3D

signal defeated(enemy: SpeederEnemy)

enum Phase { ENTER, TELEGRAPH, DASH, EXIT, DEAD }

@export var entry_speed := 4.0
@export var dash_speed := 9.5
@export var telegraph_time := 0.7
@export var contact_damage := 13
@export var entry_screen_x := 4.5
@export var exit_screen_x := -9.0
@export var respawn_screen_x := 10.8

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var visual_root: Node3D = $VisualRoot
@onready var telegraph: Node3D = $AttackTelegraph
@onready var dash_hitbox: DamageHitbox3D = $DashHitbox

var target: BeePlayer
var current_state := Phase.ENTER
var pass_count := 0
var _active := false
var _state_left := 0.0
var _dash_height := 0.0

func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	health.died.connect(_on_died)
	dash_hitbox.damage = contact_damage
	dash_hitbox.set_enabled(false)
	telegraph.hide()
	_set_inactive()

func activate(new_target: BeePlayer) -> bool:
	if _active or current_state == Phase.DEAD or new_target == null:
		return false
	target = new_target
	_active = true
	current_state = Phase.ENTER
	show()
	hurtbox.set_deferred("monitorable", true)
	set_physics_process(true)
	return true

func is_active() -> bool:
	return _active and current_state != Phase.DEAD

func is_defeated() -> bool:
	return current_state == Phase.DEAD

func _set_inactive() -> void:
	_active = false
	target = null
	hide()
	hurtbox.set_deferred("monitorable", false)
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not _active or target == null or target.is_defeated:
		velocity = Vector3.ZERO
		return
	var stage_camera := get_viewport().get_camera_3d()
	if stage_camera == null:
		return
	match current_state:
		Phase.ENTER:
			velocity = Vector3(-entry_speed, 0, 0)
			move_and_slide()
			if global_position.x <= stage_camera.global_position.x + entry_screen_x:
				_begin_telegraph()
		Phase.TELEGRAPH:
			velocity = Vector3.ZERO
			_state_left -= delta
			if _state_left <= 0.0:
				_begin_dash()
		Phase.DASH:
			velocity = Vector3(-dash_speed, 0, 0)
			move_and_slide()
			global_position.y = _dash_height
			if global_position.x < stage_camera.global_position.x + exit_screen_x:
				_end_pass(stage_camera)
		Phase.EXIT:
			velocity = Vector3.ZERO
	position.z = 0.0

func _begin_telegraph() -> void:
	current_state = Phase.TELEGRAPH
	_state_left = telegraph_time
	velocity = Vector3.ZERO
	telegraph.show()
	visual_root.scale = Vector3(1.1,0.9,1.1)

func _begin_dash() -> void:
	current_state = Phase.DASH
	_dash_height = global_position.y
	telegraph.hide()
	visual_root.scale = Vector3.ONE
	dash_hitbox.damage = contact_damage
	dash_hitbox.set_enabled(true)

func _end_pass(stage_camera: Camera3D) -> void:
	dash_hitbox.set_enabled(false)
	current_state = Phase.EXIT
	pass_count += 1
	# Re-enter from beyond the viewport while alive, so a missed first dash cannot stall the wave.
	global_position = Vector3(stage_camera.global_position.x + respawn_screen_x, _dash_height, 0.0)
	current_state = Phase.ENTER

func _on_died() -> void:
	if current_state == Phase.DEAD:
		return
	current_state = Phase.DEAD
	_active = false
	velocity = Vector3.ZERO
	dash_hitbox.set_enabled(false)
	telegraph.hide()
	hurtbox.set_deferred("monitorable", false)
	visual_root.hide()
	set_physics_process(false)
	defeated.emit(self)
