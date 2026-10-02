class_name GardenLitterMeshes
extends RefCounted
## Small faceted meshes for the ground-life decoration (candy wrappers, lollipops, bottle caps,
## straws, little cans, dry leaves, snails, beetles). Built once, instanced with MultiMesh.
## Every mesh rests with its base at y=0 (leaf/wrapper/cap/straw/can/snail/beetle) and is built
## along +Y when elongated; the placement code lays it down.

static func merge(parts: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in parts:
		st.append_from(part[0] as Mesh, 0, part[1] as Transform3D)
	return st.commit()


static func _blob(radius: Vector3, segments := 7, rings := 4) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radial_segments = segments
	sphere.rings = rings
	sphere.radius = 1.0
	sphere.height = 2.0
	var mesh := BeeLevel01VisualTarget._faceted(sphere)
	return merge([[mesh, Transform3D(Basis.from_scale(radius), Vector3.ZERO)]])


## Twisted candy wrapper along +Y: a plump body and two fanned tails.
static func wrapper() -> ArrayMesh:
	var body := GardenProps.loft([[-0.22, 0.1, 0.1, 0, 0], [-0.1, 0.15, 0.13, 0, 0], [0.1, 0.15, 0.13, 0, 0], [0.22, 0.1, 0.1, 0, 0]], 6, true, true)
	var tail_up := GardenProps.loft([[0.22, 0.05, 0.07, 0, 0], [0.38, 0.012, 0.2, 0, 0], [0.5, 0.01, 0.34, 0, 0]], 6, false, true)
	var tail_down := GardenProps.loft([[-0.22, 0.05, 0.07, 0, 0], [-0.38, 0.012, 0.2, 0, 0], [-0.5, 0.01, 0.34, 0, 0]], 6, false, true)
	return merge([[body, Transform3D.IDENTITY], [tail_up, Transform3D.IDENTITY], [tail_down, Transform3D.IDENTITY]])


static func lollipop_stick(height := 1.1) -> ArrayMesh:
	return GardenProps.loft([[0.0, 0.03, 0.03, 0, 0], [height, 0.03, 0.03, 0, 0]], 5, false, true)


## Round candy head facing the camera (disc normal along Z), centred at the top of the stick.
static func lollipop_head(height := 1.1) -> ArrayMesh:
	var disc := GardenProps.loft([[-0.035, 0.34, 0.34, 0, 0], [0.035, 0.34, 0.34, 0, 0]], 8, true, true)
	return merge([[disc, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, height + 0.25, 0))]])


static func bottle_cap() -> ArrayMesh:
	return GardenProps.loft([[0.0, 0.21, 0.21, 0, 0], [0.05, 0.22, 0.22, 0, 0], [0.085, 0.17, 0.17, 0, 0]], 10, true, true)


## Bent straw along +Y, 1.2 m long.
static func straw() -> ArrayMesh:
	return GardenProps.loft([[-0.6, 0.035, 0.035, 0, 0], [0.1, 0.035, 0.035, 0, 0], [0.3, 0.035, 0.035, 0.04, 0], [0.6, 0.035, 0.035, 0.14, 0]], 5, true, true)


## Little can along +Y (lay it down when placing).
static func small_can() -> ArrayMesh:
	return GardenProps.loft([[0.0, 0.2, 0.2, 0, 0], [0.04, 0.24, 0.24, 0, 0], [0.5, 0.24, 0.24, 0, 0], [0.56, 0.18, 0.18, 0, 0]], 9, true, true)


static func snail_shell() -> ArrayMesh:
	var shell := _blob(Vector3(0.2, 0.2, 0.15), 7, 4)
	var cap := _blob(Vector3(0.12, 0.12, 0.17), 6, 3)
	return merge([[shell, Transform3D(Basis.IDENTITY, Vector3(-0.08, 0.22, 0))], [cap, Transform3D(Basis.IDENTITY, Vector3(-0.08, 0.38, 0))]])


static func snail_body() -> ArrayMesh:
	var body := _blob(Vector3(0.36, 0.07, 0.11), 7, 3)
	var head := _blob(Vector3(0.09, 0.09, 0.09), 6, 3)
	return merge([[body, Transform3D(Basis.IDENTITY, Vector3(0, 0.07, 0))], [head, Transform3D(Basis.IDENTITY, Vector3(0.36, 0.17, 0))]])


static func beetle() -> ArrayMesh:
	var shell := _blob(Vector3(0.22, 0.1, 0.15), 7, 4)
	var head := _blob(Vector3(0.07, 0.06, 0.08), 6, 3)
	return merge([[shell, Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 0))], [head, Transform3D(Basis.IDENTITY, Vector3(0.27, 0.09, 0))]])


static func dry_leaf() -> ArrayMesh:
	return merge([[BeeLevel01VisualTarget._leaf_lying(2.0, 0.85), Transform3D(Basis.IDENTITY, Vector3(-1.0, 0, 0))]])
