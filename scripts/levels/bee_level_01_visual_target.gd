class_name BeeLevel01VisualTarget
extends Node3D
## VISUAL TARGET 01: decoration of the first ~60 m of Level 01 only (art reference slice).
## Presentation only: no collision, no gameplay nodes, no imported textures. Everything is
## generated from Godot primitives / SurfaceTool with flat (faceted) normals and flat colours.
## Layers (camera = preset D, see BeeLevel01Framing):
##   foreground  z > 4.5 : 1-2 dark leaves, always projected BELOW the playfield (see FOREGROUND_SCREEN_Y)
##   midground   |z| < 2.5: kept clear (ground, mulch, low pebbles only)
##   background  z < -2.5 : giant grass blades and flower stems (4-10 m), then deep muted silhouettes.

const X_MIN := -15.0
const X_MAX := 72.0 # The x=60 frame shows the play plane up to ~66 m and stems up to ~70 m.
const GROUND_Y := -0.2
const MIDGROUND_CLEAR_Z := 2.5
const FOREGROUND_MIN_Z := 4.5
## Foreground geometry must project onto the Z=0 plane at or below this height, i.e. under
## crates, pollen and Bee's lowest flight height (0.7 m).
const FOREGROUND_SCREEN_Y := 0.0
const OLD_TREE_Z := -48.0 # Existing full trees in this stretch are sent behind the hedge band, into the fog.

const PALETTE := {
	"mulch": Color(0.47, 0.33, 0.18),
	"mulch_dark": Color(0.33, 0.22, 0.12),
	"mulch_light": Color(0.58, 0.43, 0.24),
	"pebble": Color(0.58, 0.52, 0.42),
	"pebble_warm": Color(0.52, 0.43, 0.32),
	"leaf_fallen": Color(0.72, 0.52, 0.2),
	"grass": Color(0.24, 0.37, 0.15), # Muted on purpose: Bee, enemies and pollen must pop.
	"grass_yellow": Color(0.34, 0.42, 0.17),
	"stem": Color(0.22, 0.38, 0.15),
	"petal_yellow": Color(0.96, 0.76, 0.2),
	"petal_cream": Color(0.95, 0.89, 0.7),
	"flower_core": Color(0.62, 0.36, 0.1),
	"far_green": Color(0.3, 0.41, 0.27),
	"far_dark": Color(0.22, 0.32, 0.22),
	"far_petal": Color(0.8, 0.7, 0.38),
	"foreground": Color(0.07, 0.11, 0.05),
}

var _materials: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var hidden_scenery: Array[String] = []
var moved_trees: Array[String] = []
var foreground_nodes: Array[Node3D] = []


func _ready() -> void:
	_rng.seed = 1101
	_tidy_existing_scenery()
	_build_ground()
	_build_pebbles_and_leaves()
	_build_giant_stems()
	_build_background()
	_build_foreground()


## Existing approved props in this stretch: full trees go far back (they break insect scale),
## textured ferns and mixed-style flowers are hidden (not deleted) so the slice has one style.
## The bottle (giant human object) and the hollow log visual stay.
func _tidy_existing_scenery() -> void:
	var scenery := get_parent().get_node_or_null("Scenery")
	if scenery == null:
		return
	for child: Node3D in scenery.get_children():
		var x := child.global_position.x
		if x < X_MIN or x > X_MAX or child.name in [&"GiantBottle", &"FallenLog"]:
			continue
		var label := str(child.name)
		if label.begins_with("Tree") or label.begins_with("ClusterTree") or label.begins_with("PocketTree"):
			child.position.z = OLD_TREE_Z
			moved_trees.append(label)
		else:
			child.visible = false
			hidden_scenery.append(label)


