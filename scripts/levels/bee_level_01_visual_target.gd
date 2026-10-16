class_name BeeLevel01VisualTarget
extends Node3D
## VISUAL TARGET 01 / VISUAL LEVEL 01: decoration of the whole of Level 01 (x = -15 .. LEVEL_END).
## Presentation only: no collision, no gameplay nodes, no imported textures. Everything is
## generated from Godot primitives / SurfaceTool with flat (faceted) normals and flat colours,
## then merged into one mesh per (32 m chunk, material) so the 360 m level stays cheap to draw.
## Layers (camera = preset D, see BeeLevel01Framing):
##   foreground  z > 4.5 : dark leaves, always projected BELOW the playfield (see FOREGROUND_SCREEN_Y)
##   midground   |z| < 2.5: kept clear (ground, mulch, low pebbles only)
##   background  z < -2.5 : giant grass blades and flower stems (4-10 m), then deep muted silhouettes.
## Flower heads (pink / warm yellow / violet) sit at z <= FLOWER_MAX_Z, always behind the play band.
## Segment A (x up to X_MAX) replays the approved Visual Target 01 random sequence; segment B
## (X_MAX .. LEVEL_END) continues it with its own seed, so the 0-72 m look does not change.

const X_MIN := -15.0
const X_MAX := 72.0 # End of the originally approved slice.
const LEVEL_END := 380.0 # Sector is 360 m; the last frame still shows ~12 m past it.
const GROUND_Y := -0.2
const MIDGROUND_CLEAR_Z := 2.5
const FOREGROUND_MIN_Z := 4.5
const FLOWER_MAX_Z := -6.5
## NOCHE 01 · ETAPA 3 — readability: no tall grass blade between this depth and the flight plane (the central corridor stays
## clean for Bee and the enemies). Blades drawn closer are mirrored behind it.
const CORRIDOR_CLEAR_Z := -5.0
const CHUNK_WIDTH := 32.0
## Foreground geometry must project onto the Z=0 plane at or below this height, i.e. under
## crates, pollen and Bee's lowest flight height (0.7 m).
const FOREGROUND_SCREEN_Y := 0.0
## Imported props replaced by this decoration. Hidden, never deleted. Bottle, log and rocks stay.
const HIDDEN_SCENERY_PREFIXES := ["Tree", "ClusterTree", "PocketTree", "Flower", "ClusterFlower", "PocketFlower", "MidFern", "FrontFern", "ClusterFern", "NearFern", "PocketFern"]

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
	"petal_warm": Color(0.93, 0.7, 0.24),
	"petal_pink": Color(0.86, 0.45, 0.6),
	"petal_violet": Color(0.58, 0.42, 0.8),
	"flower_core": Color(0.62, 0.36, 0.1),
	"far_green": Color(0.3, 0.41, 0.27),
	"far_dark": Color(0.22, 0.32, 0.22),
	"far_petal": Color(0.8, 0.7, 0.38),
	"foreground": Color(0.07, 0.11, 0.05),
	"veil": Color(0.4, 0.5, 0.37), # VISUAL POLISH 02 depth layers.
	"veil_dark": Color(0.32, 0.43, 0.35),
	"seed": Color(0.72, 0.6, 0.28),
}
const GROUND_TINT_KEYS := ["mulch", "mulch_dark", "mulch_light", "pebble", "pebble_warm", "leaf_fallen"]
const FLOWER_PETALS := ["petal_pink", "petal_warm", "petal_violet"]

var _materials: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _flower_rng := RandomNumberGenerator.new() # Flower heads never consume the scatter sequence.
var _buckets: Dictionary = {}
var _flower_count := 0
var hidden_scenery: Array[String] = []
var foreground_nodes: Array[Node3D] = []
var batches: Array[MeshInstance3D] = []
var flower_head_count := 0


