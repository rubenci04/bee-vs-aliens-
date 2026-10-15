extends SceneTree
const STYLE := preload("res://scripts/vfx/bee_warning_style.gd")
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)
func run() -> void:
	var parent := Node3D.new()
	root.add_child(parent)
	STYLE.enabled = false
	var old := BeeAttackVisuals.line(parent, Vector3.ZERO, Vector3(12, 0, 0), 1.44, Color(1, 0.3, 0.2, 0.22))
	var geometry := old.mesh.get_faces()
	var transform := old.transform
	STYLE.enabled = true
	STYLE.dress(old, Color(1, 0.3, 0.2), 0.0, 0.8)
	check(old.mesh.get_faces() == geometry and old.transform == transform, "Warning style changes no geometry/position or damage area")
	check(old.material_override.get_shader_parameter("opacity") == 0.25, "Band starts translucent")
	await create_timer(0.35).timeout
	check(old.material_override.get_shader_parameter("opacity") == 0.25, "Band stays faint before final 0.3 seconds")
	await create_timer(0.20).timeout
	check(old.material_override.get_shader_parameter("opacity") == 0.6, "Band brightens only during final 0.3 seconds")
	var ray := BeeAttackVisuals.line(parent, Vector3.ZERO, Vector3(16, 0, 0), 0.05, BeeGameSettings.HOSTILE_CYAN)
	STYLE.dress(ray, BeeGameSettings.HOSTILE_CYAN, 1.0, 0.85)
	check(ray.material_override.get_shader_parameter("mode") == 1.0, "Robot warning uses shader dots")
	BeeAttackVisuals.restore_active_line(ray, Color(0.9,0.9,0.8), 0.04)
	check(ray.material_override == null, "Silk becoming active restores its original material")
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	var robot := preload("res://scenes/levels/walker_miniboss.tscn").instantiate() as WalkerMiniboss
	stage.add_child(robot)
	robot.activate(stage.bee)
	robot.set_physics_process(false)
	robot._begin_laser()
	check(robot._left == WalkerMiniboss.LASER_WARNING and robot._beam_box.damage == WalkerMiniboss.LASER_DAMAGE, "Robot warning timer and beam damage unchanged")
	check(robot._beam_box.get_child(0).shape.size == Vector3(16,0.3,1.2), "Robot beam damage volume unchanged")
	check(robot._beam.material_override.get_shader_parameter("core_fraction") == 0.25, "Active cyan beam has a fine 25-percent core")
	robot._mark_mortars()
	check(robot.mortar_xs.size() == WalkerMiniboss.MORTAR_COUNT, "Same three mortar lanes")
	for node in robot._warnings:
		if node is MeshInstance3D and node.mesh is BoxMesh:
			check(node.material_override is ShaderMaterial, "Mortar and laser warnings use visual-only shader")
	var wave := BeeGroundShockwave.launch(stage, robot, 0,10,5,7.5,1.3)
	check(wave.hitbox.damage == 5 and wave.speed == 7.5 and wave.hitbox.get_child(0).shape.size == Vector3(0.9,1.3,1.2), "Dome opacity changes no active wave damage/speed/volume")
	check(wave._visual.material_override == null, "Existing active ground wave appearance stays intact; it is not a warning")
	var dome := BeeAttackVisuals.warning_dome(stage, Vector3.ZERO, 1.5)
	check(dome.material_override.get_shader_parameter("mode") == 5.0 and dome.find_children("*", "Area3D", true, false).is_empty(), "Warning dome is translucent/dotted and has no damage area")
	print("T3H_OK bands alpha/final timing, dotted ray, active restore, real robot timers/damage/volume/mortars, dome physics invariant")
	quit()
