class_name BeeShotPalette
extends RefCounted
## LOTE 9 · ETAPA B — the shots of both sides must read apart at a glance, at any distance and under every light of the day:
##   Bee      a round PLASMA BALL: white-hot core, warm gold halo and a short warm trail (no arrow, no streak)
##   enemies  a cold ORB: pale cyan core, cyan halo and a violet rim, short cyan trail (bigger on the UFO)
## Change the look here (BEE_SHOT_COLOR / ENEMY_SHOT_COLOR and their cores / rim). The Compatibility renderer has no bloom,
## so the glow is layered unshaded spheres (core opaque, halo and rim translucent). Meshes / materials are shared.

const BEE_SHOT_COLOR := Color(1.0, 0.72, 0.16) # Warm gold halo.
const BEE_SHOT_CORE := Color(1.0, 0.99, 0.9) # White-hot core.
const ENEMY_SHOT_COLOR := Color(0.18, 0.92, 1.0) # Cyan halo: the hostile colour.
const ENEMY_SHOT_CORE := Color(0.86, 1.0, 1.0)
const ENEMY_SHOT_RIM := Color(0.66, 0.28, 1.0) # Violet outer rim.
## Radii in metres: [core, halo, outer glow].
const BEE_RADII := Vector3(0.075, 0.15, 0.22)
const ENEMY_RADII := Vector3(0.08, 0.17, 0.26)
const HALO_ALPHA := 0.6
const OUTER_ALPHA := 0.24
## Short trails: particles alive this long (s).
const BEE_TRAIL_SECONDS := 0.12
const ENEMY_TRAIL_SECONDS := 0.14
const PLASMA_NAME := "PlasmaBall"

static var _meshes := {}


static func _sphere(key: String, radius: float, color: Color, priority: int, transparent: bool) -> SphereMesh:
	if _meshes.has(key):
		return _meshes[key]
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.render_priority = priority
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_FRONT # Only the far shell: the halo never hides its own core.
	mesh.material = material
	_meshes[key] = mesh
	return mesh


## The ball itself (core + halo + outer glow), centred on the projectile.
static func plasma(enemy: bool, size := 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = PLASMA_NAME
	var radii := ENEMY_RADII if enemy else BEE_RADII
	var core_color := ENEMY_SHOT_CORE if enemy else BEE_SHOT_CORE
	var halo_color := ENEMY_SHOT_COLOR if enemy else BEE_SHOT_COLOR
	var outer_color := ENEMY_SHOT_RIM if enemy else BEE_SHOT_COLOR
	var tag := "enemy" if enemy else "bee"
	var layers := [
		["Core", _sphere(tag + "_core", radii.x, core_color, 3, false)],
		["Halo", _sphere(tag + "_halo", radii.y, Color(halo_color, HALO_ALPHA), 2, true)],
		["Outer", _sphere(tag + "_outer", radii.z, Color(outer_color, OUTER_ALPHA), 1, true)],
	]
	for layer in layers:
		var mesh := MeshInstance3D.new()
		mesh.name = str(layer[0])
		mesh.mesh = layer[1]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mesh)
	root.scale = Vector3.ONE * size
	return root


## A short trail of fading specks in the shot colour (world space).
static func trail(enemy: bool, size := 1.0) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "PlasmaTrail"
	particles.amount = 10
	particles.lifetime = ENEMY_TRAIL_SECONDS if enemy else BEE_TRAIL_SECONDS
	particles.local_coords = false
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.0
	particles.initial_velocity_max = 0.0
	particles.scale_amount_min = 0.7 * size
	particles.scale_amount_max = 1.0 * size
	particles.mesh = _sphere("enemy_trail" if enemy else "bee_trail", (ENEMY_RADII if enemy else BEE_RADII).y * 0.7,
			Color(ENEMY_SHOT_COLOR if enemy else BEE_SHOT_COLOR, 0.55), 0, true)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.2))
	particles.scale_amount_curve = shrink
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


## Level 01 / Level 02: re-dresses an enemy projectile as the cold orb (its old look and trail are hidden; collision,
## damage and speed untouched). Safe to call twice.
static func dress_enemy(projectile: Node3D, size := 1.0) -> void:
	if projectile == null or not is_instance_valid(projectile) or projectile.has_node(PLASMA_NAME):
		return
	for child in projectile.get_children():
		if child is DamageHitbox3D:
			continue
		if child is Node3D:
			(child as Node3D).visible = false
		if child is CPUParticles3D:
			(child as CPUParticles3D).emitting = false
	projectile.add_child(plasma(true, size))
	var tail := trail(true, size)
	projectile.add_child(tail)
	tail.emitting = true


## Bee's plasma ball on a Bee projectile (its old visual and trail hidden).
static func dress_bee(projectile: Node3D) -> void:
	if projectile == null or projectile.has_node(PLASMA_NAME):
		return
	for child in projectile.get_children():
		if child is DamageHitbox3D:
			continue
		if child is Node3D:
			(child as Node3D).visible = false
		if child is CPUParticles3D:
			(child as CPUParticles3D).emitting = false
	projectile.add_child(plasma(false))
	var own: Variant = projectile.get("trail")
	if own is CPUParticles3D:
		# BeeEnergyProjectile keeps its `trail`: re-skinned as the short warm plasma trail (still the same node).
		var template := trail(false)
		var tail := own as CPUParticles3D
		tail.visible = true
		tail.mesh = template.mesh
		tail.lifetime = template.lifetime
		tail.amount = template.amount
		tail.color_ramp = template.color_ramp
		tail.scale_amount_curve = template.scale_amount_curve
		tail.emitting = true
		template.free()
	else:
		var tail := trail(false)
		projectile.add_child(tail)
		tail.emitting = true


## UFO shots are a little bigger than the regular enemy orb.
const BOSS_SHOT_SIZE := 1.3


## Level stages connect their tree's `node_added` (deferred, to a method of the stage so it dies with it) to a method that
## calls this: every enemy projectile that enters the tree is re-dressed as the cold orb.
static func on_node_added(node: Node) -> void:
	if node is AlienEnemyProjectile and is_instance_valid(node) and node.is_inside_tree():
		var style: StringName = node.get_meta("shot_style", &"") # LOTE 13: family look (BeeShotStyles).
		if style != &"" and BeeShotStyles.has_style(style):
			BeeShotStyles.dress(node as Node3D, style)
			return
		dress_enemy(node as Node3D, BOSS_SHOT_SIZE if node.is_in_group(UfoBoss01.PROJECTILE_GROUP) else 1.0)