func _ready() -> void:
	_rng.seed = 1101
	_flower_rng.seed = 7311
	_tidy_existing_scenery()
	_build_ground_slab()
	# Segment A: identical call order and ranges to Visual Target 01.
	_build_ground_patches(70, X_MIN, X_MAX)
	_build_pebbles_and_leaves(X_MIN, X_MAX, [[Vector3(7.5, GROUND_Y + 0.03, -2.9), 3.4, 0.35], [Vector3(36.0, GROUND_Y + 0.03, -5.2), 4.2, -0.5], [Vector3(57.5, GROUND_Y + 0.03, -3.4), 3.0, 2.6]])
	_build_giant_stems(X_MIN, X_MAX)
	_build_background(X_MIN - 25.0, X_MAX + 30.0, X_MIN - 45.0, X_MAX + 50.0)
	_build_foreground([[29.0, 5.8, 1.1, 0.9], [51.0, 5.4, -1.2, 1.1]])
	# Segment B: the rest of the level, same recipe, new seed.
	_rng.seed = 2202
	var length := LEVEL_END - X_MAX
	_build_ground_patches(int(length * 0.8), X_MAX, LEVEL_END)
	_build_pebbles_and_leaves(X_MAX, LEVEL_END, _leaf_specs(X_MAX + 6.0, LEVEL_END))
	_build_giant_stems(X_MAX, LEVEL_END)
	_build_background(X_MAX + 30.0, LEVEL_END + 30.0, X_MAX + 50.0, LEVEL_END + 50.0)
	_build_foreground(_foreground_specs(X_MAX + 12.0, LEVEL_END))
	_build_depth_layers(X_MIN, LEVEL_END) # VISUAL POLISH 02: own RNG, the sequences above are untouched.
	_flush_batches()


## Existing imported props are replaced by this decoration: full trees, textured ferns and the
## Kenney flower blocks are hidden everywhere (never deleted). Bottles, the hollow log and rocks stay.
func _tidy_existing_scenery() -> void:
	var scenery := get_parent().get_node_or_null("Scenery")
	if scenery == null:
		return
	for child: Node3D in scenery.get_children():
		var label := str(child.name)
		for prefix: String in HIDDEN_SCENERY_PREFIXES:
			if label.begins_with(prefix):
				child.visible = false
				hidden_scenery.append(label)
				break


func _build_ground_slab() -> void:
	var slab := BoxMesh.new()
	slab.size = Vector3(LEVEL_END - X_MIN + 80.0, 0.1, 74.0)
	_add(slab, "mulch", Vector3((X_MIN + LEVEL_END) * 0.5 + 20.0, GROUND_Y - 0.04, -27.0), Vector3.ZERO, Vector3.ONE, "MulchGround", false, false, false)


func _build_ground_patches(count: int, x0: float, x1: float) -> void:
	for i in count:
		var disc := CylinderMesh.new()
		disc.radial_segments = 6
		disc.rings = 1
		disc.height = 0.02
		var r := _rng.randf_range(0.6, 2.4)
		disc.top_radius = r
		disc.bottom_radius = r
		var key: String = ["mulch_dark", "mulch_light", "mulch_dark"][i % 3]
		var pos := Vector3(_rng.randf_range(x0, x1), GROUND_Y + 0.02 + 0.001 * float(i % 5), _rng.randf_range(-14.0, 6.0))
		_add(_faceted(disc), key, pos, Vector3(0, _rng.randf() * TAU, 0), Vector3(1.0, 1.0, _rng.randf_range(0.5, 1.0)), "MulchPatch%d" % i, false)


func _build_pebbles_and_leaves(x0: float, x1: float, leaf_specs: Array) -> void:
	var count := 0
	var x := x0
	while x < x1:
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
	for spec in leaf_specs:
		_add(_leaf_lying(spec[1], spec[1] * 0.42), "leaf_fallen", spec[0], Vector3(0, spec[2], 0), Vector3.ONE, "FallenLeaf", true, true)


func _leaf_specs(from_x: float, to_x: float) -> Array:
	var specs := []
	var x := from_x
	while x < to_x:
		specs.append([Vector3(x, GROUND_Y + 0.03, _rng.randf_range(-5.4, -3.0)), _rng.randf_range(3.0, 4.4), _rng.randf_range(-2.8, 2.8)])
		x += _rng.randf_range(34.0, 58.0)
	return specs


