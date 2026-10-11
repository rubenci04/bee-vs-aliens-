extends Node3D
## Presentation motion only. Collision volumes and pickup world positions remain fixed.
@export var animating := true
var elapsed := 0.0
var rest_position: Vector3
func _ready() -> void:
	rest_position = position
func _process(delta: float) -> void:
	if animating:
		elapsed += delta
		position = rest_position+Vector3(0,sin(elapsed*2.4)*.055,0)
		rotation.y = sin(elapsed*1.3)*.12
