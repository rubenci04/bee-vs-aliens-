extends SceneTree

const LAB := preload("res://dev/extras_scifi_review/extras_scifi_review_lab.tscn")
const OUTPUTS := ["alien_quaternius.png", "robot_walker.png", "ufo_hat.png", "flying_saucer.png", "mars_rover.png", "spaceship_goodnews.png"]

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await frames(2)
	var image := root.get_viewport().get_texture().get_image()
	if image.save_png("res://dev/extras_scifi_review/" + name) != OK:
		push_error("Could not save " + name)

func run() -> void:
	var lab := LAB.instantiate()
	root.add_child(lab)
	current_scene = lab
	await frames(4)
	for i in 6:
		if not lab.show_candidate(i):
			quit(1)
			return
		await frames(5)
		var meshes := 0
		var materials := {}
		var textures := {}
		var triangles := 0
		var skeletons := 0
		for node in lab.current_model.find_children("*", "Skeleton3D", true, false):
			skeletons += 1
		var mesh_nodes: Array[Node] = [lab.current_model]
		mesh_nodes.append_array(lab.current_model.find_children("*", "MeshInstance3D", true, false))
		for node in mesh_nodes:
			var mesh_instance := node as MeshInstance3D
			if mesh_instance == null or mesh_instance.mesh == null:
				continue
			meshes += 1
			for s in mesh_instance.mesh.get_surface_count():
				var mesh := mesh_instance.mesh
				var arrays := mesh.surface_get_arrays(s)
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				triangles += indices.size() / 3 if indices.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
				var material := mesh_instance.get_surface_override_material(s)
				if material == null:
					material = mesh.surface_get_material(s)
				if material != null:
					materials[material.get_instance_id()] = true
					for property in material.get_property_list():
						var property_name := str(property.name)
						if property_name.ends_with("texture"):
							var value: Variant = material.get(property_name)
							if value is Texture2D:
								textures[value.get_instance_id()] = true
		var details := {
			"candidate": lab.LABELS[i], "aabb_origin": lab.raw_bounds.position,
			"aabb_size": lab.raw_bounds.size, "review_scale": lab.review_scale,
			"meshes": meshes, "materials": materials.size(), "textures": textures.size(), "triangles": triangles,
			"skeletons": skeletons, "clips": lab.animation_names()
		}
		print("REVIEW_AUDIT " + JSON.stringify(details))
		await capture(OUTPUTS[i])
		if i == 0:
			for clip in ["Idle", "Walk", "Bite"]:
				if lab.play_matching_clip(clip):
					await frames(10)
					print("REVIEW_CLIP ALIEN " + clip + " " + str(lab.current_animation_player.current_animation_length))
					await capture("alien_" + clip.to_lower() + ".png")
		if i == 1:
			for clip in ["Idle", "Run", "Shoot"]:
				if lab.play_matching_clip(clip):
					await frames(10)
					print("REVIEW_CLIP WALKER " + clip + " " + str(lab.current_animation_player.current_animation_length))
					await capture("walker_" + clip.to_lower() + ".png")
	# The same camera/light compares the two light saucer candidates directly.
	lab.show_candidate(2)
	await frames(3)
	lab.model_mount.position.x = -1.3
	lab.current_model.scale *= 0.7
	lab.current_model.position *= 0.7
	var second_resource := load(lab.SOURCE_PATHS[3])
	var second := MeshInstance3D.new()
	second.mesh = second_resource as Mesh
	lab.add_child(second)
	var bounds := second.get_aabb()
	var factor := 3.08 / maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	second.scale = Vector3.ONE * factor
	second.position = Vector3(2.6, 0.0, 0.0) + Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor
	lab.get_node("BeeReference").position.x = -4.2
	lab.get_node("ReferenceSquare").position.x = -4.2
	lab.get_node("Camera3D").position.z = 15.0
	lab.get_node("Camera3D").look_at(Vector3(0, 1.75, 0))
	lab.get_node("CanvasLayer/ModelLabel").text = "UFO HAT  vs  FLYING SAUCER · Bee reference"
	await capture("ufo_comparison.png")
	print("EXTRAS_SCIFI_REVIEW_OK")
	quit(0)
