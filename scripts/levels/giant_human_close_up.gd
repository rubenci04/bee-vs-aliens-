class_name GiantHumanCloseUp
extends RefCounted
## GARDEN IDENTITY 04 — close-up polish of the Giant Human (presentation only). Camera E frames mostly the jean, the
## leg and the boot, so only those change:
##   * jeans (thigh/calf/waist): smooth normals on the sides (hard caps kept) -> a round leg with soft toon bands
##     instead of hexagonal stripes; a bluer denim that survives the warm sun, with a subtle fabric variation;
##   * boots: smooth normals, become canvas sneakers: brick-red upper, cream rubber sole and toe cap. The boot is an
##     ellipsoid; the sole is its own lower rings (rest Y <= SOLE_TOP) and the toe cap its front rings, copied as new
##     skinned meshes (same skin and weights, so they follow the foot) and pushed out by SHELL_GROW to sit on top.
##     Nothing is flattened, so no plate or rim sticks out of the shoe; the boot keeps its exact vertex positions.
## Vertex POSITIONS of the original meshes are never changed and nothing here touches the skeleton, the Run clip,
## the damage hulls, the timing or the safe corridor. Callers apply it after the hulls have sampled the body.

const FABRIC := preload("res://assets/style/toon_fabric.gdshader")
const DENIM := Color(0.21, 0.33, 0.58) # Denim that stays blue under the warm sun without turning into plastic.
const SNEAKER := Color(0.5, 0.17, 0.15)
const MIDSOLE := Color(0.93, 0.89, 0.8)
const JEANS := ["JeansThighL", "JeansThighR", "JeansCalfL", "JeansCalfR", "JeansWaist"]
const BOOTS := ["BootL", "BootR"]
## Boot rest-pose rings (model units, 6x in the level): 0 .008 .03 .062 .1 .138 .17 .192 .2. The sole takes the
## rings up to 0.062 (~0.37 m in the level), the toe cap the front of the rings up to 0.138.
const SOLE_TOP := 0.0625
const TOE_TOP := 0.1385
const TOE_FRONT := 0.085 ## distance in front of the boot centre (Z, toward the toes)
const SHELL_GROW := 1.02

static var _cache: Dictionary = {}


static func apply(model: Node) -> Array[MeshInstance3D]:
	var added: Array[MeshInstance3D] = []
	for name in JEANS:
		var jean := model.find_child(name, true, false) as MeshInstance3D
		if jean != null:
			jean.mesh = _smoothed(jean.mesh, 0.55)
			jean.set_surface_override_material(0, _fabric(DENIM, 0.12, 0.3, 0.1, 0.95))
	for name in BOOTS:
		var boot := model.find_child(name, true, false) as MeshInstance3D
		if boot == null:
			continue
		var original := boot.mesh
		boot.mesh = _smoothed(original, -2.0) # An ellipsoid: smooth all over.
		boot.set_surface_override_material(0, _fabric(SNEAKER, 0.08, 0.25, 0.0, 0.2))
		var box := original.get_aabb()
		var y0 := box.position.y
		var front := box.get_center().z + TOE_FRONT
		added.append(_shell(boot, original, "Sole", func(p: Vector3) -> bool: return p.y <= y0 + SOLE_TOP, MIDSOLE))
		added.append(_shell(boot, original, "ToeCap", func(p: Vector3) -> bool: return p.z >= front and p.y <= y0 + TOE_TOP, MIDSOLE))
	return added


## Toon fabric material (Style C bands + rim + a subtle procedural weave/fade).
static func _fabric(color: Color, variation: float, rim: float, low: float, high: float) -> ShaderMaterial:
	var key := "%s|%s" % [color.to_html(), variation]
	if not _cache.has(key):
		var material := ShaderMaterial.new()
		material.shader = FABRIC
		material.set_shader_parameter("albedo", color)
		material.set_shader_parameter("fabric_variation", variation)
		material.set_shader_parameter("fabric_low", low)
		material.set_shader_parameter("fabric_high", high)
		material.set_shader_parameter("rim_strength", rim)
		material.set_shader_parameter("rim_color", Color(0.85, 0.92, 1.0))
		_cache[key] = material
	return _cache[key]


