extends RefCounted
## Level 01 legacy capsules only. Collection, placement and collision stay with the original Area3D.
const RADIUS := 0.42
const RING_RADIUS := 0.51
const DEPTH := 0.10
const EMISSION := 1.2
const GLYPH_COLOR := Color(1.0, 0.96, 0.80)
const COLORS := {0: Color(0.42, 0.48, 0.92), 1: Color(0.95, 0.65, 0.30)}
const HOVER := preload("res://scripts/items/toon_pickup_hover.gd")

static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.emission_enabled = true
	result.emission = color
	result.emission_energy_multiplier = EMISSION
	return result

static func mesh(parent: Node3D, name: String, shape: Mesh, color: Color, at := Vector3.ZERO) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = name
	result.mesh = shape
	result.material_override = material(color)
	result.position = at
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(result)
	return result

static func dress_old(item: BeePowerupPickup) -> bool:
	if item.has_node("PickupMedallion") or not item.get_node_or_null("SpreadVisual") is MeshInstance3D:
		return false
	for name in ["SpreadVisual", "BombVisual", "Label", "Halo"]:
		var old := item.get_node_or_null(name) as Node3D
		if old != null:
			old.hide() # Preserve all original assets and scene nodes.
	var root := Node3D.new()
	root.name = "PickupMedallion"
	root.set_script(HOVER)
	item.add_child(root)
	var hex := CylinderMesh.new()
	hex.top_radius = RADIUS
	hex.bottom_radius = RADIUS
	hex.height = DEPTH
	hex.radial_segments = 6
	mesh(root, "Hexagon", hex, Color(0.18, 0.13, 0.08)).rotation.x = PI * 0.5
	var rim := TorusMesh.new()
	rim.inner_radius = RING_RADIUS - 0.055
	rim.outer_radius = RING_RADIUS
	rim.rings = 24
	rim.ring_segments = 6
	mesh(root, "TypeRing", rim, COLORS[int(item.kind)]).rotation.x = PI * 0.5
	var trim := TorusMesh.new()
	trim.inner_radius = RING_RADIUS
	trim.outer_radius = RING_RADIUS + 0.035
	trim.rings = 24
	trim.ring_segments = 6
	mesh(root, "LightRim", trim, GLYPH_COLOR).rotation.x = PI * 0.5
	var halo := SphereMesh.new()
	halo.radius = 0.62
	halo.height = 1.24
	var glow := mesh(root, "SoftHalo", halo, COLORS[int(item.kind)], Vector3(0, 0, -0.08))
	glow.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.material_override.cull_mode = BaseMaterial3D.CULL_FRONT
	glow.material_override.albedo_color.a = 0.18
	if item.kind == BeePowerupPickup.Kind.BOMB:
		var ball := SphereMesh.new()
		ball.radius = 0.16
		ball.height = 0.32
		ball.radial_segments = 8
		ball.rings = 4
		mesh(root, "BombGlyph", ball, GLYPH_COLOR, Vector3(0, -0.02, 0.10))
		var fuse := BoxMesh.new()
		fuse.size = Vector3(0.06, 0.12, 0.035)
		mesh(root, "FuseGlyph", fuse, GLYPH_COLOR, Vector3(0.06, 0.18, 0.10)).rotation.z = -0.4
	else:
		for side in [-1, 0, 1]:
			var arrow := PrismMesh.new()
			arrow.size = Vector3(0.14, 0.26, 0.04)
			mesh(root, "SpreadGlyph%d" % side, arrow, GLYPH_COLOR, Vector3(side * 0.19, 0, 0.10)).rotation.z = -side * 0.3
	return true
