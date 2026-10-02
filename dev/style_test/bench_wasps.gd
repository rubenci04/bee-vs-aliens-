extends SceneTree
## DEV ONLY. Render cost of 24 on-screen wasps inside the real Level 01 (fog, shadows, glow):
## original model vs style C with outline vs style C without outline. Run WITHOUT --headless:
##   godot --path . --resolution 1152x648 --script res://dev/style_test/bench_wasps.gd

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const WASP_C := preload("res://scenes/bee_prototype/visuals/wasp_enemy_visual.tscn")
const WASP_A := preload("res://assets/models/bee_prototype/wasp_enemy_visual.glb")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func spawn(scene: PackedScene, stage: Node3D, x: float) -> Array:
	var made := []
	for i in 24:
		var node := scene.instantiate() as Node3D
		stage.add_child(node)
		node.global_position = Vector3(x - 3.5 + (i % 8) * 1.0, 1.2 + (i / 8) * 1.6, -0.5 - (i % 2) * 0.4)
		made.append(node)
	return made

func measure(label: String, rid: RID) -> void:
	await frames(40)
	var cpu := 0.0
	var gpu := 0.0
	for i in 300:
		await process_frame
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	print("BENCH %-22s render_cpu_ms=%.3f render_gpu_ms=%.3f" % [label, cpu / 300.0, gpu / 300.0])

func run() -> void:
	root.size = Vector2i(1152, 648)
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	var wave := stage.wave as BeeLevel01Controller
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	var x := 30.0
	stage.distance = x
	stage._update_camera_and_bounds()
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	await measure("empty (reference)", rid)
	var set_a := spawn(WASP_A, stage, x)
	await measure("24 wasps ORIGINAL", rid)
	for node: Node in set_a:
		node.queue_free()
	var set_c := spawn(WASP_C, stage, x)
	await measure("24 wasps C +outline", rid)
	for node: Node3D in set_c:
		for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var material := mesh.get_surface_override_material(surface) as ShaderMaterial
				if material != null:
					material.next_pass = null
	await measure("24 wasps C no outline", rid)
	quit(0)
