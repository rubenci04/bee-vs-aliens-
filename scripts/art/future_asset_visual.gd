@tool
extends Node3D
## Presentation asset only. Coordinates: X/Y gameplay plane, -X facing, +Y up.
## The animal remains intact when its external controller is removed.
@export var controlled := true:
	set(value):
		controlled = value
		_sync_control()

func _ready() -> void:
	BeeToonStyle.apply(self, true, BeeToonStyle.OUTLINE_PROP)
	# Compatibility has no HDR bloom. Keep coloured lenses readable instead of
	# clipping to white; own copies leave the game's shared Style C cache intact.
	for node: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		for surface in node.mesh.get_surface_count():
			var material := node.get_surface_override_material(surface) as ShaderMaterial
			if material == null:
				continue
			var energy: Variant = material.get_shader_parameter("emission_energy")
			if energy != null and float(energy) > 0.0:
				var own := material.duplicate() as ShaderMaterial
				own.set_shader_parameter("emission_energy", 0.65)
				node.set_surface_override_material(surface, own)
	_sync_control()

func _sync_control() -> void:
	var device := find_child("AlienControlDevice", true, false) as Node3D
	if device != null:
		device.visible = controlled

func release_control() -> void:
	controlled = false

func face_right(right: bool) -> void:
	rotation.y = PI if right else 0.0
