class_name WaspImplant
extends Node3D
## THREAT, CAMERA & BOSS REBUILD 03 — the alien implant on a controlled Wasp's back. It is the source of the
## "implant sting" shots and of the OVERLOAD: the threat visibly comes from alien tech, not from the insect.
## Modes: idle (dim cyan), sting (cyan charge), overload (red/orange, flashing faster, sparks), off (dead).
## Built in code with the shared alien palette; no collision.

var mode := &"idle"
var _t := 0.0
var _core: MeshInstance3D
var _material: StandardMaterial3D
var _spark_left := 0.0
var _halo: MeshInstance3D
var _halo_material: StandardMaterial3D

static var _shell_mesh: BoxMesh
static var _core_mesh: SphereMesh
static var _shell_material: StandardMaterial3D


func _ready() -> void:
	if _shell_mesh == null:
		_shell_mesh = BoxMesh.new()
		_shell_mesh.size = Vector3(0.26, 0.12, 0.2)
		_shell_material = StandardMaterial3D.new()
		_shell_material.albedo_color = BeeAlienPalette.SHELL
		_shell_material.roughness = 0.5
		_shell_mesh.material = _shell_material
		_core_mesh = SphereMesh.new()
		_core_mesh.radius = 0.095
		_core_mesh.height = 0.19
		_core_mesh.radial_segments = 8
		_core_mesh.rings = 4
	var shell := MeshInstance3D.new()
	shell.name = "ImplantShell"
	shell.mesh = _shell_mesh
	add_child(shell)
	_core = MeshInstance3D.new()
	_core.name = "ImplantCore"
	_core.mesh = _core_mesh
	_core.position = Vector3(0.0, 0.08, 0.0)
	_material = StandardMaterial3D.new() # Own material: each Wasp's implant flashes on its own.
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.emission_enabled = true
	_core.material_override = _material
	add_child(_core)
	# Overload halo: a big pulsing red-orange glow around the implant, readable at a glance mid-fight.
	_halo = MeshInstance3D.new()
	_halo.name = "OverloadHalo"
	var sphere := SphereMesh.new()
	sphere.radius = 0.34
	sphere.height = 0.68
	sphere.radial_segments = 12
	sphere.rings = 6
	_halo.mesh = sphere
	_halo_material = StandardMaterial3D.new()
	_halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_halo_material.albedo_color = Color(1.0, 0.35, 0.1, 0.4)
	_halo.material_override = _halo_material
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.position = _core.position
	_halo.visible = false
	add_child(_halo)
	set_mode(&"idle")


func set_mode(value: StringName) -> void:
	mode = value
	_t = 0.0
	visible = value != &"off"
	if _halo != null:
		_halo.visible = value == &"overload"
	_process(0.0)


func _process(delta: float) -> void:
	if _material == null:
		return
	_t += delta
	match mode:
		&"idle":
			_paint(BeeAlienPalette.CYAN, 0.9 + 0.3 * sin(_t * 3.0), 1.0)
		&"sting":
			_paint(BeeAlienPalette.CYAN, 1.2 + 1.6 * minf(_t / 0.45, 1.0), 1.0 + 0.6 * minf(_t / 0.45, 1.0))
		&"overload":
			var rate := lerpf(6.0, 18.0, minf(_t / 0.9, 1.0)) # Flashing speeds up until the dash.
			var on := sin(_t * rate * TAU) > 0.0
			_paint(Color(1.0, 0.25, 0.08) if on else Color(1.0, 0.62, 0.1), BeeAlienPalette.MAX_EMISSION, 1.6 if on else 1.3)
			_halo.visible = true
			_halo.scale = Vector3.ONE * (1.25 if on else 0.95)
			_halo_material.albedo_color.a = 0.5 if on else 0.28
			_spark_left -= delta
			if _spark_left <= 0.0:
				_spark_left = 0.16
				BeeCombatVFX.spawn(self, global_position + Vector3(0.0, 0.1, 0.1), &"neutral_hit", Vector3.UP, 0.8)


func _paint(color: Color, energy: float, scale_factor: float) -> void:
	_material.albedo_color = color
	_material.emission = color
	_material.emission_energy_multiplier = minf(energy, BeeAlienPalette.MAX_EMISSION)
	_core.scale = Vector3.ONE * scale_factor
