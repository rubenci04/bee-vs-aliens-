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
## NOCHE 01 · ETAPA 2 — Codex props (miniature world: Bee 1.18 m). All behind the flight plane, no collision.
const GREEN_BOTTLE := preload("res://scenes/art_labs/ground_litter_v01/glass_bottle.tscn")
const TUNA_TIN := preload("res://scenes/art_labs/ground_litter_v02/open_tuna_tin.tscn")
const BANANA_PEEL := preload("res://scenes/art_labs/ground_litter_v02/banana_peel.tscn")
const HOSE := preload("res://scenes/art_labs/garden_backdrop_v01/garden_hose.tscn")
const FENCE := preload("res://scenes/art_labs/garden_backdrop_v01/garden_fence_module.tscn")
const HOUSE := preload("res://scenes/art_labs/garden_backdrop_v01/garden_distant_house.tscn")
const WATERING_CAN := preload("res://scenes/art_labs/garden_backdrop_v01/garden_watering_can.tscn")
const PINE_CONE := preload("res://scenes/art_labs/pine_woods_v01/pine_cone.tscn")
const TALL_PINE := preload("res://scenes/art_labs/pine_woods_v01/tall_pine.tscn")
const UMBRELLA_PINE := preload("res://scenes/art_labs/pine_woods_v01/umbrella_pine.tscn")
const HOLLOW_LOG := preload("res://scenes/art_labs/forest_floor_v01/hollow_fallen_log.tscn")
const BELLFLOWER := preload("res://scenes/art_labs/forest_floor_v01/garden_bellflower.tscn")
const SUN_MODEL := preload("res://scenes/art_labs/assets_v07/sky_sun.tscn")
const MOON_MODEL := preload("res://assets/models/levels/level_01_garden/environment/sky_crescent_moon.glb")
const STARS_MODEL := preload("res://assets/models/levels/level_01_garden/environment/sky_star_cluster.glb")

const RELAY_SCALE := 2.1 # The model is ~0.95 m tall; the old pylon column was 1.8 m.
const SKY_DEPTH := 70.0
const SKY_FADE_FROM := 255.0 # Level distance where the night sky starts to appear...
const SKY_FADE_TO := 310.0 # ...and where it is fully visible.
const SUN_DEPTH := 38.0 # Inside the far fog cut-off, so the toon disk remains crisp.
const SUN_SCREEN_X := 0.82
const SUN_ASSET_HEIGHT := 1.44
const SUN_SCREEN_HEIGHT := 0.19
const SUN_MORNING_SCREEN_Y := 0.31
const SUN_MIDDAY_SCREEN_Y := 0.13
const SUN_MIDDAY_FROM := 80.0
const SUN_MIDDAY_TO := 180.0
const SUN_FADE_FROM := 270.0
const SUN_FADE_TO := 315.0
## Fireflies are reserved for a forest level. Keep the scene, movement and model available, but off in Level 01.
const FIREFLIES_ENABLED := false
const FIREFLY_COUNT := 3
const FIREFLY_FADE_FROM := 150.0
## NOCHE 01 — foreground fireflies: world drift (m/s, towards -X), wrap distance from the camera, depths (behind the plane).
const FIREFLY_DRIFT := 0.8
const FIREFLY_WRAP := 8.5
const FIREFLY_Z := [-1.8, -2.4, -2.1]
## Far fireflies are only soft light points (no body), so they are never mistaken for wasps.
const FAR_LIGHTS := 16
const FIREFLY_MODEL_LENGTH := 1.293 # controlled_firefly.glb body length at scale 1 (catalogue).

## LOTE 14 · ETAPA 3.2: the large human-scale pieces (can, bottle, watering can, hollow log) are 20 % smaller and sit a metre further back
## (small screens: they filled the frame). Applied to the scenes in BIG_PROPS when the litter is built.
const BIG_PROP_SCALE := 0.8
const BIG_PROP_PUSH_BACK := 1.0
var BIG_PROPS: Array = [CAN, GREEN_BOTTLE, WATERING_CAN, HOLLOW_LOG]

