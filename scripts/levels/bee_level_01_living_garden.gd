class_name BeeLevel01LivingGarden
extends Node3D
## ARCADE CONTENT & SPECTACLE REBUILD 02 — the garden breathes. Presentation only: no collision, no gameplay, no
## shadows, shared meshes/materials, and nothing processes far from the camera.
##   pollen motes   warm specks drifting through the whole view (world-space particles that follow the camera)
##   leaves         a few leaves tumbling down; some cross IN FRONT of the flight plane (foreground crossings)
##   gnat clouds    tiny buzzing clouds over flowers in the background
##   butterflies    three butterflies wandering behind the flight plane (distant movement)

const GNATS := [Vector3(58.0, 1.4, -2.6), Vector3(112.0, 1.2, -3.0), Vector3(164.0, 1.5, -2.4), Vector3(236.0, 1.3, -2.8), Vector3(292.0, 1.4, -2.6)]
const BUTTERFLIES := [[30.0, 3.6, -3.2, Color(0.98, 0.62, 0.18)], [132.0, 4.4, -4.6, Color(0.97, 0.95, 0.88)], [214.0, 3.2, -3.6, Color(0.98, 0.84, 0.25)]]
const ACTIVE_RANGE := 15.0

@export var stage_path: NodePath = ^".."

var stage: BeeShmupStage
var pollen: CPUParticles3D
var leaves: CPUParticles3D
var gnat_clouds: Array[CPUParticles3D] = []
var butterflies: Array[Node3D] = []
var _t := 0.0


func _ready() -> void:
	stage = get_node(stage_path) as BeeShmupStage
	pollen = _particles("PollenMotes", 42, 7.0, Vector3(11.0, 3.2, 3.5), _speck(Color(1.0, 0.86, 0.36), 0.05, true))
	pollen.direction = Vector3(-1.0, 0.25, 0.0)
	pollen.spread = 70.0
	pollen.initial_velocity_min = 0.08
	pollen.initial_velocity_max = 0.3
	pollen.gravity = Vector3(0.0, 0.03, 0.0)
	leaves = _particles("FallingLeaves", 7, 9.0, Vector3(9.0, 0.6, 2.8), _leaf_mesh())
	leaves.direction = Vector3(-0.8, -0.6, 0.0)
	leaves.spread = 25.0
	leaves.initial_velocity_min = 0.35
	leaves.initial_velocity_max = 0.7
	leaves.gravity = Vector3(-0.05, -0.12, 0.0)
	leaves.angular_velocity_min = -110.0
	leaves.angular_velocity_max = 110.0
	leaves.particle_flag_rotate_y = true
	leaves.scale_amount_min = 0.8
	leaves.scale_amount_max = 1.4
	var tint := Gradient.new()
	tint.colors = PackedColorArray([Color(0.47, 0.62, 0.22), Color(0.82, 0.6, 0.22), Color(0.66, 0.36, 0.16)])
	leaves.color_initial_ramp = tint
	for point in GNATS:
		var cloud := _particles("GnatCloud", 14, 0.9, Vector3.ONE * 0.5, _speck(Color(0.12, 0.1, 0.08), 0.045, false))
		cloud.local_coords = true
		cloud.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		cloud.emission_sphere_radius = 0.55
		cloud.spread = 180.0
		cloud.initial_velocity_min = 0.25
		cloud.initial_velocity_max = 0.6
		cloud.position = point
		cloud.emitting = false
		gnat_clouds.append(cloud)
	for spec in BUTTERFLIES:
		butterflies.append(_butterfly(Vector3(float(spec[0]), float(spec[1]), float(spec[2])), spec[3]))


func _process(delta: float) -> void:
	_t += delta
	var cam_x := stage.camera.global_position.x
	pollen.global_position = Vector3(cam_x + 1.5, 3.6, -0.8)
	leaves.global_position = Vector3(cam_x + 4.5, 7.6, -0.6)
	for cloud in gnat_clouds:
		var near := absf(cloud.global_position.x - cam_x) < ACTIVE_RANGE
		if cloud.emitting != near:
			cloud.emitting = near
	for i in butterflies.size():
		var fly := butterflies[i]
		var home: Vector3 = fly.get_meta("home")
		var near := absf(home.x - cam_x) < ACTIVE_RANGE + 6.0
		fly.visible = near
		if not near:
			continue
		var t := _t + float(i) * 2.1
		# A lazy figure-eight around its flowers.
		fly.global_position = home + Vector3(sin(t * 0.45) * 2.4, sin(t * 0.9) * 0.7 + sin(t * 3.1) * 0.12, cos(t * 0.45) * 0.5)
		fly.rotation.y = PI if cos(t * 0.45) < 0.0 else 0.0
		var flap := sin(t * 15.0) * 0.95
		(fly.get_child(0) as Node3D).rotation.x = flap
		(fly.get_child(1) as Node3D).rotation.x = -flap


func _particles(label: String, amount: int, lifetime: float, extents: Vector3, mesh: Mesh) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = label
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = extents
	particles.mesh = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	add_child(particles)
	return particles


static func _speck(color: Color, radius: float, glow: bool) -> Mesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.6
	mesh.material = material
	return mesh


static func _leaf_mesh() -> Mesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.24, 0.13)
	var material := StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	mesh.material = material
	return mesh


func _butterfly(home: Vector3, color: Color) -> Node3D:
	var body := Node3D.new()
	body.name = "Butterfly"
	body.set_meta("home", home)
	add_child(body)
	var wing_mesh := QuadMesh.new()
	wing_mesh.size = Vector2(0.42, 0.34)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.9
	wing_mesh.material = material
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		body.add_child(pivot)
		var wing := MeshInstance3D.new()
		wing.mesh = wing_mesh
		wing.position = Vector3(side * 0.1, 0.16, side * 0.02) # Wings face the side camera; the flap foreshortens them.
		wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivot.add_child(wing)
	body.global_position = home
	return body
