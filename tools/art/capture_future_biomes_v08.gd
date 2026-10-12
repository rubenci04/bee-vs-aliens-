extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func snap(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(path)
	assert(error == OK,"Capture failed: " + path)

func run() -> void:
	var folder := "res://docs/art/future_biomes_v08/"
	DirAccess.make_dir_recursive_absolute(folder)
	var lab := load("res://scenes/art_labs/future_biomes_v08.tscn").instantiate() as Node3D
	root.add_child(lab)
	current_scene = lab
	lab.animating = false
	# Let the initial page reach the renderer before rebuilding it for capture.
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	for i in 3:
		print("CAPTURE_PAGE: ",i)
		lab.show_page(i)
		await snap(folder + ["coast_gallery.png","waves_gallery.png","studio_gallery.png"][i])
		lab.ui.visible = false
		await snap(folder + ["coast_clean.png","waves_clean.png","studio_clean.png"][i])
	for id in lab.NEW_IDS:
		print("CAPTURE_ASSET: ",id)
		lab.show_single(id)
		await snap(folder+id+"_side.png")
		lab.show_single(id,false,true)
		await snap(folder+id+"_three_quarter.png")
	lab.queue_free()
	await process_frame
	print("FUTURE_BIOMES_V08_CAPTURE_OK: 12 viewport images")
	quit(0)
