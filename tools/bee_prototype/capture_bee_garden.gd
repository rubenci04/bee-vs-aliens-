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
	for entry in [["flowers",-11.0,4.0],["orchard",8.0,5.0]]:
		scene.get_node("BeePlayer").position = Vector3(entry[1],entry[2],0)
		for i in 100: await process_frame
		for enemy in scene.get_node("Enemies").get_children(): enemy.set_physics_process(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/bee_prototype/garden_"+entry[0]+".png")
	print("GARDEN_INSTANCES ",scene.decoration_count," SHARED_MESHES ",scene.meshes.size()," DRAW_CALLS ",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)," TRIANGLES_FRAME ",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	quit()


