extends SceneTree
## Mide tiempos de cuadro reales del Nivel 1 (con ventana, sin vsync, velocidad normal, Bee disparando).
## Uso: godot --path . --script res://dev/mejora_visual/perf_probe.gd -- <salida.txt> [ancho] [alto]
const LEVEL := "res://scenes/levels/bee_level_01_vertical_slice.tscn"
const SPOTS := [12.0, 60.0, 120.0, 150.0, 215.0, 262.0, 294.0, 340.5]
const SECONDS := 6.0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "res://qa_screenshots/perf.txt"
	var w := int(args[1]) if args.size() > 1 else 1280
	var h := int(args[2]) if args.size() > 2 else 720
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	DisplayServer.window_set_size(Vector2i(w, h))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var lines: Array[String] = ["%dx%d" % [w, h]]
	for x in SPOTS:
		var stage = load(LEVEL).instantiate()
		root.add_child(stage)
		current_scene = stage
		for i in 8:
			await physics_frame
		stage.bee.health.damage_blocked = true
		stage.distance = x
		stage.wave.resume_after_checkpoint(x)
		stage._update_camera_and_bounds()
		if x > 330.0:
			stage.wave._start_tarantula()
		var times: Array[float] = []
		var t := 0.0
		var last := Time.get_ticks_usec()
		while t < SECONDS:
			await process_frame
			var now := Time.get_ticks_usec()
			var dt := (now - last) / 1000.0
			last = now
			t += dt / 1000.0
			times.append(dt)
			var half: float = BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(stage.get_viewport()))
			stage.bee.global_position.x = stage.distance - half * 0.55
			stage.bee.global_position.y = 3.2 + sin(t * 0.8) * 1.6
			if int(t * 12) % 2 == 0:
				stage.bee.fire()
		times.sort()
		var total := 0.0
		for v in times:
			total += v
		var mean := total / times.size()
		var line := "x=%-6.1f fps_medio=%-5d ms_medio=%-6.2f p95=%-6.2f p99=%-6.2f draw=%-5d objs=%-5d prims=%d" % [x, 1000.0 / mean, mean, times[int(times.size() * 0.95)], times[int(times.size() * 0.99)],
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)]
		lines.append(line)
		print(line)
		root.remove_child(stage)
		stage.queue_free()
		for i in 3:
			await process_frame
	var file := FileAccess.open(out, FileAccess.WRITE)
	for line in lines:
		file.store_line(line)
	file.close()
	quit(0)
