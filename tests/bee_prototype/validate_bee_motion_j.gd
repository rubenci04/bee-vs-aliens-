extends SceneTree

const PLAYER := preload("res://scenes/bee_prototype/bee_player.tscn")
const MOTION := preload("res://scripts/game/bee_motion_settings.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


func run() -> void:
	MOTION.enabled = true
	var bee := PLAYER.instantiate() as BeePlayer
	root.add_child(bee)
	bee.set_physics_process(false)
	await process_frame
	var visual = bee.get_node("VisualRoot/BeeVisual")
	var body_shape = (bee.get_node("CollisionShape3D") as CollisionShape3D).shape as SphereShape3D
	var hurt_shape = (bee.get_node("Hurtbox3D/CollisionShape3D") as CollisionShape3D).shape as SphereShape3D
	check(is_equal_approx(body_shape.radius, 0.28) and is_equal_approx(hurt_shape.radius, 0.2), "Body and hurt hitboxes unchanged")
	check(is_equal_approx(bee.horizontal_speed, 7.0) and is_equal_approx(bee.vertical_speed, 6.0) and bee.melee_damage == 30, "Speed caps and melee damage unchanged")
	var desired := Vector2(bee.horizontal_speed, 0.0)
	var first := bee._flight_velocity_step(Vector2.ZERO, desired, 1.0 / 60.0)
	var at_limit := bee._flight_velocity_step(Vector2.ZERO, desired, MOTION.INPUT_RESPONSE_LIMIT_SECONDS)
	check(first.x > 0.0 and at_limit.x >= desired.x * 0.70, "Input responds within 80 ms")
	var braking := bee._flight_velocity_step(desired, Vector2.ZERO, 1.0 / 60.0)
	check(braking.x > 0.0 and braking.x < desired.x, "Brake is gradual")
	bee.velocity = Vector3(bee.horizontal_speed, bee.vertical_speed, 0.0)
	for i in 50:
		visual._update_flight_tilt(1.0 / 60.0)
	check(absf(visual._flight_tilt.x) <= deg_to_rad(MOTION.PITCH_MAX_DEGREES) + 0.001, "Pitch is limited")
	check(absf(visual._flight_tilt.z) <= deg_to_rad(MOTION.ROLL_MAX_DEGREES) + 0.001, "Roll is limited")
	check(absf(visual._flight_tilt.y) <= deg_to_rad(MOTION.TURN_ARC_DEGREES) + 0.001, "Yaw arc is limited")
	check(visual.nozzles.size() == 2, "Both nozzles are present")
	bee.velocity = Vector3.ZERO
	visual._last_velocity = Vector3.ZERO
	visual.elapsed = 0.0
	visual._update_thrusters(1.0 / 60.0)
	var idle: float = visual.nozzles["L"]["intensity"]
	bee.velocity = Vector3(bee.horizontal_speed, 0.0, 0.0)
	visual._update_thrusters(1.0 / 60.0)
	var thrust: float = visual.nozzles["L"]["intensity"]
	check(thrust > idle + 0.15, "Thruster grows with acceleration")
	check(visual.nozzles["L"]["particles"].mesh is QuadMesh, "Thruster has a soft textured quad")
	check(visual._wing_hz() > MOTION.WING_IDLE_HZ, "Wings speed up under effort")
	visual._shot_left = MOTION.WING_SHOT_SECONDS
	check(visual._wing_hz() > MOTION.WING_EFFORT_HZ, "Wings vibrate after a shot")
	check(is_equal_approx(bee.roll_cooldown, 1.2), "Existing roll cooldown stays at 1.2 s")
	check(bee.start_roll(), "First roll starts")
	check(not bee.start_roll(), "Roll cannot restart during cooldown")
	check(visual.motion_trail != null and visual.motion_trail.mesh is QuadMesh, "Roll has a soft trail")
	bee._update_roll(bee.roll_duration + 0.01)
	check(not bee.start_roll(), "Roll cooldown still blocks after animation")
	bee._update_roll(bee.roll_cooldown)
	check(bee.start_roll(), "Roll starts again after cooldown")
	MOTION.enabled = false
	visual._update_motion_pose(1.0 / 60.0)
	check(visual.model.scale.is_equal_approx(visual._model_rest_scale), "Legacy switch restores model pose")
	MOTION.enabled = true
	bee.queue_free()
	await process_frame
	print("BEE_MOTION_J_OK" if failures == 0 else "BEE_MOTION_J_FAILED %d" % failures)
	quit(0 if failures == 0 else 1)
