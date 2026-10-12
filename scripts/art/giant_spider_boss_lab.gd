extends Node3D
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var clip := ""
	match event.keycode:
		KEY_1: clip = "idle"
		KEY_2: clip = "walk"
		KEY_3: clip = "attack"
		KEY_L: $Controlled.controlled = not $Controlled.controlled
	if clip != "":
		$Controlled.play_clip(clip)
		$Liberated.play_clip(clip)
