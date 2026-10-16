extends "res://tests/levels/bee_t7b_fixture.gd"
func run() -> void:
	var stage := await fixture()
	var baseline := BeeLevel01Framing.bottom_y()
	var actor := robot(stage)
	var ground := actor.global_position
	for i in 45: stage._update_camera_and_bounds()
	check(BeeLevel01Framing.bottom_y() < baseline - 1.3, "Robot arena gains lower-edge clearance")
	check(actor.global_position == ground and actor.health.max_health == 600, "Camera never changes Robot floor, depth or health")
	check(is_equal_approx(stage.camera.fov, BeeLevel01Framing.effective_fov()) and is_equal_approx(stage.camera.position.y, BeeLevel01Framing.effective_height()), "Camera and all framing formulas share the effective view")
	var minimum_clearance := INF
	for yaw in [-PI / 3.0, PI / 3.0]:
		actor.visual_root.rotation.y = yaw
		for crouch in [0.0, -0.25]:
			actor.visual_root.position.y = crouch
			actor._play(&"Walk")
			for time in [0.0, 0.25, 0.5, 0.75]:
				actor.animation_player.seek(time, true)
				for point in preload("res://tools/bee_boss_pose_probe.gd").vertices(actor.visual_root):
					minimum_clearance = minf(minimum_clearance, root.size.y - stage.camera.unproject_position(point).y)
	check(minimum_clearance >= root.size.y * 0.035, "Actual skinned feet retain at least 3.5 percent bottom clearance in both facings/crouch")
	print("ROBOT_MIN_BOTTOM_PX ", minimum_clearance, " viewport_height=", root.size.y)
	var dressing := stage.get_node("AssetDressing")
	var can: Node3D
	for item in dressing.litter:
		if is_equal_approx(item.position.x, 301.0): can = item
	check(can != null and AssetFauna._bounds(can, stage).end.z < -8.0, "Only the arena's can is pushed deeper by its whole mesh")
	actor.health.current_health = 0
	for i in 45: stage._update_camera_and_bounds()
	check(is_equal_approx(BeeLevel01Framing.bottom_y(), baseline), "Normal view returns after Robot")
	done()
