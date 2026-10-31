extends SceneTree

# LOTE 14 · ETAPA 3: anthills (5-6, >= 20 s of scroll apart, never touching a solid object), small screens (camera +12 %, big pieces 20 % smaller or
# in the background, >= 65 % of the playable height free of large solids, thin / sparse / 40 % foreground blades that never cross the centre of the
# screen), readability (<= 3 LIBERADO signs, no HUD overlap, thin aim lines that vanish when dodged).

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const SOLID_MARGIN := 0.15 ## m of clear space an anthill keeps from any solid object (X range).
const MAX_COVERED_FRACTION := 0.35 ## Large solids may cover at most this share of the playable height in any column.
## Scene file names of the ground objects an anthill must never touch (peels, bottles, cans, tins, caps, hoses, candies, logs, watering cans).
const GROUND_PIECES := ["banana_peel", "glass_bottle", "empty_drink_can", "tuna", "bottle_cap", "garden_hose", "wrapped_candy", "hollow_fallen_log", "garden_watering_can", "apple"]


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


func world_box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for c in node.find_children("*", "MeshInstance3D", true, false):
		var m := c as MeshInstance3D
		if m.mesh == null:
			continue
		var b: AABB = m.global_transform * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box if not first else AABB(node.global_position, Vector3.ZERO)


