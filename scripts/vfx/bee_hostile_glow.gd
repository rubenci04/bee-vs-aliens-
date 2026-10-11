class_name BeeHostileGlow
extends RefCounted
## LOTE 9 · ETAPA B — cyan means HOSTILE again: every Level 01 enemy must show a cyan glow that still reads at dusk
## (implant, core, emitter...). `ensure` measures the strongest cyan glow of a unit and, below MIN_GLOW, adds a small
## pulsing cyan core where its hurtbox is (EyeDrone: its textured model had none). Nothing changes on units that already
## glow; presentation only.

const MIN_GLOW := 0.9 # Emission energy x value (or unshaded cyan value) that still reads at dusk.
const CORE_RADIUS := 0.12
const HALO_RADIUS := 0.26
const COLOR := Color(0.25, 1.0, 1.0)
const NODE_NAME := "HostileGlow"

static var _core_mesh: SphereMesh
static var _halo_mesh: SphereMesh


## Strength of a cyan glow on one material (0 = none).
static func glow_of(material: Material) -> float:
	if material is ShaderMaterial:
		var shader := material as ShaderMaterial
		var emission: Variant = shader.get_shader_parameter("emission")
		var energy: Variant = shader.get_shader_parameter("emission_energy")
		if emission is Color and energy != null and BeeToonStyle.is_cyan(emission):
			return float(energy) * (emission as Color).v
		var albedo: Variant = shader.get_shader_parameter("albedo")
		if albedo is Color and BeeToonStyle.is_cyan(albedo) and energy != null and float(energy) > 0.0:
			return float(energy) * (albedo as Color).v
	elif material is BaseMaterial3D:
		var base := material as BaseMaterial3D
		if base.emission_enabled and BeeToonStyle.is_cyan(base.emission):
			return base.emission_energy_multiplier * base.emission.v
		if base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and BeeToonStyle.is_cyan(base.albedo_color) and base.albedo_color.a > 0.6:
			return base.albedo_color.v
	return 0.0


## Strongest cyan glow among the visible meshes of `unit` (telegraph shapes excluded: they are not always there).
static func strongest(unit: Node3D) -> float:
	var best := 0.0
	for mesh: MeshInstance3D in unit.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.visible or str(mesh.name).contains("Telegraph"):
			continue
		var shown := true
		var node: Node = mesh
		while node != null and node != unit:
			if node is Node3D and not (node as Node3D).visible and node != unit:
				shown = false
				break
			node = node.get_parent()
		if not shown:
			continue
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material != null:
				best = maxf(best, glow_of(material))
	return best


## Adds the cyan core when the unit has no readable cyan glow. Returns true when one was added.
static func ensure(unit: Node3D) -> bool:
	if unit == null or unit.has_node(NODE_NAME) or strongest(unit) >= MIN_GLOW:
		return false
	if _core_mesh == null:
		_core_mesh = _sphere(CORE_RADIUS, Color(COLOR, 1.0), false)
		_halo_mesh = _sphere(HALO_RADIUS, Color(COLOR, 0.35), true)
	var glow := Node3D.new()
	glow.name = NODE_NAME
	var anchor := unit.get_node_or_null("Hurtbox3D") as Node3D
	glow.position = (anchor.position if anchor != null else Vector3.ZERO) + Vector3(0.0, 0.0, 0.32) # Towards the camera.
	for spec in [["Core", _core_mesh], ["Halo", _halo_mesh]]:
		var mesh := MeshInstance3D.new()
		mesh.name = str(spec[0])
		mesh.mesh = spec[1]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		glow.add_child(mesh)
	unit.add_child(glow)
	var pulse := glow.create_tween().set_loops()
	pulse.tween_property(glow, "scale", Vector3.ONE * 1.18, 0.45).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_SINE)
	return true


static func _sphere(radius: float, color: Color, transparent: bool) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color, 1.0)
	material.emission_energy_multiplier = 1.4
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_FRONT
	mesh.material = material
	return mesh
