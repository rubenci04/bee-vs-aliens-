extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/art/title_screen_v01")
	var title = load("res://scenes/art_labs/title_screen_v01.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	title.animating = false
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://docs/art/title_screen_v01/title.png")==OK)
	print("TITLE_CAPTURE_OK")
	quit(0)
