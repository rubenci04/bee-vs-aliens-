extends Node3D
## Presentation-only inspection: actors retain their normal visual and wingbeat.
func _ready() -> void:
	for entry in [$RightFacing, $LeftFacing]:
		entry.set_physics_process(false)
	$LeftFacing.facing_x = -1.0
	$LeftFacing/VisualRoot.rotation.y = PI * 0.5