func _foreground_specs(from_x: float, to_x: float) -> Array:
	var specs := []
	var x := from_x
	var side := 1.0
	while x < to_x:
		specs.append([x, _rng.randf_range(5.3, 5.9), side * _rng.randf_range(0.9, 1.3), _rng.randf_range(0.9, 1.15)])
		side = -side
		x += _rng.randf_range(32.0, 48.0)
	return specs


## Giant grass blades and flower stems behind the flight plane, 4-10 m tall.
func _build_giant_stems(x0: float, x1: float) -> void:
	var x := x0
	var i := 0
	while x < x1:
		x += _rng.randf_range(1.2, 2.8)
		var z := _rng.randf_range(-9.0, -MIDGROUND_CLEAR_Z - 0.3)
		var height := _rng.randf_range(4.0, 10.0)
		if z > CORRIDOR_CLEAR_Z:
			z = 2.0 * CORRIDOR_CLEAR_Z - z # NOCHE 01 · ETAPA 3: tall blades leave the band next to the flight plane (mirrored back; same RNG draws).
		if i % 3 == 2 and height >= 6.0:
			_flower_stem(Vector3(x, GROUND_Y, FLOWER_MAX_Z + (z + 2.8) * 0.65), height, i)
			if height < 7.5:
				_rng.randf() # Keeps the scatter sequence aligned with Visual Target 01.
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
	_rng.randf_range(0.8, 1.2) # Keeps the scatter sequence aligned with Visual Target 01.
	var radius := _flower_rng.randf_range(0.75, 1.15)
	var tilt := Vector3(_flower_rng.randf_range(-0.35, 0.1), _flower_rng.randf_range(-0.5, 0.5), _flower_rng.randf_range(-0.3, 0.3))
	var petals: String = FLOWER_PETALS[_flower_count % FLOWER_PETALS.size()]
	_flower_count += 1
	flower_head_count += 1
	var center := base + Vector3(0, height, 0)
	_add(_flower_face(radius), petals, center, tilt, Vector3.ONE, "FlowerHead%d" % index, true, false)
	var core := SphereMesh.new()
	core.radial_segments = 6
	core.rings = 3
	core.radius = radius * 0.3
	core.height = radius * 0.3
	_add(_faceted(core), "flower_core", center + Basis.from_euler(tilt) * Vector3(0, 0, radius * 0.1), Vector3.ZERO, Vector3.ONE, "FlowerCore%d" % index, true)


## Faceted daisy face: 8 diamond petals around the origin in the XY plane, tips cupped toward +Z.
static func _flower_face(radius: float, petals := 8) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for k in petals:
		var a := TAU * float(k) / float(petals)
		var d := Vector3(cos(a), sin(a), 0.0)
		var p := Vector3(-sin(a), cos(a), 0.0)
		var base := d * radius * 0.2
		var left := d * radius * 0.58 - p * radius * 0.2 + Vector3(0, 0, radius * 0.05)
		var right := d * radius * 0.58 + p * radius * 0.2 + Vector3(0, 0, radius * 0.05)
		var tip := d * radius + Vector3(0, 0, radius * 0.13)
		for v in [base, right, left, left, right, tip]:
			st.add_vertex(v)
		# Closed thin petals support the same inverted-hull outline as other props.
		var back := Vector3(0, 0, -radius * 0.04)
		for v in [base, left, right, left, tip, right]:
			st.add_vertex(v + back)
		var edge := [base, right, tip, left]
		for i in 4:
			var a0: Vector3 = edge[i]
			var b0: Vector3 = edge[(i + 1) % 4]
			for v in [a0, a0 + back, b0, b0, a0 + back, b0 + back]:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


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
func _build_background(x0: float, x1: float, mound_x0: float, mound_x1: float) -> void:
	var x := x0
	var i := 0
	while x < x1:
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
	var mx := mound_x0
	var m := 0
	while mx < mound_x1:
		mx += _rng.randf_range(6.0, 9.0)
		var mound := SphereMesh.new()
		mound.radial_segments = 9
		mound.rings = 5
		mound.radius = 1.0
		mound.height = 2.0
		var radius := _rng.randf_range(7.0, 11.0)
		_add(_faceted(mound), "far_dark" if m % 2 else "far_green", Vector3(mx, GROUND_Y, _rng.randf_range(-42.0, -32.0)), Vector3(0, _rng.randf() * TAU, 0), Vector3(radius, _rng.randf_range(6.0, 9.5), radius * 0.6), "Hedge%d" % m, false)
		m += 1


