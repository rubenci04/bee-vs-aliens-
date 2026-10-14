class_name BeeFacetShotStyles
extends RefCounted
## Tanda 3d: selected B visuals only. No gameplay or collision data.
const EMISSION_GAIN := 0.8
const ALBEDO_GAIN := 0.35
const HALO_ALPHA := 0.10
const TRAIL_ALPHA := 0.55
const B_RADII := {&"pebble": 0.16, &"seed": 0.18, &"stone": 0.23, &"mud": 0.20, &"pellet": 0.19, &"bubble": 0.42}
const COLORS := {&"pebble": Color("ef16cf"), &"seed": Color("d70c43"), &"stone": Color("135fff"), &"mud": Color("dfef16"), &"pellet": Color("00eaff"), &"bubble": Color("00d9f5")}
const CORE_COLORS := {&"stone": Color("69ceff"), &"mud": Color("f7ffd0")}
const HALO_COLORS := {&"seed": Color("fff0d5")}

const SEED_HALO_RADIUS := 0.36
const SEED_HALO_ALPHA := 0.28

static func has_style(style: StringName) -> bool:
	return COLORS.has(style)

static func build(style: StringName) -> Node3D:
	var color: Color = COLORS[style]
	var root := Node3D.new()
	root.name = "StyledShot"
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	match style:
		&"pebble":
			var shaft := _piece(body, _faceted_sphere(B_RADII[style]), color)
			shaft.scale = Vector3(1.25, 0.8, 0.8)
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.16
			cone.height = 0.30
			cone.radial_segments = 4
			var tip := _piece(body, _flat(cone), color)
			tip.rotation.z = -PI * 0.5
			tip.position.x = 0.25
		&"seed":
			var seed := _piece(body, _faceted_sphere(B_RADII[style]), color)
			seed.scale = Vector3(1.55, 0.85, 0.8)
			var seam := _piece(body, _faceted_sphere(0.045), color.darkened(0.35))
			seam.position = Vector3(0, 0.07, 0.13)
		&"stone":
			var crystal := _piece(body, _faceted_sphere(B_RADII[style]), color)
			crystal.scale = Vector3(1.22, 0.85, 0.85)
		&"mud":
			_piece(body, _faceted_sphere(B_RADII[style]), color)
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.17
			cone.height = 0.32
			cone.radial_segments = 5
			var tip := _piece(body, _flat(cone), color)
			tip.rotation.z = PI * 0.5
			tip.position.x = -0.26
		&"pellet":
			_piece(body, _faceted_sphere(B_RADII[style]), color)
		&"bubble":
			_piece(body, _faceted_sphere(B_RADII[style]), Color(color, 0.24))
			var rim := TorusMesh.new()
			rim.inner_radius = 0.365
			rim.outer_radius = 0.42
			rim.rings = 10
			rim.ring_segments = 4
			var edge := _piece(body, _flat(rim), color)
			edge.rotation.x = PI * 0.5
			_piece(body, _faceted_sphere(0.13), color)
	if style in [&"stone", &"mud"]:
		var core := _piece(body, _faceted_sphere(0.07), CORE_COLORS[style])
		core.position.z = 0.18
	var halo_radius := 0.46 if style == &"bubble" else (SEED_HALO_RADIUS if style == &"seed" else 0.25)
	var halo_alpha := SEED_HALO_ALPHA if style == &"seed" else HALO_ALPHA
	var halo := _piece(body, _faceted_sphere(halo_radius), Color(HALO_COLORS.get(style, color.lightened(0.45)), halo_alpha))
	halo.name = "SoftHalo"
	return root

static func trail_material(style: StringName) -> StandardMaterial3D:
	return _emissive(Color(COLORS[style], TRAIL_ALPHA))

static func _emissive(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r * ALBEDO_GAIN, color.g * ALBEDO_GAIN, color.b * ALBEDO_GAIN, color.a)
	material.emission_enabled = true
	material.emission = Color(color, 1.0)
	material.emission_energy_multiplier = EMISSION_GAIN
	material.roughness = 1.0
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		material.emission_enabled = false
	return material

static func _piece(parent: Node3D, mesh: Mesh, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _emissive(color)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)
	return visual

static func _faceted_sphere(radius: float) -> ArrayMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	return _flat(mesh)

static func _flat(mesh: Mesh) -> ArrayMesh:
	var vertices := mesh.get_faces()
	var normals := PackedVector3Array()
	for i in range(0, vertices.size(), 3):
		var normal := (vertices[i + 2] - vertices[i]).cross(vertices[i + 1] - vertices[i]).normalized()
		for j in 3:
			normals.append(normal)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

