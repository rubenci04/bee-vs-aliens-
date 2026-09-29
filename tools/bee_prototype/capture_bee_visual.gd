extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var lab: Node3D = load("res://scenes/bee_prototype/visuals/bee_player_visual_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/bee_prototype/bee_visual_facings.png")
	quit()

