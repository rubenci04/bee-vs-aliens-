extends "res://tests/levels/bee_t7b_fixture.gd"
## Tanda X: capturas con ventana de las gotas de rocío, la cortadora, los resultados y el título.
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/tanda_x/" + name + ".png")
func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var M := preload("res://scripts/game/bee_moment_settings.gd")
	var stage := await fixture()
	stage.set_physics_process(false)
	stage.distance = M.MOMENT_DEW_X
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(stage.distance - 3.0, 3.4, 0.0)
	var pieces := stage.get_node("SetPieces")
	pieces.play(&"dew_drops")
	await create_timer(2.0).timeout
	await shot("gotas")
	pieces._finish()
	stage.distance = M.MOMENT_MOWER_X
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(stage.distance - 3.0, 4.6, 0.0)
	pieces.played.clear()
	pieces.play(&"lawnmower")
	await create_timer(3.5).timeout
	await shot("cortadora")
	var results = load("res://scenes/game/bee_results_screen.tscn").instantiate()
	results.released = 342; results.total = 384; results.score = 81200; results.combo = 52; results.seconds = 412.0; results.bombs = 7; results.swarms = 5; results.hits = 24
	root.add_child(results)
	await create_timer(4.0).timeout
	await shot("resultados")
	results.queue_free()
	stage.queue_free()
	var title = load("res://scenes/game/bee_title_screen.tscn").instantiate()
	root.add_child(title)
	await create_timer(1.5).timeout
	await shot("titulo")
	quit(0)
