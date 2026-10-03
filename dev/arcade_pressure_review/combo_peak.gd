extends SceneTree
## DEV ONLY. Hostile projectile peak/average for ranged trios (the level caps simultaneous threats at 3), Bee not shooting.
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(func(): quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 5:
		await physics_frame
	var wave := stage.wave as BeeLevel01Controller
	var bee := stage.bee
	bee.set_physics_process(false)
	for combo in [["Probe", "EyeDrone", "Turret"], ["Walker", "EyeDrone", "Probe"], ["Walker", "Probe", "Turret"], ["Probe", "Probe", "EyeDrone"], ["Turret", "EyeDrone", "Wasp"]]:
		for unit in wave.active_units.duplicate():
			wave.active_units.erase(unit)
			unit.queue_free()
		for shot in get_nodes_in_group("alien_projectiles"):
			shot.queue_free()
		stage.scroll_speed = 0.0
		stage.distance = 100.0
		stage._update_camera_and_bounds()
		wave.set_physics_process(false)
		bee.health.damage_blocked = true
		bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 3.5, 0)
		for i in combo.size():
			wave._spawn({"family": combo[i], "slot": i, "event": 0, "hard": false})
		var peak := 0
		var sum := 0
		var n := 0
		for i in 60 * 20:
			bee.global_position.y = 3.5 + sin(float(i) / 60.0 * 2.2) * 0.8
			await physics_frame
			var c := get_nodes_in_group("alien_projectiles").size()
			peak = maxi(peak, c)
			sum += c
			n += 1
		print("COMBO %s peak=%d avg=%.1f" % [str(combo), peak, float(sum) / n])
	quit(0)
