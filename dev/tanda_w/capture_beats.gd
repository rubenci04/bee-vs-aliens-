extends "res://tests/levels/bee_t7b_fixture.gd"
## Tanda W: capturas con ventana de la escena de arranque, la del robot y el cartel del jefe.
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://dev/tanda_w/" + name + ".png")
func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var stage := await fixture()
	stage.distance = 30.0
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(26.0, 3.6, 0.0)
	var beats := stage.get_node("StoryBeats")
	beats.play(&"start")
	await create_timer(0.75, true, false, true).timeout
	await shot("arranque")
	beats.finish(true)
	stage.distance = 294.0
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(290.0, 3.6, 0.0)
	var robot_actor := robot(stage)
	robot_actor.global_position = Vector3(296.0, -0.2, 0.0)
	await frames(3)
	beats.play(&"robot")
	await create_timer(1.6, true, false, true).timeout
	await shot("robot")
	await create_timer(1.2, true, false, true).timeout
	await shot("cartel_robot")
	await create_timer(0.8, true, false, true).timeout
	print("BEAT active=", beats.active, " age=", beats._age)
	await shot("cartel_robot_2")
	quit(0)