func _build_ground() -> void:
	var slab := BoxMesh.new()
	slab.size = Vector3(X_MAX - X_MIN + 40.0, 0.1, 74.0)
	_add(slab, "mulch", Vector3((X_MIN + X_MAX) * 0.5, GROUND_Y - 0.04, -27.0), Vector3.ZERO, Vector3.ONE, "MulchGround", false)
	for i in 70:
		var disc := CylinderMesh.new()
		disc.radial_segments = 6
		disc.rings = 1
		disc.height = 0.02
		var r := _rng.randf_range(0.6, 2.4)
		disc.top_radius = r
		disc.bottom_radius = r
		var key: String = ["mulch_dark", "mulch_light", "mulch_dark"][i % 3]
		var pos := Vector3(_rng.randf_range(X_MIN, X_MAX), GROUND_Y + 0.02 + 0.001 * float(i % 5), _rng.randf_range(-14.0, 6.0))
		_add(_faceted(disc), key, pos, Vector3(0, _rng.randf() * TAU, 0), Vector3(1.0, 1.0, _rng.randf_range(0.5, 1.0)), "MulchPatch%d" % i, false)


func _build_pebbles_and_leaves() -> void:
	var count := 0
	var x := X_MIN
	while x < X_MAX:
		x += _rng.randf_range(0.8, 2.6)
		var front := _rng.randf() < 0.3
		var z := _rng.randf_range(1.0, 3.5) if front else _rng.randf_range(-8.0, -3.4)
		var size := Vector3(_rng.randf_range(0.3, 0.85), _rng.randf_range(0.2, 0.5), _rng.randf_range(0.3, 0.75))
		if front:
			size *= 0.45 # Low enough to stay under the playfield in screen space.
		var pebble := SphereMesh.new()
		pebble.radial_segments = 7
		pebble.rings = 3
		pebble.radius = 1.0
		pebble.height = 2.0
		var pos := Vector3(x, GROUND_Y + size.y * 0.55, z)
		_add(_faceted(pebble), "pebble" if count % 3 else "pebble_warm", pos, Vector3(0, _rng.randf() * TAU, _rng.randf_range(-0.2, 0.2)), size, "Pebble%d" % count, true)
		count += 1
	# Big fallen leaves lying on the soil, behind the flight plane.
	for spec in [[Vector3(7.5, GROUND_Y + 0.03, -2.9), 3.4, 0.35], [Vector3(36.0, GROUND_Y + 0.03, -5.2), 4.2, -0.5], [Vector3(57.5, GROUND_Y + 0.03, -3.4), 3.0, 2.6]]:
		_add(_leaf_lying(spec[1], spec[1] * 0.42), "leaf_fallen", spec[0], Vector3(0, spec[2], 0), Vector3.ONE, "FallenLeaf%d" % get_child_count(), true, true)


## Giant grass blades and flower stems behind the flight plane, 4-10 m tall. Flower heads are
## only put on stems tall enough to leave the frame, so warm yellows never sit behind Bee.
func _build_giant_stems() -> void:
	var x := X_MIN
	var i := 0
	while x < X_MAX:
		x += _rng.randf_range(1.2, 2.8)
		var z := _rng.randf_range(-9.0, -MIDGROUND_CLEAR_Z - 0.3)
		var height := _rng.randf_range(4.0, 10.0)
		if i % 3 == 2 and height >= 7.5:
			z = minf(z, -3.8) # Tilted heads must not hang over the flight plane.
			_flower_stem(Vector3(x, GROUND_Y, z), maxf(height, frame_top_at(z) + 1.4), i)
		else:
			var blade := _blade(height, _rng.randf_range(0.35, 0.7), _rng.randf_range(-0.8, 0.8))
			_add(blade, "grass" if i % 2 else "grass_yellow", Vector3(x, GROUND_Y, z), Vector3(0, _rng.randf_range(-0.5, 0.5), 0), Vector3.ONE, "GrassBlade%d" % i, true, true)
		i += 1


func _flower_stem(base: Vector3, height: float, index: int) -> void:
	var stem := CylinderMesh.new()
	stem.radial_segments = 5
	stem.rings = 1
	stem.height = height
	stem.bottom_radius = _rng.randf_range(0.11, 0.17)
	stem.top_radius = stem.bottom_radius * 0.7
	_add(_faceted(stem), "stem", base + Vector3(0, height * 0.5, 0), Vector3.ZERO, Vector3.ONE, "FlowerStem%d" % index, true)
	var leaf := _blade(height * 0.3, 0.45, 0.6)
	_add(leaf, "grass", base + Vector3(0, height * 0.3, 0), Vector3(0, 0, -0.35 if index % 2 else 0.35), Vector3.ONE, "StemLeaf%d" % index, true, true)
	_flower_head(base + Vector3(0, height, 0), _rng.randf_range(0.8, 1.2), "petal_yellow" if index % 2 else "petal_cream", "FlowerHead%d" % index, true)


