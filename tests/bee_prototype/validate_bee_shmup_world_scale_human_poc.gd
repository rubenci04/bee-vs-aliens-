extends SceneTree

const POC := preload("res://scenes/bee_prototype/bee_shmup_world_scale_human_poc.tscn")
var scene: BeeShmupStage
var bee: BeePlayer
var hazard: GiantHumanCrossingHazard

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func until_phase(phase: int, limit := 1800) -> bool:
	for i in limit:
		if hazard.current_phase == phase:
			return true
		await frames(1)
	return false

func capture_runtime(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	check(image.save_png("res://dev/world_scale_human_review/" + filename) == OK, "Capture failed")

func run() -> void:
	create_timer(115.0).timeout.connect(func(): quit(1))
	scene = POC.instantiate() as BeeShmupStage
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	bee = scene.bee
	hazard = scene.get_node("GiantHuman") as GiantHumanCrossingHazard
	check(bee != null and hazard != null and is_equal_approx(scene.scroll_speed, 2.0) and is_equal_approx(scene.sector_length, 78.0), "Scene setup wrong")
	check(scene.get_node("Pollen").get_child_count() == 5 and scene.get_node("WorldScenery").get_child_count() >= 10, "World-scale props/pollen missing")
	check(hazard.current_phase == GiantHumanCrossingHazard.Phase.WAITING and not hazard.visual_root.visible and not hazard.hitbox.enabled, "WAITING state wrong")
	check(not hazard.is_in_group("bee_auto_aim_targets") and hazard.get_node_or_null("HealthComponent") == null and bee.refresh_auto_aim() == null, "Human is targetable/has enemy health")
	check(hazard.animation_player != null and hazard.animation_player.has_animation(&"Run") and hazard.visual_root.scale == Vector3.ONE * 6.0, "Reused giant Run/scale missing")
	check(is_equal_approx(hazard.animation_player.get_animation(&"Run").length, 0.8) and is_equal_approx(hazard.run_playback_speed, 0.72), "Run timing wrong")
	check(is_equal_approx(hazard.crossing_speed, 2.6) and is_equal_approx(hazard.second_crossing_speed, 2.4), "Crossing speed wrong")
	check(hazard.hitbox.damage == 20 and is_equal_approx(hazard.telegraph_seconds, 1.0), "Damage/telegraph wrong")
	check(hazard.hitbox.get_child_count() == 3 and hazard.hitbox.get_node_or_null("LeftLeg") != null and hazard.hitbox.get_node_or_null("RightLeg") != null and hazard.hitbox.get_node_or_null("Torso") != null, "Leg gap/torso shapes missing")
	var left_shape := hazard.hitbox.get_node("LeftLeg") as CollisionShape3D
	var right_shape := hazard.hitbox.get_node("RightLeg") as CollisionShape3D
	var gap_width := right_shape.position.x - (right_shape.shape as BoxShape3D).size.x * 0.5 - (left_shape.position.x + (left_shape.shape as BoxShape3D).size.x * 0.5)
	check(gap_width > 1.5 and bee.get_node_or_null("Hurtbox3D") != null, "Gap is too narrow for Bee")
	check(await until_phase(GiantHumanCrossingHazard.Phase.TELEGRAPH), "First telegraph missing")
	check(scene.warning.visible and not hazard.hitbox.enabled and not hazard.visual_root.visible, "Telegraph warning/safety wrong")
	await capture_runtime("human_warning.png")
	check(await until_phase(GiantHumanCrossingHazard.Phase.CROSSING), "First crossing missing")
	check(not scene.warning.visible and hazard.visual_root.visible and hazard.hitbox.enabled and hazard.animation_player.current_animation == "Run" and is_equal_approx(hazard.animation_player.speed_scale, 0.72), "Crossing/Run wrong")
	check(is_equal_approx(hazard.current_crossing_speed, 2.6), "First crossing speed wrong")
	for i in 240:
		if hazard.global_position.x <= scene.camera.global_position.x + 3.5:
			break
		await frames(1)
	check(hazard.global_position.x <= scene.camera.global_position.x + 3.5, "Human never became visible")
	await capture_runtime("human_scale.png")
	await capture_runtime("human_legs_gap.png")
	bee.velocity = Vector3.ZERO
	var hp := bee.health.current_health
	for i in 28:
		bee.global_position = Vector3(hazard.global_position.x, 1.35, 0.0)
		await frames(1)
		if i == 2:
			await capture_runtime("bee_between_legs.png")
	check(bee.health.current_health == hp and hazard.hit_count == 0, "Bee took damage in visual leg gap")
	bee.global_position = Vector3(hazard.global_position.x + right_shape.position.x, 1.35, 0.0)
	for i in 12:
		if bee.health.current_health < hp: break
		await frames(1)
	check(bee.health.current_health == hp - 20 and hazard.hit_count == 1, "Leg contact did not deal exactly 20")
	await capture_runtime("bee_hits_leg.png")
	await frames(12)
	check(bee.health.current_health == hp - 20, "Contact damage repeated every frame")
	bee.global_position = Vector3(scene.camera.global_position.x - 4.0, 1.35, 0.0)
	check(await until_phase(GiantHumanCrossingHazard.Phase.EXITED), "Human did not exit")
	check(hazard.crossings_exited == 1 and not hazard.hitbox.enabled and not hazard.visual_root.visible, "First exit cleanup failed")
	check(await until_phase(GiantHumanCrossingHazard.Phase.TELEGRAPH), "Second crossing did not start")
	check(hazard.crossings_started == 2, "Second crossing counter wrong")
	check(is_equal_approx(hazard.current_crossing_speed, 2.4) and is_equal_approx(hazard.animation_player.speed_scale, 0.66), "Second crossing variation missing")
	bee.global_position = Vector3(scene.camera.global_position.x, 6.5, 0)
	check(await until_phase(GiantHumanCrossingHazard.Phase.CROSSING), "Second crossing did not enter")
	check(await until_phase(GiantHumanCrossingHazard.Phase.EXITED), "Second crossing did not exit")
	await frames(2)
	check(hazard.crossings_exited == 2 and scene.wave.is_complete(), "Progression blocked after second crossing")
	check(bee.refresh_auto_aim() == null, "Human became auto-aim target")
	var pollen := scene.get_node("Pollen/PollenE") as BeePollenPickup
	var before_heal := bee.health.current_health
	check(pollen.collect(bee), "Optional pollen could not be collected")
	await frames(2)
	check(bee.health.current_health == mini(before_heal + 20, 100), "Pollen healing failed")
	for i in 1600:
		if scene.sector_complete:
			break
		await frames(1)
	check(scene.sector_complete and scene.status.text == "SECTOR DESPEJADO", "Sector did not complete")
	bee.health.take_damage(1000)
	await frames(2)
	check(bee.is_defeated and scene.status.text.contains("PLAYER DOWN"), "Defeat missing")
	var previous_id := scene.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(4)
	check(current_scene.get_instance_id() != previous_id, "R did not reload scene")
	var reset := current_scene as BeeShmupStage
	var reset_hazard := reset.get_node("GiantHuman") as GiantHumanCrossingHazard
	check(reset.distance < 0.5 and reset_hazard.current_phase == GiantHumanCrossingHazard.Phase.WAITING and reset_hazard.crossings_started == 0, "Scroll/hazard restart failed")
	check(reset.bee.health.current_health == 100 and reset.get_node("Pollen").get_child_count() == 5, "Bee/pollen restart failed")
	check(reset_hazard.begin_crossing(reset.camera), "Torso test crossing failed to start")
	for i in 100:
		if reset_hazard.current_phase == GiantHumanCrossingHazard.Phase.CROSSING: break
		await frames(1)
	check(reset_hazard.current_phase == GiantHumanCrossingHazard.Phase.CROSSING, "Torso test crossing failed to activate")
	for i in 240:
		if reset_hazard.global_position.x <= reset.camera.global_position.x + 3.5: break
		await frames(1)
	reset.bee.global_position = Vector3(reset_hazard.global_position.x, 5.0, 0.0)
	var torso_hp := reset.bee.health.current_health
	for i in 10:
		if reset.bee.health.current_health < torso_hp: break
		await frames(1)
	check(reset.bee.health.current_health == torso_hp - 20, "Torso contact did not damage Bee")
	print("BEE_SHMUP_WORLD_SCALE_HUMAN_OK giant_run two_crossings leg_gap leg_torso once_per_contact restart")
	quit(0)
