extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/lote10_b_review/" + label + ".png")
func run() -> void:
	var stage := (load("res://scenes/levels/bee_level_01_vertical_slice.tscn") as PackedScene).instantiate() as BeeShmupStage
	root.add_child(stage)
	await frames(5)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(-2, 4, 0)
	bee.set_aim_point(Vector3(7, 5, 0))
	bee.bomb_charges = 5
	var bomb := bee.use_bomb()
	await frames(18)
	await capture("bomb_in_flight")
	bomb.detonate()
	await frames(2)
	await capture("bomb_warning")
	await frames(15)
	await capture("bomb_explosion")
	print("LOTE10_B_VISUAL_REVIEW_OK")
	quit(0)
