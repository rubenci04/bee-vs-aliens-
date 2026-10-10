@tool
extends Node3D
## Background-only Style C profile. Materials are local copies of shared toon.
@export_range(0.0003,0.003,0.0001) var outline_width := 0.0011
@export var tint := Color.WHITE:
	set(value):
		tint = value
		if is_node_ready():
			_apply_tint()

func _ready() -> void:
	for node: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		BeeToonStyle.apply(node,not node.name.begins_with("MoonMare_"),outline_width)
		for surface in node.mesh.get_surface_count():
			var material := node.get_surface_override_material(surface) as ShaderMaterial
			if material == null:
				continue
			var own := material.duplicate() as ShaderMaterial
			own.set_meta("sky_base_albedo",own.get_shader_parameter("albedo"))
			own.set_shader_parameter("rim_strength",0.12)
			node.set_surface_override_material(surface,own)
	_apply_tint()

func _apply_tint() -> void:
	for node: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		for surface in node.mesh.get_surface_count():
			var material := node.get_surface_override_material(surface) as ShaderMaterial
			if material == null or not material.has_meta("sky_base_albedo"):
				continue
			var base_color: Color = material.get_meta("sky_base_albedo")
			material.set_shader_parameter("albedo",base_color*tint)