func _flower_head(center: Vector3, radius: float, petal_key: String, label: String, shadows: bool) -> void:
	var petals := CylinderMesh.new()
	petals.radial_segments = 6
	petals.rings = 1
	petals.top_radius = radius
	petals.bottom_radius = radius * 0.25
	petals.height = radius * 0.45
	_add(_faceted(petals), petal_key, center, Vector3(0.9, 0, 0), Vector3.ONE, label, shadows)
	var core := SphereMesh.new()
	core.radial_segments = 6
	core.rings = 3
	core.radius = radius * 0.35
	core.height = radius * 0.35
	_add(_faceted(core), "flower_core", center + Vector3(0, radius * 0.25, 0), Vector3.ZERO, Vector3.ONE, label + "Core", shadows)


## Deep garden: huge muted stems, leaves and flower heads, then a continuous band of low-poly
## mounds that hides the ground/sky horizon. Depth fog lightens and separates all of it.
func _build_background() -> void:
	var x := X_MIN - 25.0
	var i := 0
	while x < X_MAX + 30.0:
		x += _rng.randf_range(3.0, 6.5)
		var z := _rng.randf_range(-24.0, -12.0)
		var height := _rng.randf_range(10.0, 22.0)
		if i % 2 == 0:
			height = maxf(height, frame_top_at(z) + 3.0) # Far flower heads stay above the frame too.
		if i % 2 == 0:
			var stem := CylinderMesh.new()
			stem.radial_segments = 5
			stem.rings = 1
			stem.height = height
			stem.bottom_radius = _rng.randf_range(0.35, 0.6)
			stem.top_radius = stem.bottom_radius * 0.7
			_add(_faceted(stem), "far_green", Vector3(x, GROUND_Y + height * 0.5, z), Vector3.ZERO, Vector3.ONE, "FarStem%d" % i, false)
			_flower_head(Vector3(x, GROUND_Y + height, z), _rng.randf_range(2.2, 3.4), "far_petal", "FarHead%d" % i, false)
		else:
			_add(_blade(height * 0.8, _rng.randf_range(1.6, 2.8), _rng.randf_range(-4.0, 4.0)), "far_dark", Vector3(x, GROUND_Y, z), Vector3(0, _rng.randf_range(-0.4, 0.4), 0), Vector3.ONE, "FarLeaf%d" % i, false, true)
		i += 1
	var mx := X_MIN - 45.0
	var m := 0
	while mx < X_MAX + 50.0:
		mx += _rng.randf_range(6.0, 9.0)
		var mound := SphereMesh.new()
		mound.radial_segments = 9
		mound.rings = 5
		mound.radius = 1.0
		mound.height = 2.0
		var radius := _rng.randf_range(7.0, 11.0)
		_add(_faceted(mound), "far_dark" if m % 2 else "far_green", Vector3(mx, GROUND_Y, _rng.randf_range(-42.0, -32.0)), Vector3(0, _rng.randf() * TAU, 0), Vector3(radius, _rng.randf_range(6.0, 9.5), radius * 0.6), "Hedge%d" % m, false)
		m += 1


## Two dark leaves very close to the camera. Their height is derived from the camera so that,
## in screen space, they only cover the band below FOREGROUND_SCREEN_Y on the play plane.
func _build_foreground() -> void:
	for spec in [[29.0, 5.8, 1.1, 0.9], [51.0, 5.4, -1.2, 1.1]]:
		var z: float = spec[1]
		var height := foreground_height_limit(z) - GROUND_Y - 0.05
		var leaf := _blade(height, spec[3], spec[2], 4)
		var node := _add(leaf, "foreground", Vector3(spec[0], GROUND_Y, z), Vector3.ZERO, Vector3.ONE, "ForegroundLeaf%d" % foreground_nodes.size(), false, true)
		foreground_nodes.append(node)