func run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func(): quit(1))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(6)
	var wave := stage.wave as BeeLevel01Controller

	# --- 3.1 anthills ------------------------------------------------------------------------------------------------------
	var anthills := stage.get_node("Anthills") as BeeLevel01Anthills
	check(anthills.hills.size() >= 5 and anthills.hills.size() <= 6, "5 or 6 anthills (got %d)" % anthills.hills.size())
	var xs: Array[float] = []
	for hill in anthills.hills:
		xs.append(float(hill["x"]))
	xs.sort()
	for i in range(1, xs.size()):
		check(xs[i] - xs[i - 1] >= BeeLevel01Anthills.MIN_SPACING, "Anthills at %.1f and %.1f are closer than %.0f m (20 s of scroll)" % [xs[i - 1], xs[i], BeeLevel01Anthills.MIN_SPACING])
	check(is_equal_approx(BeeLevel01Anthills.MIN_SPACING, 20.0 * BeeLevel01Controller.LEVEL_SCROLL), "The spacing is 20 s of cruise scroll")
	var solids: Array[Dictionary] = [] # {name, min_x, max_x}
	for path in ["Destructibles", "GardenMushrooms", "Scenery", "AssetDressing"]:
		var holder := stage.get_node_or_null(path)
		if holder == null:
			continue
		for child in holder.get_children():
			var node := child as Node3D
			if node == null or not node.visible:
				continue
			var label := str(node.name)
			var relevant: bool = path == "Destructibles" or path == "GardenMushrooms" or label.begins_with("FlightRock") or label.begins_with("BackdropRock")
			if path == "AssetDressing" and label.begins_with("Litter"):
				for sub in node.find_children("*", "Node3D", true, false):
					for piece in GROUND_PIECES:
						if str(sub.name).to_lower().replace("_", "").contains(piece.replace("_", "")) or str(sub.scene_file_path).contains(piece):
							relevant = true
				for piece in GROUND_PIECES:
					if str(node.scene_file_path).contains(piece):
						relevant = true
			if not relevant:
				continue
			var box := world_box(node)
			if box.size.x < 0.05:
				continue
			solids.append({"name": "%s/%s" % [path, label], "min_x": box.position.x, "max_x": box.end.x})
	check(solids.size() > 30, "The solid objects were found (%d)" % solids.size())
	for hill in anthills.hills:
		var hbox := world_box(hill["node"] as Node3D)
		for solid in solids:
			var overlap := minf(hbox.end.x, float(solid["max_x"])) - maxf(hbox.position.x, float(solid["min_x"]))
			check(overlap < -SOLID_MARGIN, "Anthill %s [%.2f, %.2f] touches %s [%.2f, %.2f]" % [str((hill["node"] as Node3D).name), hbox.position.x, hbox.end.x, solid["name"], solid["min_x"], solid["max_x"]])
	check(is_equal_approx(BeeLevel01Anthills.HILL_SCALE, 1.8 * 0.8), "Anthills are 20 % smaller")

	# --- 3.2 small screens -------------------------------------------------------------------------------------------------------
	var e: Dictionary = BeeLevel01Framing.PRESETS[&"E"]
	var f: Dictionary = BeeLevel01Framing.PRESETS[BeeLevel01Framing.DEFAULT_PRESET]
	check(BeeLevel01Framing.DEFAULT_PRESET == &"F" and absf(float(f["distance"]) / float(e["distance"]) - BeeLevel01Framing.CAMERA_BACK_SCALE) < 0.001, "The camera is pulled back 12 %% (preset F = E x %.2f)" % BeeLevel01Framing.CAMERA_BACK_SCALE)
	check(is_equal_approx(BeeLevel01Framing.CAMERA_BACK_SCALE, 1.12), "CAMERA_BACK_SCALE is 1.12")
	check(is_equal_approx(stage.camera.global_position.z, float(f["distance"])), "The level uses the pulled-back camera")
	var span_f := BeeLevel01Framing.top_y() - BeeLevel01Framing.bottom_y()
	BeeLevel01Framing.use_preset(&"E")
	var span_e := BeeLevel01Framing.top_y() - BeeLevel01Framing.bottom_y()
	BeeLevel01Framing.use_preset(&"F")
	check(span_f / span_e >= 1.10 and span_f / span_e <= 1.14, "The view is ~12 %% taller (%.3f)" % (span_f / span_e))
	check(BeeLevel01Framing.bottom_y() < 0.0, "The ground line stays in frame")
	# Big human-scale pieces: 20 % smaller and further back.
	var dressing := stage.get_node("AssetDressing") as BeeLevel01AssetDressing
	var checked := 0
	for entry in BeeLevel01AssetDressing.LITTER:
		if not (entry[0] in dressing.BIG_PROPS):
			continue
		for item in dressing.litter:
			if absf(item.position.x - float(entry[1])) < 0.01 and absf(item.scale.x - float(entry[3]) * BeeLevel01AssetDressing.BIG_PROP_SCALE) < 0.001:
				check(item.position.z <= float(entry[2]) - BeeLevel01AssetDressing.BIG_PROP_PUSH_BACK + 0.001, "Big piece at X=%.0f sits further back" % float(entry[1]))
				checked += 1
	check(checked >= 8 and is_equal_approx(BeeLevel01AssetDressing.BIG_PROP_SCALE, 0.8), "The cans, bottle, watering cans and log are 20 %% smaller (%d)" % checked)
	check(is_equal_approx(BeeGardenMushroom.SIZE_SCALE, 0.8) and is_equal_approx(BeeLevel01Moments.CAN_SCALE, 0.8), "Mushrooms / flowers and the opening can are 20 % smaller")
	# At least 65 % of the playable height is free of large solids in every column (the plane |z| < 1.0).
	var floor_y: float = stage.bee.flight_min.y
	var play_height: float = stage.bee.flight_max.y - floor_y
	var worst := 0.0
	var worst_name := ""
	for node in stage.find_children("*", "Node3D", true, false):
		var holder_name := str(node.get_parent().name)
		var label := str(node.name)
		var is_solid: bool = holder_name in ["Destructibles", "GardenMushrooms"] or label.begins_with("FlightRock") or (holder_name == "Anthills" and label.begins_with("Anthill_"))
		if not is_solid:
			continue
		var box := world_box(node as Node3D)
		if box.position.z > 1.0 or box.end.z < -1.0 or box.size.x < 0.3:
			continue
		var covered := clampf((box.end.y - floor_y) / play_height, 0.0, 1.0)
		if covered > worst:
			worst = covered
			worst_name = label
	check(worst <= MAX_COVERED_FRACTION + 0.001, "A large solid covers %.0f %% of the playable height (%s), max %.0f %%" % [100.0 * worst, worst_name, 100.0 * MAX_COVERED_FRACTION])
	# Foreground blades: thinner, sparser, 40 % opacity, faded out over the middle of the screen.
	check(BeeLevel01Foreground.WIDTH_SCALE <= 0.65 and BeeLevel01Foreground.STEP_SCALE >= 1.7 and is_equal_approx(BeeLevel01Foreground.ALPHA, 0.40), "Foreground blades: thinner, fewer, 40 %% opacity")
	var foreground := stage.get_node("Foreground") as BeeLevel01Foreground
	check(foreground.layers.size() == BeeLevel01Foreground.LAYERS.size(), "Foreground layers exist")
	for layer in foreground.layers:
		var material := (layer.multimesh.mesh as QuadMesh).material as ShaderMaterial
		check(float(material.get_shader_parameter("fade")) <= 0.40 + 0.0001, "Blade opacity <= 40 %")
		var centre: Vector2 = material.get_shader_parameter("center_half")
		check(centre.x >= 0.25 and centre.y >= 0.25, "The blades fade out over the centre of the screen")
	var shader_code := (BeeLevel01Foreground.SHADER as Shader).code
	check(shader_code.contains("SCREEN_UV") and shader_code.contains("center_half"), "The blade shader masks the centre")

	# --- 3.3 readability ---------------------------------------------------------------------------------------------------------
	for i in 6:
		var liberated := BeeLiberation.float_text(stage, Vector3(float(i), 3.0, 0.0))
		check((liberated != null) == (i < BeeLiberation.max_texts()), "Only the first max_texts() liberations return a world sign")
	var singles := 0
	var groups := 0
	var group_text := ""
	for node in get_nodes_in_group("bee_liberated_text"):
		if (node as Node).has_meta("liberated_group"):
			groups += 1
			group_text = (node as Label3D).text
		else:
			singles += 1
	check(singles == BeeLiberation.max_texts() and groups == 0 and stage.get_node("HUDNotices").liberated_count == 6, "At most %d LIBERADO signs; the rest merge: singles %d, groups %d '%s'" % [BeeLiberation.max_texts(), singles, groups, group_text])
	# HUD: the zone notice (top centre) never overlaps the other HUD lines.
	var section := stage.get_node("CanvasLayer/Section") as Label
	section.text = "ZONA DE COMBATE · SOMBRA BAJO LAS HOJAS · 6/7"
	wave._announce_species("Ant")
	await frames(3)
	var viewport_size := Vector2(1280.0, 720.0)
	var rects: Array[Dictionary] = []
	for node in stage.find_children("*", "Label", true, false):
		var label := node as Label
		if not label.visible or label.text.is_empty():
			continue
		var layer := label.get_parent()
		if not (layer is CanvasLayer or str(layer.name) == "WeaponsHUD"):
			continue
		var size := label.get_minimum_size()
		var left := label.offset_left + viewport_size.x * label.anchor_left
		if label.anchor_left == 0.5 and label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
			left = viewport_size.x * 0.5 - size.x * 0.5
		var top := label.offset_top + viewport_size.y * label.anchor_top
		var origin := Vector2.ZERO
		if layer is Control:
			origin = Vector2((layer as Control).offset_left, (layer as Control).offset_top)
		rects.append({"rect": Rect2(Vector2(left, top) + origin, size), "text": label.text})
	# The Lote 17 HUD draws its meters/icons directly on CanvasItem instead of creating text Labels.
	check(stage.get_node("HUDNotices").panel.visible, "Central notices exist")
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			var a: Rect2 = rects[i]["rect"]
			var b: Rect2 = rects[j]["rect"]
			check(not a.intersects(b), "HUD overlap: '%s' %s and '%s' %s" % [rects[i]["text"], str(a), rects[j]["text"], str(b)])
	# Aim lines: thin, and a locked line disappears once Bee has stepped off it.
	check(AssetFauna.AIM_LINE_WIDTH <= 0.05 and WormBehavior.LINE_WIDTH <= 0.05, "The aim lines are thin")
	var line := BeeAttackVisuals.line(stage, Vector3(0, 3, 0), Vector3(8, 3, 0), 0.04, Color.ORANGE)
	BeeAttackVisuals.hide_when_dodged(line, Vector3(0, 3, 0), Vector3(8, 3, 0), Vector3(5, 3.3, 0), AssetFauna.AIM_DODGE_CLEARANCE)
	check(line.visible, "The locked line stays while Bee is on it")
	BeeAttackVisuals.hide_when_dodged(line, Vector3(0, 3, 0), Vector3(8, 3, 0), Vector3(5, 5.2, 0), AssetFauna.AIM_DODGE_CLEARANCE)
	check(not line.visible, "The locked line disappears when Bee dodges")
	print("BEE_LOTE14_SCREEN_V01_OK anthills=%d spacing>=%.0fm camera=F(+12%%) solids_cover<=%.0f%% libs<=3 hud_no_overlap thin_lines" % [anthills.hills.size(), BeeLevel01Anthills.MIN_SPACING, 100.0 * MAX_COVERED_FRACTION])
	quit(0)
