extends Node3D
## Historical resource path kept; live pollen is three round grains.
const S := preload("res://scripts/game/bee_pollen_settings.gd")
var elapsed := 0.0
var radius := 0.425
var sparkle: MeshInstance3D

func _ready() -> void:
	var size := radius * S.PICKUP_SIZE_FACTOR
	for i in 3:
		var angle := -PI * 0.5 + i * TAU / 3.0
		var grain := _sphere("Grain%d" % i, size * S.GRAIN_RADIUS_FACTOR, S.GOLD)
		grain.position = Vector3(cos(angle), sin(angle), 0) * size * (1.0 - S.GRAIN_RADIUS_FACTOR)
	sparkle = _sphere("Sparkle", size * S.SPARK_RADIUS_FACTOR, Color(1, 0.97, 0.7))
	sparkle.position = Vector3(size * 0.55, size * 0.6, size * 0.5)

func _sphere(part_name: String, size: float, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = size
	shape.height = size * 2.0
	shape.radial_segments = 12
	shape.rings = 6
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	mesh.mesh = shape
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.45
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = S.EMISSION
	mesh.material_override = material
	add_child(mesh)
	return mesh

func _process(delta: float) -> void:
	elapsed += delta
	rotation.z = elapsed * S.ROTATION_SPEED
	position.y = sin(elapsed * S.BOB_RATE) * S.BOB_HEIGHT
	sparkle.scale = Vector3.ONE * (0.6 + 0.4 * sin(elapsed * S.BOB_RATE * 2.0))
