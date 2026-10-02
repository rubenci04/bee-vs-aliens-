extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene: Node3D = load("res://scenes/bee_prototype/human_detection_poc.tscn").instantiate()
	root.add_child(scene)
	var bee: BeePlayer = scene.get_node("BeePlayer")
	bee.position = Vector3(-2,1.5,0)
	for i in 160: await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://dev/human_detection/poc_view.png")
	print("POC_CAPTURE=",result," STATE=",scene.get_node("HumanObserver").current_state)
	quit(0)
