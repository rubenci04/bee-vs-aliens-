class_name BeeShmupStage
extends Node3D

@export_range(0.1, 8.0, 0.1) var scroll_speed := 2.0
@export_range(10.0, 200.0, 1.0) var sector_length := 54.0
@export var screen_left := -5.2
@export var screen_right := 5.2
@export var flight_bottom := 0.7
@export var flight_top := 7.2
@export var clear_scroll_distance := 4.0

@onready var bee: BeePlayer = $BeePlayer
@onready var camera: BeeShmupCamera = $ShmupCamera
@onready var wave: Node = $WaveController
@onready var status: Label = $CanvasLayer/Status
@onready var debug_label: Label = $CanvasLayer/Debug

var distance := 0.0
var pollen_count := 0
var sector_complete := false
var wave_clear_announced := false
var _clear_at := 0.0
var _wave_notice_until := 0.0

func _ready() -> void:
	_update_camera_and_bounds()
	bee.defeated.connect(_on_bee_defeated)
	wave.wave_completed.connect(_on_wave_completed)
	for pickup: BeePollenPickup in $Pollen.get_children():
		pickup.collected.connect(_on_pollen_collected)

func _physics_process(delta: float) -> void:
	if bee.is_defeated:
		return
	if sector_complete:
		return
	# The world stays in global coordinates. Only the camera's stage coordinate advances.
	if distance < sector_length or wave_clear_announced and distance < _clear_at:
		distance += scroll_speed * delta
	_update_camera_and_bounds()
	if wave_clear_announced and distance >= _clear_at and wave.is_complete():
		sector_complete = true
		status.text = "SECTOR COMPLETO"
		wave.freeze_enemies()
	elif wave_clear_announced:
		status.text = "OLEADA ELIMINADA" if distance < _wave_notice_until else "AVANZÁ AL FINAL DEL SECTOR →"
	else:
		status.text = "WASD/FLECHAS VOLAR · X DISPARO · Z MELEE · POLEN %d/4" % pollen_count
	debug_label.text = "SCROLL SPEED %.1f m/s  ·  DISTANCE %.1f/%.0f m" % [scroll_speed, distance, sector_length]

func _update_camera_and_bounds() -> void:
	camera.set_stage_x(distance)
	bee.flight_min = Vector2(distance + screen_left, flight_bottom)
	bee.flight_max = Vector2(distance + screen_right, flight_top)
	# At the rear edge the advancing flight window carries Bee along.
	# Obstacles are placed away from this edge; there is no crush damage.
	if bee.global_position.x < bee.flight_min.x:
		bee.global_position.x = bee.flight_min.x

func _on_wave_completed() -> void:
	if wave_clear_announced:
		return
	wave_clear_announced = true
	_clear_at = maxf(sector_length, distance + clear_scroll_distance)
	_wave_notice_until = distance + scroll_speed * 2.0
	status.text = "OLEADA ELIMINADA"

func _on_pollen_collected(_pickup: BeePollenPickup, _restored: int) -> void:
	pollen_count += 1

func _on_bee_defeated() -> void:
	status.text = "PLAYER DOWN — PRESS R TO RESTART"
	wave.freeze_enemies()

func _process(_delta: float) -> void:
	if bee.is_defeated and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()




