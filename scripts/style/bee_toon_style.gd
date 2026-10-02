class_name BeeToonStyle
extends RefCounted
## Style C (APPLY STYLE C 01): toon bands + soft rim + thin dark outline + translucent wings.
## Presentation only: swaps surface materials of an imported model; never touches transforms or physics.

const TOON := preload("res://assets/style/toon_body.gdshader")
const OUTLINE := preload("res://assets/style/toon_outline.gdshader")
const WING := preload("res://assets/style/toon_wing.gdshader")

static var _outline_material: ShaderMaterial
static var _cache: Dictionary = {}


## outline = false keeps toon + rim only (cheaper: no second draw of every surface).
static func apply(model: Node, outline: bool) -> void:
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_surface_override_material(surface) as BaseMaterial3D
			if source == null:
				source = mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			if source != null:
				mesh.set_surface_override_material(surface, _material_for(source, outline))


static func _material_for(source: BaseMaterial3D, outline: bool) -> ShaderMaterial:
	var is_wing := source.resource_name == "Wing"
	var key := "%s|%s|%s|%s|%s" % [is_wing, source.albedo_color.to_html(), source.emission_enabled, source.emission.to_html() if source.emission_enabled else "", outline]
	if _cache.has(key):
		return _cache[key]
	var material := ShaderMaterial.new()
	if is_wing:
		material.shader = WING
		material.set_shader_parameter("tint", source.albedo_color.lerp(Color.WHITE, 0.35))
	else:
		material.shader = TOON
		material.set_shader_parameter("albedo", source.albedo_color)
		if source.emission_enabled:
			material.set_shader_parameter("emission", source.emission)
			material.set_shader_parameter("emission_energy", source.emission_energy_multiplier)
		if outline:
			material.next_pass = _shared_outline()
	_cache[key] = material
	return material


static func _shared_outline() -> ShaderMaterial:
	if _outline_material == null:
		_outline_material = ShaderMaterial.new()
		_outline_material.shader = OUTLINE
	return _outline_material
