extends Node3D
## Reuses the original amphibian mount. Presentation only, not a combat controller.
@export var preview_motion := true
@export_range(0.0,5.0) var hop_height := 1.4
var elapsed := 0.0
@onready var visual: Node3D = $Toad
func _process(delta: float) -> void:
	if preview_motion:
		elapsed = fmod(elapsed+delta,5.0)
		pose_at(elapsed)
func pose_at(seconds: float) -> void:
	var t := fposmod(seconds,5.0)
	var hop := clampf((t-1.3)/1.2,0,1)
	visual.position.y = sin(hop*PI)*hop_height
	var crouch := .08*sin(clampf(t/.95,0,1)*PI) if t<1.3 else 0.0
	visual.scale = Vector3(1+crouch,1-crouch,1)
func release_control() -> void:
	preview_motion = false
	visual.position = Vector3.ZERO
	visual.scale = Vector3.ONE
	visual.release_control()
func restore_control() -> void:
	visual.controlled = true
	preview_motion = true
	elapsed = 0
