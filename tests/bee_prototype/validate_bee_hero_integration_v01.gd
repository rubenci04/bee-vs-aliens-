extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func run() -> void:
	BeeGameSettings.BEE_MODEL_VERSION = "v02"
	var host := Node3D.new()
	host.name = "IntegrationTestHost"
	root.add_child(host)
	var player_scene := load("res://scenes/bee_prototype/bee_player.tscn") as PackedScene
	var bee := player_scene.instantiate() as BeePlayer
	host.add_child(bee)
	for _i in 4:
		await process_frame
	var visual := bee.get_node("VisualRoot/BeeVisual") as Node3D
	var model := visual.get("model") as Node3D
	check(visual != null and str(visual.get("model_version")) == "v02", "Bee player must load v02 by default")
	for anchor in ["muzzle", "nozzle_L", "nozzle_R", "stinger_tip", "helmet_socket"]:
		check(model != null and model.find_child(anchor, true, false) != null, "Missing v02 anchor: "+anchor)
	check(is_equal_approx(bee.get_node("VisualRoot").scale.x, 1.0), "v02 visual scale must be 1.0")
	var nozzles: Dictionary = visual.get("nozzles")
	check(nozzles.size() == 2, "Both v02 thrusters should attach")
	for entry: Dictionary in nozzles.values():
		var particles := entry["particles"] as CPUParticles3D
		check(particles != null and particles.emitting and particles.visible, "Thrusters should emit in game")
		check(particles.color_ramp.colors[1].b < particles.color_ramp.colors[1].r, "Bee exhaust must stay warm")
	var body_shape := (bee.get_node("CollisionShape3D") as CollisionShape3D).shape as SphereShape3D
	var hurt_shape := (bee.get_node("Hurtbox3D/CollisionShape3D") as CollisionShape3D).shape as SphereShape3D
	check(is_equal_approx(body_shape.radius, 0.28), "Bee body collider changed")
	check(is_equal_approx(hurt_shape.radius, 0.2), "Bee hurtbox changed")
	var flash := bee.get_node("HitFlash3D") as HitFlash3D
	bee.health.take_damage(1)
	check(flash.is_flashing(), "Hit flash should start on v02")
	var mesh_count: int = model.find_children("*", "MeshInstance3D", true, false).size()
	var overlay_count := 0
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.material_overlay != null:
			overlay_count += 1
	check(mesh_count > 40 and overlay_count == mesh_count, "Hit flash must cover every v02 mesh, including metal")

	# Check muzzle projection on both yaw directions, plus unchanged free-aim direction.
	bee.facing_x = 1.0
	bee.visual_root.rotation.y = -PI * 0.5
	var right_origin: Vector3 = visual.call("firing_origin", bee.global_position)
	bee.facing_x = -1.0
	bee.visual_root.rotation.y = PI * 0.5
	var left_origin: Vector3 = visual.call("firing_origin", bee.global_position)
	check(right_origin.x > bee.global_position.x + 0.2 and left_origin.x < bee.global_position.x - 0.2, "Muzzle should face forward after yaw in both directions")
	bee.set_aim_point(bee.global_position + Vector3(3.0, 2.0, 0.0))
	var wanted := bee.aim_direction()
	var projectile := bee._spawn_projectile(wanted)
	check(projectile != null and projectile.global_position.distance_to(visual.call("firing_origin", bee.global_position)) < 0.001, "v02 projectile must spawn at muzzle")
	check(projectile != null and projectile.travel_direction.dot(wanted) > 0.999, "Muzzle change must preserve aim direction")
	visual.call("play_muzzle_effect", projectile.global_position, wanted)
	var blaster := visual.get("blaster") as Node3D
	await process_frame
	check(blaster.position != visual.get("_blaster_rest_position"), "A shot should recoil the antenna gun")

	check(bee.start_melee(), "Bee sting should start")
	model = visual.get("model") as Node3D
	check((model.find_child("AnimationPlayer", true, false) as AnimationPlayer).current_animation == "wingbeat", "T4g preserves wingbeat instead of playing drill_spin")
	check(model.find_child("Stinger", true, false).visible, "E1: cosmetic metal drill stinger visible")
	check(model.find_child("Stinger", true, false).find_children("*", "Area3D", true, false).is_empty(), "E1: cosmetic stinger has no hitbox")
	visual.call("sting_impact_effect", bee.melee_hitbox.global_position)
	check(host.find_child("PunchContactStar", true, false) != null and host.find_child("BeeDrillMetalTrail", true, false) == null, "Small contact star replaces drill trail")

	check(not bee.start_roll() and bee.sting_dash.queued_roll, "Roll should wait for sting")
	for _i in 90:
		if bee.is_rolling: break
		await physics_frame
	check(bee.is_rolling, "Queued roll should start after sting")
	check(bee.health.invulnerable and bee.is_rolling, "Roll remains invulnerable")
	var plate: Node = model.find_child("plates", true, false)
	check(plate != null and plate.find_children("*", "MeshInstance3D", true, false).any(func(m: MeshInstance3D): return m.material_overlay != null), "Roll should flash armor plates")
	await create_timer(0.08).timeout
	check(bool(visual.get("_last_blink_state")), "Roll should drive the full-model invulnerability blink")
	for _i in 24:
		await physics_frame
	check(not bee.is_rolling and not bee.health.invulnerable, "Roll should restore visibility and invulnerability state")
	check(model.visible, "Bee model should be visible after roll")

	# Runtime fallback reuses the exact v01 GLB and original scale; changing back is immediate.
	check(BeeGameSettings.set_bee_model_version("v01"), "v01 runtime switch should be accepted")
	await process_frame
	check(str(visual.get("model_version")) == "v01" and visual.get("muzzle") == null, "Runtime switch should load v01")
	check(is_equal_approx(bee.get_node("VisualRoot").scale.x, BeeGameSettings.BEE_V01_VISUAL_SCALE), "v01 should keep its original 1.2 visual multiplier")
	check(BeeGameSettings.set_bee_model_version("v02"), "v02 runtime switch should be accepted")
	await process_frame
	check(str(visual.get("model_version")) == "v02" and visual.get("muzzle") != null, "Runtime switch should restore v02 and its muzzle")
	check(not BeeGameSettings.set_bee_model_version("v03"), "Unknown Bee model version must be rejected")
	BeeGameSettings.BEE_MODEL_VERSION = "v02"
	print("BEE_HERO_INTEGRATION failures=", failures.size(), " v02/v01 muzzle yaw, aim, flash, thrusters, drill, roll")
	quit(0 if failures.is_empty() else 1)
