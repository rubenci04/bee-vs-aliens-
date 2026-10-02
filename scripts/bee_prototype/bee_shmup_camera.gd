class_name BeeShmupCamera
extends Camera3D

@export var fixed_y := 4.0
@export var fixed_z := 13.0

func set_stage_x(stage_x: float) -> void:
	global_position = Vector3(stage_x, fixed_y, fixed_z)
	rotation = Vector3.ZERO

