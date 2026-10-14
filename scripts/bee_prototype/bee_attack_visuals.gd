class_name BeeAttackVisuals
extends RefCounted
## COMBAT VARIETY 01: tiny shared telegraph / hazard visuals built in code (no assets): warning lines, rings and discs.
## Everything is unshaded and transparent so it reads over any lighting; nothing here deals damage.

static var _materials: Dictionary = {}


static func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_color = color
		m.render_priority = 40
		_materials[key] = m
	return _materials[key]


## Keep T3 warning legibility without changing restored active attack materials.
static func warning_material(color: Color) -> StandardMaterial3D:
	var key := "warning|" + color.to_html()
	if not _materials.has(key):
		var own := material(color).duplicate() as StandardMaterial3D
		own.disable_fog = true
		_materials[key] = own
	return _materials[key]


## A thin box from `from` to `to` (world space, top_level). Re-aim later with `place_line`.
static func line(parent: Node, from: Vector3, to: Vector3, width: float, color: Color, preserve_warning := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var box := BoxMesh.new()
	var warning := color.r > 0.8 and color.g > 0.25 and color.b < 0.4
	var enhanced := warning or preserve_warning
	if enhanced:
		width = maxf(width, BeeGameSettings.DANGER_LINE_MIN_WIDTH)
	if warning:
		color.a = maxf(color.a, BeeGameSettings.WARNING_MIN_ALPHA)
	box.size = Vector3(1.0, width, 0.04)
	box.material = warning_material(color) if enhanced else material(color)
	node.mesh = box
	node.top_level = true
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	if enhanced:
		var edge := MeshInstance3D.new()
		edge.name = "ReadabilityEdge"
		var outline := BoxMesh.new()
		outline.size = Vector3(1.0, width + BeeGameSettings.WARNING_EDGE_WIDTH * 2.0, 0.02)
		outline.material = warning_material(BeeGameSettings.WARNING_EDGE if warning else BeeGameSettings.DANGER_BORDER)
		edge.mesh = outline
		edge.position.z = -0.035
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(edge)
		if not warning and color.a >= 0.7 and color.s > 0.35:
			var core := MeshInstance3D.new()
			core.name = "DangerCore"
			var center := BoxMesh.new()
			center.size = Vector3(1.0, maxf(width * 0.3, 0.025), 0.02)
			center.material = warning_material(BeeGameSettings.DANGER_CORE)
			core.mesh = center
			core.position.z = 0.04
			core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.add_child(core)
	place_line(node, from, to)
	return node


## Warning becomes an active strand: restore its original width and material.
static func restore_active_line(node: MeshInstance3D, color: Color, width: float) -> void:
	for child_name in ["ReadabilityEdge", "DangerCore"]:
		var child := node.get_node_or_null(child_name)
		if child != null:
			node.remove_child(child)
			child.queue_free()
	(node.mesh as BoxMesh).size.y = width
	node.mesh.material = material(color)


static func place_line(node: Node3D, from: Vector3, to: Vector3) -> void:
	var delta := Vector3(to.x - from.x, to.y - from.y, 0.0)
	var length := maxf(delta.length(), 0.01)
	node.global_position = Vector3((from.x + to.x) * 0.5, (from.y + to.y) * 0.5, from.z)
	node.rotation = Vector3(0.0, 0.0, atan2(delta.y, delta.x))
	node.scale = Vector3(length, 1.0, 1.0)


## LOTE 14 · ETAPA 3.3: distance (m, XY) from `point` to the segment from -> to.
static func segment_distance(point: Vector3, from: Vector3, to: Vector3) -> float:
	var a := Vector2(from.x, from.y)
	var ab := Vector2(to.x, to.y) - a
	var p := Vector2(point.x, point.y)
	if ab.length_squared() < 0.0001:
		return (p - a).length()
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return (p - (a + ab * t)).length()


## A locked warning line disappears once Bee has dodged it (she stands more than `clearance` m from the line the shots will take).
static func hide_when_dodged(line: MeshInstance3D, from: Vector3, locked_point: Vector3, bee: Vector3, clearance: float, length := 14.0) -> void:
	var direction := Vector3(locked_point.x - from.x, locked_point.y - from.y, 0.0)
	var to := from + (direction.normalized() * length if direction.length() > 0.01 else Vector3.ZERO)
	line.visible = segment_distance(bee, from, to) <= clearance


## A ring facing the side camera (XY plane), radius in metres.
static func ring(parent: Node, center: Vector3, radius: float, thickness: float, color: Color, preserve_warning := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0 - thickness
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 6
	var warning := color.r > 0.8 and color.g > 0.25 and color.b < 0.4
	var enhanced := warning or preserve_warning
	torus.material = warning_material(Color(color, maxf(color.a, 0.9))) if enhanced else material(color)
	node.mesh = torus
	node.top_level = true
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.global_position = center
	node.rotation.x = PI * 0.5
	node.scale = Vector3(radius, 1.0, radius)
	if enhanced:
		var edge := MeshInstance3D.new()
		edge.name = "ReadabilityEdge"
		var outline := TorusMesh.new()
		outline.inner_radius = 1.0 - thickness - 0.045
		outline.outer_radius = 1.045
		outline.material = warning_material(BeeGameSettings.WARNING_EDGE if warning else BeeGameSettings.DANGER_BORDER)
		edge.mesh = outline
		edge.position.y = 0.035 # Behind the camera-facing coloured ring after its X rotation.
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(edge)
	return node


## A flat disc lying on the ground (XZ plane).
static func ground_disc(parent: Node, center: Vector3, radius: float, color: Color, warning := true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 20
	disc.material = warning_material(Color(color, maxf(color.a, BeeGameSettings.WARNING_MIN_ALPHA))) if warning else material(color)
	node.mesh = disc
	node.top_level = true
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.global_position = center
	node.scale = Vector3(radius, 1.0, radius * 0.6)
	if warning:
		var border := MeshInstance3D.new()
		border.name = "WarningBorder"
		var rim := TorusMesh.new()
		rim.inner_radius = 0.95
		rim.outer_radius = 1.05
		rim.material = warning_material(BeeGameSettings.WARNING_EDGE)
		border.mesh = rim
		border.position.y = 0.025
		border.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(border)
		var dark_edge := MeshInstance3D.new()
		dark_edge.name = "DarkOuterBorder"
		var outer := TorusMesh.new()
		outer.inner_radius = 1.04
		outer.outer_radius = 1.12
		outer.material = warning_material(BeeGameSettings.DANGER_BORDER)
		dark_edge.mesh = outer
		dark_edge.position.y = 0.02
		dark_edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(dark_edge)
	return node


## A sphere of `radius` with a flat colour (orbs, mines, shells).
static func sphere(parent: Node, center: Vector3, radius: float, color: Color, emissive := true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.6
	mesh.material = m
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.global_position = center
	return node


## An alien-team damage area (sphere or box) owned by `attacker`. Hits each hurtbox once per enable.
static func hazard_area(parent: Node, attacker: Node, damage: int, shape: Shape3D) -> DamageHitbox3D:
	var hitbox := DamageHitbox3D.new()
	hitbox.team_id = &"alien"
	hitbox.damage = damage
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	hitbox.attacker_path = NodePath()
	var collider := CollisionShape3D.new()
	collider.shape = shape
	hitbox.add_child(collider)
	parent.add_child(hitbox)
	hitbox.attacker = attacker
	return hitbox
