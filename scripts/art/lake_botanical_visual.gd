@tool
extends Node3D
## Art-only prop wrapper, using the project's cel shader. No gameplay collision or emission.
@export var preview_motion := true
func _ready() -> void:
	BeeToonStyle.apply(self, true, BeeToonStyle.OUTLINE_PROP)
	var player := find_child("AnimationPlayer",true,false) as AnimationPlayer
	if preview_motion and player != null and player.has_animation("idle"):
		player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		player.play("idle")
