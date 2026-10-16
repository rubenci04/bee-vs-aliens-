extends RefCounted
## Review/test only: sample actual skinned vertices, not the FBX bind-pose AABB.
static func vertices(root: Node3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
		var skeleton := mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
		var palette: Array[Transform3D] = []
		if mesh.skin != null and skeleton != null:
			for bind in mesh.skin.get_bind_count():
				var bone := mesh.skin.get_bind_bone(bind)
				if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(bind))
				palette.append(skeleton.global_transform * skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind))
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: Variant = arrays[Mesh.ARRAY_BONES]
			var weights: Variant = arrays[Mesh.ARRAY_WEIGHTS]
			var stride: int = bones.size() / points.size() if bones != null and not palette.is_empty() else 0
			for i in points.size():
				var point := Vector3.ZERO
				if stride == 0:
					point = mesh.global_transform * points[i]
				else:
					for k in stride:
						if weights[i * stride + k] > 0:
							point += palette[bones[i * stride + k]] * points[i] * weights[i * stride + k]
				result.append(point)
	return result
