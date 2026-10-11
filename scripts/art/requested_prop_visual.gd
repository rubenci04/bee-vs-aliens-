extends "res://scripts/art/future_asset_visual.gd"
const GLASS := preload("res://assets/style/toon_prop_glass.gdshader")
func _ready() -> void:
	super._ready()
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if source != null and source.resource_name == "BottleGlass":
				var material := ShaderMaterial.new()
				material.shader = GLASS
				var tint := source.albedo_color
				tint.a = 0.38
				material.set_shader_parameter("albedo",tint)
				# Glass draws a dark silhouette edge in its own transparent pass.
				mesh.set_surface_override_material(surface,material)
			elif source != null and source.resource_name == "LampWarm":
				var material := mesh.get_surface_override_material(surface) as ShaderMaterial
				if material != null:
					material.set_shader_parameter("emission_energy",0.22)
