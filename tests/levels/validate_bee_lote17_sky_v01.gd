extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 3:
		await physics_frame
	stage.set_physics_process(false)
	var progression := stage.get_node("LightProgression") as BeeLevel01LightProgression
	var checkpoint := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	stage.distance = 281.0
	stage.elapsed_seconds = 0.0
	checkpoint.activate_second_checkpoint()
	checkpoint.restore_snapshot()
	var expected := BeeLevel01LightProgression.settings_at(281.0)
	var sky := (stage.get_node("WorldEnvironment") as WorldEnvironment).environment.sky.sky_material as ProceduralSkyMaterial
	var sun := stage.get_node("Sun") as DirectionalLight3D
	check(is_equal_approx(sun.light_energy, float(expected["sun_energy"])), "Checkpoint restore applies light from level distance immediately")
	check(sky.sky_top_color.is_equal_approx(expected["sky_top"]), "Checkpoint restore keeps sunset sky based on progress, regardless of elapsed seconds")
	check(is_zero_approx(stage.elapsed_seconds), "Time counter remains independent from the light cycle")
	check(progression != null, "Level has a progress-driven light controller")
	print("LOTE17 SKY failures=", failures)
	quit(1 if failures else 0)
