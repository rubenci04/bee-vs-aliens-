extends RefCounted
## DEV ONLY (ASSET LIBRARY DEEP AUDIT 02). Minimal Wavefront OBJ reader so library OBJ files can be
## inspected at runtime without importing them into the project. Reads v / vt / f / usemtl and the
## Kd colour + map_Kd texture of the companion .mtl. Polygons are fan-triangulated.

var vertex_count := 0
var triangle_count := 0
var material_names: Array[String] = []
var object_count := 0
var aabb := AABB()


static func read_mtl(obj_path: String, lines: PackedStringArray) -> Dictionary:
	var materials := {} # name -> {"kd": Color, "map": String}
	var mtl_file := ""
	for line in lines:
		if line.begins_with("mtllib "):
			mtl_file = line.substr(7).strip_edges()
			break
	if mtl_file == "":
		mtl_file = obj_path.get_basename().get_file() + ".mtl"
	var mtl_path := obj_path.get_base_dir().path_join(mtl_file)
	if not FileAccess.file_exists(mtl_path):
		return materials
	var current := ""
	for raw in FileAccess.get_file_as_string(mtl_path).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("newmtl "):
			current = line.substr(7).strip_edges()
			materials[current] = {"kd": Color(0.7, 0.7, 0.7), "map": ""}
		elif current == "":
			continue
		elif line.begins_with("Kd "):
			var p := line.split(" ", false)
			if p.size() >= 4:
				materials[current]["kd"] = Color(p[1].to_float(), p[2].to_float(), p[3].to_float())
		elif line.begins_with("map_Kd "):
			var map := line.substr(7).strip_edges().replace("\\", "/")
			materials[current]["map"] = obj_path.get_base_dir().path_join(map.get_file())
	return materials


## Returns a Node3D with one MeshInstance3D (one surface per material) or null.
func load_obj(path: String, build_mesh := true) -> Node3D:
	if not FileAccess.file_exists(path):
		return null
	var lines := FileAccess.get_file_as_string(path).split("\n")
	var positions := PackedVector3Array()
	var uvs := PackedVector2Array()
	var faces := {} # material -> [PackedVector3Array positions, PackedVector2Array uvs]
	var current := "default"
	var first := true
	for raw in lines:
		if raw.length() < 2:
			continue
		var c0 := raw[0]
		if c0 == "v" and raw[1] == " ":
			var p := raw.split(" ", false)
			if p.size() >= 4:
				var v := Vector3(p[1].to_float(), p[2].to_float(), p[3].to_float())
				positions.append(v)
				if first:
					aabb = AABB(v, Vector3.ZERO)
					first = false
				else:
					aabb = aabb.expand(v)
		elif c0 == "v" and raw[1] == "t":
			var p := raw.split(" ", false)
			if p.size() >= 3:
				uvs.append(Vector2(p[1].to_float(), 1.0 - p[2].to_float()))
		elif c0 == "f" and raw[1] == " ":
			var p := raw.split(" ", false)
			var idx := PackedInt32Array()
			var tdx := PackedInt32Array()
			for i in range(1, p.size()):
				var parts := p[i].split("/")
				var n := parts[0].to_int()
				idx.append(n - 1 if n > 0 else positions.size() + n)
				var t := parts[1].to_int() if parts.size() > 1 and parts[1] != "" else 0
				tdx.append(t - 1 if t > 0 else (uvs.size() + t if t < 0 else -1))
			for i in range(1, idx.size() - 1):
				triangle_count += 1
				if build_mesh:
					if not faces.has(current):
						faces[current] = [PackedVector3Array(), PackedVector2Array()]
					var soup: PackedVector3Array = faces[current][0]
					var soup_uv: PackedVector2Array = faces[current][1]
					# OBJ is counter-clockwise; Godot front faces are clockwise.
					for k in [0, i + 1, i]:
						soup.append(positions[idx[k]])
						soup_uv.append(uvs[tdx[k]] if tdx[k] >= 0 and tdx[k] < uvs.size() else Vector2.ZERO)
					faces[current] = [soup, soup_uv]
		elif raw.begins_with("usemtl "):
			current = raw.substr(7).strip_edges()
			if not material_names.has(current):
				material_names.append(current)
		elif c0 == "o" or c0 == "g":
			object_count += 1
	vertex_count = positions.size()
	if not build_mesh:
		return null
	var mtl := read_mtl(path, lines)
	var textures := {}
	var mesh := ArrayMesh.new()
	for material_name in faces:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var soup: PackedVector3Array = faces[material_name][0]
		var soup_uv: PackedVector2Array = faces[material_name][1]
		for i in soup.size():
			st.set_uv(soup_uv[i])
			st.add_vertex(soup[i])
		st.generate_normals()
		var material := StandardMaterial3D.new()
		var info: Dictionary = mtl.get(material_name, {"kd": Color(0.7, 0.7, 0.7), "map": ""})
		material.albedo_color = info["kd"]
		var map: String = info["map"]
		if map != "" and FileAccess.file_exists(map):
			if not textures.has(map):
				var image := Image.load_from_file(map)
				textures[map] = ImageTexture.create_from_image(image) if image != null else null
			if textures[map] != null:
				material.albedo_texture = textures[map]
				material.albedo_color = Color.WHITE
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.resource_name = material_name
		st.set_material(material)
		st.commit(mesh)
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	root.add_child(instance)
	return root
