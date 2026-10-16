extends SceneTree
const SETTINGS := preload("res://scripts/game/bee_readability_settings.gd")
var stage: BeeShmupStage

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func run() -> void:
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	var live := stage.get_node("LiveReadability")
	check(live.enabled, "Editor/debug binary activates dev-only controls")
	check(live.bee_index == 2 and live.outline_level == 1 and live.background_level == 1 and live.neon_level == 1, "Final defaults")
	var hud := stage.get_node("CanvasLayer/WeaponsHUD")
	check(not hud.debug_visible and not live.panel.visible, "Debug starts hidden")
	var blocked_key := InputEventKey.new()
	blocked_key.keycode = KEY_J
	blocked_key.pressed = true
	live._unhandled_key_input(blocked_key)
	check(live.neon_level == 1, "Comparator ignored without F3")
	hud.debug_visible = true
	var visual := stage.bee.get_node("VisualRoot/BeeVisual")
	live.set_modes(0, 0, 0, 0)
	var origin: Vector3 = visual.firing_origin(stage.bee.global_position)
	var collider := stage.bee.get_node("CollisionShape3D") as CollisionShape3D
	var original_scale := collider.global_transform
	var shape := collider.shape
	var model := visual.get("model") as Node3D
	var model_scale := model.scale
	for i in 3:
		live.set_modes(i, i, i, i)
		check(model.scale.is_equal_approx(model_scale * SETTINGS.BEE_SCALES[i]), "Bee visual scale cycles without accumulation")
		check(visual.firing_origin(stage.bee.global_position).is_equal_approx(origin), "Visual scale never changes gameplay muzzle/aim origin")
		check(collider.global_transform == original_scale and collider.shape == shape, "Player collider/hurtbox geometry untouched")
	check(live.background_materials.size() > 0, "Only distant scenery has opt-in copies")
	for record in live.background_materials:
		check(record["own"] != record["source"], "Far material isolated from actor/shared materials")
		check(record["mesh"].get_ref().get_active_material(record["surface"]) == record["own"], "Far palette modifies the material actually rendered")
		check(is_equal_approx(record["own"].get_shader_parameter("dev_saturation"), 0.65), "Background clamps to final level 1; gray level 2 removed")
	var shot := preload("res://scenes/projectiles/toon/alien_bolt.tscn").instantiate() as AlienEnemyProjectile
	shot.set_meta("shot_style", &"stinger")
	shot.damage = 5
	shot.speed = 13
	stage.add_child(shot)
	shot.set_physics_process(false)
	await process_frame
	var body := shot.get_node("StyledShot") as Node3D
	var radius: float = shot.hitbox.get_node("CollisionShape3D").shape.radius
	live.set_modes(0, 0, 0, 0)
	var normal_scale := body.scale
	var needle := body.get_node("Body/Needle") as MeshInstance3D
	var normal_faces := needle.mesh.get_faces()
	var normal_color: Color = needle.get_active_material(0).albedo_color
	live.set_modes(2, 2, 2, 2)
	check(body.scale.is_equal_approx(normal_scale * 1.3), "Neon 2 scales visual root only by +30%")
	check(shot.hitbox.get_node("CollisionShape3D").shape.radius == radius and shot.damage == 5 and shot.speed == 13, "Enemy collision/damage/speed unchanged")
	check(needle.mesh.get_faces() == normal_faces and needle.get_active_material(0).albedo_color == normal_color, "Enemy shot shape and color are unchanged")
	check(needle.get_active_material(0).emission_energy_multiplier > 1.0, "Neon raises actual material emission above 1")
	live.set_modes(0, 0, 0, 0)
	check(body.scale == normal_scale, "Neon off restores original visual scale")
	check(needle.get_active_material(0).emission_enabled == false, "Neon off restores original material emission")
	var cyan := preload("res://scenes/projectiles/toon/alien_bolt.tscn").instantiate() as AlienEnemyProjectile
	cyan.set_meta("shot_style", &"pellet")
	stage.add_child(cyan)
	cyan.set_physics_process(false)
	await process_frame
	live.set_modes(1, 1, 1, 1)
	var solid := cyan.get_node("StyledShot/Body").get_child(0) as MeshInstance3D
	check(solid.material_override.emission_energy_multiplier > 1.0, "Neon also modifies the real material_override used by selected B shots")
	cyan.queue_free()
	live.set_modes(0, 0, 0, 0)
	for key in SETTINGS.KEYS:
		for action in InputMap.get_actions():
			if str(action).begins_with("ui_"):
				continue # Engine editor/FileDialog defaults are not gameplay bindings.
			for event in InputMap.action_get_events(action):
				if event is InputEventKey:
					check(event.keycode != key and event.physical_keycode != key, "Comparator keys do not clash with mapped gameplay actions")
	var event := InputEventKey.new()
	event.keycode = SETTINGS.KEYS[0]
	event.pressed = true
	live._unhandled_key_input(event)
	check(live.bee_index == 1 and "×1.25" in live.panel.text, "Live key updates state and debug text")
	shot.queue_free()
	await process_frame
	print("LIVE_READABILITY_OK defaults/keys, actor scale/muzzle/collider invariance, isolated far palette, original shot color/mesh/hitbox/damage/speed, neon energy/size restoration")
	quit(0)
