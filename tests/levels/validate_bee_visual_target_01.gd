extends SceneTree

# VISUAL LEVEL 01 contract: decoration only, one flat style over the whole level, readable
# playfield, continuous ground/background (no cut), smooth time-of-day progression.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const FLOWER_KEYS := ["petal_pink", "petal_warm", "petal_violet"]

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func world_vertices(mesh: MeshInstance3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	for s in mesh.mesh.get_surface_count():
		for v: Vector3 in mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
			result.append(mesh.global_transform * v)
	return result

func color_distance(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)

func run() -> void:
	create_timer(90.0, true, false, true).timeout.connect(func(): quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 3:
		await process_frame
	var target := stage.get_node("VisualTarget01") as BeeLevel01VisualTarget
	check(target != null and target.batches.size() > 100, "Visual target decoration missing")
	check(target.get_child_count() < 600, "Decoration must be merged into batches, not thousands of nodes (%d)" % target.get_child_count())
	check(target.find_children("*", "CollisionObject3D", true, false).is_empty(), "Decoration must not collide")

	# Imported props: hidden everywhere (never deleted); gameplay props stay visible.
	var scenery := stage.get_node("Scenery")
	check(scenery.get_child_count() == 350, "Existing scenery must be kept (hidden, not deleted)")
	for child: Node3D in scenery.get_children():
		var label := str(child.name)
		var replaced := false
		for prefix: String in BeeLevel01VisualTarget.HIDDEN_SCENERY_PREFIXES:
			replaced = replaced or label.begins_with(prefix)
		check(child.visible != replaced, "Scenery visibility wrong for " + label)
	check(target.hidden_scenery.size() > 250, "Trees, ferns and Kenney flowers must be hidden along the whole level")
	for label in ["GiantBottle", "DistantBottle", "FallenLog", "FlightRock96", "FlightRock307", "BackdropRock38"]:
		var node := scenery.get_node_or_null(label) if scenery.has_node(label) else scenery.get_node_or_null(label + "Mesh")
		check(node != null and (node as Node3D).visible, "Gameplay prop must stay visible: " + label)

	# Flat colours, no cyan, readable layers, flower heads out of the play band.
	var foreground_limit_ok := true
	var coverage := {}
	var flower_vertices := 0
	var min_x := INF
	var max_x := -INF
	var all_meshes: Array = target.find_children("*", "MeshInstance3D", true, false)
	for mesh: MeshInstance3D in all_meshes:
		var material := mesh.material_override as StandardMaterial3D
		check(material != null and material.albedo_texture == null, "Decoration must use flat colours: " + mesh.name)
		var c := material.albedo_color
		check(not (c.h > 0.42 and c.h < 0.56 and c.s > 0.35), "Cyan is reserved for alien tech: " + mesh.name)
		var is_flower := false
		for key in FLOWER_KEYS:
			is_flower = is_flower or str(mesh.name).contains(key)
		var is_ground_cover := str(mesh.name).contains("_pebble") or str(mesh.name).contains("_grass") or str(mesh.name).contains("_stem")
		for v in world_vertices(mesh):
			if mesh.name != &"MulchGround":
				min_x = minf(min_x, v.x)
				max_x = maxf(max_x, v.x)
			if is_ground_cover:
				coverage[int(floorf(v.x / 20.0))] = true
			if is_flower:
				flower_vertices += 1
				check(v.z <= -5.0, "Flower head enters the play band (z=%.2f)" % v.z)
			if v.z > BeeLevel01VisualTarget.FOREGROUND_MIN_Z:
				if v.y > BeeLevel01VisualTarget.foreground_height_limit(v.z) + 0.001:
					foreground_limit_ok = false
			elif absf(v.z) < BeeLevel01VisualTarget.MIDGROUND_CLEAR_Z and v.y > 0.35:
				check(false, "Midground must stay clear: " + mesh.name)
	check(foreground_limit_ok, "Foreground covers the playfield")
	check(flower_vertices > 0 and target.flower_head_count >= 30, "Expected faceted flower heads along the level (%d)" % target.flower_head_count)
	check(target.foreground_nodes.size() >= 8, "Expected foreground leaves along the whole level")

	# No cut: ground cover in every 20 m window of the level, and decoration past both ends.
	for window in range(0, 19):
		check(coverage.has(window), "Gap in decoration at x=%d..%d" % [window * 20, window * 20 + 20])
	check(min_x < -20.0 and max_x > 390.0, "Decoration does not reach the level ends (%.0f..%.0f)" % [min_x, max_x])
	var slab := target.get_node("MulchGround") as MeshInstance3D
	var bounds := slab.global_transform * slab.get_aabb()
	check(bounds.position.x <= -15.0 and bounds.end.x >= 380.0, "Ground slab must cover the whole level")

	# Ground life (POLISH-02): MultiMesh litter, no collision, nothing tall in the midground, never cyan.
	var life := stage.get_node("GroundLife01") as BeeLevel01GroundLife
	check(life != null and life.instance_total >= 300 and life.batches.size() >= 30, "Ground life missing (%d instances)" % (life.instance_total if life != null else 0))
	check(life.find_children("*", "CollisionObject3D", true, false).is_empty() and life.find_children("*", "MeshInstance3D", true, false).is_empty(), "Ground life must be MultiMesh only, without collision")
	var life_windows := {}
	var life_cyan := 0
	for record: Dictionary in life.records:
		var batch := record["node"] as MultiMeshInstance3D
		var box := (record["mesh"] as Mesh).get_aabb()
		for k in (record["transforms"] as Array).size():
			var transform: Transform3D = (record["transforms"] as Array)[k]
			var colour: Color = (record["colors"] as Array)[k]
			if colour.h > 0.42 and colour.h < 0.56 and colour.s > 0.35:
				life_cyan += 1
			transform = batch.global_transform * transform
			life_windows[int(floorf(transform.origin.x / 40.0))] = true
			for corner in 8:
				var point := transform * (box.position + box.size * Vector3(corner & 1, (corner >> 1) & 1, (corner >> 2) & 1))
				check(point.z <= -3.0 or point.z >= 0.6, "Ground life inside the flight band: " + str(batch.name))
				if absf(point.z) < BeeLevel01VisualTarget.MIDGROUND_CLEAR_Z + 0.5:
					check(point.y <= 0.35 or point.z <= -BeeLevel01VisualTarget.MIDGROUND_CLEAR_Z, "Ground life too tall near the midground: %s y=%.2f z=%.2f" % [batch.name, point.y, point.z])
				if point.z > 0.0:
					check(point.y <= 0.35, "Front litter too tall: %s y=%.2f" % [batch.name, point.y])
	check(life_cyan == 0, "Cyan is reserved for alien tech (ground life)")
	for window in range(0, 9):
		check(life_windows.has(window), "No ground life around x=%d" % (window * 40))

	# Fog and shadows still start behind the playfield.
	var env := (stage.get_node("WorldEnvironment") as WorldEnvironment).environment
	check(env.fog_enabled and env.fog_mode == Environment.FOG_MODE_DEPTH and env.fog_depth_begin > BeeLevel01Framing.CAMERA_DISTANCE + 2.5, "Depth fog must start behind the playfield")
	check((stage.get_node("Sun") as DirectionalLight3D).shadow_enabled, "Sun shadows off")

	# Time of day: morning -> golden midday -> sunset, no jumps.
	var morning := BeeLevel01LightProgression.settings_at(0.0)
	var midday := BeeLevel01LightProgression.settings_at(195.0)
	var sunset := BeeLevel01LightProgression.settings_at(330.0)
	check(color_distance(morning["sun_color"], BeeLevel01LightProgression.MORNING["sun_color"]) < 0.001, "x=0 is not the approved morning")
	check(color_distance(midday["sun_color"], BeeLevel01LightProgression.MIDDAY["sun_color"]) < 0.001, "x=195 is not midday")
	check(color_distance(sunset["sun_color"], BeeLevel01LightProgression.SUNSET["sun_color"]) < 0.001, "x=330 is not sunset")
	check((sunset["sun_color"] as Color).r > (sunset["sun_color"] as Color).b + 0.5, "Sunset sun is not orange")
	check((sunset["sun_color"] as Color).b < (morning["sun_color"] as Color).b - 0.3, "Sunset not warmer than morning")
	check((midday["sun_color"] as Color).b < (morning["sun_color"] as Color).b, "Midday is not more golden than morning")
	check((sunset["glow_intensity"] as float) > (morning["glow_intensity"] as float), "Alien cyan should glow more at sunset")
	var worst := 0.0
	var previous := BeeLevel01LightProgression.settings_at(-20.0)
	for step in range(-19, 381):
		var now := BeeLevel01LightProgression.settings_at(float(step))
		for key in ["sun_color", "ambient_color", "fog_color", "sky_top", "sky_horizon"]:
			worst = maxf(worst, color_distance(previous[key], now[key]))
		worst = maxf(worst, absf(previous["sun_energy"] - now["sun_energy"]) * 0.5)
		previous = now
	check(worst < 0.03, "Light changes too abruptly (max step %.4f per metre)" % worst)
	stage.distance = 300.0
	await process_frame
	var sun := stage.get_node("Sun") as DirectionalLight3D
	check(color_distance(sun.light_color, BeeLevel01LightProgression.settings_at(300.0)["sun_color"]) < 0.001, "Sun not following the scroll position")
	# Sunset readability: darker, less saturated soil and a stronger rim on Bee, both gradual.
	var soil := (target.get_node("MulchGround") as MeshInstance3D).material_override as StandardMaterial3D
	stage.distance = 0.0
	await process_frame
	var morning_soil := soil.albedo_color
	check(is_zero_approx(BeeToonStyle.bee_rim_boost), "Bee rim boost must be off in the morning")
	stage.distance = 330.0
	await process_frame
	check(soil.albedo_color.v < morning_soil.v * 0.65 and soil.albedo_color.s < morning_soil.s * 0.6, "Sunset soil must be darker and less saturated")
	check(BeeToonStyle.bee_rim_boost > 0.99, "Bee rim boost must be full at sunset")
	stage.distance = 270.0
	await process_frame
	var mid := BeeToonStyle.bee_rim_boost
	check(mid > 0.0 and mid < 1.0 and soil.albedo_color.v < morning_soil.v and soil.albedo_color.v > Color.from_hsv(morning_soil.h, 0.0, morning_soil.v * 0.58).v, "Sunset contrast aids must blend in gradually")
	print("VISUAL_LEVEL_01_OK life=", life.instance_total, " batches=", target.batches.size(), " flowers=", target.flower_head_count, " hidden=", target.hidden_scenery.size(), " foreground=", target.foreground_nodes.size(), " light_step=", snappedf(worst, 0.0001))
	quit(0)
