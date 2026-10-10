class_name BeeToonStyle
extends RefCounted
## Style C: toon bands + soft rim + thin dark outline + translucent wings.
## Presentation only: swaps surface materials of an imported model; never touches transforms,
## skeletons, animation or physics. Albedo texture, vertex colour, emission and double-sided
## culling of the source material are preserved.

const TOON := preload("res://assets/style/toon_body.gdshader")
const TOON_DOUBLE := preload("res://assets/style/toon_body_double.gdshader")
const TOON_CUTOUT := preload("res://assets/style/toon_body_cutout.gdshader")
const OUTLINE := preload("res://assets/style/toon_outline.gdshader")
const WING := preload("res://assets/style/toon_wing.gdshader")
## Alien-tech cyan emission is raised to at least this energy so it clears the glow threshold.
const CYAN_MIN_ENERGY := 2.0
const BRIGHT_ALBEDO_CAP := 0.8
## Outline weight in fractions of the screen height (same on-screen thickness at any distance or scale).
## LEVEL 01 TRANSFORMATION PASS 01 (style): a slightly more drawn look on what the player reads, subtler on big props.
##   BEFORE: 0.0025 for everything (~1.3 px at 1080p).
##   AFTER:  Bee 0.0030 (+20 %), actors (enemies, dragonfly, UFO) 0.0029 (+16 %), props 0.0023 (-8 %).
##   The Giant Human keeps no outline (its scale would turn it into a sticker).
const OUTLINE_BEE := 0.0030
const OUTLINE_ACTOR := 0.0029
const OUTLINE_PROP := 0.0023

## 0..1, written by the level light progression: strengthens the rim light on Bee at sunset.
static var bee_rim_boost := 0.0
static var _outline_materials: Dictionary = {} # width -> ShaderMaterial
## VISUAL POLISH 02: outline colour follows the light of the level (warm brown by day, violet at sunset). Set by
## BeeLevel01LightProgression; every outline material (shared by width) is updated together.
const OUTLINE_BASE := Color(0.035, 0.022, 0.015)
const OUTLINE_TINT_STRENGTH := 0.6
static var outline_color := OUTLINE_BASE
static var _cache: Dictionary = {}


## outline = false keeps toon + rim only (cheaper: no second draw of every surface).
static func apply(model: Node, outline: bool, outline_width := OUTLINE_PROP) -> void:
	var meshes: Array = model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for mesh: MeshInstance3D in meshes:
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_surface_override_material(surface) as BaseMaterial3D
			if source == null:
				source = mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			if source != null:
				mesh.set_surface_override_material(surface, _material_for(source, outline, outline_width))


## GARDEN IDENTITY 04 — Style C by asset type (imported props). Never applied blindly:
##   &"prop"     closed meshes (pots, cans, tools, bushes): toon + rim + the thin prop outline
##   &"foliage"  thin single-layer leaves / blades: toon double sided, NO outline (an inverted hull would paint the
##               back faces black when the leaf is seen from behind)
##   &"cutout"   leaves whose texture has holes (alpha): toon double sided with alpha scissor, NO outline
static func apply_profile(model: Node, profile: StringName) -> void:
	match profile:
		&"foliage":
			_apply_with(model, TOON_DOUBLE)
		&"cutout":
			_apply_with(model, TOON_CUTOUT)
		_:
			apply(model, true, OUTLINE_PROP)


static func _apply_with(model: Node, shader: Shader) -> void:
	var meshes: Array = model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for mesh: MeshInstance3D in meshes:
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_surface_override_material(surface) as BaseMaterial3D
			if source == null:
				source = mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			if source != null:
				mesh.set_surface_override_material(surface, _material_for(source, false, OUTLINE_PROP, shader))


static func is_cyan(color: Color) -> bool:
	return color.h > 0.42 and color.h < 0.56 and color.s > 0.35


## `forced_shader` (profiles): use this body shader instead of choosing by the source's culling.
static func _material_for(source: BaseMaterial3D, outline: bool, outline_width: float, forced_shader: Shader = null) -> ShaderMaterial:
	var is_wing := source.resource_name == "Wing"
	var texture := source.albedo_texture
	var key := "%s|%s|%s|%s|%s|%s|%s|%s|%s" % [is_wing, source.albedo_color.to_html(), source.emission_enabled, source.emission.to_html() if source.emission_enabled else "",
			source.emission_energy_multiplier, source.cull_mode, texture.get_instance_id() if texture != null else 0, str(source.vertex_color_use_as_albedo) + str(outline) + str(outline_width),
			forced_shader.get_instance_id() if forced_shader != null else 0]
	if _cache.has(key):
		return _cache[key]
	var material := ShaderMaterial.new()
	if is_wing:
		material.shader = WING
		material.set_shader_parameter("tint", source.albedo_color.lerp(Color.WHITE, 0.35))
	else:
		material.shader = forced_shader if forced_shader != null else (TOON_DOUBLE if source.cull_mode == BaseMaterial3D.CULL_DISABLED else TOON)
		var albedo := source.albedo_color
		var luminance := albedo.get_luminance()
		if luminance > BRIGHT_ALBEDO_CAP:
			albedo = Color(albedo.r, albedo.g, albedo.b) * (BRIGHT_ALBEDO_CAP / luminance) # Sun + ambient would blow out near-white models.
		material.set_shader_parameter("albedo", albedo)
		if texture != null:
			material.set_shader_parameter("albedo_tex", texture)
			material.set_shader_parameter("use_texture", true)
		if source.vertex_color_use_as_albedo:
			material.set_shader_parameter("use_vertex_color", true)
		if source.emission_enabled and source.emission.get_luminance() > 0.001:
			var energy := source.emission_energy_multiplier
			if is_cyan(source.emission):
				energy = maxf(energy, CYAN_MIN_ENERGY)
			material.set_shader_parameter("emission", source.emission)
			material.set_shader_parameter("emission_energy", energy)
		if outline:
			material.next_pass = shared_outline(outline_width)
	_cache[key] = material
	return material


static func shared_outline(width: float) -> ShaderMaterial:
	if not _outline_materials.has(width):
		var material := ShaderMaterial.new()
		material.shader = OUTLINE
		material.set_shader_parameter("width", width)
		material.set_shader_parameter("outline_color", outline_color)
		_outline_materials[width] = material
	return _outline_materials[width]


static func set_outline_tint(tint: Color) -> void:
	outline_color = OUTLINE_BASE.lerp(tint, OUTLINE_TINT_STRENGTH)
	for material: ShaderMaterial in _outline_materials.values():
		material.set_shader_parameter("outline_color", outline_color)
