@tool
extends Node3D
## Art lab only; never attached to the live BeePlayer scene.
const GOLD_ENERGY := 0.65
@export var preview_motion := true
func _ready() -> void:
	BeeToonStyle.apply(self,true,BeeToonStyle.OUTLINE_BEE)
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_surface_override_material(surface) as ShaderMaterial
			if material == null:
				continue
			var own := material.duplicate() as ShaderMaterial
			if own.shader == BeeToonStyle.WING:
				own.set_shader_parameter("sheen_strength",0.0)
				own.set_shader_parameter("alpha",0.42)
			else:
				var energy: Variant = own.get_shader_parameter("emission_energy")
				if energy != null and float(energy)>0:
					own.set_shader_parameter("emission_energy",GOLD_ENERGY)
			mesh.set_surface_override_material(surface,own)
	if preview_motion:
		play_clip("wingbeat")
func play_clip(name: String) -> void:
	var player := find_child("AnimationPlayer",true,false) as AnimationPlayer
	if player != null and player.has_animation(name):
		player.get_animation(name).loop_mode = Animation.LOOP_LINEAR
		player.play(name)
