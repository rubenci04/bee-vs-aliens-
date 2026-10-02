extends SceneTree
## DEV ONLY diagnostic: why does the human report a hit while Bee is 16 m away from it?
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func run() -> void:
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	stage.scroll_speed = 0.0
	stage.distance = 140.0
	stage._update_camera_and_bounds()
	(stage.wave as Node).set_physics_process(false)
	stage.bee.set_physics_process(false)
	await frames(3)
	var human := stage.get_node("GiantHuman") as GiantHumanCrossingHazard
	var bee := stage.bee
	bee.global_position = Vector3(135.05, 0.8, 0)
	await frames(3)
	human.hitbox.hit_confirmed.connect(func(_h, d): print("GHOST_HIT frame=", Engine.get_physics_frames(), " phase=", human.current_phase))
	human.hitbox.area_shape_entered.connect(func(_r, a, _ai, li): print("ENTERED frame=", Engine.get_physics_frames(), " local_shape=", li, " owner=", human.hitbox.shape_owner_get_owner(human.hitbox.shape_find_owner(li)).name, " area=", a.get_parent().name))
	human.begin_crossing(stage.camera)
	var last_phase := -1
	for i in 140:
		bee.global_position = Vector3(135.05, 0.8, 0)
		await physics_frame
		if human.current_phase != last_phase or human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING and i % 1 == 0 and i > 55:
			var parts := []
			for c in human.hitbox.get_children():
				parts.append("%s%s@%.1f" % [c.name, "(off)" if c.disabled else "", c.global_position.x])
			print("f=%d phase=%d human_x=%.2f bee_hp=%d monitoring=%s %s" % [Engine.get_physics_frames(), human.current_phase, human.global_position.x, bee.health.current_health, human.hitbox.monitoring, " ".join(parts)])
			last_phase = human.current_phase
		if bee.health.current_health < 100 and i > 70:
			break
	quit(0)
