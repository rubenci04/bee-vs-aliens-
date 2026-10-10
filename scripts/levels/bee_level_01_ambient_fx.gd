class_name BeeLevel01AmbientFx
extends Node3D
## VISUAL POLISH 02 — GPU particle ambience, presentation only (no collision, no gameplay, no shadows, no gravity):
##   pylon sparks   tiny cyan sparks rising from the alien pylons' rings (only the pylons near the camera emit)
##   ground dust    a soft puff where Bee flies low over the soil (follows Bee, emits only below DUST_MAX_BEE_Y)
##   dew glints     a few twinkling points on the background grass (follows the camera)
##   haze           a thin drifting mist in the far background, tinted by the fog colour of the time of day
## Every system uses GPUParticles3D with a ParticleProcessMaterial, ZERO gravity, shared soft-disc material and a small
## `amount`; all positions are driven by the camera so the cost does not depend on the length of the level.

const SPARK_AMOUNT := 8
const SPARK_RANGE := 16.0 # Pylons farther than this (in X) from the camera do not emit.
const DUST_MAX_BEE_Y := 1.9 # Bee must be this low to kick up dust.
const DUST_AMOUNT := 10
const DEW_AMOUNT := 22
const HAZE_AMOUNT := 7
const HAZE_ALPHA_DAY := 0.10
const HAZE_ALPHA_SUNSET := 0.16

var stage: BeeShmupStage
var spark_systems: Array[GPUParticles3D] = []
var dust: GPUParticles3D
var dew: GPUParticles3D
var haze: GPUParticles3D
var _pylons: Array[Node3D] = []
var _haze_material: StandardMaterial3D
var _haze_timer := 0.0
var _soft_disc: GradientTexture2D


func _ready() -> void:
	stage = get_parent() as BeeShmupStage
	_soft_disc = GradientTexture2D.new()
	_soft_disc.fill = GradientTexture2D.FILL_RADIAL
	_soft_disc.fill_from = Vector2(0.5, 0.5)
	_soft_disc.fill_to = Vector2(1.0, 0.5)
	_soft_disc.width = 64
	_soft_disc.height = 64
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	_soft_disc.gradient = ramp
	_build_dust()
	_build_dew()
	_build_haze()
	call_deferred("_build_sparks") # After the escalation node has created its pylons.


# --- builders ------------------------------------------------------------------------------------------------

func _quad(size: float, color: Color, additive := false) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = _soft_disc
	material.albedo_color = color
	material.disable_receive_shadows = true
	if additive:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mesh.material = material
	return mesh


func _fade_ramp(peak: float = 1.0) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.75, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, peak), Color(1, 1, 1, peak), Color(1, 1, 1, 0)])
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


func _shrink_curve(grow := false) -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.2 if grow else 1.0))
	curve.add_point(Vector2(1.0, 1.0 if grow else 0.1))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


func _twinkle_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


func _system(label: String, amount: float, lifetime: float, process: ParticleProcessMaterial, mesh: Mesh, aabb: AABB) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = label
	particles.amount = int(amount)
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.local_coords = false
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.visibility_aabb = aabb
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	return particles


func _process_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.gravity = Vector3.ZERO # No gravity anywhere: every system drifts on purpose.
	return material


func _build_sparks() -> void:
	for node in stage.get_children():
		if node is BeeLevel01AlienEscalation:
			for pylon: Node3D in (node as BeeLevel01AlienEscalation).pylons:
				_pylons.append(pylon)
	for pylon in _pylons:
		var material := _process_material()
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		material.emission_sphere_radius = 0.18 * pylon.scale.x
		material.direction = Vector3(0, 1, 0)
		material.spread = 55.0
		material.initial_velocity_min = 0.25
		material.initial_velocity_max = 0.7
		material.damping_min = 0.4
		material.damping_max = 0.9
		material.scale_min = 0.5
		material.scale_max = 1.0
		material.scale_curve = _shrink_curve()
		material.color_ramp = _fade_ramp()
		var particles := _system("Sparks_" + str(pylon.name), SPARK_AMOUNT, 1.1, material,
				_quad(0.07, Color(0.35, 1.0, 1.0, 1.0), true), AABB(Vector3(-1.5, -0.5, -1.5), Vector3(3, 3.5, 3)))
		particles.emitting = false
		particles.global_position = pylon.global_position + Vector3(0, 1.3 * pylon.scale.x, 0.1)
		spark_systems.append(particles)


