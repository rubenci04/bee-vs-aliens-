extends SceneTree
## DEV ONLY. Render cost of the full Level 01 at several scroll positions (no enemies spawned).
## Run WITHOUT --headless: godot --path . --resolution 1152x648 --script res://dev/visual_target/bench_level.gd

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	(stage.wave as Node).set_physics_process(false)
	stage.bee.set_physics_process(false)
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for x: float in [10.0, 100.0, 200.0, 300.0, 355.0]:
		stage.distance = x
		stage._update_camera_and_bounds()
		await frames(40)
		var cpu := 0.0
		var gpu := 0.0
		for i in 200:
			await process_frame
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		var info := "draw_calls=%d objects=%d" % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)]
		print("BENCH x=%3d render_cpu_ms=%.3f render_gpu_ms=%.3f %s" % [x, cpu / 200.0, gpu / 200.0, info])
	quit(0)
