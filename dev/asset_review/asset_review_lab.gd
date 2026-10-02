extends Node3D

var metrics: Array = []
const HEIGHTS = [7.0, 2.0, 2.0, 4.0, 6.0]

func _ready() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.16, 0.19, 0.23)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.7
	env.environment = environment
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -25, 0)
	light.light_energy = 1.2
	add_child(light)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(45, 16)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.36, 0.38)
	floor_node.material_override = mat
	add_child(floor_node)
	var candidates: Array = JSON.parse_string(FileAccess.get_file_as_string("res://dev/asset_review/candidates.json"))
	for i in range(candidates.size()):
		var item: Dictionary = candidates[i]
		var model: Node3D = load(item.model).instantiate()
		model.name = item.asset
		add_child(model)
		var data := measure(model)
		var bounds: AABB = data.bounds
		var factor: float = HEIGHTS[i] / bounds.size.y
		model.scale = Vector3.ONE * factor
		model.position = Vector3(-12 + i * 6, -bounds.position.y * factor, 0)
		data.erase("bounds")
		data.asset = item.asset
		data.scale_original = [1, 1, 1]
		data.scale_suggested = factor
		metrics.append(data)
		label(item.asset + "\nx%.2f" % factor, Vector3(-12 + i * 6, 0.15, 2.4))
	var bee: Node3D = load("res://assets/models/bee_prototype/bee_alien_visual.glb").instantiate()
	add_child(bee)
	bee.position = Vector3(17, 1.3, 0)
	bee.rotation.y = -PI / 2
	label("Bee\nescala actual", Vector3(17, 0.15, 2.4))
	var human := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.75
	capsule.radius = 0.24
	human.mesh = capsule
	human.position = Vector3(20, 0.875, 0)
	add_child(human)
	label("Humano\n1.75 m", Vector3(20, 0.15, 2.4))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23
	camera.position = Vector3(4, 11, 28)
	add_child(camera)
	camera.look_at(Vector3(4, 3, 0))
	camera.current = true

func label(value: String, at: Vector3) -> void:
	var node := Label3D.new()
	node.text = value
	node.font_size = 40
	node.pixel_size = 0.012
	node.position = at
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(node)

func measure(model: Node3D) -> Dictionary:
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var materials: Dictionary = {}
	var textures: Dictionary = {}
	var triangles := 0
	var bounds := AABB()
	var first := true
	for instance: MeshInstance3D in meshes:
		var local: Transform3D = model.global_transform.affine_inverse() * instance.global_transform
		var box: AABB = local * instance.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		for surface in range(instance.mesh.get_surface_count()):
			var material := instance.get_active_material(surface)
			if material != null:
				materials[material.get_instance_id()] = true
				if material is BaseMaterial3D:
					for slot in range(BaseMaterial3D.TEXTURE_MAX):
						var texture: Texture2D = material.get_texture(slot)
						if texture != null:
							textures[texture.get_instance_id()] = true
			var arrays := instance.mesh.surface_get_arrays(surface)
			var indices = arrays[Mesh.ARRAY_INDEX]
			triangles += int(indices.size() / 3) if indices != null and indices.size() > 0 else int(arrays[Mesh.ARRAY_VERTEX].size() / 3)
	var animations: Array = []
	for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
		animations.append_array(player.get_animation_list())
	return {"bounds": bounds, "dimensions": [bounds.size.x, bounds.size.y, bounds.size.z], "meshes": meshes.size(), "materials": materials.size(), "textures": textures.size(), "triangles": triangles, "animations": animations, "colliders": model.find_children("*", "CollisionShape3D", true, false).size()}


