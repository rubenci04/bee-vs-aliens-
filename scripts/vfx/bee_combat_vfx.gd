class_name BeeCombatVFX
extends Node3D

# Small visual-only vocabulary. No collisions, damage, timers or game state.
var kind: StringName = &"impact"
var direction := Vector3.RIGHT
var extent := 1.0
var duration := 0.24
static var _materials: Dictionary = {}
## NOCHE 01 · ETAPA 2: Level 01 switches this on: explosions use the Codex toon bursts (core + shock ring + fragments, no
## bloom). POCs keep the old particles. Hits and muzzles are unchanged.
static var toon_bursts := false
## Only deaths: the "bomb" shockwave (Bee bomb, mines) keeps the old visual because its ring shows the real blast radius.
const TOON_BURSTS := {&"tech_death": "res://scenes/vfx/bee_level_toon_burst.tscn"}
static var _particle_meshes: Dictionary = {}
static var _sphere_meshes: Dictionary = {}
static var _ring_meshes: Dictionary = {}

static func spawn(parent: Node3D, point: Vector3, effect: StringName, forward := Vector3.RIGHT, size := 1.0) -> BeeCombatVFX:
	if toon_bursts and TOON_BURSTS.has(effect):
		_spawn_toon_burst(parent, point, effect, size)
		return null
	var packed := load("res://scenes/vfx/combat_feedback_vfx.tscn") as PackedScene
	var visual := packed.instantiate() as BeeCombatVFX
	visual.kind = effect
	visual.direction = forward
	visual.extent = size
	var host := parent
	while host.get_parent() is Node3D:
		host = host.get_parent()
	var container := host.get_node_or_null("CombatVFX") as Node3D
	if container == null:
		container = Node3D.new()
		container.name = "CombatVFX"
		host.add_child(container)
	visual.position = container.to_local(point)
	container.add_child(visual)
	return visual

func _ready() -> void:
	add_to_group("bee_combat_vfx")
	var color := Color(0.15, 0.95, 1.0)
	var amount := 8
	var reach := 0.45
	match kind:
		&"bee_muzzle", &"bee_muzzle_spread":
			duration = 0.07
			var flash := _sphere(Color(1.0, 0.9, 0.52), Vector3(0.16, 0.06, 0.06) if kind == &"bee_muzzle" else Vector3(0.19, 0.105, 0.07))
			flash.rotation.z = atan2(direction.y, direction.x)
			_fade(flash, duration)
		&"muzzle", &"muzzle_spread":
			duration = 0.07
			var flash := _sphere(Color(0.85, 1, 1), Vector3(0.2, 0.075, 0.075) if kind == &"muzzle" else Vector3(0.23, 0.14, 0.09))
			flash.rotation.z = atan2(direction.y, direction.x)
			_fade(flash, duration)
		&"bomb":
			duration = 0.55
			amount = 24
			reach = extent * 0.8
			var flash := _sphere(Color(0.85, 1, 1, 0.65), Vector3.ONE * 0.4)
			_fade(flash, 0.07)
			_ring(color, extent, 0.26, 0.29)
		&"tech_death":
			duration = 0.5
			amount = 14
			reach = 0.9
			_ring(Color(0.6, 1, 1, 0.8), 0.45, 0.12, 0.2)
			_fade(_sphere(Color(1, 1, 0.92, 0.85), Vector3.ONE * 0.42), 0.09) # REBUILD 02: a bright pop first, then shards.
		&"organic_death":
			duration = 0.5
			color = Color(0.85, 0.75, 0.3)
			amount = 12
			reach = 0.65
			_fade(_sphere(Color(1, 0.95, 0.7, 0.8), Vector3.ONE * 0.38), 0.09)
			_ring(Color(0.95, 0.85, 0.45, 0.6), 0.4, 0.12, 0.18)
		&"pop":
			# REBUILD 02: popcorn drones - short, bright, satisfying; smaller than a real enemy death.
			duration = 0.3
			amount = 7
			reach = 0.55
			_fade(_sphere(Color(0.9, 1, 1, 0.9), Vector3.ONE * 0.3), 0.07)
			_ring(Color(0.6, 1, 1, 0.7), 0.3, 0.08, 0.14)
		&"heavy_death":
			# REBUILD 02: heavy enemies (Walker) - a second, larger shockwave layered over tech_death.
			duration = 0.7
			amount = 18
			reach = 1.4
			_fade(_sphere(Color(1, 0.95, 0.8, 0.8), Vector3.ONE * 0.8), 0.12)
			_ring(Color(1, 0.85, 0.5, 0.55), 1.3, 0.2, 0.3)
		&"impact_organic":
			color = Color(0.95, 0.9, 0.55)
			reach = 0.3
		&"bee_melee":
			duration = 0.18
			color = Color(1.0, 0.72, 0.2)
			reach = 0.3
			var arc := MeshInstance3D.new()
			var mesh := TorusMesh.new()
			mesh.inner_radius = 0.23
			mesh.outer_radius = 0.3
			mesh.rings = 12
			mesh.ring_segments = 4
			mesh.material = _material(color)
			arc.mesh = mesh
			arc.rotation.x = PI * 0.5
			arc.scale = Vector3(0.6, 1.0, 1.0)
			add_child(arc)
			_fade(arc, duration)
		&"bee_impact":
			color = Color(1.0, 0.7, 0.18)
			amount = 8
			reach = 0.36
		&"crate":
			duration = 0.45
			color = Color(0.62, 0.43, 0.23)
			amount = 12
			reach = 0.8
		&"neutral_hit":
			duration = 0.2
			color = Color(0.92, 0.94, 0.97, 0.8)
			amount = 5
			reach = 0.22
		&"rock_hit":
			duration = 0.28
			color = Color(0.72, 0.68, 0.6)
			amount = 6
			reach = 0.4
		&"rock_break":
			duration = 0.6
			color = Color(0.62, 0.58, 0.5)
			amount = 18
			reach = maxf(extent, 1.0) * 0.9
			_ring(Color(0.72, 0.68, 0.6, 0.45), maxf(extent, 1.0) * 0.55, 0.18, 0.3)
		&"pickup", &"pickup_bomb":
			duration = 0.3 if kind == &"pickup" else 0.4
			amount = 8 if kind == &"pickup" else 14
			reach = 0.35 if kind == &"pickup" else 0.55
			_ring(color, reach, 0.12, duration - 0.12)
		&"pollen":
			duration = 0.25
			color = Color(1, 0.85, 0.22)
			amount = 5
			reach = 0.2
	if not kind in [&"muzzle", &"muzzle_spread", &"bee_muzzle", &"bee_muzzle_spread"]:
		_burst(color, amount, reach)
	var cleanup := create_tween()
	cleanup.tween_interval(duration + 0.08)
	cleanup.tween_callback(queue_free)

