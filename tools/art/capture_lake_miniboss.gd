extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snap(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path)==OK)
func run() -> void:
	var folder := "res://docs/art/lake_miniboss_v01/"
	DirAccess.make_dir_recursive_absolute(folder)
	var lab = load("res://scenes/art_labs/lake_miniboss_v01.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	lab.animating = false
	lab.boss.preview_motion = false
	lab.boss.pose_at(0)
	await snap(folder+"lake_gallery.png")
	lab.ui.visible = false
	await snap(folder+"lake_clean.png")
	lab.boss.pose_at(1.9)
	await snap(folder+"lake_hop.png")
	lab.toggle_control()
	await snap(folder+"lake_liberated.png")
	print("LAKE_MINIBOSS_CAPTURE_OK")
	quit(0)
