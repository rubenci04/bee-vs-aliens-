extends SceneTree
## DEV ONLY (diagnostic, changes nothing in the game). Real-play approach probe for the Giant Human:
## Bee flies +X at her real speed through the crossing at several heights and start timings, with
## the real level running its physics. For every damage it reports the hitbox the engine blamed and
## how far Bee's centre was from the VISIBLE (skinned, camera-projected) silhouette of the human.
## Run headless: godot --headless --path . --script res://dev/diagnostics/human_approach_probe.gd

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const HEIGHTS := [0.8, 1.4, 2.0, 2.6, 3.2, 3.8, 4.2]
const START_OFFSETS := [4.0, 7.0, 10.0] # Human distance to the camera centre when Bee starts flying.

var stage: BeeShmupStage
var human: GiantHumanCrossingHazard
var bee: BeePlayer
var debug: GiantHumanHitboxDebug

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

## Distance from p to the union of the human's visible, camera-projected triangles (0 = covered).
func silhouette_distance(p: Vector2) -> float:
	var skeleton: Skeleton3D = human.get_node("VisualRoot/Hipster/Rig/Skeleton3D")
	var camera_position := stage.camera.global_position
	var best := INF
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", false, false):
		if not mesh.visible or mesh.skin == null:
			continue
		var skin := mesh.skin
		var palette: Array[Transform3D] = []
		for bind in skin.get_bind_count():
			var bone := skin.get_bind_bone(bind)
			if bone < 0:
				bone = skeleton.find_bone(skin.get_bind_name(bind))
			palette.append(skeleton.global_transform * skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(bind))
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var stride := bones.size() / vertices.size()
			var projected := PackedVector2Array()
			projected.resize(vertices.size())
			for i in vertices.size():
				var skinned := Vector3.ZERO
				for k in stride:
					if weights[i * stride + k] > 0.0:
						skinned += (palette[bones[i * stride + k]] * vertices[i]) * weights[i * stride + k]
				var scale := camera_position.z / maxf(camera_position.z - skinned.z, 0.5)
				projected[i] = Vector2(camera_position.x + (skinned.x - camera_position.x) * scale, camera_position.y + (skinned.y - camera_position.y) * scale)
			for t in range(0, indices.size(), 3):
				var a := projected[indices[t]]
				var b := projected[indices[t + 1]]
				var c := projected[indices[t + 2]]
				if Geometry2D.point_is_inside_triangle(p, a, b, c):
					return 0.0
				for edge in [[a, b], [b, c], [c, a]]:
					best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, edge[0], edge[1])))
	return best

func trial(height: float, offset: float) -> Dictionary:
	bee.health.current_health = bee.health.max_health
	human.hitbox.set_enabled(false)
	human.visual_root.hide()
	human.current_phase = GiantHumanCrossingHazard.Phase.EXITED
	await frames(3)
	human.hit_count = 0
	debug.damage_events.clear()
	assert(human.begin_crossing(stage.camera))
	var camera_x := stage.camera.global_position.x
	var launched := false
	var result := {"damaged": false}
	for i in 1500:
		if not launched and human.global_position.x - camera_x <= offset:
			launched = true
		var next_x := bee.global_position.x
		if launched:
			next_x = minf(next_x + bee.horizontal_speed / 60.0, camera_x + stage.screen_right)
		else:
			next_x = camera_x + stage.screen_left
		bee.global_position = Vector3(next_x, height, 0)
		await physics_frame
		if debug.damage_events.size() > 0 and not result["damaged"]:
			await physics_frame
			var event: Dictionary = debug.damage_events[0]
			var bee_xy := Vector2(event["bee"].x, event["bee"].y)
			result = {"damaged": true, "shapes": event["engine_shapes"], "rel_x": event["bee"].x - event["human_x"], "silhouette_distance": silhouette_distance(bee_xy)}
			break
		if human.current_phase == GiantHumanCrossingHazard.Phase.EXITED:
			break
	await frames(30)
	return result

func run() -> void:
	create_timer(300.0, true, false, true).timeout.connect(func(): quit(1))
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	stage.scroll_speed = 0.0
	stage.distance = 140.0
	stage._update_camera_and_bounds()
	await frames(3)
	(stage.wave as Node).set_physics_process(false)
	bee = stage.bee
	bee.set_physics_process(false)
	human = stage.get_node("GiantHuman") as GiantHumanCrossingHazard
	debug = stage.get_node("HumanHitboxDebug") as GiantHumanHitboxDebug
	print("PROBE bee radius=0.28 hurtbox, screen_left=%.2f screen_right=%.2f" % [stage.screen_left, stage.screen_right])
	var safe := 0
	var total := 0
	for height in HEIGHTS:
		for offset in START_OFFSETS:
			var r := await trial(height, offset)
			total += 1
			if r["damaged"]:
				print("PROBE y=%.1f start_human_dx=%.0f -> DAMAGE %s bee_minus_human_x=%.2f dist_to_visible_silhouette=%.2f" % [height, offset, r["shapes"], r["rel_x"], r["silhouette_distance"]])
			else:
				safe += 1
				print("PROBE y=%.1f start_human_dx=%.0f -> safe" % [height, offset])
	print("PROBE SUMMARY safe=%d of %d" % [safe, total])
	quit(0)
