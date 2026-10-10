extends SceneTree
## DEV ONLY. Renders every Level 01 enemy family (style C) in two light conditions.
## Run WITHOUT --headless: godot --path . --resolution 1152x648 --script res://dev/visual_target/capture_enemies.gd -- <prefix>

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
# [family, x offset from camera, y]
const LINEUP_A := []

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0] if args.size() > 0 else "enemies"
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	var wave := stage.wave as BeeLevel01Controller
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").controls_hint.hide()
	for x: float in [150.0]:
		for unit in stage.get_node("Enemies").get_children():

			unit.queue_free()
		stage.distance = x
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(x - 6.0, 3.0, 0)
		for spec in LINEUP_A:
			wave._spawn({"family": spec[0], "slot": 0, "event": 0, "hard": false})
			var unit: Node3D = stage.get_node("Enemies").get_child(-1)
			unit.global_position = Vector3(x + spec[1], spec[2], 0)
			unit.set_physics_process(false)
		stage.wave.director_moment.emit(&"human_aftermath")
		var old := stage.get_node("Moments") if stage.has_node("Moments") else null
		var cur: Node3D = null
		for n in stage.get_children():
			if n.get("beetle") != null:
				cur = n.get("beetle")
		if cur != null:
			var pos := cur.position
			cur.get_parent().remove_child(cur)
			cur.queue_free()
			var b := Node3D.new()
			var shell := MeshInstance3D.new()
			shell.mesh = GardenLitterMeshes.beetle()
			shell.mesh.surface_set_material(0, GardenProps.flat(Color(0.12, 0.24, 0.16)))
			b.add_child(shell)
			BeeToonStyle.apply(b, true)
			b.scale = Vector3.ONE * 2.6
			stage.add_child(b)
			b.position = Vector3(stage.distance + 2.2, -0.12, -1.6)
			b.rotation.y = PI
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		print("CAPTURE ", root.get_texture().get_image().save_png("res://dev/visual_target/%s_beetle_x%d.png" % [prefix, int(x)]))
	quit(0)
