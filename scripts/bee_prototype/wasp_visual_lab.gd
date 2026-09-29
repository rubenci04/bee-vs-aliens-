extends Node3D
## Side-by-side inspection at the same world scale; no combat simulation here.
func _ready() -> void:
	$BeePlayer.set_physics_process(false)
	for wasp in [$WaspRight, $WaspLeft]:
		wasp.activate($BeePlayer)
		wasp.set_physics_process(false)
	$WaspRight.facing_x = 1.0
	$WaspRight/VisualRoot.rotation.y = -PI * 0.5
	$WaspLeft/VisualRoot.rotation.y = PI * 0.5
