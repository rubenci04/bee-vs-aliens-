class_name AlienProbeEnemy
extends CharacterBody3D

signal defeated(enemy: AlienProbeEnemy)

@export var patrol_half_width := 2.2
@export var patrol_speed := 1.5
@export var vertical_bob := 0.18
@export var bob_speed := 2.4

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: DamageHurtbox3D = $Hurtbox3D
@onready var visual_root: Node3D = $VisualRoot

var _origin := Vector3.ZERO
var _time := 0.0
var _active := true
var _defeated := false


func _ready() -> void:
	add_to_group("bee_auto_aim_targets")
	_origin = global_position
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_time += delta
	var desired_x := _origin.x + sin(_time * patrol_speed) * patrol_half_width
	velocity.x = (desired_x - global_position.x) * 2.2
	velocity.y = 0.0
	velocity.z = 0.0
	move_and_slide()
	global_position.y = _origin.y + sin(_time * bob_speed) * vertical_bob
	global_position.z = 0.0


func is_active() -> bool:
	return _active and not _defeated


func is_defeated() -> bool:
	return _defeated


func _on_died() -> void:
	if _defeated:
		return
	_defeated = true
	_active = false
	velocity = Vector3.ZERO
	set_physics_process(false)
	hurtbox.set_deferred("monitorable", false)
	visual_root.hide()
	defeated.emit(self)