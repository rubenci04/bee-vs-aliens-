class_name GiantHumanCrossingHazard
extends Node3D

signal phase_changed(phase: int)
signal crossing_exited

enum Phase { WAITING, TELEGRAPH, CROSSING, EXITED }

@export var telegraph_seconds := 1.0
@export var crossing_speed := 2.6
@export var second_crossing_speed := 2.4
@export var run_playback_speed := 0.72
@export var second_run_playback_speed := 0.66
@export var contact_damage := 20

@onready var visual_root: Node3D = $VisualRoot
@onready var hitbox: DamageHitbox3D = $ContactHitbox

var current_phase := Phase.WAITING
var crossings_started := 0
var crossings_exited := 0
var hit_count := 0
var animation_player: AnimationPlayer
var current_crossing_speed := 2.6
var _camera: Camera3D
var _time_left := 0.0
var _paused := false

func _ready() -> void:
	visual_root.hide()
	hitbox.team_id = &"human_hazard"
	hitbox.damage = contact_damage
	hitbox.set_enabled(false)
	hitbox.hit_confirmed.connect(func(_hurtbox: DamageHurtbox3D, _damage: int): hit_count += 1)
	var players := $VisualRoot/Hipster.find_children("*", "AnimationPlayer", true, false)
	if players.size() != 1:
		push_error("Giant human requires Hipster's AnimationPlayer")
		return
	animation_player = players[0] as AnimationPlayer
	if not animation_player.has_animation(&"Run"):
		push_error("Giant human requires Hipster's Run clip")
		return
	animation_player.get_animation(&"Run").loop_mode = Animation.LOOP_LINEAR
	animation_player.speed_scale = run_playback_speed

func begin_crossing(stage_camera: Camera3D) -> bool:
	if current_phase != Phase.WAITING and current_phase != Phase.EXITED:
		return false
	if animation_player == null or stage_camera == null:
		return false
	_camera = stage_camera
	current_crossing_speed = crossing_speed if crossings_started == 0 else second_crossing_speed
	animation_player.speed_scale = run_playback_speed if crossings_started == 0 else second_run_playback_speed
	global_position = Vector3(_camera.global_position.x + 11.0, 0.0, 0.0)
	visual_root.hide()
	hitbox.set_enabled(false)
	_time_left = telegraph_seconds
	current_phase = Phase.TELEGRAPH
	crossings_started += 1
	phase_changed.emit(current_phase)
	return true

func _physics_process(delta: float) -> void:
	if _paused:
		return
	match current_phase:
		Phase.TELEGRAPH:
			_time_left -= delta
			if _time_left <= 0.0:
				current_phase = Phase.CROSSING
				visual_root.show()
				hitbox.set_enabled(true)
				animation_player.play(&"Run")
				phase_changed.emit(current_phase)
		Phase.CROSSING:
			global_position.x -= current_crossing_speed * delta
			if global_position.x < _camera.global_position.x - 11.0:
				hitbox.set_enabled(false)
				visual_root.hide()
				animation_player.stop()
				current_phase = Phase.EXITED
				crossings_exited += 1
				phase_changed.emit(current_phase)
				crossing_exited.emit()

func freeze() -> void:
	_paused = true
	hitbox.set_enabled(false)
	if animation_player != null:
		animation_player.pause()
