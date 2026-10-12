extends "res://tools/art/capture_catalog.gd"
func run() -> void:
	var folder := "res://docs/art/eagle_sky_v01/"
	DirAccess.make_dir_recursive_absolute(folder)
	var lab = load("res://scenes/art_labs/eagle_sky_v01.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	lab.animating = false
	await snap(folder+"studio_gallery.png")
	lab.show_sky()
	lab.seek_preview(0.0)
	await snap(folder+"sky_gallery.png")
	lab.ui.visible = false
	await snap(folder+"sky_clean.png")
	lab.start_dive()
	lab.seek_preview(1.2)
	lab.ui.visible = false
	await snap(folder+"dive_clean.png")
	for view in ["side","three_quarter","liberated"]:
		lab.show_single("controlled_eagle_flight",view=="liberated",view=="three_quarter")
		await snap(folder+"eagle_"+view+".png")
	lab.queue_free()
	await process_frame
	print("EAGLE_SKY_CAPTURE_OK")
	quit(0)
