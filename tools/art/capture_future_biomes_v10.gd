extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func snap(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path)==OK,"Capture failed: "+path)

func run() -> void:
	var folder := "res://docs/art/future_biomes_v10/"
	DirAccess.make_dir_recursive_absolute(folder)
	var lab = load("res://scenes/art_labs/future_biomes_v10.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	lab.animating = false
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	for i in 4:
		lab.show_page(i)
		await snap(folder+["air_gallery.png","mines_gallery.png","cannon_gallery.png","studio_gallery.png"][i])
		lab.ui.visible = false
		await snap(folder+["air_clean.png","mines_clean.png","cannon_clean.png","studio_clean.png"][i])
	for id in lab.NEW_IDS:
		lab.show_single(id)
		await snap(folder+id+"_side.png")
		lab.show_single(id,false,true)
		await snap(folder+id+"_three_quarter.png")
		if id != "moth_stationary_bomb":
			lab.show_single(id,true)
			await snap(folder+id+"_liberated.png")
	lab.queue_free()
	await process_frame
	print("FUTURE_BIOMES_V10_CAPTURE_OK: 19 viewport images")
	quit(0)
