extends "res://tests/levels/bee_t7b_fixture.gd"
func run() -> void:
	var stage := await fixture()
	var boss := spider(stage)
	for side in [-1.0, 1.0]:
		for swing in [-0.5, 0.0, 0.5]:
			for mode in [&"ceiling", &"hang"]:
				boss.side = side
				boss.mode = mode
				boss._flip = PI
				boss._swing = swing
				boss.global_position = Vector3(294, BeeLevel01Framing.top_y(), 0)
				boss._apply_pose()
				var bounds: AABB = boss._visual_bounds
				for i in 8:
					var local := bounds.get_endpoint(i)
					var world := boss.global_position + boss.visual_root.basis * local
					check(world.y <= boss._ceiling_y() + 0.001, "Whole pose stays below safe ceiling in both orientations")
					check(stage.camera.unproject_position(world).y >= 0, "No upper vertex leaves camera")
	check(boss._ceiling_y() < BeeLevel01Framing.top_y() - 1.0, "Ceiling is inside camera with HUD safety space")
	done()
