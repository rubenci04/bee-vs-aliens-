extends RefCounted
## Shared tiny trail geometry, aligned with the existing Blender bolt colours.
const BEE := Color("efab26")
const ALIEN := Color("1bc7d9")
static var warm_mesh: SphereMesh
static var cyan_mesh: SphereMesh
static func trail_mesh(alien: bool) -> SphereMesh:
	var cached := cyan_mesh if alien else warm_mesh
	if cached!=null:
		return cached
	var mesh := SphereMesh.new()
	mesh.radius = .025
	mesh.height = .05
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = ALIEN if alien else BEE
	material.albedo_color.a = .65
	material.vertex_color_use_as_albedo = true
	if alien:
		material.emission_enabled = true
		material.emission = ALIEN
		material.emission_energy_multiplier = .35
	mesh.material = material
	if alien:
		cyan_mesh = mesh
	else:
		warm_mesh = mesh
	return mesh
static func make_trail(alien: bool) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "ShortTrail"
	particles.amount = 8
	particles.lifetime = .16
	particles.local_coords = false
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0
	particles.initial_velocity_max = 0
	particles.mesh = trail_mesh(alien)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE,Color(1,1,1,0)])
	particles.color_ramp = gradient
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles
static func impact(parent: Node, position: Vector3, effect: PackedScene) -> void:
	var burst := effect.instantiate() as Node3D
	parent.add_child(burst)
	# Visual depth offset keeps the flash readable over the target's front surface.
	burst.global_position = position+Vector3(0,0,.6)