## Same skinned mesh with smooth normals. Faces whose normal's Y is below `cap_below` (or above -cap_below for
## positive values: hexagonal prism caps) keep flat normals. Positions, bones and weights are copied untouched.
static func _smoothed(source: Mesh, cap_limit: float) -> ArrayMesh:
	var key := "smooth|%d|%s" % [source.get_instance_id(), cap_limit]
	if _cache.has(key):
		return _cache[key]
	var arrays := source.surface_get_arrays(0)
	var st := _begin(arrays)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices := _indices(arrays)
	for t in range(0, indices.size(), 3):
		# The source is flat shaded: its own vertex normals give the true outward face normal (winding-proof).
		var n := (normals[indices[t]] + normals[indices[t + 1]] + normals[indices[t + 2]]).normalized()
		# Prism caps (|n.y| large) stay hard; the sole of the boot (n.y very negative) stays hard.
		var hard := absf(n.y) > cap_limit if cap_limit > 0.0 else n.y < cap_limit
		st.set_smooth_group(-1 if hard else 0)
		for k in 3:
			_vertex(st, arrays, indices[t + k], positions[indices[t + k]])
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, source.surface_get_material(0))
	_cache[key] = mesh
	return mesh


## A shell over part of the boot: the boot's own triangles whose three rest-pose vertices pass `inside`, pushed out
## by SHELL_GROW around the boot's centre so they sit just over it. Same skin and weights; smooth toon shading.
static func _shell(boot: MeshInstance3D, source: Mesh, label: String, inside: Callable, color: Color) -> MeshInstance3D:
	var key := "shell|%d|%s" % [source.get_instance_id(), label]
	var mesh: ArrayMesh = _cache.get(key)
	if mesh == null:
		var arrays := source.surface_get_arrays(0)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var centre := source.get_aabb().get_center()
		var st := _begin(arrays)
		st.set_smooth_group(0)
		var indices := _indices(arrays)
		for t in range(0, indices.size(), 3):
			if not (inside.call(positions[indices[t]]) and inside.call(positions[indices[t + 1]]) and inside.call(positions[indices[t + 2]])):
				continue
			for k in 3:
				var p := positions[indices[t + k]]
				_vertex(st, arrays, indices[t + k], centre + (p - centre) * SHELL_GROW)
		st.generate_normals()
		mesh = st.commit()
		_cache[key] = mesh
	var band := MeshInstance3D.new()
	band.name = boot.name + label
	band.mesh = mesh
	band.skin = boot.skin
	band.skeleton = boot.skeleton
	band.set_surface_override_material(0, BeeToonStyle._material_for(_flat(color), false, BeeToonStyle.OUTLINE_PROP))
	band.set_meta("close_up_polish", true)
	boot.add_sibling(band)
	return band


static func _flat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


static func _begin(arrays: Array) -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bones = arrays[Mesh.ARRAY_BONES]
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if bones != null and positions.size() > 0 and bones.size() / positions.size() == 8:
		st.set_skin_weight_count(SurfaceTool.SKIN_8_WEIGHTS)
	return st


static func _indices(arrays: Array) -> PackedInt32Array:
	var indices = arrays[Mesh.ARRAY_INDEX]
	if indices != null and indices.size() > 0:
		return indices
	var plain := PackedInt32Array()
	for i in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
		plain.append(i)
	return plain


static func _vertex(st: SurfaceTool, arrays: Array, index: int, position: Vector3) -> void:
	var bones = arrays[Mesh.ARRAY_BONES]
	var weights = arrays[Mesh.ARRAY_WEIGHTS]
	if bones != null and bones.size() > 0:
		var per: int = bones.size() / (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		st.set_bones(bones.slice(index * per, index * per + per))
		st.set_weights(weights.slice(index * per, index * per + per))
	var uvs = arrays[Mesh.ARRAY_TEX_UV]
	if uvs != null and uvs.size() > index:
		st.set_uv(uvs[index])
	st.add_vertex(position)
