extends SceneTree
## EXPERIMENT (copy of the project on Forward+): same flight as bench_polish plus optional Forward+-only effects.
## -- <prefix> <variant: plain|ssao|full> [x1,x2,...]
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
func frames(count: int) -> void:
	for i in count:
		await process_frame
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else "fwd"
	var variant: String = args[1] if args.size() > 1 else "plain"
	var xs: PackedStringArray = (args[2] if args.size() > 2 else "10,100,300").split(",")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1152, 648)
	print("RENDERER ", RenderingServer.get_current_rendering_method(), " variant=", variant)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	stage.set_physics_process(false)
	(stage.wave as Node).set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").controls_hint.hide()
	var env := (stage.get_node("WorldEnvironment") as WorldEnvironment).environment
	if variant == "ssao" or variant == "full":
		env.ssao_enabled = true
		env.ssao_radius = 1.2
		env.ssao_intensity = 2.0
		env.ssao_power = 1.6
	if variant == "full":
		var attrs := CameraAttributesPractical.new()
		attrs.dof_blur_far_enabled = true
		attrs.dof_blur_far_distance = 16.0
		attrs.dof_blur_far_transition = 10.0
		attrs.dof_blur_amount = 0.08
		stage.camera.attributes = attrs
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.08
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var cpu_total := 0.0
	var gpu_total := 0.0
	for x_text in xs:
		var x := float(x_text)
		stage.distance = x
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(x - 2.5, 3.2, 0)
		await frames(40)
		var cpu := 0.0
		var gpu := 0.0
		for i in 240:
			await process_frame
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		cpu_total += cpu / 240.0
		gpu_total += gpu / 240.0
		print("BENCH x=%3d render_cpu_ms=%.3f render_gpu_ms=%.3f draw_calls=%d" % [x, cpu / 240.0, gpu / 240.0, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://dev/visual_target/%s_%s_x%d.png" % [prefix, variant, int(x)])
	print("BENCH_AVG variant=%s render_cpu_ms=%.3f render_gpu_ms=%.3f" % [variant, cpu_total / xs.size(), gpu_total / xs.size()])
	quit(0)
