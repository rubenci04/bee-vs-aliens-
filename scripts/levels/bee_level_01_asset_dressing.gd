class_name BeeLevel01AssetDressing
extends Node3D
## LOTE 6 — Codex GLB assets used as scenery (presentation only: no collision, no gameplay, always behind the flight plane):
##   signal relays   the cyan pylons after the checkpoint get the `alien_signal_relay` model (the old column/ring/tip are hidden)
##   garden litter   bottle caps, drink cans, wrapped candy, flowering shrubs and tree saplings, placed by hand between the old props
##   fireflies       three free (liberated, no implant) fireflies drifting behind the flight plane with a soft glow that grows at dusk
##   night sky       crescent moon and two star clusters that fade in over the last stretch (sunset -> first contact), fixed to the
##                   camera with a tiny drift (no fog, unshaded: they are sky, not scenery)
## Everything uses the same art wrapper (`future_asset_visual.gd`: toon + outline + rim) as the rest of the level, except the sky.

const RELAY := preload("res://scenes/art_labs/assets_v02/alien_signal_relay.tscn")
const CAP := preload("res://scenes/art_labs/assets_v04/giant_bottle_cap.tscn")
const CAN := preload("res://scenes/art_labs/assets_v06/empty_drink_can.tscn")
const CANDY := preload("res://scenes/art_labs/assets_v06/wrapped_candy.tscn")
const SHRUB := preload("res://scenes/art_labs/assets_v06/flowering_shrub.tscn")
const SAPLING := preload("res://scenes/art_labs/assets_v06/garden_sapling.tscn")
const FIREFLY := preload("res://scenes/art_labs/assets_v03/controlled_firefly.tscn")
const MOON_MODEL := preload("res://assets/models/future_biomes_v07/sky_crescent_moon.glb")
const STARS_MODEL := preload("res://assets/models/future_biomes_v07/sky_star_cluster.glb")

const RELAY_SCALE := 2.1 # The model is ~0.95 m tall; the old pylon column was 1.8 m.
const SKY_DEPTH := 70.0
const SKY_FADE_FROM := 255.0 # Level distance where the night sky starts to appear...
const SKY_FADE_TO := 310.0 # ...and where it is fully visible.
const FIREFLY_COUNT := 3
const FIREFLY_FADE_FROM := 150.0
## NOCHE 01 — foreground fireflies: world drift (m/s, towards -X), wrap distance from the camera, depths (behind the plane).
const FIREFLY_DRIFT := 0.8
const FIREFLY_WRAP := 8.5
const FIREFLY_Z := [-1.8, -2.4, -2.1]
## Far fireflies are only soft light points (no body), so they are never mistaken for wasps.
const FAR_LIGHTS := 16
const FIREFLY_MODEL_LENGTH := 1.293 # controlled_firefly.glb body length at scale 1 (catalogue).

## [scene, x, z, scale, yaw (rad), tilt (rad, z axis)]. All z < 0: behind the flight plane.
const LITTER := [
	[CAP, 22.0, -2.4, 2.0, 0.3, 0.0], [CAP, 176.0, -2.9, 2.2, 2.2, 0.12],
	[CAN, 120.0, -4.2, 4.5, 0.4, 0.0], [CAN, 243.0, -4.8, 4.2, 5.4, -0.05],
	[CANDY, 83.0, -2.6, 1.7, 0.2, 0.0], [CANDY, 297.0, -3.0, 1.5, 3.4, 0.0],
	[SHRUB, 12.0, -3.8, 3.2, 0.2, 0.0], [SHRUB, 137.0, -3.6, 3.5, 3.1, 0.0], [SHRUB, 212.0, -4.0, 3.0, 0.4, 0.0], [SHRUB, 325.0, -3.8, 3.3, 2.5, 0.0],
	[SAPLING, 60.0, -8.0, 3.0, 0.5, 0.0], [SAPLING, 190.0, -9.0, 3.3, 2.0, 0.0], [SAPLING, 270.0, -8.5, 3.0, 4.1, 0.0],
]

var stage: BeeShmupStage
var relays: Array[Node3D] = []
var litter: Array[Node3D] = []
var fireflies: Array[Node3D] = []
var moon: Node3D
var stars: Array[Node3D] = []
var _glows: Array[MeshInstance3D] = []
var _sky_materials: Array[StandardMaterial3D] = []
var _clock := 0.0
var _firefly_x: Dictionary = {}
var far_lights: GPUParticles3D
var _far_material: StandardMaterial3D


