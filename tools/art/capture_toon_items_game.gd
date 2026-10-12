extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snap(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path)==OK)
func run() -> void:
	var folder := "res://docs/art/pickups_game_toon_v01/"
	DirAccess.make_dir_recursive_absolute(folder)
	var lab = load("res://scenes/art_labs/pickups_game_toon_v01.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	await snap(folder+"items_ready.png")
	for pickup in lab.pickups:
		for visual in pickup.get_children():
			if visual.get_script()==preload("res://scripts/items/toon_pickup_hover.gd"):
				visual.animating = false
	lab.collect_item(1)
	await snap(folder+"spread_collected.png")
	lab.collect_item(2)
	await snap(folder+"bomb_collected.png")
	lab.collect_item(0)
	lab.collect_item(3)
	await snap(folder+"all_collected.png")
	print("TOON_ITEMS_CAPTURE_OK")
	quit(0)
