extends SceneTree

# VISUAL TARGET 01 contract: decoration only, one flat style, readable playfield.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

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

func run() -> void:
	create_timer(60.0, true, false, true).timeout.connect(func(): quit(1))
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 3:
		await process_frame
	var target := stage.get_node("VisualTarget01") as BeeLevel01VisualTarget
	check(target != null and target.get_child_count() > 150, "Visual target decoration missing")
	check(target.find_children("*", "CollisionObject3D", true, false).is_empty(), "Decoration must not collide")
	check(stage.get_node("Scenery").get_child_count() == 350, "Existing scenery must be kept (hidden/moved, not deleted)")
	check(not target.moved_trees.is_empty() and not target.hidden_scenery.is_empty(), "Old trees/ferns in the stretch untouched")
	for label in target.moved_trees:
		check(stage.get_node("Scenery/" + label).position.z <= BeeLevel01VisualTarget.OLD_TREE_Z + 0.01, "Tree not sent back: " + label)
	var foreground_limit_ok := true
	for mesh: MeshInstance3D in target.find_children("*", "MeshInstance3D", true, false):
		var material := mesh.material_override as StandardMaterial3D
		check(material != null and material.albedo_texture == null, "Decoration must use flat colours: " + mesh.name)
		var c := material.albedo_color
		check(not (c.h > 0.42 and c.h < 0.56 and c.s > 0.35), "Cyan is reserved for alien tech: " + mesh.name)
		for v in world_vertices(mesh):
			if v.z > BeeLevel01VisualTarget.FOREGROUND_MIN_Z:
				# Foreground: projected onto the play plane, never above the bottom band.
				if v.y > BeeLevel01VisualTarget.foreground_height_limit(v.z) + 0.001:
					foreground_limit_ok = false
			elif absf(v.z) < BeeLevel01VisualTarget.MIDGROUND_CLEAR_Z and v.y > 0.35:
				check(false, "Midground must stay clear: " + mesh.name)
	check(foreground_limit_ok, "Foreground covers the playfield")
	check(target.foreground_nodes.size() >= 1 and target.foreground_nodes.size() <= 2, "Expected 1-2 foreground leaves")
	var env := (stage.get_node("WorldEnvironment") as WorldEnvironment).environment
	check(env.fog_enabled and env.fog_mode == Environment.FOG_MODE_DEPTH and env.fog_depth_begin > BeeLevel01Framing.CAMERA_DISTANCE + 2.5, "Depth fog must start behind the playfield")
	check((stage.get_node("Sun") as DirectionalLight3D).shadow_enabled, "Sun shadows off")
	print("VISUAL_TARGET_01_OK nodes=", target.get_child_count(), " hidden=", target.hidden_scenery.size(), " trees_back=", target.moved_trees.size())
	quit(0)