func _ready() -> void:
	stage = get_parent() as BeeShmupStage
	_build_litter()
	_build_fireflies()
	_build_sky()
	call_deferred("_swap_pylons") # After the escalation node has created its pylons.


# --- signal relays --------------------------------------------------------------------------------------------

func _swap_pylons() -> void:
	for node in stage.get_children():
		if node is BeeLevel01AlienEscalation:
			for pylon: Node3D in (node as BeeLevel01AlienEscalation).pylons:
				for part in ["Column", "Ring", "Tip"]:
					var old := pylon.get_node_or_null(part) as Node3D
					if old != null:
						old.hide()
				var relay := RELAY.instantiate() as Node3D
				relay.name = "SignalRelay"
				relay.scale = Vector3.ONE * RELAY_SCALE
				relay.rotation.y = PI # Faces the lane (-X is "forward" in the asset; the lens looks at the camera side).
				pylon.add_child(relay)
				relays.append(relay)


# --- litter ---------------------------------------------------------------------------------------------------

func _build_litter() -> void:
	for entry in LITTER:
		var item := (entry[0] as PackedScene).instantiate() as Node3D
		item.name = "Litter%d" % litter.size()
		add_child(item)
		item.position = Vector3(float(entry[1]), -0.05, float(entry[2]))
		item.scale = Vector3.ONE * float(entry[3])
		item.rotation = Vector3(0.0, float(entry[4]), float(entry[5]))
		litter.append(item)


# --- fireflies ------------------------------------------------------------------------------------------------

func _build_fireflies() -> void:
	var glow_mesh := QuadMesh.new()
	glow_mesh.size = Vector2(1.6, 1.6)
	var disc := GradientTexture2D.new()
	disc.fill = GradientTexture2D.FILL_RADIAL
	disc.fill_from = Vector2(0.5, 0.5)
	disc.fill_to = Vector2(1.0, 0.5)
	disc.width = 64
	disc.height = 64
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	disc.gradient = ramp
	for i in FIREFLY_COUNT:
		var bug := FIREFLY.instantiate() as Node3D
		bug.name = "Firefly%d" % i
		bug.scale = Vector3.ONE * BeeFaunaSizes.target_length(&"firefly") / FIREFLY_MODEL_LENGTH # NOCHE 01: 0.6 x Bee.
		add_child(bug)
		if bug.has_method("release_control"):
			bug.call("release_control") # A free animal: no alien device.
		var glow := MeshInstance3D.new()
		glow.name = "Glow"
		glow.mesh = glow_mesh
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.albedo_texture = disc
		material.albedo_color = Color(1.0, 0.92, 0.45, 0.0)
		material.disable_receive_shadows = true
		material.no_depth_test = false
		glow.material_override = material
		glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		glow.position = Vector3(0.45, 0.0, 0.0) # Behind the abdomen (the animal faces -X).
		bug.add_child(glow)
		fireflies.append(bug)
		_glows.append(glow)
	_build_far_lights(disc)


# --- sky --------------------------------------------------------------------------------------------------------

func _sky_item(model: PackedScene, label: String) -> Node3D:
	var item := model.instantiate() as Node3D
	item.name = label
	for mesh: MeshInstance3D in item.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.disable_fog = true # Sky: far away but never washed out by the garden fog.
			material.disable_receive_shadows = true
			material.albedo_color = source.albedo_color if source != null else Color(0.9, 0.88, 0.7)
			mesh.set_surface_override_material(surface, material)
			_sky_materials.append(material)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(item)
	item.hide()
	return item


func _build_sky() -> void:
	moon = _sky_item(MOON_MODEL, "CrescentMoon")
	for i in 2:
		stars.append(_sky_item(STARS_MODEL, "Stars%d" % i))


## Places `item` at a fraction of the screen (0..1), SKY_DEPTH away, covering about `height_fraction` of the screen height.
func _pin(item: Node3D, camera: Camera3D, screen: Vector2, height_fraction: float, asset_height: float, drift: float) -> void:
	var size := get_viewport().get_visible_rect().size
	var point := Vector2(size.x * screen.x, size.y * screen.y)
	item.global_position = camera.project_position(point, SKY_DEPTH) + Vector3(drift, 0.0, 0.0)
	var view_height := 2.0 * SKY_DEPTH * tan(deg_to_rad(camera.fov) * 0.5)
	item.scale = Vector3.ONE * (height_fraction * view_height / asset_height)
	item.global_rotation = camera.global_rotation


