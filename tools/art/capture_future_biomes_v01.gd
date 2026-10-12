extends SceneTree
## Real Compatibility viewport screenshots, not Blender renders.
func _initialize() -> void:
	call_deferred("run")

func snap(lab: Node3D, path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(path)
	assert(error == OK, "Capture failed: " + path)

func run() -> void:
	var folder := "res://docs/art/future_biomes_v01/"
	DirAccess.make_dir_recursive_absolute(folder)
	var lab := load("res://scenes/art_labs/future_biomes_v01.tscn").instantiate() as Node3D
	root.add_child(lab)
	current_scene = lab
	lab.animating = false
	for i in 3:
		lab.show_page(i)
		if i == 2:
			lab.ui.visible = false
		await snap(lab,folder + ["lake_gallery.png", "space_gallery.png", "creatures_studio.png"][i])
		if i < 2:
			lab.ui.visible = false
			await snap(lab,folder + ["lake_clean.png", "space_clean.png"][i])
	for id in lab.IDS:
		lab.show_single(id)
		await snap(lab,folder + id + "_side.png")
		lab.show_single(id,false,true)
		await snap(lab,folder + id + "_three_quarter.png")
	for id in ["controlled_mosquito","controlled_perch"]:
		lab.show_single(id,true)
		await snap(lab,folder + id + "_liberated.png")
	lab.queue_free()
	await process_frame
	print("FUTURE_BIOMES_CAPTURE_OK: 19 viewport images")
	quit(0)
