extends SceneTree
## DEV ONLY (lote 5). Renders Level 01 at fixed scroll positions, prints ms per frame (real frame time, vsync off) and the
## renderer's CPU / GPU render time, and saves a capture per position.
## godot --path . --resolution 1152x648 --disable-vsync --script res://dev/visual_target/bench_polish.gd -- <prefix> [x1,x2,...]
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else "bench"
	var xs: PackedStringArray = (args[1] if args.size() > 1 else "10,100,200,300,355").split(",")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	(stage.wave as Node).set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").controls_hint.hide()
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var total_ms := 0.0
	var total_cpu := 0.0
	var total_gpu := 0.0
	for x_text in xs:
		var x := float(x_text)
		stage.distance = x
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(x - 2.5, 3.2, 0)
		await frames(40)
		var cpu := 0.0
		var gpu := 0.0
		var t0 := Time.get_ticks_usec()
		for i in 240:
			await process_frame
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / 240.0
		total_ms += ms
		total_cpu += cpu / 240.0
		total_gpu += gpu / 240.0
		print("BENCH x=%3d frame_ms=%.2f render_cpu_ms=%.3f render_gpu_ms=%.3f draw_calls=%d objects=%d" % [x, ms, cpu / 240.0, gpu / 240.0,
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://dev/visual_target/%s_x%d.png" % [prefix, int(x)])
	var n := float(xs.size())
	print("BENCH_AVG frame_ms=%.2f render_cpu_ms=%.3f render_gpu_ms=%.3f" % [total_ms / n, total_cpu / n, total_gpu / n])
	quit(0)
