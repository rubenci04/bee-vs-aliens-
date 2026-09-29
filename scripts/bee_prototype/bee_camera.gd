class_name BeeArcadeCamera
extends Camera3D

@export var target_path: NodePath
@export var smoothing := 5.5
@export var look_ahead_x := 2.3
@export var fixed_z := 13.0

@onready var target: Node3D = get_node(target_path) as Node3D


func _ready() -> void:
	position = Vector3(target.position.x + look_ahead_x, target.position.y, fixed_z)


func _process(delta: float) -> void:
	if target == null:
		return
	var desired := Vector3(target.global_position.x + target.get("facing_x") * look_ahead_x, target.global_position.y, fixed_z)
	global_position = global_position.lerp(desired, 1.0 - exp(-smoothing * delta))
	rotation = Vector3.ZERO