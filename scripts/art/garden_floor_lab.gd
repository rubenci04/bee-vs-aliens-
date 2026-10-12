extends Node3D
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_L:
		for model in [$WormRose,$WormCompost]:
			model.controlled = not model.controlled
		return
	var worm_clip := ""
	var mushroom_clip := ""
	match event.keycode:
		KEY_1:
			worm_clip = "idle"
			mushroom_clip = "idle"
		KEY_2:
			worm_clip = "crawl"
			mushroom_clip = "sway"
		KEY_3:
			worm_clip = "recoil"
			mushroom_clip = "sway"
	if worm_clip != "":
		for model in [$WormRose,$WormCompost]:
			model.play_clip(worm_clip)
		for model in [$MushroomButton,$MushroomUmbrella,$MushroomSpotted]:
			model.play_clip(mushroom_clip)
