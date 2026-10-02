class_name GardenProps
extends RefCounted
## Procedural garden props for Level 01: boulders for the solid rocks and the three "litter"
## objects that replace the wooden crates (crushed can, giant matchbox, snack bag).
## Everything is faceted (one normal per triangle) with flat colours and double-sided materials;
## callers apply BeeToonStyle on top. No textures, no imported assets.

const BASE_Y := 0.05 # Props sit just above the mulch (ground top is y=-0.19, gameplay floor is y=0).

static var _materials: Dictionary = {}


static func flat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1.0
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials[key] = material
	return _materials[key]


static func add_part(parent: Node3D, mesh: Mesh, color: Color, label: String, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	if mesh is PrimitiveMesh:
		(mesh as PrimitiveMesh).material = flat(color)
	else:
		mesh.surface_set_material(0, flat(color))
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	parent.add_child(node)
	return node


# --- boulders ---------------------------------------------------------------------------------

## Faceted boulder occupying x in +-half.x, z in +-half.z and y from just below the ground
## (buried base) up to 2*half.y - 0.1. It always rests on the ground: the lowest ring is flattened.
static func boulder(half: Vector3, noise_seed: int, segments := 8, rings := 5) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radial_segments = segments
	sphere.rings = rings
	sphere.radius = 1.0
	sphere.height = 2.0
	var arrays := sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var shaped := PackedVector3Array()
	for v in vertices:
		var p := v.normalized()
		var biggest := maxf(absf(p.x), maxf(absf(p.y), absf(p.z)))
		p *= lerpf(1.0, 1.0 / maxf(biggest, 0.001), 0.45) # Blocky silhouette that fills its collider.
		var key := Vector3i(roundi(v.x * 64.0), roundi(v.y * 64.0), roundi(v.z * 64.0))
		var jitter := 1.0 + (float(hash(Vector3i(key.x + noise_seed * 31, key.y, key.z)) % 1000) / 1000.0 - 0.5) * 0.22
		p *= jitter
		var out := Vector3(p.x * half.x, p.y * half.y + half.y - 0.1, p.z * half.z)
		out.y = maxf(out.y, -0.08) # Flat buried base.
		shaped.append(out)
	return _triangles_from(shaped, indices)


static func _triangles_from(vertices: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for index in indices:
		st.add_vertex(vertices[index])
	st.generate_normals()
	return st.commit()


# --- lofted bodies ----------------------------------------------------------------------------

## ring = [y, radius_x, radius_z, offset_x, offset_z]. Closed tube through the rings, with optional caps.
static func loft(rings: Array, sides := 10, cap_bottom := true, cap_top := true, twist := 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var points: Array = []
	for r in rings:
		var ring := PackedVector3Array()
		for i in sides:
			var a := TAU * float(i) / float(sides) + twist
			ring.append(Vector3(r[3] + cos(a) * r[1], r[0], r[4] + sin(a) * r[2]))
		points.append(ring)
	for j in points.size() - 1:
		var a: PackedVector3Array = points[j]
		var b: PackedVector3Array = points[j + 1]
		for i in sides:
			var n := (i + 1) % sides
			st.add_vertex(a[i]); st.add_vertex(a[n]); st.add_vertex(b[i])
			st.add_vertex(a[n]); st.add_vertex(b[n]); st.add_vertex(b[i])
	if cap_bottom:
		_cap(st, points[0], false)
	if cap_top:
		_cap(st, points[points.size() - 1], true)
	st.generate_normals()
	return st.commit()


static func _cap(st: SurfaceTool, ring: PackedVector3Array, up: bool) -> void:
	var centre := Vector3.ZERO
	for p in ring:
		centre += p
	centre /= float(ring.size())
	for i in ring.size():
		var n := (i + 1) % ring.size()
		if up:
			st.add_vertex(centre); st.add_vertex(ring[i]); st.add_vertex(ring[n])
		else:
			st.add_vertex(centre); st.add_vertex(ring[n]); st.add_vertex(ring[i])


## Flat strip with a zig-zag top edge along X (crimped bag seam). Thickness along Z.
static func serrated_strip(width: float, height: float, teeth: int, depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for side in [-depth * 0.5, depth * 0.5]:
		for t in teeth:
			var x0 := -width * 0.5 + width * float(t) / float(teeth)
			var x1 := -width * 0.5 + width * float(t + 1) / float(teeth)
			var xm := (x0 + x1) * 0.5
			var order := [Vector3(x0, 0, side), Vector3(x1, 0, side), Vector3(xm, height, side)]
			if side > 0.0:
				order.reverse()
			for v in order:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


# --- the three crate replacements ---------------------------------------------------------------
# Each fits the unchanged crate collider (x +-0.75, y 0..2.5, z +-0.6) so hitboxes stay valid.

static func build_item(kind: int, root: Node3D) -> void:
	match kind:
		0: _crushed_can(root)
		1: _matchbox(root)
		_: _snack_bag(root)


static func _crushed_can(root: Node3D) -> void:
	var rings := [
		[BASE_Y, 0.52, 0.42, 0.0, 0.0], [0.5, 0.62, 0.5, 0.0, 0.0], [1.0, 0.61, 0.49, -0.04, 0.0],
		[1.25, 0.48, 0.4, 0.08, 0.0], [1.5, 0.58, 0.46, 0.1, 0.0], [2.15, 0.61, 0.48, 0.16, 0.0], [2.3, 0.5, 0.4, 0.2, 0.0],
	]
	add_part(root, loft(rings, 10, true, false), Color(0.84, 0.16, 0.18), "CanBody")
	var band := rings.slice(1, 3).map(func(r: Array): return [r[0], r[1] * 1.02, r[2] * 1.02, r[3], r[4]])
	add_part(root, loft(band, 10, false, false), Color(0.96, 0.92, 0.8), "CanBand")
	add_part(root, loft([[2.3, 0.5, 0.4, 0.2, 0.0], [2.34, 0.44, 0.35, 0.2, 0.0]], 10, true, true), Color(0.76, 0.78, 0.82), "CanLid")
	var tab := BoxMesh.new()
	tab.size = Vector3(0.28, 0.04, 0.14)
	add_part(root, tab, Color(0.64, 0.66, 0.7), "CanTab", Vector3(0.2, 2.38, 0.0), Vector3(0, 0.4, 0))


static func _matchbox(root: Node3D) -> void:
	var sleeve := BoxMesh.new()
	sleeve.size = Vector3(1.36, 1.95, 1.0)
	add_part(root, sleeve, Color(0.58, 0.36, 0.18), "BoxSleeve", Vector3(0, BASE_Y + 0.975, 0))
	var label := BoxMesh.new()
	label.size = Vector3(1.2, 1.3, 0.05)
	add_part(root, label, Color(0.96, 0.76, 0.16), "BoxLabel", Vector3(0, 1.1, 0.51))
	var stripe := BoxMesh.new()
	stripe.size = Vector3(1.2, 0.32, 0.06)
	add_part(root, stripe, Color(0.78, 0.13, 0.12), "BoxLabelBand", Vector3(0, 0.55, 0.52))
	var strike := BoxMesh.new()
	strike.size = Vector3(0.05, 1.7, 0.7)
	add_part(root, strike, Color(0.22, 0.12, 0.08), "BoxStrike", Vector3(0.69, 1.05, 0))
	var tray := BoxMesh.new()
	tray.size = Vector3(1.26, 0.45, 0.9)
	add_part(root, tray, Color(0.86, 0.7, 0.42), "BoxTray", Vector3(0, 2.1, 0))
	for i in 4:
		var stick := BoxMesh.new()
		stick.size = Vector3(0.07, 0.34, 0.07)
		var x := -0.42 + 0.28 * float(i)
		add_part(root, stick, Color(0.82, 0.62, 0.36), "Match%d" % i, Vector3(x, 2.28, -0.1 + 0.1 * float(i % 2)), Vector3(0.0, 0.0, 0.05 * float(i - 2)))
		var head := BoxMesh.new()
		head.size = Vector3(0.11, 0.13, 0.11)
		add_part(root, head, Color(0.82, 0.12, 0.1), "MatchHead%d" % i, Vector3(x, 2.46, -0.1 + 0.1 * float(i % 2)))


static func _snack_bag(root: Node3D) -> void:
	var rings := [
		[BASE_Y, 0.6, 0.3, 0.0, 0.0], [0.4, 0.72, 0.44, 0.0, 0.0], [1.0, 0.75, 0.5, 0.0, 0.0],
		[1.6, 0.7, 0.42, 0.0, 0.0], [2.0, 0.55, 0.22, 0.0, 0.0], [2.12, 0.6, 0.06, 0.0, 0.0],
	]
	add_part(root, loft(rings, 8, true, false), Color(0.94, 0.38, 0.12), "BagBody")
	var band := [[0.85, 0.76, 0.51, 0.0, 0.0], [1.4, 0.74, 0.5, 0.0, 0.0]]
	add_part(root, loft(band, 8, false, false), Color(0.99, 0.83, 0.16), "BagBand")
	add_part(root, serrated_strip(1.3, 0.34, 7, 0.08), Color(0.78, 0.8, 0.84), "BagSeam", Vector3(0, 2.12, 0))
	var emblem := CylinderMesh.new()
	emblem.top_radius = 0.28
	emblem.bottom_radius = 0.28
	emblem.height = 0.04
	emblem.radial_segments = 6
	add_part(root, emblem, Color(0.97, 0.92, 0.8), "BagEmblem", Vector3(0, 1.12, 0.52), Vector3(PI * 0.5, 0, 0))
