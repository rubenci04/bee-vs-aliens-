extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snap(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path)==OK)
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var batch := args[0]
	var folder := "res://docs/art/"+batch+"/"
	DirAccess.make_dir_recursive_absolute(folder)
	var lab = load("res://scenes/art_labs/"+batch+".tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	lab.animating = false
	if lab.get("effects") != null:
		for fx in lab.effects:
			fx.playing = false
			fx.seek(.20)
	await snap(folder+"studio_gallery.png")
	lab.ui.visible = false
	await snap(folder+"studio_clean.png")
	if lab.has_method("show_garden"):
		lab.show_garden()
		await snap(folder+"garden_gallery.png")
		lab.ui.visible = false
		await snap(folder+"garden_clean.png")
	if lab.has_method("show_lake"):
		lab.show_lake()
		await snap(folder+"lake_gallery.png")
		lab.ui.visible = false
		await snap(folder+"lake_clean.png")
	for id in lab.asset_ids:
		lab.show_single(id)
		await snap(folder+id+"_side.png")
		lab.show_single(id,false,true)
		await snap(folder+id+"_three_quarter.png")
		if lab.removable_control:
			lab.show_single(id,true)
			await snap(folder+id+"_liberated.png")
	lab.queue_free()
	await process_frame
	print("CATALOG_CAPTURE_OK: ",batch)
	quit(0)
