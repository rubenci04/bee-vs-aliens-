extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if "--combat" in OS.get_cmdline_user_args():
		await capture_combat()
		return
	var lab: Node3D = load("res://scenes/bee_prototype/visuals/wasp_enemy_visual_lab.tscn").instantiate()
	root.add_child(lab)
	for path in ["WaspRight/VisualRoot/WaspEnemyVisual", "WaspLeft/VisualRoot/WaspEnemyVisual", "BeePlayer/VisualRoot/BeeVisual"]:
		var visual := lab.get_node(path)
		visual.elapsed = 0.0
		visual._process(0.0)
		visual.set_process(false)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://docs/bee_prototype/wasp_visual_comparison.png")
	quit(result)

func capture_combat() -> void:
	var poc: Node3D = load("res://scenes/bee_prototype/bee_combat_poc.tscn").instantiate()
	root.add_child(poc)
	current_scene = poc
	var bee := poc.get_node("BeePlayer") as BeePlayer
	var wasp := poc.get_node("Enemies/WaspA") as WaspEnemy
	bee.position = Vector3(-5.9,3,0)
	for i in 15: await physics_frame
	bee.set_physics_process(false)
	bee.position = wasp.position + Vector3(-0.8,0,0)
	for i in 90:
		if wasp.current_state == WaspEnemy.State.WINDUP: break
		await physics_frame
	if wasp.current_state != WaspEnemy.State.WINDUP:
		push_error("Runtime capture did not reach windup")
		quit(1)
		return
	wasp.set_physics_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://docs/bee_prototype/wasp_combat_windup.png")
	quit(result)
