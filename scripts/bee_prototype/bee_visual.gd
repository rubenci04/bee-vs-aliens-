extends Node3D
const FEEDBACK := preload("res://scripts/game/bee_feedback_settings.gd")
var _tilt_rest := Transform3D.IDENTITY
var _flight_tilt := Vector2.ZERO
## Selectable Bee model and presentation. This wrapper owns no gameplay state.
@export var wing_frequency := 16.0
@export var wing_amplitude := 0.55
@onready var actor: BeePlayer = get_parent().get_parent() as BeePlayer
const MODEL_PATHS := {
	"v01": "res://assets/models/shared/bee/bee_mid_poly.glb",
	"v02": "res://assets/models/shared/bee_hero/shared_hero_bee_v02.glb",
}
const VISUAL_SCALE := BeeGameSettings.BEE_VISUAL_SCALE
const BODY_LIFT := 0.9
const BUZZ_STREAM := "res://audio/sfx/real/wing_buzz.wav"
const BUZZ_DB := -36.0

var model: Node3D
var model_version := ""
var wings: Array[Node3D] = []
var rest_angles: Array[Vector3] = []
var muzzle: Node3D
var drill: Node3D
var drill_tip: Node3D
var helmet_socket: Node3D
var blaster: Node3D
var _blaster_rest_position := Vector3.ZERO
var _blaster_recoil_tween: Tween
var nozzles: Dictionary = {}
var elapsed := 0.0
var _rim_materials: Array[ShaderMaterial] = []
var _rim_applied := -1.0
var buzz_player: AudioStreamPlayer
var punch_pose := preload("res://scripts/bee_prototype/bee_punch_pose.gd").new()
var _roll_burst_left := 0.0
var _blink_visible := true
var _last_blink_state := false
var _roll_flash_tween: Tween
var _plate_overlays: Dictionary = {}


func _ready() -> void:
	_tilt_rest = transform
	add_to_group("bee_visual_instances")
	_setup_buzz()
	apply_model_version(BeeGameSettings.BEE_MODEL_VERSION)
	if actor != null:
		actor.roll_started.connect(play_roll_effects)


func apply_model_version(version := "") -> bool:
	var chosen := BeeGameSettings.BEE_MODEL_VERSION if version.is_empty() else version
	if not MODEL_PATHS.has(chosen):
		return false
	if model_version == chosen and is_instance_valid(model):
		return true
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	model = null
	model_version = chosen
	wings.clear()
	rest_angles.clear()
	_rim_materials.clear()
	nozzles.clear()
	muzzle = null
	drill = null
	drill_tip = null
	helmet_socket = null
	blaster = null
	var packed := load(MODEL_PATHS[chosen]) as PackedScene
	if packed == null:
		push_error("Bee model failed to load: "+MODEL_PATHS[chosen])
		return false
	model = packed.instantiate() as Node3D
	if model == null:
		push_error("Bee model root must be Node3D: "+MODEL_PATHS[chosen])
		return false
	model.name = "Model"
	add_child(model)
	BeeToonStyle.apply(model, true, BeeToonStyle.OUTLINE_BEE)
	_own_rim_materials()
	for wing_name in ["Wing_L", "Wing_R"]:
		var wing := model.find_child(wing_name, true, false) as Node3D
		if wing != null:
			wings.append(wing)
			rest_angles.append(wing.rotation)
	if chosen == "v01" and wings.size() != 2:
		push_error("Bee v01 requires its two named wings")
		return false
	muzzle = model.find_child("muzzle", true, false) as Node3D
	drill = model.find_child("stinger_drill", true, false) as Node3D
	drill_tip = model.find_child("stinger_tip", true, false) as Node3D
	var cosmetic_stinger := model.find_child("Stinger", true, false) as Node3D
	if cosmetic_stinger != null: cosmetic_stinger.show() # Tanda E1: the metal drill stinger is permanent and purely cosmetic (no hitbox; the melee is only the punch).
	punch_pose.bind(model)
	helmet_socket = model.find_child("helmet_socket", true, false) as Node3D
	blaster = model.find_child("antenna_R_blaster", true, false) as Node3D
	if blaster != null:
		_blaster_rest_position = blaster.position
	for side in ["L", "R"]:
		var nozzle := model.find_child("nozzle_"+side, true, false) as Node3D
		if nozzle != null:
			nozzles[side] = {"node": nozzle, "rest": nozzle.rotation, "particles": _make_thruster(nozzle, side)}
	var facing := actor.facing_x if actor != null else 1.0
	get_parent().rotation.y = -facing * PI * 0.5
	get_parent().scale = Vector3.ONE * (BeeGameSettings.BEE_V01_VISUAL_SCALE if chosen == "v01" else BeeGameSettings.BEE_VISUAL_SCALE)
	_rim_applied = -1.0
	if chosen == "v02":
		_play_model_animation(&"wingbeat")
	return true


