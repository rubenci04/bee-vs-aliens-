class_name BeeToonStyle
extends RefCounted
## Style C: toon bands + soft rim + thin dark outline + translucent wings.
## Presentation only: swaps surface materials of an imported model; never touches transforms,
## skeletons, animation or physics. Albedo texture, vertex colour, emission and double-sided
## culling of the source material are preserved.

const TOON := preload("res://assets/style/toon_body.gdshader")
const TOON_DOUBLE := preload("res://assets/style/toon_body_double.gdshader")
const OUTLINE := preload("res://assets/style/toon_outline.gdshader")
const WING := preload("res://assets/style/toon_wing.gdshader")
## Alien-tech cyan emission is raised to at least this energy so it clears the glow threshold.
const CYAN_MIN_ENERGY := 2.0
const BRIGHT_ALBEDO_CAP := 0.8

static var _outline_material: ShaderMaterial
static var _cache: Dictionary = {}


## outline = false keeps toon + rim only (cheaper: no second draw of every surface).
static func apply(model: Node, outline: bool) -> void:
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
				mesh.set_surface_override_material(surface, _material_for(source, outline))


static func is_cyan(color: Color) -> bool:
	return color.h > 0.42 and color.h < 0.56 and color.s > 0.35


static func _material_for(source: BaseMaterial3D, outline: bool) -> ShaderMaterial:
	var is_wing := source.resource_name == "Wing"
	var texture := source.albedo_texture
	var key := "%s|%s|%s|%s|%s|%s|%s|%s" % [is_wing, source.albedo_color.to_html(), source.emission_enabled, source.emission.to_html() if source.emission_enabled else "",
			source.emission_energy_multiplier, source.cull_mode, texture.get_instance_id() if texture != null else 0, str(source.vertex_color_use_as_albedo) + str(outline)]
	if _cache.has(key):
		return _cache[key]
	var material := ShaderMaterial.new()
	if is_wing:
		material.shader = WING
		material.set_shader_parameter("tint", source.albedo_color.lerp(Color.WHITE, 0.35))
	else:
		material.shader = TOON_DOUBLE if source.cull_mode == BaseMaterial3D.CULL_DISABLED else TOON
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
			material.next_pass = _shared_outline()
	_cache[key] = material
	return material


static func _shared_outline() -> ShaderMaterial:
	if _outline_material == null:
		_outline_material = ShaderMaterial.new()
		_outline_material.shader = OUTLINE
	return _outline_material