## VISUAL POLISH 02 — extra depth layers, built with their OWN random generator so the approved scatter sequences above stay
## identical:
##   veil    a soft band of broad, muted blades far behind the stems (z -20 .. -13): fog does the rest, so it reads as out-of-focus
##   seeds   clusters of 2-3 slender seed-grass stems at irregular gaps (z -8 .. -4.5) that break the rows of giant stems
## Spacing is deliberately uneven (long empty stretches, then clumps) so no two stretches of the level repeat.
func _build_depth_layers(x0: float, x1: float) -> void:
	var layer_rng := RandomNumberGenerator.new()
	layer_rng.seed = 9091
	var x := x0
	var i := 0
	while x < x1:
		x += layer_rng.randf_range(0.9, 4.6) if layer_rng.randf() < 0.7 else layer_rng.randf_range(5.0, 9.0)
		var height := layer_rng.randf_range(5.0, 13.0)
		var blade := _blade(height, layer_rng.randf_range(1.2, 2.4), layer_rng.randf_range(-2.5, 2.5))
		_add(blade, "veil" if i % 3 else "veil_dark", Vector3(x, GROUND_Y, layer_rng.randf_range(-20.0, -13.0)), Vector3(0, layer_rng.randf_range(-0.6, 0.6), 0), Vector3.ONE, "VeilBlade%d" % i, false, true)
		i += 1
	x = x0
	i = 0
	while x < x1:
		x += layer_rng.randf_range(4.0, 11.0)
		for k in layer_rng.randi_range(2, 3):
			var base := Vector3(x + float(k) * layer_rng.randf_range(0.3, 0.7), GROUND_Y, layer_rng.randf_range(-8.0, -4.5))
			var height := layer_rng.randf_range(2.4, 5.5)
			var bend := layer_rng.randf_range(-0.7, 0.7)
			var stalk := _blade(height, 0.32, bend, 4) # Thick enough to read as a stalk (a thin one made the head look like it floated).
			_add(stalk, "grass", base, Vector3(0, layer_rng.randf_range(-0.4, 0.4), 0), Vector3.ONE, "SeedStalk%d_%d" % [i, k], true, true)
			var head := SphereMesh.new()
			head.radial_segments = 5
			head.rings = 3
			head.radius = 0.16
			head.height = 0.55
			var tip := base + Vector3(bend, height, 0) # The blade bends by `bend` at its tip (t = 1).
			_add(_faceted(head), "seed", tip + Vector3(0, 0.1, 0), Vector3(0, 0, layer_rng.randf_range(-0.3, 0.3)), Vector3.ONE, "SeedHead%d_%d" % [i, k], true)
		i += 1


## Dark leaves very close to the camera. Their height is derived from the camera so that,
## in screen space, they only cover the band below FOREGROUND_SCREEN_Y on the play plane.
func _build_foreground(specs: Array) -> void:
	for spec in specs:
		var z: float = spec[1]
		var height := foreground_height_limit(z) - GROUND_Y - 0.05
		var leaf := _blade(height, spec[3], spec[2], 4)
		var node := _add(leaf, "foreground", Vector3(spec[0], GROUND_Y, z), Vector3.ZERO, Vector3.ONE, "ForegroundLeaf%d" % foreground_nodes.size(), false, true, false)
		foreground_nodes.append(node)


## Highest world Y at depth z that still projects at/below FOREGROUND_SCREEN_Y on the Z=0 plane.
static func foreground_height_limit(z: float) -> float:
	var cam_y := BeeLevel01Framing.CAMERA_HEIGHT
	var cam_z := BeeLevel01Framing.CAMERA_DISTANCE
	return cam_y + (FOREGROUND_SCREEN_Y - cam_y) * (cam_z - z) / cam_z


## batch = true: the mesh is baked (transformed) into its (chunk, material) bucket instead of
## becoming a node; _flush_batches() turns every bucket into one MeshInstance3D.
func _add(mesh: Mesh, key: String, pos: Vector3, rot: Vector3, scl: Vector3, label: String, shadows: bool, double_sided := false, batch := true) -> MeshInstance3D:
	if batch:
		_bake(mesh as ArrayMesh, key, pos, rot, scl, shadows, double_sided)
		return null
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


