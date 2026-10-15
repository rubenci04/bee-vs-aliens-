extends SceneTree
const CUE := preload("res://scripts/vfx/bee_common_attack_cue.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 3: await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 110
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(107, 4, 0)
	# T6c validates FlyCloud's individual opaque instanced cues, not the retired whole-body tween.
	for family in ["Ant", "FlyCommon", "FlyGreen", "Ladybird", "StagBeetle", "Snail", "WormB", "MushroomCannon", "WormA"]:
		stage.wave._spawn({"family":family, "slot":0, "event":0, "hard":false})
		var enemy := stage.wave.active_units.back() as AssetFauna
		enemy.global_position = Vector3(113, 0 if enemy.is_ground() else 4, 0)
		enemy.set_physics_process(false)
		var collider := enemy.attack_hitbox.get_node("CollisionShape3D") as CollisionShape3D
		var radius: float = collider.shape.radius
		var damage := enemy.attack_hitbox.damage
		var scale := enemy.visual.scale
		var hurt_transform := enemy.hurtbox.global_transform
		if family in ["WormA", "WormB"]:
			check(enemy._ground_worm != null and enemy._warn.is_empty(), "T4d worms have no trajectory or ground warnings")
			if enemy._worm != null:
				check(enemy._worm.lasers == 0 and not enemy._worm._beam_box.enabled, "T4d replaced the active worm laser")

		else:
			enemy._start_telegraph()
			check(is_equal_approx(enemy._left, maxf(float(enemy.config.telegraph), AssetFauna.MIN_TELEGRAPH)), "Attack warning clock unchanged: " + family)
			for warning in enemy._warn:
				check(warning.layers == 0, "No common trajectory/charge mark: " + family)
		CUE.begin(enemy, StringName(family), enemy.visual)
		var animation: Dictionary = enemy.visual.get_meta("t3j_cue")
		animation.tween.custom_step(CUE.SECONDS / 2)
		check(enemy.visual.scale.x <= scale.x * 1.121 and enemy.visual.scale.x > scale.x, "Small readable anticipation: " + family)
		check(is_equal_approx(collider.shape.radius, radius) and enemy.attack_hitbox.damage == damage and collider.scale == Vector3.ONE, "Damage/impact unchanged: " + family)
		check(enemy.hurtbox.global_transform.is_equal_approx(hurt_transform) or family == "WormA", "Cue leaves the sibling hurtbox transform unchanged: " + family)
		check(not animation.meshes.is_empty(), "Cue reuses existing materials: " + family)
		animation.tween.custom_step(CUE.SECONDS)
		check(enemy.visual.scale.is_equal_approx(scale), "Pose restores: " + family)
		for entry in animation.meshes:
			var current = entry.mesh.material_override if entry.surface < 0 else entry.mesh.get_surface_override_material(entry.surface)
			check(current == entry.original, "Pulse material restores")
		CUE.begin(enemy, StringName(family), enemy.visual)
		CUE.cancel(enemy.visual)
		check(not enemy.visual.has_meta("t3j_cue"), "Liberation can cancel a pulse before warming the body")
		enemy.queue_free()
		for i in 2: await process_frame
		stage.wave.active_units.clear()
	var robot := preload("res://scenes/levels/walker_miniboss.tscn").instantiate() as WalkerMiniboss
	stage.add_child(robot)
	robot.activate(stage.bee)
	robot._begin_laser()
	for warning in robot._warnings: check(warning.layers != 0, "Robot marks retained")
	var add := TarantulaDropSpider.new()
	stage.add_child(add)
	add.setup(stage,113,3,6)
	add.set_physics_process(false)
	check(add._model.visible and add._thread.layers == 0 and not add._hitbox.enabled, "Spider add has a visible warning pose, no early damage")
	add._clock = TarantulaDropSpider.TELEGRAPH + .01
	add._physics_process(0)
	check(add._drop_started and add._thread.layers != 0 and add._hitbox.enabled, "Visible pose cannot skip the unchanged drop attack")
	stage.wave._spawn({"family":"Swarm","slot":0,"event":0,"hard":false})
	var swarm := stage.wave.swarm_units.back() as PopcornDrone
	swarm._kz_vel = Vector2(-8,0)
	swarm._show_kamikaze_line()
	check(swarm._kz_line.layers == 0, "Legacy kamikaze drones have no warning lines")
	print("T3J_OK failures=", failures)
	quit(1 if failures else 0)
