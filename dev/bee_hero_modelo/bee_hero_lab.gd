extends Node3D
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			$Full.play_clip("wingbeat")
			$Lite.play_clip("wingbeat")
		KEY_2:
			$Full.play_clip("drill_spin")
			$Lite.play_clip("drill_spin")
		KEY_SPACE:
			for model in [$Full,$Lite]:
				var player := model.find_child("AnimationPlayer",true,false) as AnimationPlayer
				if player.is_playing():player.pause()
				else:player.play()
