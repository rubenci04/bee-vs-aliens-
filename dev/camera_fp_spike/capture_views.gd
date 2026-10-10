extends SceneTree
## DEV ONLY. Renders the same moment of the same scripted flight in views A, B and C (one fresh run per view,
## identical fixed-step simulation). Run WITHOUT --headless:
##   godot --path . --resolution 1152x648 --script res://dev/camera_fp_spike/capture_views.gd -- <seconds>
const SPIKE := preload("res://dev/camera_fp_spike/camera_fp_spike.tscn")
const NAMES := ["A_lateral", "B_persecucion", "C_primera_persona"]

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var seconds: float = float(args[0]) if args.size() > 0 else 8.0
	root.size = Vector2i(1152, 648)
	for view in 3:
		var spike := SPIKE.instantiate()
		root.add_child(spike)
		await frames(3)
		spike.autoplay = false

		spike.set_view(view)
		var t := 0.0
		while t < seconds:
			# Scripted flight: drifts across the lane and up / down; same for every view.
			spike.force_fire = t > seconds - 0.7
			spike.scripted_input = Vector2(sin(t * 0.9), 0.7 * cos(t * 0.7))
			spike.step(1.0 / 60.0)
			t += 1.0 / 60.0
		await frames(4)
		await RenderingServer.frame_post_draw
		print("CAPTURE ", NAMES[view], " ", root.get_texture().get_image().save_png("res://dev/camera_fp_spike/%s.png" % NAMES[view]), " enemies=", spike.enemies.size(), " kills=", spike.kills)
		spike.queue_free()
		await frames(2)
	quit(0)
