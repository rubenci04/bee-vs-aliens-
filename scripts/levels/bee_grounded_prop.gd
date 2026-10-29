extends RefCounted
## Banana wrappers have an elevated mesh pivot: ground their actual transformed bounds.
const GROUND_Y := BeeLevel01VisualTarget.GROUND_Y + 0.01
const TILT := 0.10
static func settle(item: Node3D, tilt := TILT) -> void:
	item.rotation.z = tilt
	var bottom := INF
	for mesh: MeshInstance3D in item.find_children("*", "MeshInstance3D", true, false):
		for vertex in mesh.mesh.get_faces():
			bottom = minf(bottom, (mesh.global_transform * vertex).y)
	if is_finite(bottom): item.global_position.y += GROUND_Y - bottom
