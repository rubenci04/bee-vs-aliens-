extends SceneTree
## DEV ONLY. Prints the bone list of the Giant Human and, over a full Run cycle, the camera-projected
## (Z=0) vertical/horizontal extents of each body group, to design the new damage envelopes.
## godot --headless --path . --script res://dev/level01_challenge_review/human_geometry_probe.gd

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

var stage: BeeShmupStage
var human: GiantHumanCrossingHazard

func _initialize() -> void:
	call_deferred("run")

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func(): quit(1))
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	stage.scroll_speed = 0.0
	stage.distance = 140.0
	stage._update_camera_and_bounds()
	(stage.wave as Node).set_physics_process(false)
	stage.bee.set_physics_process(false)
	human = stage.get_node("GiantHuman") as GiantHumanCrossingHazard
	var skeleton: Skeleton3D = human.get_node("VisualRoot/Hipster/Rig/Skeleton3D")
	var names := []
	for i in skeleton.get_bone_count():
		names.append(skeleton.get_bone_name(i))
	print("BONES ", names)
	print("HUMAN scale=", human.visual_root.scale, " hipster scale=", (human.get_node("VisualRoot/Hipster") as Node3D).scale)
	# vertex ownership by dominant bone
	var groups := {}
	var owners := []
	for mesh: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", false, false):
		if not mesh.visible or mesh.skin == null:
			continue
		var skin_index := owners.size()
		owners.append(mesh.skin)
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var stride := bones.size() / vertices.size()
			for i in vertices.size():
				var dominant := 0
				for k in stride:
					if weights[i * stride + k] > weights[i * stride + dominant]:
						dominant = k
				var bind := bones[i * stride + dominant]
				var skin_ref: Skin = owners[skin_index]
				var bone: int = skin_ref.get_bind_bone(bind) if skin_ref.get_bind_bone(bind) >= 0 else skeleton.find_bone(skin_ref.get_bind_name(bind))
				var bone_name := skeleton.get_bone_name(bone)
				if not groups.has(bone_name):
					groups[bone_name] = []
				var indices := PackedInt32Array()
				var used := PackedFloat32Array()
				for k in stride:
					if weights[i * stride + k] > 0.0:
						indices.append(bones[i * stride + k])
						used.append(weights[i * stride + k])
				groups[bone_name].append([skin_index, vertices[i], indices, used])
	for g in groups:
		print("GROUP ", g, " vertices=", groups[g].size())
	assert(human.begin_crossing(stage.camera))
	await frames(70)
	var camera_position := stage.camera.global_position
	print("CAMERA ", camera_position)
	var length := human.animation_player.get_animation(&"Run").length
	print("RUN length=", length, " speed_scale=", human.animation_player.speed_scale)
	var lo := {}
	var hi := {}
	for step in 24:
		var t := length * float(step) / 24.0
		human.animation_player.seek(t, true)
		human.animation_player.advance(0.0)
		var palettes := []
		for skin in owners:
			var palette: Array[Transform3D] = []
			for bind in skin.get_bind_count():
				var bone: int = skin.get_bind_bone(bind) if skin.get_bind_bone(bind) >= 0 else skeleton.find_bone(skin.get_bind_name(bind))
				palette.append(skeleton.global_transform * skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(bind))
			palettes.append(palette)
		var line := "t=%.2f" % t
		for g in ["foot_L", "foot_R", "calf_L", "calf_R", "thigh_L", "thigh_R", "pelvis", "spine", "chest", "head"]:
			if not groups.has(g):
				continue
			var min_x := INF
			var max_x := -INF
			var min_y := INF
			var max_y := -INF
			for sample: Array in groups[g]:
				var palette: Array = palettes[sample[0]]
				var skinned := Vector3.ZERO
				for k in (sample[2] as PackedInt32Array).size():
					skinned += (palette[sample[2][k]] * (sample[1] as Vector3)) * sample[3][k]
				var scale := camera_position.z / maxf(camera_position.z - skinned.z, 0.5)
				var px := camera_position.x + (skinned.x - camera_position.x) * scale - human.global_position.x
				var py := camera_position.y + (skinned.y - camera_position.y) * scale
				min_x = minf(min_x, px)
				max_x = maxf(max_x, px)
				min_y = minf(min_y, py)
				max_y = maxf(max_y, py)
			line += " | %s x[%.1f,%.1f] y[%.1f,%.1f]" % [g, min_x, max_x, min_y, max_y]
		print(line)
	quit(0)