func _material(color: Color) -> StandardMaterial3D:
	if _materials.has(color):
		return _materials[color]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	_materials[color] = material
	return material

func _sphere(color: Color, size: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	if not _sphere_meshes.has(color):
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		mesh.radial_segments = 8
		mesh.rings = 4
		mesh.material = _material(color)
		_sphere_meshes[color] = mesh
	instance.mesh = _sphere_meshes[color]
	instance.scale = size
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func _fade(mesh: MeshInstance3D, time: float) -> void:
	var fade := create_tween()
	fade.tween_property(mesh, "transparency", 1.0, time)
	fade.tween_callback(mesh.queue_free)

func _ring(color: Color, radius: float, expand: float, fade: float) -> void:
	var ring := MeshInstance3D.new()
	if not _ring_meshes.has(color):
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.96
		mesh.outer_radius = 1.0
		mesh.rings = 32
		mesh.ring_segments = 4
		mesh.material = _material(color)
		_ring_meshes[color] = mesh
	ring.mesh = _ring_meshes[color]
	ring.name = "Shockwave" if kind == &"bomb" else "Pulse"
	ring.rotation.x = PI * 0.5
	ring.scale = Vector3.ONE * 0.08
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector3.ONE * radius, expand)
	tween.tween_property(ring, "transparency", 1.0, fade)

func _burst(color: Color, amount: int, reach: float) -> void:
	var particles := CPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = duration
	particles.one_shot = true
	particles.local_coords = true
	particles.explosiveness = 1.0
	particles.randomness = 0.25
	particles.direction = Vector3.RIGHT
	particles.spread = 180.0
	particles.gravity = Vector3(0.0, -7.0, 0.0) if kind == &"rock_break" else Vector3.ZERO
	particles.initial_velocity_min = reach / duration * 0.5
	particles.initial_velocity_max = reach / duration
	particles.scale_amount_min = 0.65
	particles.scale_amount_max = 1.1
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.3 if kind in [&"tech_death", &"organic_death", &"crate", &"rock_break", &"heavy_death"] else 0.06
	var mesh_key := str(kind) + color.to_html()
	if not _particle_meshes.has(mesh_key):
		var mesh: PrimitiveMesh
		if kind in [&"organic_death", &"impact_organic", &"pollen"]:
			var sphere := SphereMesh.new()
			sphere.radius = 0.045
			sphere.height = 0.09
			sphere.radial_segments = 6
			sphere.rings = 3
			mesh = sphere
		else:
			var shard := BoxMesh.new()
			shard.size = Vector3(0.14, 0.08, 0.06) if kind in [&"crate", &"rock_break"] else Vector3(0.09, 0.035, 0.035)
			mesh = shard
		mesh.material = _material(color)
		_particle_meshes[mesh_key] = mesh
	particles.mesh = _particle_meshes[mesh_key]
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	particles.color_ramp = gradient
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	particles.restart()


static func _spawn_toon_burst(parent: Node3D, point: Vector3, effect: StringName, size: float) -> void:
	var burst := (load(str(TOON_BURSTS[effect])) as PackedScene).instantiate() as Node3D
	burst.add_to_group("bee_combat_vfx")
	burst.set("kind", effect)
	burst.set("extent", size)
	var host := parent
	while host.get_parent() is Node3D:
		host = host.get_parent()
	var container := host.get_node_or_null("CombatVFX") as Node3D
	if container == null:
		container = Node3D.new()
		container.name = "CombatVFX"
		host.add_child(container)
	burst.scale *= clampf(size, 0.3, 3.0) * (1.4 if effect == &"bomb" else 0.8)
	container.add_child(burst)
	burst.global_position = point
