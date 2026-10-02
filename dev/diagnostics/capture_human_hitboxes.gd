extends SceneTree
## DEV ONLY. Screenshot of the H hitbox view (and the on-screen damage message) in the real level.
## Run WITHOUT --headless: godot --path . --resolution 1152x648 --script res://dev/diagnostics/capture_human_hitboxes.gd
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	stage.scroll_speed = 0.0
	stage.distance = 140.0
	stage._update_camera_and_bounds()
	(stage.wave as Node).set_physics_process(false)
	stage.bee.set_physics_process(false)
	await frames(3)
	var human := stage.get_node("GiantHuman") as GiantHumanCrossingHazard
	var debug := stage.get_node("HumanHitboxDebug") as GiantHumanHitboxDebug
	# Real keypress path: H toggles the view.
	var press := InputEventKey.new()
	press.physical_keycode = KEY_H
	press.pressed = true
	debug._unhandled_input(press)
	human.begin_crossing(stage.camera)
	stage.bee.global_position = Vector3(137.0, 3.0, 0)
	for i in 400:
		stage.bee.global_position = Vector3(137.0, 3.0, 0)
		await physics_frame
		if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING and human.global_position.x < 141.2:
			break
	await frames(2)
	await RenderingServer.frame_post_draw
	print("CAPTURE view ", root.get_texture().get_image().save_png("res://dev/diagnostics/human_hitbox_view.png"))
	# Walk Bee into the front leg to get a real damage message.
	stage.bee.health.damage_blocked = false
	for i in 400:
		stage.bee.global_position = Vector3(minf(stage.bee.global_position.x + 0.12, 140.2), 1.6, 0)
		await physics_frame
		if debug.damage_events.size() > 0:
			break
	await frames(3)
	await RenderingServer.frame_post_draw
	print("CAPTURE damage ", root.get_texture().get_image().save_png("res://dev/diagnostics/human_hitbox_damage.png"), " events=", debug.damage_events.size())
	quit(0)