## [scene, x, z, scale, yaw (rad), tilt (rad, z axis)]. All z < 0: behind the flight plane.
const LITTER := [
	[CAP, 22.0, -2.4, 2.0, 0.3, 0.0], [CAP, 176.0, -2.9, 2.2, 2.2, 0.12],
	[CAN, 120.0, -4.2, 4.5, 0.4, 0.0], [CAN, 243.0, -4.8, 4.2, 5.4, -0.05],
	[CANDY, 83.0, -2.6, 1.7, 0.2, 0.0], [CANDY, 297.0, -3.0, 1.5, 3.4, 0.0],
	[SHRUB, 12.0, -3.8, 3.2, 0.2, 0.0], [SHRUB, 137.0, -3.6, 3.5, 3.1, 0.0], [SHRUB, 212.0, -4.0, 3.0, 0.4, 0.0], [SHRUB, 325.0, -3.8, 3.3, 2.5, 0.0],
	[SAPLING, 60.0, -11.0, 2.6, 0.5, 0.0], [SAPLING, 190.0, -12.0, 2.8, 2.0, 0.0], [SAPLING, 270.0, -11.5, 2.6, 4.1, 0.0],
	# NOCHE 01 · ETAPA 2: the green bottle replaces the red one at the start; hose, fence, distant house, pine cones, pines,
	# a hollow log with bellflowers, more daisy shrubs and trees.
	[GREEN_BOTTLE, 41.0, -3.4, 6.0, 0.2, 0.0],
	[TUNA_TIN, 171.0, -3.9, 3.2, 0.5, 0.0], [BANANA_PEEL, 63.0, -2.6, 2.0, 1.1, 0.0],
	[HOSE, 96.0, -3.8, 4.0, 0.3, 0.0],
	[HOLLOW_LOG, 55.0, -3.4, 2.5, 0.2, 0.0], [BELLFLOWER, 122.5, -3.0, 1.6, 0.1, 0.0], [BELLFLOWER, 129.5, -3.6, 1.4, 1.2, 0.0],
	[BELLFLOWER, 31.0, -3.2, 1.5, 0.4, 0.0], [BELLFLOWER, 72.0, -3.4, 1.6, 2.0, 0.0], [BELLFLOWER, 205.0, -3.0, 1.5, 0.8, 0.0],
	[SHRUB, 68.0, -3.9, 3.0, 1.3, 0.0], [SHRUB, 158.0, -4.1, 3.3, 0.6, 0.0],
	[SAPLING, 104.0, -14.0, 2.4, 1.0, 0.0], # NOCHE 01 · ETAPA 3: smaller and further (was z -9.5, 3.2: it filled the centre).
	# LOTE 13 · ETAPA 1: the whole level is a HOUSE GARDEN, also at dusk. The pines and pine cones of the second half left the
	# level (they belong to level_03_forest, see FOREST_PIECES) and the background is filled with garden pieces: the second half
	# gets shrubs, bellflowers, saplings, cans, a hose and watering cans where the pines stood. Fence and houses: see FENCE_* / HOUSE_*.
	[SHRUB, 240.0, -3.9, 3.1, 0.9, 0.0], [SHRUB, 262.0, -4.0, 3.3, 2.0, 0.0], [SHRUB, 283.0, -3.8, 3.0, 4.0, 0.0], [SHRUB, 306.0, -4.1, 3.4, 1.2, 0.0],
	[SHRUB, 340.0, -3.9, 3.2, 3.3, 0.0], [SHRUB, 4.0, -4.0, 3.0, 2.2, 0.0],
	[BELLFLOWER, 244.0, -3.2, 1.6, 0.3, 0.0], [BELLFLOWER, 258.0, -3.5, 1.5, 1.7, 0.0], [BELLFLOWER, 271.0, -3.1, 1.6, 2.6, 0.0],
	[BELLFLOWER, 290.0, -3.4, 1.4, 0.8, 0.0], [BELLFLOWER, 311.0, -3.2, 1.6, 3.4, 0.0], [BELLFLOWER, 322.0, -3.6, 1.5, 5.0, 0.0],
	[BELLFLOWER, 346.0, -3.3, 1.6, 1.1, 0.0], [BELLFLOWER, 358.0, -3.1, 1.5, 4.2, 0.0],
	[SAPLING, 252.0, -13.0, 2.5, 3.0, 0.0], [SAPLING, 296.0, -12.5, 2.7, 0.7, 0.0], [SAPLING, 334.0, -13.5, 2.6, 5.2, 0.0], [SAPLING, 20.0, -12.0, 2.5, 1.9, 0.0],
	[CAN, 301.0, -4.6, 4.3, 2.1, 0.05], [CAN, 349.0, -4.4, 4.0, 0.9, 0.0], [CANDY, 255.0, -2.9, 1.6, 1.3, 0.0], [CANDY, 331.0, -3.0, 1.5, 4.4, 0.0],
	[HOSE, 226.0, -3.8, 4.0, 3.6, 0.0], [HOSE, 318.0, -3.9, 4.0, 0.4, 0.0],
	[WATERING_CAN, 38.0, -4.6, 3.3, 0.6, 0.0], [WATERING_CAN, 205.0, -4.8, 3.3, 3.4, 0.0], [WATERING_CAN, 277.0, -4.6, 3.3, 5.8, 0.0], [WATERING_CAN, 352.0, -4.7, 3.3, 2.7, 0.0],
]
## Garden backdrop generated along the whole level: a fence (module every FENCE_STEP m) and distant houses.
const FENCE_FROM := -10.0
const FENCE_TO := 392.0
const FENCE_STEP := 7.2
const FENCE_Z := -21.0
const FENCE_SCALE := 3.6
const HOUSE_X := [20.0, 120.0, 176.0, 252.0, 330.0]
const HOUSE_Z := -58.0
const HOUSE_SCALE := 8.0
## Forest pieces (pines, pine cones): kept for the forest level, NOT built in Level 01 (flip to bring them back for previews).
const BUILD_FOREST_PIECES := false
const FOREST_PIECES := [
	[PINE_CONE, 160.0, -2.8, 4.0, 0.7, 0.0], [PINE_CONE, 236.0, -3.0, 3.6, 2.1, 0.0],
	[TALL_PINE, 250.0, -20.0, 8.0, 0.3, 0.0], [TALL_PINE, 268.0, -22.0, 8.5, 1.1, 0.0], [UMBRELLA_PINE, 286.0, -24.0, 7.0, 0.5, 0.0],
	[TALL_PINE, 304.0, -21.0, 8.0, 2.4, 0.0], [TALL_PINE, 330.0, -22.0, 9.0, 0.9, 0.0], [UMBRELLA_PINE, 352.0, -25.0, 7.5, 1.7, 0.0],
]

