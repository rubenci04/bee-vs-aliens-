class_name BeeLevel01Foreground
extends Node3D
## LOTE 11 · C4 — foreground: LAYERS of soft, out-of-focus grass blades between the camera and the flight plane, so the grass
## passes IN FRONT of Bee at a faster parallax than the scenery. World-fixed (the scroll makes them pass), one MultiMesh per
## layer, alpha-only (they never block input or collisions) and faint enough not to hide enemies or shots.
## Each layer: [z, step along X (m), blade width, blade height, alpha, blur feather, colour].

const ENABLED := true
const LENGTH := 400.0
const BASE_Y := -0.35
## LOTE 14 · ETAPA 3.2: small screens - thinner blades (WIDTH_SCALE), fewer of them (STEP_SCALE), all at ALPHA, and they fade out over the middle of
## the screen (CENTER_HALF_WIDTH / CENTER_HALF_HEIGHT, fractions of the screen; the shader reads SCREEN_UV) so they never cover the action.
const WIDTH_SCALE := 0.6
const STEP_SCALE := 1.8
const ALPHA := 0.40
const CENTER_HALF_WIDTH := 0.30
const CENTER_HALF_HEIGHT := 0.34
const CENTER_FEATHER := 0.10
const LAYERS := [
	{"z": 3.2, "step": 2.8, "width": 0.40, "height": 3.2, "alpha": 0.42, "feather": 0.45, "color": Color(0.28, 0.40, 0.13)},
	{"z": 6.0, "step": 4.6, "width": 0.55, "height": 4.2, "alpha": 0.34, "feather": 0.62, "color": Color(0.24, 0.36, 0.11)},
	{"z": 7.9, "step": 8.0, "width": 0.85, "height": 5.4, "alpha": 0.26, "feather": 0.85, "color": Color(0.20, 0.31, 0.09)},
]
const SHADER := preload("res://assets/style/foreground_blade.gdshader")

var layers: Array[MultiMeshInstance3D] = []
var combat_intensity := 0.0


func _ready() -> void:
	if not ENABLED:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 11011
	for i in LAYERS.size():
		var spec: Dictionary = LAYERS[i]
		var count := int(LENGTH / (float(spec["step"]) * STEP_SCALE))
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("blade_color", spec["color"])
		material.set_shader_parameter("fade", minf(float(spec["alpha"]), ALPHA))
		material.set_shader_parameter("center_half", Vector2(CENTER_HALF_WIDTH, CENTER_HALF_HEIGHT))
		material.set_shader_parameter("center_feather", CENTER_FEATHER)
		material.set_shader_parameter("feather", float(spec["feather"]))
		quad.material = material
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = quad
		multimesh.instance_count = count
		for k in count:
			var width := float(spec["width"]) * WIDTH_SCALE * rng.randf_range(0.7, 1.35)
			var height := float(spec["height"]) * rng.randf_range(0.65, 1.25)
			var x := (float(k) + rng.randf_range(0.0, 0.9)) * float(spec["step"]) * STEP_SCALE
			var tilt := rng.randf_range(-0.16, 0.16)
			var basis := Basis(Vector3.BACK, tilt) * Basis.from_scale(Vector3(width, height, 1.0))
			multimesh.set_instance_transform(k, Transform3D(basis, Vector3(x, BASE_Y + height * 0.5, float(spec["z"]) + rng.randf_range(-0.4, 0.4))))
		var instance := MultiMeshInstance3D.new()
		instance.name = "ForegroundLayer%d" % i
		instance.multimesh = multimesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.extra_cull_margin = 8.0
		add_child(instance)
		layers.append(instance)


func _process(delta: float) -> void:
	var stage := get_parent() as Node3D
	combat_intensity = move_toward(combat_intensity, BeeGameSettings.presentation_combat_intensity(stage), delta * BeeGameSettings.AMBIENT_COMBAT_RESPONSE)
	for i in layers.size():
		var material := (layers[i].multimesh.mesh as QuadMesh).material as ShaderMaterial
		material.set_shader_parameter("fade", minf(float(LAYERS[i]["alpha"]), ALPHA) * lerpf(1.0, BeeGameSettings.FOREGROUND_COMBAT_ALPHA_SCALE, combat_intensity))