# --- per frame --------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if stage == null or stage.camera == null:
		return
	_clock += delta
	var camera := stage.camera
	var camera_x := camera.global_position.x
	var distance := stage.distance
	var dusk := clampf(inverse_lerp(FIREFLY_FADE_FROM, 290.0, distance), 0.0, 1.0)
	for i in fireflies.size():
		var phase := float(i) * 2.1
		# NOCHE 01: foreground fireflies (the real model, near the flight plane) drift through the WORLD towards -X with a
		# soft bob, so they always look where they go (model forward = -X); far ones are light points (see _far_lights).
		var bug := fireflies[i]
		if not _firefly_x.has(i) or _firefly_x[i] < camera_x - FIREFLY_WRAP:
			_firefly_x[i] = camera_x + FIREFLY_WRAP - (0.0 if _firefly_x.has(i) else FIREFLY_WRAP * 2.0 * float(i) / float(FIREFLY_COUNT))
		_firefly_x[i] = float(_firefly_x[i]) - FIREFLY_DRIFT * delta
		bug.global_position = Vector3(float(_firefly_x[i]), 2.0 + 1.0 * float(i % 2) + 0.45 * sin(_clock * 0.9 + phase * 1.7), FIREFLY_Z[i % FIREFLY_Z.size()])
		bug.visible = dusk > 0.02 # Not drawn (nor animated) before the evening starts.
		bug.rotation.y = 0.0 # Moving towards -X, the way the model looks.
		var pulse := 0.5 + 0.5 * sin(_clock * 2.3 + phase * 3.0)
		((_glows[i].material_override) as StandardMaterial3D).albedo_color.a = (0.12 + 0.5 * pulse) * dusk
	_update_far_lights(camera_x, dusk)
	var night := clampf(inverse_lerp(SKY_FADE_FROM, SKY_FADE_TO, distance), 0.0, 1.0)
	var visible_now := night > 0.01
	moon.visible = visible_now
	for star in stars:
		star.visible = visible_now
	if not visible_now:
		return
	for material in _sky_materials:
		material.albedo_color.a = night
	var drift := -distance * 0.02
	_pin(moon, camera, Vector2(0.74, 0.2), 0.2, 1.44, drift)
	_pin(stars[0], camera, Vector2(0.3, 0.12), 0.2, 1.23, drift * 0.5)
	_pin(stars[1], camera, Vector2(0.62, 0.07), 0.14, 1.23, drift * 0.7)


# --- NOCHE 01: far fireflies = soft light points -----------------------------------------------------------------

func _build_far_lights(disc: Texture2D) -> void:
	var process := ParticleProcessMaterial.new()
	process.gravity = Vector3.ZERO
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(11.0, 1.8, 3.0)
	process.direction = Vector3(-1, 0.2, 0)
	process.spread = 60.0
	process.initial_velocity_min = 0.05
	process.initial_velocity_max = 0.25
	var curve := Curve.new() # Glow in and out: a twinkle, no motion to read as a body.
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var curve_texture := CurveTexture.new()
	curve_texture.curve = curve
	process.scale_curve = curve_texture
	process.scale_min = 0.6
	process.scale_max = 1.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.32, 0.32)
	_far_material = StandardMaterial3D.new()
	_far_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_far_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_far_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_far_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_far_material.albedo_texture = disc
	_far_material.albedo_color = Color(1.0, 0.9, 0.45, 0.0)
	_far_material.disable_receive_shadows = true
	quad.material = _far_material
	far_lights = GPUParticles3D.new()
	far_lights.name = "FarFireflyLights"
	far_lights.amount = FAR_LIGHTS
	far_lights.lifetime = 3.2
	far_lights.preprocess = 3.2
	far_lights.local_coords = false
	far_lights.process_material = process
	far_lights.draw_pass_1 = quad
	far_lights.visibility_aabb = AABB(Vector3(-14, -4, -5), Vector3(28, 8, 10))
	far_lights.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	far_lights.emitting = false
	add_child(far_lights)


func _update_far_lights(camera_x: float, dusk: float) -> void:
	if far_lights == null:
		return
	far_lights.global_position = Vector3(camera_x + 1.0, 2.6, -9.5)
	var on := dusk > 0.02
	if far_lights.emitting != on:
		far_lights.emitting = on
	_far_material.albedo_color.a = 0.85 * dusk
