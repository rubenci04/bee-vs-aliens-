extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene: Node3D = load("res://scenes/bee_prototype/bee_garden_poc.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.get_node("BeePlayer").set_physics_process(false)
	for enemy in scene.get_node("Enemies").get_children():
		enemy.activate(scene.get_node("BeePlayer"))
		enemy.set_physics_process(false)
	var results: Array = []
	var baseline := "--baseline" in OS.get_cmdline_user_args()
	for entry in [["flowers",-11.0,4.0],["bottle",8.0,4.5]]:
		scene.get_node("BeePlayer").position = Vector3(entry[1],entry[2],0)
		for i in 100: await process_frame
		await RenderingServer.frame_post_draw
		var data := {"view":entry[0], "mesh_instances":scene.find_children("*","MeshInstance3D",true,false).size(), "draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), "triangles_frame":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)}
		results.append(data)
		if not baseline:
			root.get_texture().get_image().save_png("res://dev/asset_integration/garden_"+entry[0]+".png")
	var name := "before" if baseline else "after"
	var file := FileAccess.open("res://dev/asset_integration/metrics_"+name+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	file.close()
	print("GARDEN_INTEGRATION_",name.to_upper()," ",results)
	scene.queue_free()
	await process_frame
	quit(0)

