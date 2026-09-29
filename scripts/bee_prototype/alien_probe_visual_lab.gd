extends Node3D
func _ready() -> void:
	$Bee.set_physics_process(false)
	$Wasp.activate($Bee)
	$Wasp.set_physics_process(false)