var stage: BeeShmupStage
var relays: Array[Node3D] = []
var litter: Array[Node3D] = []
var fireflies: Array[Node3D] = []
var sun: Node3D
var sun_halo: MeshInstance3D
var _sun_materials: Array[ShaderMaterial] = []
var _sun_halo_material: StandardMaterial3D
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
	call_deferred("_hide_old_props")
	if FIREFLIES_ENABLED:
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
	var entries: Array = LITTER.duplicate()
	if BUILD_FOREST_PIECES or not BeeLevel01Controller.roster_only: # The legacy (pre-roster) table keeps its pines.
		entries.append_array(FOREST_PIECES)
	var fence_x := FENCE_FROM
	while fence_x <= FENCE_TO:
		entries.append([FENCE, fence_x, FENCE_Z, FENCE_SCALE, 0.0, 0.0])
		fence_x += FENCE_STEP
	for x in HOUSE_X:
		entries.append([HOUSE, float(x), HOUSE_Z, HOUSE_SCALE, 0.0, 0.0])
	for entry in entries:
		var item := (entry[0] as PackedScene).instantiate() as Node3D
		item.name = "Litter%d" % litter.size()
		add_child(item)
		var big: bool = entry[0] in BIG_PROPS
		item.position = Vector3(float(entry[1]), -0.05, float(entry[2]) - (BIG_PROP_PUSH_BACK if big else 0.0))
		item.scale = Vector3.ONE * float(entry[3]) * (BIG_PROP_SCALE if big else 1.0)
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
	sun = SUN_MODEL.instantiate() as Node3D
	sun.name = "DaySun"
	add_child(sun)
	sun.hide()
	for mesh: MeshInstance3D in sun.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.get_surface_override_material(surface) as ShaderMaterial
			if original == null:
				continue
			var own := original.duplicate() as ShaderMaterial
			var base: Color = own.get_meta("sky_base_albedo", own.get_shader_parameter("albedo"))
			own.set_meta("sun_base_albedo", base)
			mesh.set_surface_override_material(surface, own)
			_sun_materials.append(own)
	var halo_mesh := QuadMesh.new()
	halo_mesh.size = Vector2(2.2, 2.2)
	var halo_gradient := GradientTexture2D.new()
	halo_gradient.fill = GradientTexture2D.FILL_RADIAL
	halo_gradient.fill_from = Vector2(0.5, 0.5)
	halo_gradient.fill_to = Vector2(1.0, 0.5)
	halo_gradient.width = 64
	halo_gradient.height = 64
	var halo_ramp := Gradient.new()
	halo_ramp.colors = PackedColorArray([Color(1.0, 0.72, 0.28, 0.36), Color(1.0, 0.72, 0.28, 0.0)])
	halo_gradient.gradient = halo_ramp
	_sun_halo_material = StandardMaterial3D.new()
	_sun_halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sun_halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sun_halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_sun_halo_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_sun_halo_material.albedo_texture = halo_gradient
	_sun_halo_material.disable_receive_shadows = true
	sun_halo = MeshInstance3D.new()
	sun_halo.name = "SoftHalo"
	sun_halo.mesh = halo_mesh
	sun_halo.material_override = _sun_halo_material
	sun_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sun_halo.position.z = -0.18
	sun.add_child(sun_halo)
	moon = _sky_item(MOON_MODEL, "CrescentMoon")
	for i in 2:
		stars.append(_sky_item(STARS_MODEL, "Stars%d" % i))


