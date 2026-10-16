extends Node3D
const S := preload("res://scripts/game/bee_pollen_nova_settings.gd")
var age := 0.0
var ring: MeshInstance3D
var material: StandardMaterial3D
func _ready() -> void:
	name = "PollenHealGlow"
	ring = MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.55
	mesh.outer_radius = 0.62
	mesh.rings = 24
	mesh.ring_segments = 6
	ring.mesh = mesh
	ring.rotation.x = PI * 0.5
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.8, 0.18, 0.9)
	ring.material_override = material
	add_child(ring)
func _process(delta: float) -> void:
	age += delta
	var progress := clampf(age / S.HEAL_GLOW_SECONDS, 0.0, 1.0)
	ring.scale = Vector3.ONE * (1.0 + progress * 0.8)
	material.albedo_color.a = 0.9 * (1.0 - progress)
	if progress >= 1.0: queue_free()