func _build_dust() -> void:
	var material := _process_material()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(0.35, 0.02, 0.3)
	material.direction = Vector3(-1, 0.5, 0)
	material.spread = 35.0
	material.initial_velocity_min = 0.25
	material.initial_velocity_max = 0.7
	material.damping_min = 0.5
	material.damping_max = 1.0
	material.scale_min = 0.8
	material.scale_max = 1.4
	material.scale_curve = _shrink_curve(true)
	material.color_ramp = _fade_ramp(0.5)
	dust = _system("GroundDust", DUST_AMOUNT, 0.9, material, _quad(0.5, Color(0.78, 0.66, 0.5, 0.55)), AABB(Vector3(-3, -1, -3), Vector3(6, 3, 6)))
	dust.emitting = false


func _build_dew() -> void:
	var material := _process_material()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(9.0, 1.6, 2.5)
	material.scale_min = 0.5
	material.scale_max = 1.2
	material.scale_curve = _twinkle_curve() # A glint: grows and fades out in place, no motion at all.
	material.color_ramp = _fade_ramp()
	dew = _system("DewGlints", DEW_AMOUNT, 2.4, material, _quad(0.11, Color(1.0, 1.0, 0.92, 1.0), true), AABB(Vector3(-12, -3, -5), Vector3(24, 6, 10)))


func _build_haze() -> void:
	var material := _process_material()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(11.0, 1.2, 2.0)
	material.direction = Vector3(-1, 0, 0)
	material.spread = 8.0
	material.initial_velocity_min = 0.15
	material.initial_velocity_max = 0.3
	material.scale_min = 0.9
	material.scale_max = 1.5
	material.color_ramp = _fade_ramp()
	var mesh := _quad(7.0, Color(0.86, 0.87, 0.78, HAZE_ALPHA_DAY))
	_haze_material = mesh.material as StandardMaterial3D
	haze = _system("DistanceHaze", HAZE_AMOUNT, 12.0, material, mesh, AABB(Vector3(-16, -3, -4), Vector3(32, 8, 8)))


# --- per frame -----------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if stage == null or stage.camera == null:
		return
	var camera_x := stage.camera.global_position.x
	dew.global_position = Vector3(camera_x, 1.7, -6.0)
	haze.global_position = Vector3(camera_x + 1.0, 2.6, -12.0)
	var bee := stage.bee
	if is_instance_valid(bee) and not bee.is_defeated:
		var low := bee.global_position.y < DUST_MAX_BEE_Y
		dust.global_position = Vector3(bee.global_position.x, -0.1, bee.global_position.z + 0.3)
		if dust.emitting != low:
			dust.emitting = low
	for i in spark_systems.size():
		var near := absf(_pylons[i].global_position.x - camera_x) < SPARK_RANGE
		if spark_systems[i].emitting != near:
			spark_systems[i].emitting = near
	_haze_timer -= delta
	if _haze_timer <= 0.0:
		_haze_timer = 0.3
		_tint_haze()


## The mist takes the fog colour (warm by day, violet at sunset) and gets a little denser as the light goes down.
func _tint_haze() -> void:
	var world_env := stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env == null or world_env.environment == null or _haze_material == null:
		return
	var fog := world_env.environment.fog_light_color
	var sunset := clampf(inverse_lerp(210.0, 290.0, stage.distance), 0.0, 1.0)
	_haze_material.albedo_color = Color(fog.r, fog.g, fog.b, lerpf(HAZE_ALPHA_DAY, HAZE_ALPHA_SUNSET, sunset))
