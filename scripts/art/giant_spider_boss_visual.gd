@tool
extends Node3D
## Art wrapper only. No AI, collisions or replacement of the current Level 01 boss.
@export var controlled := true:
	set(value):
		controlled = value
		_sync_control()
@export var preview_motion := true
const CORE_ENERGY := 0.65
func _ready() -> void:
	BeeToonStyle.apply(self, true, BeeToonStyle.OUTLINE_ACTOR)
	for node: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		for surface in node.mesh.get_surface_count():
			var mat := node.get_surface_override_material(surface) as ShaderMaterial
			var energy: Variant = mat.get_shader_parameter("emission_energy") if mat != null else null
			if energy != null and float(energy) > 0:
				var own := mat.duplicate() as ShaderMaterial
				own.set_shader_parameter("emission_energy", CORE_ENERGY)
				node.set_surface_override_material(surface, own)
	_sync_control()
	if preview_motion:
		play_clip("idle")
func _sync_control() -> void:
	for part: Node3D in find_children("implant*", "Node3D", true, false):
		part.visible = controlled
func release_control() -> void:
	controlled = false
func play_clip(clip: String) -> void:
	var player := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player != null and player.has_animation(clip):
		player.get_animation(clip).loop_mode = Animation.LOOP_NONE if clip == "attack" else Animation.LOOP_LINEAR
		player.play(clip)
