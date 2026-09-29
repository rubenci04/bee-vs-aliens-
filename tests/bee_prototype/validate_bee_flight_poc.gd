extends SceneTree

const POC := preload("res://scenes/bee_prototype/bee_flight_poc.tscn")


func _initialize() -> void:
	call_deferred("run_checks")


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)


func frames(count: int) -> void:
	for index in count:
		await physics_frame


func release_flight_input() -> void:
	for action in [&"move_left", &"move_right", &"move_forward", &"move_back", &"throw_orange"]:
		Input.action_release(action)


func run_checks() -> void:
	create_timer(45.0).timeout.connect(func(): quit(1))
	check(POC != null, "Bee Flight POC scene failed to load")
	var poc := POC.instantiate()
	root.add_child(poc)
	current_scene = poc
	await frames(5)

	var bee := poc.get_node("BeePlayer") as BeePlayer
	var enemy := poc.get_node("AlienProbeEnemy") as AlienProbeEnemy
	check(bee != null and bee is CharacterBody3D, "BeePlayer is missing or wrong body type")
	check(bee.health.max_health == 100 and bee.health.current_health == 100, "BeePlayer HP changed")
	var idle_y := bee.position.y
	await frames(4)
	check(is_equal_approx(bee.position.y, idle_y) and is_zero_approx(bee.velocity.z), "BeePlayer should have no gravity")
	check(is_equal_approx(bee.horizontal_speed, 7.0) and is_equal_approx(bee.vertical_speed, 6.0), "Flight speeds changed")
	check(bee.position.z == 0.0, "BeePlayer left the fixed gameplay plane")

	var start := bee.position
	Input.action_press("move_right")
	await frames(8)
	Input.action_release("move_right")
	check(bee.position.x > start.x, "Horizontal flight failed")
	var after_horizontal := bee.position
	Input.action_press("move_forward")
	await frames(8)
	Input.action_release("move_forward")
	check(bee.position.y > after_horizontal.y, "W/up did not move upward on screen")
	Input.action_press("move_back")
	await frames(8)
	Input.action_release("move_back")
	check(bee.position.y < bee.flight_max.y, "S/down flight failed")
	release_flight_input()

	bee.position = Vector3(99, -5, 2)
	bee.velocity = Vector3.ZERO
	await frames(2)
	check(bee.position.x <= bee.flight_max.x and bee.position.y >= bee.flight_min.y and bee.position.z == 0.0, "Flight bounds failed")

	# With no valid target in range, X fires straight according to facing.
	bee.position = Vector3(-8, 3, 0)
	bee.facing_x = 1.0
	enemy.position = Vector3(7, 6, 0)
	enemy.set_physics_process(false)
	await frames(2)
	check(bee.refresh_auto_aim() == null, "Out-of-range enemy was auto-aimed")
	var straight := bee.fire()
	check(straight != null and straight.travel_direction.is_equal_approx(Vector3.RIGHT), "No-target shot was not straight")
	straight.queue_free()
	await frames(2)

	# A living, visible enemy in the front cone becomes the contextual target.
	enemy.position = Vector3(4.5, 4.5, 0)
	bee.position = Vector3(0, 3, 0)
	bee.velocity = Vector3.ZERO
	await frames(2)
	check(bee.refresh_auto_aim() == enemy, "Auto-aim did not select the valid enemy")
	check(bee.target_indicator.visible, "Contextual target indicator is hidden")
	var aimed := bee.fire()
	check(aimed != null and aimed.travel_direction.x > 0.0 and aimed.travel_direction.y > 0.0, "Auto-aim shot direction is wrong")
	aimed.queue_free()
	await frames(2)

	# Real projectiles damage and kill the proxy through reusable hitbox/hurtbox components.
	enemy.position = Vector3(4, 3, 0)
	bee.position = Vector3(0, 3, 0)
	var expected_health := [15, 5, 0]
	for expected in expected_health:
		check(bee.refresh_auto_aim() == enemy, "Enemy stopped being a valid target before defeat")
		var projectile := bee.fire()
		check(projectile != null, "X failed to create an energy projectile")
		for frame in 45:
			if enemy.health.current_health == expected:
				break
			await physics_frame
		check(enemy.health.current_health == expected, "Directed projectile did not apply expected damage")
	check(enemy.is_defeated() and not enemy.is_active(), "Alien probe did not die")
	await frames(2)
	check(bee.refresh_auto_aim() == null and not bee.target_indicator.visible, "Dead enemy remained targeted")

	# Three pollen proxies feed the visible counter.
	var pickups := poc.get_node("Pollen").get_children()
	check(pickups.size() == 3, "POC must contain three pollen pickups")
	for pickup in pickups:
		check((pickup as BeePollenPickup).collect(bee), "Pollen could not be collected")
		await frames(1)
	check(poc.pollen_count == 3, "Pollen counter did not reach 3")
	check(poc.get_node("CanvasLayer/Panel/VBox/Pollen").text == "POLEN: 3/3", "Pollen UI did not update")
	check(poc.completion_shown and poc.get_node("CanvasLayer/Completion").visible, "POC loop did not complete")

	print("BEE_FLIGHT_POC_OK characterbody no_gravity xy_plane movement bounds x_projectile autoaim range=12 cone=80 straight_no_homing enemy_hp=25 damage=10 pollen=3")
	release_flight_input()
	current_scene = null
	poc.queue_free()
	await process_frame
	quit(0)