## Highest world Y at depth z that still projects at/below FOREGROUND_SCREEN_Y on the Z=0 plane.
static func foreground_height_limit(z: float) -> float:
	var cam_y := BeeLevel01Framing.CAMERA_HEIGHT
	var cam_z := BeeLevel01Framing.CAMERA_DISTANCE
	return cam_y + (FOREGROUND_SCREEN_Y - cam_y) * (cam_z - z) / cam_z


func _add(mesh: Mesh, key: String, pos: Vector3, rot: Vector3, scl: Vector3, label: String, shadows: bool, double_sided := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = _material(key, double_sided)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.position = pos
	node.rotation = rot
	node.scale = scl
	return node


func _material(key: String, double_sided: bool) -> StandardMaterial3D:
	var cache_key := key + ("_2" if double_sided else "")
	if not _materials.has(cache_key):
		var material := StandardMaterial3D.new()
		material.albedo_color = PALETTE[key]
		material.roughness = 1.0
		material.metallic_specular = 0.2
		if double_sided:
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials[cache_key] = material
	return _materials[cache_key]


## Re-emits a primitive with one normal per triangle: the low-poly faceted look.
static func _faceted(source: PrimitiveMesh) -> ArrayMesh:
	var arrays := source.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	if indices.is_empty():
		for v in vertices:
			st.add_vertex(v)
	else:
		for index in indices:
			st.add_vertex(vertices[index])
	st.generate_normals()
	return st.commit()


## Tapered, V-folded blade rising along +Y and bending along X. Base at the origin.
static func _blade(height: float, base_width: float, bend: float, segments := 5) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var rows: Array = []
	for s in segments + 1:
		var t := float(s) / float(segments)
		var half := base_width * 0.5 * pow(1.0 - t, 0.8)
		var spine := Vector3(bend * t * t, height * t, 0.0)
		# Width faces the camera (X); the midrib ridge folds toward it (+Z).
		rows.append([spine + Vector3(-half, 0, 0), spine + Vector3(0, 0, half * 0.3), spine + Vector3(half, 0, 0)])
	for s in segments:
		var a: Array = rows[s]
		var b: Array = rows[s + 1]
		for side in [[0, 1], [1, 2]]:
			st.add_vertex(a[side[0]]); st.add_vertex(a[side[1]]); st.add_vertex(b[side[0]])
			st.add_vertex(a[side[1]]); st.add_vertex(b[side[1]]); st.add_vertex(b[side[0]])
	st.generate_normals()
	return st.commit()


## Flat leaf lying on the ground along +X with a raised midrib and slightly curled tip.
static func _leaf_lying(length: float, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var segments := 6
	var rows: Array = []
	for s in segments + 1:
		var t := float(s) / float(segments)
		var half := width * 0.5 * sin(PI * t)
		var x := length * t
		var curl := 0.12 * t * t * length * 0.2
		rows.append([Vector3(x, curl, -half), Vector3(x, curl + 0.06 * sin(PI * t) + 0.02, 0), Vector3(x, curl, half)])
	for s in segments:
		var a: Array = rows[s]
		var b: Array = rows[s + 1]
		for side in [[0, 1], [1, 2]]:
			st.add_vertex(a[side[0]]); st.add_vertex(a[side[1]]); st.add_vertex(b[side[0]])
			st.add_vertex(a[side[1]]); st.add_vertex(b[side[1]]); st.add_vertex(b[side[0]])
	st.generate_normals()
	return st.commit()


## World Y of the top screen edge at depth z (any X), for the preset D camera.
static func frame_top_at(z: float) -> float:
	var cam_z := BeeLevel01Framing.CAMERA_DISTANCE
	var cam_y := BeeLevel01Framing.CAMERA_HEIGHT
	return cam_y + (BeeLevel01Framing.top_y() - cam_y) * (cam_z - z) / cam_z
