extends SceneTree
## DEV ONLY. Render cost of 28 enemies (4 of each family) on screen inside Level 01 with style C:
## toon + outline, toon only (outline pass removed), and the original materials.
## Run WITHOUT --headless: godot --path . --resolution 1152x648 --script res://dev/visual_target/bench_enemies.gd

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const FAMILIES := ["Probe", "EyeDrone", "Speeder", "Wasp", "Turret", "OrganicAlien", "Walker"]

func frames(count: int) -> void:
	for i in count:
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func measure(label: String, rid: RID) -> void:
	await frames(40)
	var cpu := 0.0
	var gpu := 0.0
	for i in 300:
		await process_frame
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	print("BENCH %-26s render_cpu_ms=%.3f render_gpu_ms=%.3f" % [label, cpu / 300.0, gpu / 300.0])

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
	var x := 150.0
	stage.distance = x
	stage._update_camera_and_bounds()
	var units: Array[Node3D] = []
	for family in FAMILIES:
		for k in 4:
			wave._spawn({"family": family, "slot": 0, "event": k, "hard": false})
			var unit: Node3D = wave.active_units.back()
			var ground: bool = family in ["Turret", "Walker"]
			unit.global_position = Vector3(x - 7.0 + float(FAMILIES.find(family)) * 2.0 + float(k) * 0.4, -0.2 if ground else 1.5 + float(k) * 1.6, -float(k % 2) * 0.6)
			unit.set_physics_process(false)
			units.append(unit)
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	await measure("28 enemies C +outline", rid)
	for unit in units:
		for mesh: MeshInstance3D in unit.find_children("*", "MeshInstance3D", true, false):
			for s in mesh.mesh.get_surface_count():
				var material := mesh.get_surface_override_material(s) as ShaderMaterial
				if material != null:
					material.next_pass = null
	await measure("28 enemies C no outline", rid)
	for unit in units:
		for mesh: MeshInstance3D in unit.find_children("*", "MeshInstance3D", true, false):
			for s in mesh.mesh.get_surface_count():
				if mesh.get_surface_override_material(s) is ShaderMaterial:
					mesh.set_surface_override_material(s, null)
	await measure("28 enemies ORIGINAL", rid)
	quit(0)
