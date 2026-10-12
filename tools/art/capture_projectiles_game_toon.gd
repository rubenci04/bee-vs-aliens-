extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snap(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path)==OK)
func run() -> void:
	var folder := "res://docs/art/projectiles_game_toon_v01/"
	DirAccess.make_dir_recursive_absolute(folder)
	var lab = load("res://scenes/art_labs/projectiles_game_toon_v01.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	lab.set_paused(true)
	for i in 2:
		lab.shots[i].position.x = -2.0 if i==0 else 2.0
	for fx in lab.effects:
		fx.seek(.22)
	await snap(folder+"palette_gallery.png")
	lab.ui.visible = false
	await snap(folder+"palette_clean.png")
	lab.set_paused(false)
	for i in 150:
		await physics_frame
		if lab.targets[0].get_node("HealthComponent").current_health<100 and lab.targets[1].get_node("HealthComponent").current_health<100:
			break
	lab.set_paused(true)
	for child in lab.stage.get_children():
		if child is BeeToonBurstVisual and child not in lab.effects:
			child.set_process(false)
			child.seek(child.duration*.40)
	await snap(folder+"impacts.png")
	lab.camera.size = 3.0
	lab.camera.position = Vector3(6.5,1.8,20)
	await snap(folder+"bee_impact_close.png")
	lab.camera.position = Vector3(-6.5,-.4,20)
	await snap(folder+"alien_impact_close.png")
	print("PROJECTILES_GAME_TOON_CAPTURE_OK")
	quit(0)
