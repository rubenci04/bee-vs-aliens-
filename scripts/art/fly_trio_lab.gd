extends Node3D
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var clip := ""
	match event.keycode:
		KEY_1: clip = "hover"
		KEY_2: clip = "attack"
		KEY_3: clip = "liberate"
		KEY_L:
			for model in [$Common,$Green,$Swarm]:
				model.controlled = not model.controlled
	if clip != "":
		for model in [$Common,$Green,$Swarm]:
			model.play_clip(clip)
