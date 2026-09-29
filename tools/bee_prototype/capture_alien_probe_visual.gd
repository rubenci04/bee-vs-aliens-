extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var lab: Node3D = load("res://scenes/bee_prototype/visuals/alien_probe_visual_lab.tscn").instantiate()
	root.add_child(lab)
	for path in ["Bee/VisualRoot/BeeVisual", "Wasp/VisualRoot/WaspEnemyVisual"]:
		var visual := lab.get_node(path)
		visual.elapsed = 0
		visual._process(0)
		visual.set_process(false)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	quit(root.get_texture().get_image().save_png("res://docs/bee_prototype/alien_probe_comparison.png"))
