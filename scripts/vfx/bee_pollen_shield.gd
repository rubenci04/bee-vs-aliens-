extends Node3D
## Tanda E1: translucent golden bubble that follows Bee for SHIELD_SECONDS. Destroys enemy projectiles that touch it.
const S := preload("res://scripts/game/bee_pollen_nova_settings.gd")
var age := 0.0
var bubble: MeshInstance3D
var material: StandardMaterial3D

func _ready() -> void:
	name = "PollenShield"
	bubble = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = S.SHIELD_RADIUS
	sphere.height = S.SHIELD_RADIUS * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	bubble.mesh = sphere
	bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(1.0, 0.8, 0.2, 0.3)
	bubble.material_override = material
	add_child(bubble)

func _physics_process(delta: float) -> void:
	age += delta
	if age >= S.SHIELD_SECONDS:
		queue_free()
		return
	var left := S.SHIELD_SECONDS - age
	var pulse := 1.0 + 0.05 * sin(age * TAU * 2.0)
	bubble.scale = Vector3.ONE * pulse
	var alpha := 0.3
	if left < S.SHIELD_WARN_SECONDS:
		alpha = 0.3 if int(left * 16.0) % 2 == 0 else 0.1
	material.albedo_color.a = alpha
	if not is_inside_tree():
		return
	for shot in get_tree().get_nodes_in_group("alien_projectiles"):
		if shot is Node3D and not shot.is_queued_for_deletion() and global_position.distance_to(shot.global_position) <= S.SHIELD_RADIUS + 0.15:
			for child in shot.find_children("*", "Area3D", true, false):
				if child is DamageHitbox3D: child.set_enabled(false)
			shot.queue_free()
