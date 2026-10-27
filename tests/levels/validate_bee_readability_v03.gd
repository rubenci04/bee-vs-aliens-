extends SceneTree

# NOCHE 01 · ETAPA 3 — READABILITY.
#   corridor  no decoration rises into the flight band closer than BeeLevel01Readability.CORRIDOR_Z (Codex + domestic props)
#   contrast  at the violet sunset the actors' outline stays near-black while props keep the tinted outline; implants glow more
#   cyan      cyan surfaces only on alien technology (enemies, implants, pylons/relays, the contaminated device, alien shots/VFX)
# With a rendering window it saves res://dev/visual_target/noche3_*.png.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/visual_target/"
## Path fragments that mark alien technology (cyan allowed).
const ALIEN_MARKS := ["Alien", "Enemies", "Implant", "AlienControlDevice", "AlienPylon", "SignalRelay", "Contaminated", "ControlDevice", "Ufo", "CombatVFX", "AlienEscalation", "Relay", "Pylon"]

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var report: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "noche3_" + label + ".png"))

func goto(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(distance - 2.5, 3.2, 0)

static func cyan_of(material: Material) -> bool:
	if material is ShaderMaterial:
		var shader := material as ShaderMaterial
		var albedo: Variant = shader.get_shader_parameter("albedo")
		var emission: Variant = shader.get_shader_parameter("emission")
		var energy: Variant = shader.get_shader_parameter("emission_energy")
		if albedo is Color and BeeToonStyle.is_cyan(albedo) and (albedo as Color).v > 0.45:
			return true
		if emission is Color and energy != null and float(energy) > 0.05 and BeeToonStyle.is_cyan(emission):
			return true
	elif material is BaseMaterial3D:
		var base := material as BaseMaterial3D
		if BeeToonStyle.is_cyan(base.albedo_color) and base.albedo_color.v > 0.45:
			return true
		if base.emission_enabled and BeeToonStyle.is_cyan(base.emission):
			return true
	return false

func cyan_offenders() -> Array[String]:
	var list: Array[String] = []
	for mesh: MeshInstance3D in stage.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		var path := str(mesh.get_path())
		var alien := false
		for mark in ALIEN_MARKS:
			alien = alien or path.contains(mark)
		if alien or path.contains("BeePlayer"): # Bee carries its own alien implant (the story's premise).
			continue
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material != null and cyan_of(material):
				list.append(path.replace(str(stage.get_path()), ""))
				break
	return list

func run() -> void:
	BeeLevel01Controller.instant_arrival = true # Tanda E
	create_timer(300.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_children().filter(func(n): return n.name != "SceneFade").back() # Tanda E: the scene-fade cover is added after the level
	await frames(6)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	var readability := stage.get_node("Readability") as BeeLevel01Readability
	# --- corridor ---
	var intruders := readability.intruders()
	var names: Array[String] = []
	for node in intruders:
		names.append(str(node.name))
	check(intruders.is_empty(), "Decoration still invades the central corridor: " + ", ".join(names))
	check(BeeLevel01VisualTarget.CORRIDOR_CLEAR_Z <= readability.CORRIDOR_Z + 0.01, "Tall procedural grass must also stay behind the corridor")
	report.append("corridor: %d props moved back behind z=%.1f, 0 intruders" % [readability.moved.size(), readability.CORRIDOR_Z])
	for x in [100.0, 176.0, 300.0]:
		goto(x)
		await frames(4)
		await capture("x%d" % int(x))
	# --- contrast ---
	goto(320.0)
	await frames(4)
	var actor := BeeToonStyle.shared_outline(BeeToonStyle.OUTLINE_ACTOR).get_shader_parameter("outline_color") as Color
	var prop := BeeToonStyle.shared_outline(BeeToonStyle.OUTLINE_PROP).get_shader_parameter("outline_color") as Color
	check(actor.get_luminance() < 0.08 and prop.get_luminance() > actor.get_luminance(), "At sunset actor outlines must stay darker than prop outlines (%s vs %s)" % [actor, prop])
	wave._spawn({"family": "Mosquito", "slot": 0, "event": 0, "hard": false, "y": 4.0})
	var mosquito := wave.active_units.back() as AssetFauna
	var glow_found := false
	for mesh: MeshInstance3D in mosquito.visual.find_child("AlienControlDevice", true, false).find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as ShaderMaterial
			if material != null and material.get_shader_parameter("emission_energy") != null and is_equal_approx(float(material.get_shader_parameter("emission_energy")), AssetFauna.IMPLANT_GLOW):
				glow_found = true
	check(glow_found, "Implant glow must be raised to IMPLANT_GLOW")
	await capture("sunset_actor")
	mosquito.queue_free()
	wave.active_units.clear()
	report.append("contrast: actor outline lum %.3f vs prop %.3f at sunset; implant glow %.1f" % [actor.get_luminance(), prop.get_luminance(), AssetFauna.IMPLANT_GLOW])
	# --- cyan only for alien technology ---
	var offenders: Array[String] = []
	for x in [20.0, 100.0, 190.0, 281.0, 330.0]:
		goto(x)
		await frames(3)
		for path in cyan_offenders():
			if not path in offenders:
				offenders.append(path)
	check(offenders.is_empty(), "Cyan outside alien technology: " + ", ".join(offenders))
	report.append("cyan audit: 0 non-alien cyan surfaces")
	for line in report:
		print("READABILITY ", line)
	print("BEE_READABILITY_V03_OK")
	quit(0)
