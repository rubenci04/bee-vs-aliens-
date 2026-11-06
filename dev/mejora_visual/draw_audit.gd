extends SceneTree
## Cuenta qué consume los draw calls: apaga un hijo del nivel por vez y mide la diferencia (con ventana).
const LEVEL := "res://scenes/levels/bee_level_01_vertical_slice.tscn"
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await process_frame
func count() -> Vector2i:
	await frames(3)
	return Vector2i(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var stage = load(LEVEL).instantiate()
	root.add_child(stage)
	current_scene = stage
	for i in 8:
		await physics_frame
	stage.bee.health.damage_blocked = true
	stage.wave.set_physics_process(false)
	for spot in [120.0, 215.0, 280.0]:
		stage.distance = spot
		stage._update_camera_and_bounds()
		stage.bee.global_position = Vector3(spot - 3.0, 3.5, 0.0)
		await frames(10)
		var base: Vector2i = await count()
		print("== X=", spot, " total draw=", base.x, " prims=", base.y)
		var rows: Array = []
		for child in stage.get_children():
			if not (child is Node3D):
				continue
			var was: bool = child.visible
			child.visible = false
			var now: Vector2i = await count()
			child.visible = was
			rows.append([base.x - now.x, base.y - now.y, str(child.name)])
		rows.sort_custom(func(a, b): return a[0] > b[0])
		for r in rows.slice(0, 14):
			print("%6d draw %8d prims  %s" % r)
		var sun := stage.get_node("Sun") as DirectionalLight3D
		sun.shadow_enabled = false
		var noshadow: Vector2i = await count()
		sun.shadow_enabled = true
		print("sin sombras: draw=", noshadow.x, " prims=", noshadow.y)
	quit(0)