func _bake(mesh: ArrayMesh, key: String, pos: Vector3, rot: Vector3, scl: Vector3, shadows: bool, double_sided: bool) -> void:
	var chunk := floori(pos.x / CHUNK_WIDTH)
	var bucket_key := "%d|%s|%s|%s" % [chunk, key, double_sided, shadows]
	if not _buckets.has(bucket_key):
		_buckets[bucket_key] = {"chunk": chunk, "key": key, "double_sided": double_sided, "shadows": shadows, "vertices": PackedVector3Array(), "normals": PackedVector3Array()}
	var bucket: Dictionary = _buckets[bucket_key]
	var xf := Basis.from_euler(rot) * Basis.from_scale(scl)
	var normal_basis := xf.inverse().transposed()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var out_vertices: PackedVector3Array = bucket["vertices"]
	var out_normals: PackedVector3Array = bucket["normals"]
	if indices.is_empty():
		for i in vertices.size():
			out_vertices.append(xf * vertices[i] + pos)
			out_normals.append((normal_basis * normals[i]).normalized())
	else:
		for index in indices:
			out_vertices.append(xf * vertices[index] + pos)
			out_normals.append((normal_basis * normals[index]).normalized())
	bucket["vertices"] = out_vertices
	bucket["normals"] = out_normals


func _flush_batches() -> void:
	var keys := _buckets.keys()
	keys.sort()
	for bucket_key in keys:
		var bucket: Dictionary = _buckets[bucket_key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = bucket["vertices"]
		arrays[Mesh.ARRAY_NORMAL] = bucket["normals"]
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var node := MeshInstance3D.new()
		node.name = "Batch_c%d_%s%s%s" % [bucket["chunk"], bucket["key"], "_2" if bucket["double_sided"] else "", "_s" if bucket["shadows"] else ""]
		node.mesh = mesh
		node.material_override = _material(bucket["key"], bucket["double_sided"])
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bucket["shadows"] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		batches.append(node)
	_buckets.clear()


## VISUAL POLISH 02: the decoration uses the same style C toon shader as every actor and prop (3 light bands, rim, fine
## outline on closed solids) instead of the smooth StandardMaterial3D it had, so nothing in the level has another "look".
## No rim on the ground (it faces the camera at a grazing angle and would wash out); no outline on thin blades / petals.
const OUTLINE_KEYS := ["pebble", "pebble_warm", "flower_core", "stem", "petal_yellow", "petal_cream", "petal_warm", "petal_pink", "petal_violet"]
const NO_RIM_KEYS := ["mulch", "mulch_dark", "mulch_light", "leaf_fallen", "grass", "grass_yellow", "foreground", "far_green", "far_dark", "veil", "veil_dark"]


func _material(key: String, double_sided: bool) -> ShaderMaterial:
	var cache_key := key + ("_2" if double_sided else "")
	if not _materials.has(cache_key):
		var material := ShaderMaterial.new()
		material.shader = BeeToonStyle.TOON_DOUBLE if double_sided else BeeToonStyle.TOON
		material.set_shader_parameter("albedo", PALETTE[key])
		material.set_shader_parameter("rim_strength", 0.0 if key in NO_RIM_KEYS else 0.22)
		if key in OUTLINE_KEYS and not double_sided:
			material.next_pass = BeeToonStyle.shared_outline(BeeToonStyle.OUTLINE_PROP)
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


## Sunset readability: the soil, pebbles and fallen leaves get darker and less saturated so Bee
## (golden, then orange in the low sun) separates from the ground. strength 0 = approved palette.
func apply_ground_tint(strength: float) -> void:
	for cache_key: String in _materials:
		var key := cache_key.trim_suffix("_2")
		if not GROUND_TINT_KEYS.has(key):
			continue
		var base: Color = PALETTE[key]
		(_materials[cache_key] as ShaderMaterial).set_shader_parameter("albedo", Color.from_hsv(base.h, base.s * (1.0 - 0.5 * strength), base.v * (1.0 - 0.42 * strength)))
