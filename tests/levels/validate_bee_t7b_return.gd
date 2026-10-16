extends "res://tests/levels/bee_t7b_fixture.gd"
func run() -> void:
	var stage := await fixture()
	var boss := spider(stage)
	for cancel in [false, true]:
		boss.state = TarantulaBoss01.State.PHASE_2
		boss.mode = &"hang"
		boss.side = 1
		boss._swing = 0.5
		boss.global_position = Vector3(294, 3.5, 0)
		boss.hang_pivot_x = 294
		boss._apply_pose()
		var start := boss.global_position
		var basis := boss.visual_root.basis
		if cancel: boss._cancel_attack()
		else: boss._end_hang()
		check(boss.global_position.is_equal_approx(start) and boss.visual_root.basis.is_equal_approx(basis), "Starting return/cancelling a phase never teleports or flips")
		var prior := start
		for i in 30:
			boss._update_hang_return(TarantulaBoss01.HANG_UP / 30.0)
			check(boss.global_position.distance_to(prior) < 0.4, "Return has bounded continuous movement")
			prior = boss.global_position
		boss._update_hang_return(0.00001)
		check(boss.mode == &"ceiling" and is_equal_approx(boss._flip, PI), "Return finishes in normal ceiling pose")
		check(not boss._charge_box.enabled, "Return never reactivates the swing hitbox")
	done()
