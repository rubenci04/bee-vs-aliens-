extends Node3D
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var clip := ""
	match event.keycode:
		KEY_1: clip = "idle"
		KEY_2: clip = "swim"
		KEY_3: clip = "attack"
		KEY_4: clip = "liberate"
		KEY_L:
			for model in [$Turtle,$Salamander,$Cloud]:
				model.controlled = not model.controlled
	if clip != "":
		for model in [$Turtle,$Salamander,$Cloud]:
			model.play_clip(clip)