## Places `item` at a fraction of the screen (0..1), SKY_DEPTH away, covering about `height_fraction` of the screen height.
func _pin(item: Node3D, camera: Camera3D, screen: Vector2, height_fraction: float, asset_height: float, drift: float, depth := SKY_DEPTH) -> void:
	var size := get_viewport().get_visible_rect().size
	var point := Vector2(size.x * screen.x, size.y * screen.y)
	item.global_position = camera.project_position(point, depth) + Vector3(drift, 0.0, 0.0)
	var view_height := 2.0 * depth * tan(deg_to_rad(camera.fov) * 0.5)
	item.scale = Vector3.ONE * (height_fraction * view_height / asset_height)
	item.global_rotation = camera.global_rotation


static func sun_screen_y_at(distance: float) -> float:
	var midday := smoothstep(SUN_MIDDAY_FROM, SUN_MIDDAY_TO, distance)
	var sunset := smoothstep(SUN_FADE_FROM, SUN_FADE_TO, distance)
	return lerpf(lerpf(SUN_MORNING_SCREEN_Y, SUN_MIDDAY_SCREEN_Y, midday), SUN_MORNING_SCREEN_Y, sunset)


static func sun_visibility_at(distance: float) -> float:
	return 1.0 - smoothstep(SUN_FADE_FROM, SUN_FADE_TO, distance)


# --- per frame --------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if stage == null or stage.camera == null:
		return
	_clock += delta
	var camera := stage.camera
	var camera_x := camera.global_position.x
	var distance := stage.distance
	var sun_alpha := sun_visibility_at(distance)
	sun.visible = sun_alpha > 0.01
	for material in _sun_materials:
		var base: Color = material.get_meta("sun_base_albedo")
		var sun_brightness := lerpf(0.05, 1.0, sun_alpha)
		material.set_shader_parameter("albedo", Color(base.r * sun_brightness, base.g * sun_brightness, base.b * sun_brightness, base.a))
	_sun_halo_material.albedo_color.a = sun_alpha
	var sun_y := sun_screen_y_at(distance)
	_pin(sun, camera, Vector2(SUN_SCREEN_X, sun_y), SUN_SCREEN_HEIGHT, SUN_ASSET_HEIGHT, 0.0, SUN_DEPTH)
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


## NOCHE 01 · ETAPA 2: the red soda bottle at the start is replaced by the Codex green bottle (node kept, hidden: other
## scenes and tests still find it by name).
func _hide_old_props() -> void:
	var old_log := stage.get_node_or_null("Scenery/FallenLog") as Node3D
	if old_log != null:
		old_log.hide() # Its imported light material reads as a white angular block; reuse the existing brown hollow log above.
	var bottle := stage.find_child("GiantBottle", true, false) as Node3D
	if bottle != null:
		bottle.hide()
	# The red/cream snack wrapper of the picnic (X=171) gives way to the Codex tuna tin (see LITTER).
	for node in stage.find_children("wrapper_*", "Node3D", true, false):
		(node as Node3D).hide()