func firing_origin(fallback: Vector3) -> Vector3:
	if muzzle == null:
		return fallback
	var point := _untilted_point(muzzle.global_position)
	# Development visual scaling must not move the gameplay muzzle or aim origin.
	if is_instance_valid(model) and model.has_meta("dev_readability_scale"):
		var centre := _untilted_point(model.global_position)
		point = centre + (point - centre) / float(model.get_meta("dev_readability_scale"))
	point.z = actor.global_position.z if actor != null else fallback.z
	return point


func play_muzzle_effect(fallback: Vector3, direction: Vector3, spread := false) -> void:
	var point := muzzle.global_position if is_instance_valid(muzzle) else firing_origin(fallback)
	BeeCombatVFX.spawn(actor.get_parent(), point, &"bee_muzzle_spread" if spread else &"bee_muzzle", direction)
	if blaster == null:
		return
	if _blaster_recoil_tween != null:
		_blaster_recoil_tween.kill()
	blaster.position = _blaster_rest_position
	_blaster_recoil_tween = create_tween()
	_blaster_recoil_tween.tween_property(blaster, "position", _blaster_rest_position + Vector3(0.0, 0.0, BeeGameSettings.BEE_BLASTER_RECOIL_DISTANCE), BeeGameSettings.BEE_BLASTER_RECOIL_IN_SECONDS)
	_blaster_recoil_tween.tween_property(blaster, "position", _blaster_rest_position, BeeGameSettings.BEE_BLASTER_RECOIL_OUT_SECONDS)


func _play_model_animation(clip: StringName) -> void:
	if model == null:
		return
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null or not player.has_animation(clip):
		return
	player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	player.play(clip)


func _process(delta: float) -> void:
	_update_buzz(delta, actor != null and actor.is_defeated)
	if actor == null or model == null or actor.is_defeated:
		return
	elapsed += delta
	_update_flight_tilt(delta)
	_update_rim()
	if model_version == "v01":
		for i in wings.size():
			wings[i].rotation = rest_angles[i] + Vector3(0, 0, sin(elapsed * TAU * wing_frequency) * wing_amplitude * (-1.0 if i == 0 else 1.0))
	_update_thrusters(delta)
	punch_pose.update(actor.sting_dash)
	_update_invulnerability_blink()


func _make_thruster(nozzle: Node3D, side: String) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "BeeThruster_"+side
	particles.amount = BeeGameSettings.BEE_THRUSTER_PARTICLES
	particles.lifetime = BeeGameSettings.BEE_THRUSTER_PARTICLE_LIFETIME
	particles.local_coords = true
	particles.explosiveness = 0.0
	particles.randomness = BeeGameSettings.BEE_THRUSTER_PARTICLE_RANDOMNESS
	particles.direction = Vector3(0.0, 0.0, 1.0)
	particles.spread = BeeGameSettings.BEE_THRUSTER_PARTICLE_SPREAD_DEGREES
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = BeeGameSettings.BEE_THRUSTER_MIN_PARTICLE_SPEED
	particles.initial_velocity_max = BeeGameSettings.BEE_THRUSTER_IDLE_MAX_PARTICLE_SPEED
	particles.scale_amount_min = BeeGameSettings.BEE_THRUSTER_PARTICLE_SCALE_MIN
	particles.scale_amount_max = BeeGameSettings.BEE_THRUSTER_PARTICLE_SCALE_MAX
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = BeeGameSettings.BEE_THRUSTER_EMISSION_RADIUS
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([BeeGameSettings.BEE_THRUSTER_COLOR_START, BeeGameSettings.BEE_THRUSTER_COLOR_MID, BeeGameSettings.BEE_THRUSTER_COLOR_END])
	particles.color_ramp = gradient
	var spark := SphereMesh.new()
	spark.radius = BeeGameSettings.BEE_THRUSTER_MESH_RADIUS
	spark.height = BeeGameSettings.BEE_THRUSTER_MESH_HEIGHT
	spark.radial_segments = 6
	spark.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	spark.material = material
	particles.mesh = spark
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	nozzle.add_child(particles)
	particles.emitting = BeeGameSettings.BEE_THRUSTERS_ENABLED
	particles.visible = BeeGameSettings.BEE_THRUSTERS_ENABLED
	return particles


