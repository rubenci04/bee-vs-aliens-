extends "res://tools/art/capture_catalog.gd"
func run() -> void:
	var folder := "res://docs/art/requested_props_v01/"
	DirAccess.make_dir_recursive_absolute(folder)
	var lab = load("res://scenes/art_labs/ground_litter_v01.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	await process_frame
	await process_frame
	lab.show_single("glass_bottle")
	# Warm shapes behind the bottle provide a direct transparency inspection.
	lab.shape(Vector3(-0.28,-0.1,-1.5),Vector3(0.12,0.6,0.02),Color("e6ba6a"))
	lab.shape(Vector3(0.28,-0.1,-1.5),Vector3(0.12,0.6,0.02),Color("ba6b48"))
	await snap(folder+"glass_transparency.png")
	var bottle := lab.stage.get_child(0) as Node3D
	bottle.visible = false
	await snap(folder+"glass_background_check.png")
	bottle.visible = true
	lab._clear()
	await process_frame
	await process_frame
	lab.camera.size = 12.3
	var index := 0
	for batch in ["pine_woods_v01","ground_litter_v01","ground_litter_v02","residential_sky_v01"]:
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/"+batch+"/manifest.json"))
		lab.asset_folder = batch
		for entry in manifest.assets:
			var visual: Node3D = lab.asset(entry.id,Vector3.ZERO,1.0)
			var box: AABB = lab.bounds_of(visual)
			visual.scale *= minf(2.25/maxf(box.size.y,0.01),3.6/maxf(box.size.x,0.01))
			var centre := Vector3((index%4-1.5)*4.6,3.0-floorf(index/4.0)*3.0,0)
			visual.position = centre-lab.bounds_of(visual).get_center()
			index += 1
	await snap(folder+"all_props_clean.png")
	lab.queue_free()
	await process_frame
	await process_frame
	var hub = load("res://scenes/art_labs/art_delivery_hub_v01.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await snap(folder+"collection_top.png")
	var buttons = hub.find_children("*","Button",true,false)
	buttons[-1].grab_focus()
	await process_frame
	hub.get_node("DeliveryScroll").ensure_control_visible(buttons[-1])
	await snap(folder+"collection_bottom.png")
	print("REQUESTED_PROPS_DETAILS_CAPTURE_OK")
	quit(0)
