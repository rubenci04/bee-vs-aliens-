extends SceneTree

# GIANT HUMAN CORRIDOR FIX 01: the corridor between the legs is safe for the whole crossing,
# feet/torso still hurt (20 HP, once per crossing), and speed/targetability are unchanged.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const LEG_PARTS := ["LeftFoot", "RightFoot"] # Thighs and calves no longer damage (CHALLENGE & BALANCE PASS 01).

var stage: BeeShmupStage
var human: GiantHumanCrossingHazard
var bee: BeePlayer

func _initialize() -> void:
	BeeLevel01Controller.giant_human_enabled = true # NOCHE 01: the human is off in the game (GIANT_HUMAN_ENABLED); this test covers it.
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func collider(part: String) -> CollisionShape3D:
	return human.get_node("ContactHitbox/" + part)

func world_points(part: String) -> PackedVector3Array:
	var node := collider(part)
	var result := PackedVector3Array()
	for point in (node.shape as ConvexPolygonShape3D).points:
		result.append(node.global_transform * point)
	return result

## Bee follows the human's centre line (plus offset) for the whole crossing; returns damage taken.
func fly_with_human(height: float, offset: float) -> int:
	bee.health.current_health = bee.health.max_health
	human.hit_count = 0
	check(human.begin_crossing(stage.camera), "Crossing rejected")
	var crossing_frames := 0
	for i in 1500:
		bee.global_position = Vector3(human.global_position.x + offset, height, 0)
		await frames(1)
		if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING:
			crossing_frames += 1
		if human.current_phase == GiantHumanCrossingHazard.Phase.EXITED:
			break
	check(crossing_frames > 400, "Crossing did not run to the end")
	return bee.health.max_health - bee.health.current_health

## Freezes the Run clip at a wide-stride pose with physics still live.
func freeze_pose(seek: float) -> void:
	check(human.begin_crossing(stage.camera), "Pose crossing rejected")
	for i in 100:
		if human.current_phase == GiantHumanCrossingHazard.Phase.CROSSING:
			break
		bee.global_position = Vector3(human.global_position.x, 0.9, 0)
		await frames(1)
	human.animation_player.seek(seek, true)
	human.animation_player.advance(0.0)
	human._physics_process(0.0)
	human.set_physics_process(false)
	human.animation_player.pause()
	await frames(2)

func end_pose() -> void:
	human.hitbox.set_enabled(false)
	human.visual_root.hide()
	human.current_phase = GiantHumanCrossingHazard.Phase.EXITED
	human.set_physics_process(true)
	human.animation_player.stop()

func run() -> void:
	create_timer(240.0, true, false, true).timeout.connect(func(): quit(1))
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	stage.set_physics_process(false)
	(stage.wave as Node).set_physics_process(false)
	bee = stage.bee
	bee.set_physics_process(false)
	human = stage.get_node("GiantHuman") as GiantHumanCrossingHazard

	# 1. Unchanged: speed, 20 damage, not targetable/shootable.
	check(is_equal_approx(human.crossing_speed, 2.6) and is_equal_approx(human.second_crossing_speed, 2.4), "Human speed changed")
	check(human.hitbox.damage == 20, "Human damage is not 20")
	check(human.find_children("*", "HealthComponent", true, false).is_empty() and human.find_children("*", "DamageHurtbox3D", true, false).is_empty(), "Human became shootable")

	# 2. Bee flying the corridor centre never takes damage, at every height up to the pelvis.
	for height in [0.9, 2.0, 3.2, 4.1]:
		check(await fly_with_human(height, 0.0) == 0, "Corridor centre damaged Bee at y=%.1f" % height)
	for offset in [-0.6, 0.6]:
		check(await fly_with_human(2.4, offset) == 0, "Corridor edge damaged Bee at dx=%.1f" % offset)

	# 3. Wide stride: nothing hurts inside the visible gap between the legs, and legs stay outside
	#    the central column.
	await freeze_pose(0.2)
	var enabled_legs := 0
	for part in LEG_PARTS:
		if collider(part).disabled:
			continue
		enabled_legs += 1
		for point in world_points(part):
			check(absf(point.x - human.global_position.x) >= safe_half_width() - 0.01, part + " reaches into the central corridor")
	check(enabled_legs >= 2, "Wide-stride pose lost its shoe envelopes")
	var torso_bottom := 99.0
	for point in world_points("Torso"):
		torso_bottom = minf(torso_bottom, point.y)
	check(torso_bottom > 4.3, "Torso envelope hangs into the visible gap (bottom y=%.2f)" % torso_bottom)
	var hp := bee.health.current_health
	bee.global_position = Vector3(human.global_position.x, 3.6, 0)
	await frames(30)
	check(bee.health.current_health == hp and human.hit_count == 0, "Bee in the gap between the thighs was damaged")
	end_pose()

	# 4. Touching a foot / the torso still costs exactly 20 HP, once per crossing.
	for part in ["LeftFoot", "RightFoot", "Torso"]:
		await freeze_pose(0.2)
		var node := collider(part)
		check(not node.disabled, "Contact envelope absent for " + part)
		bee.global_position = node.global_position
		hp = bee.health.current_health
		var hits := human.hit_count
		await frames(20)
		check(bee.health.current_health == hp - 20 and human.hit_count == hits + 1, part + " must cause exactly one 20 HP hit")
		await frames(20)
		check(bee.health.current_health == hp - 20, part + " repeated damage during the same crossing")
		end_pose()
	print("GIANT_HUMAN_CORRIDOR_OK safe_half_width=", safe_half_width())
	quit(0)

func safe_half_width() -> float:
	return float((human.get_script() as GDScript).get_script_constant_map()["SAFE_HALF_WIDTH"])