func _update_thrusters(delta: float) -> void:
	_roll_burst_left = maxf(0.0, _roll_burst_left - delta)
	var speed := Vector2(actor.velocity.x, actor.velocity.y).length()
	var max_speed := maxf(Vector2(actor.horizontal_speed, actor.vertical_speed).length(), 0.1)
	var speed_ratio := clampf(speed / max_speed, 0.0, 1.0)
	var intensity := lerpf(BeeGameSettings.BEE_THRUSTER_IDLE_INTENSITY, BeeGameSettings.BEE_THRUSTER_MAX_INTENSITY, speed_ratio)
	if _roll_burst_left > 0.0:
		intensity = 1.0
	for entry: Dictionary in nozzles.values():
		var nozzle: Node3D = entry["node"]
		var rest: Vector3 = entry["rest"]
		var particles: CPUParticles3D = entry["particles"]
		var vertical := clampf(actor.velocity.y / maxf(actor.vertical_speed, 0.1), -1.0, 1.0)
		nozzle.rotation = rest + Vector3(-vertical * BeeGameSettings.BEE_THRUSTER_MAX_TILT_RADIANS, 0.0, 0.0)
		particles.visible = BeeGameSettings.BEE_THRUSTERS_ENABLED
		particles.emitting = BeeGameSettings.BEE_THRUSTERS_ENABLED
		particles.scale = Vector3.ONE * lerpf(BeeGameSettings.BEE_THRUSTER_IDLE_SCALE, BeeGameSettings.BEE_THRUSTER_FULL_SCALE, intensity)
		particles.initial_velocity_min = lerpf(BeeGameSettings.BEE_THRUSTER_MIN_PARTICLE_SPEED, BeeGameSettings.BEE_THRUSTER_ACCEL_PARTICLE_SPEED, intensity)
		particles.initial_velocity_max = lerpf(BeeGameSettings.BEE_THRUSTER_IDLE_MAX_PARTICLE_SPEED, BeeGameSettings.BEE_THRUSTER_MAX_PARTICLE_SPEED, intensity)


func play_roll_effects() -> void:
	_roll_burst_left = BeeGameSettings.BEE_THRUSTER_BURST_SECONDS
	if model_version == "v02":
		_flash_armor()


func _update_invulnerability_blink() -> void:
	if not actor.is_rolling:
		if _last_blink_state:
			model.visible = true
		_last_blink_state = false
		_blink_visible = true
		return
	_last_blink_state = true
	var step := int(floor(Time.get_ticks_msec() * BeeGameSettings.BEE_INVULNERABILITY_BLINK_HZ / 1000.0))
	var visible_now := step % 2 == 0
	if visible_now != _blink_visible:
		_blink_visible = visible_now
		model.visible = visible_now


func _flash_armor() -> void:
	var plates := model.find_child("plates", true, false)
	if plates == null:
		return
	if _roll_flash_tween != null:
		_roll_flash_tween.kill()
	_restore_armor_overlays()
	var overlay := StandardMaterial3D.new()
	overlay.metallic = 0.88
	overlay.roughness = 0.16
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	overlay.albedo_color = BeeGameSettings.BEE_ROLL_FLASH_GOLD
	overlay.emission_enabled = true
	overlay.emission = BeeGameSettings.BEE_ROLL_FLASH_EMISSION
	overlay.emission_energy_multiplier = BeeGameSettings.BEE_ROLL_FLASH_EMISSION_STRENGTH
	for mesh: MeshInstance3D in plates.find_children("*", "MeshInstance3D", true, false):
		_plate_overlays[mesh] = mesh.material_overlay
		mesh.material_overlay = overlay
	_roll_flash_tween = create_tween()
	_roll_flash_tween.tween_interval(BeeGameSettings.BEE_ROLL_ARMOR_FLASH_SECONDS)
	_roll_flash_tween.tween_callback(_restore_armor_overlays)


