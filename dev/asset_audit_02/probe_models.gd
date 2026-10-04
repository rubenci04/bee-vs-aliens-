extends SceneTree
## DEV ONLY (ASSET LIBRARY DEEP AUDIT 02). Opens every model listed in data/model_manifest.tsv at
## runtime from its absolute library path (GLTFDocument / FBXDocument / obj_loader.gd): NOTHING is
## imported into the project and the library is only read.
##   godot --headless --path . --script res://dev/asset_audit_02/probe_models.gd [-- start=N]
## Appends one row per model to dev/asset_audit_02/data/model_probe.tsv (resumable with start=N).

const MANIFEST := "res://dev/asset_audit_02/data/model_manifest.tsv"
const OUT := "res://dev/asset_audit_02/data/model_probe.tsv"
const ObjLoader := preload("res://dev/asset_audit_02/obj_loader.gd")
const HEADER := "group\tpath\text\tbytes\tstatus\tmesh_instances\ttriangles\tvertices\tmaterials\ttextures\tbones\tanim_count\tsize_x\tsize_y\tsize_z\tanimations"


func _initialize() -> void:
	call_deferred("run")


func ext_of(path: String) -> String:
	return path.get_extension().to_lower()


func importer_mesh_counts(mesh: ImporterMesh) -> Vector2i:
	var tris := 0
	var verts := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.get_surface_arrays(s)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		verts += positions.size()
		if mesh.get_surface_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var indices = arrays[Mesh.ARRAY_INDEX]
		if indices is PackedInt32Array and indices.size() > 0:
			tris += indices.size() / 3
		else:
			tris += positions.size() / 3
	return Vector2i(tris, verts)


func scene_bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		var b: AABB = mesh.global_transform * mesh.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func clip_list(scene: Node) -> Array[String]:
	var clips: Array[String] = []
	for player: AnimationPlayer in scene.find_children("*", "AnimationPlayer", true, false):
		for clip in player.get_animation_list():
			if str(clip) == "RESET":
				continue
			var animation := player.get_animation(clip)
			clips.append("%s(%.2fs)" % [clip, animation.length])
	return clips


func bone_count(scene: Node) -> int:
	var total := 0
	for skeleton: Skeleton3D in scene.find_children("*", "Skeleton3D", true, false):
		total += skeleton.get_bone_count()
	return total


func probe_document(path: String) -> Dictionary:
	var state: GLTFState
	var document: GLTFDocument
	if ext_of(path) == "fbx":
		state = FBXState.new()
		document = FBXDocument.new()
	else:
		state = GLTFState.new()
		document = GLTFDocument.new()
	var err := document.append_from_file(path, state)
	if err != OK:
		return {"status": "LOAD_ERROR_%d" % err}
	var meshes := state.get_meshes()
	var tris := 0
	var verts := 0
	var instances := 0
	for gltf_node: GLTFNode in state.get_nodes():
		if gltf_node.mesh >= 0 and gltf_node.mesh < meshes.size():
			var counts := importer_mesh_counts((meshes[gltf_node.mesh] as GLTFMesh).mesh)
			tris += counts.x
			verts += counts.y
			instances += 1
	var textures := state.get_images().size()
	if state.json is Dictionary and state.json.has("images"):
		textures = maxi(textures, (state.json["images"] as Array).size())
	var scene := document.generate_scene(state) as Node3D
	if scene == null:
		return {"status": "SCENE_ERROR"}
	root.add_child(scene)
	var box := scene_bounds(scene)
	var result := {
		"status": "OK", "mesh_instances": instances, "triangles": tris, "vertices": verts,
		"materials": state.get_materials().size(), "textures": textures, "bones": bone_count(scene),
		"clips": clip_list(scene), "size": box.size,
	}
	scene.queue_free()
	return result


func probe_obj(path: String) -> Dictionary:
	var loader := ObjLoader.new()
	loader.load_obj(path, false)
	return {
		"status": "OK", "mesh_instances": maxi(1, loader.object_count), "triangles": loader.triangle_count,
		"vertices": loader.vertex_count, "materials": loader.material_names.size(), "textures": 0, "bones": 0,
		"clips": [] as Array[String], "size": loader.aabb.size,
	}


func run() -> void:
	var start := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("start="):
			start = arg.substr(6).to_int()
	var rows := FileAccess.get_file_as_string(MANIFEST).strip_edges().split("\n")
	var out: FileAccess
	if start == 0 or not FileAccess.file_exists(OUT):
		out = FileAccess.open(OUT, FileAccess.WRITE)
		out.store_line(HEADER)
	else:
		out = FileAccess.open(OUT, FileAccess.READ_WRITE)
		out.seek_end()
	for i in range(start, rows.size()):
		var cols := rows[i].split("\t")
		var group := cols[0]
		var path := cols[1]
		var ext := ext_of(path)
		print("PROBE %d/%d %s" % [i, rows.size(), path.get_file()])
		var r: Dictionary
		if ext == "obj":
			r = probe_obj(path)
		elif ext in ["glb", "gltf", "fbx"]:
			r = probe_document(path)
		else:
			r = {"status": "SKIPPED_FORMAT"}
		var size: Vector3 = r.get("size", Vector3.ZERO)
		var clips: Array = r.get("clips", [])
		out.store_line("\t".join(PackedStringArray([group, path, ext, cols[2], r["status"], str(r.get("mesh_instances", 0)),
				str(r.get("triangles", 0)), str(r.get("vertices", 0)), str(r.get("materials", 0)), str(r.get("textures", 0)),
				str(r.get("bones", 0)), str(clips.size()), "%.3f" % size.x, "%.3f" % size.y, "%.3f" % size.z, ";".join(PackedStringArray(clips))])))
		out.flush()
		if i % 25 == 0:
			await process_frame # let queued scenes free
	out.close()
	print("PROBE DONE ", rows.size())
	quit(0)
