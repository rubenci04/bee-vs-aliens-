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


## A thin box from `from` to `to` (world space, top_level). Re-aim later with `place_line`.
static func line(parent: Node, from: Vector3, to: Vector3, width: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, width, 0.04)
	box.material = material(color)
	node.mesh = box
	node.top_level = true
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	place_line(node, from, to)
	return node


static func place_line(node: Node3D, from: Vector3, to: Vector3) -> void:
	var delta := Vector3(to.x - from.x, to.y - from.y, 0.0)
	var length := maxf(delta.length(), 0.01)
	node.global_position = Vector3((from.x + to.x) * 0.5, (from.y + to.y) * 0.5, from.z)
	node.rotation = Vector3(0.0, 0.0, atan2(delta.y, delta.x))
	node.scale = Vector3(length, 1.0, 1.0)


## A ring facing the side camera (XY plane), radius in metres.
static func ring(parent: Node, center: Vector3, radius: float, thickness: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0 - thickness
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 6
	torus.material = material(color)
	node.mesh = torus
	node.top_level = true
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.global_position = center
	node.rotation.x = PI * 0.5
	node.scale = Vector3(radius, 1.0, radius)
	return node


## A flat disc lying on the ground (XZ plane).
static func ground_disc(parent: Node, center: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 20
	disc.material = material(color)
	node.mesh = disc
	node.top_level = true
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.global_position = center
	node.scale = Vector3(radius, 1.0, radius * 0.6)
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