func _restore_armor_overlays() -> void:
	for mesh in _plate_overlays:
		if is_instance_valid(mesh):
			(mesh as MeshInstance3D).material_overlay = _plate_overlays[mesh]
	_plate_overlays.clear()


func sting_impact_effect(point: Vector3) -> void:
	if actor == null: return
	var star := preload("res://scripts/vfx/bee_punch_star.gd").new()
	actor.get_parent().add_child(star)
	star.global_position = point


func _own_rim_materials() -> void:
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_surface_override_material(surface) as ShaderMaterial
			if material != null and (material.shader == BeeToonStyle.TOON or material.shader == BeeToonStyle.TOON_DOUBLE):
				var own := material.duplicate() as ShaderMaterial
				mesh.set_surface_override_material(surface, own)
				_rim_materials.append(own)


func _update_rim() -> void:
	var boost := BeeToonStyle.bee_rim_boost
	var rim_boost := maxf(boost, BeeGameSettings.BEE_READABILITY_RIM_MIN)
	if absf(boost - _rim_applied) < 0.01:
		return
	_rim_applied = boost
	for material in _rim_materials:
		if not material.has_meta("body_albedo"):
			var energy: Variant = material.get_shader_parameter("emission_energy")
			if energy != null and float(energy) > 0.0:
				material.set_meta("body_albedo", Color.TRANSPARENT)
			else:
				material.set_meta("body_albedo", material.get_shader_parameter("albedo"))
		var albedo: Color = material.get_meta("body_albedo")
		if albedo.a > 0.0:
			material.set_shader_parameter("emission", albedo.lightened(0.1))
			material.set_shader_parameter("emission_energy", BODY_LIFT * boost)
		material.set_shader_parameter("rim_strength", lerpf(0.3, 1.25, rim_boost))
		material.set_shader_parameter("rim_power", lerpf(3.0, 1.7, rim_boost))
		material.set_shader_parameter("rim_color", Color(1.0, 0.93, 0.8).lerp(Color(1.0, 0.98, 0.9), boost))


func _setup_buzz() -> void:
	var source := load(BUZZ_STREAM) as AudioStreamWAV
	if source == null:
		return
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	buzz_player = AudioStreamPlayer.new()
	buzz_player.name = "WingBuzz"
	buzz_player.stream = stream
	buzz_player.bus = &"SFX"
	buzz_player.volume_db = BUZZ_DB
	add_child(buzz_player)
	if DisplayServer.get_name() != "headless":
		buzz_player.play()


func _update_buzz(delta: float, defeated: bool) -> void:
	if buzz_player == null:
		return
	buzz_player.volume_db = move_toward(buzz_player.volume_db, -80.0 if defeated else BUZZ_DB, 90.0 * delta)
	buzz_player.stream_paused = buzz_player.volume_db <= -79.0


## Rotate only this visual wrapper. Physics, root facing/roll and muzzle stay neutral.
func _untilted_point(point: Vector3) -> Vector3:
	return get_parent().global_transform * _tilt_rest * global_transform.affine_inverse() * point

func _update_flight_tilt(delta: float) -> void:
	var desired := Vector2.ZERO
	if FEEDBACK.tilt_enabled and not actor.is_rolling and not actor.sting_dash.active:
		desired.x = deg_to_rad(FEEDBACK.PITCH_DEGREES)*clampf(actor.velocity.y/maxf(actor.vertical_speed,.01),-1,1)
		desired.y = -deg_to_rad(FEEDBACK.BANK_DEGREES)*clampf(actor.velocity.x*actor.facing_x/maxf(actor.horizontal_speed,.01),-1,1)
	_flight_tilt = _flight_tilt.lerp(desired,1.0-exp(-delta/FEEDBACK.TILT_SMOOTH_SECONDS))
	transform = _tilt_rest * Transform3D(Basis.from_euler(Vector3(_flight_tilt.x,0,_flight_tilt.y)),Vector3.ZERO)
