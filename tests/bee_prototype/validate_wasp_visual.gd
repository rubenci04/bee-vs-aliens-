extends SceneTree
const POC := preload("res://scenes/bee_prototype/bee_combat_poc.tscn")

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

func run() -> void:
	create_timer(25.0).timeout.connect(func(): quit(1))
	var poc := POC.instantiate()
	root.add_child(poc)
	current_scene = poc
	await frames(3)
	var bee := poc.get_node("BeePlayer") as BeePlayer
	var wasp := poc.get_node("Enemies/WaspA") as WaspEnemy
	var visual := wasp.get_node("VisualRoot/WaspEnemyVisual") as Node3D
	check(not wasp.has_node("VisualRoot/Body"), "Duplicate proxy")
	check(visual.find_child("Stinger", true, false) != null, "GLB did not load")
	check(is_equal_approx(wasp.get_node("CollisionShape3D").shape.radius, 0.38), "Collider changed")
	check(is_equal_approx(wasp.get_node("Hurtbox3D/CollisionShape3D").shape.radius, 0.38), "Hurtbox changed")
	check(wasp.get_node("AttackHitbox/CollisionShape3D").shape.size == Vector3(0.75,0.65,0.55), "Hitbox changed")
	check(wasp.health.current_health == 30 and wasp.move_speed == 5.0 and wasp.attack_damage == 10, "Balance changed")
	check(is_equal_approx(wasp.windup_time,0.30) and is_equal_approx(wasp.recovery_time,0.60), "Timing changed")

	# Real progression activates the new visual and normal chase.
	bee.position = Vector3(-5.9,3,0)
	await frames(5)
	check(wasp.is_active() and visual.is_visible_in_tree(), "Progression did not show Wasp")
	var initial := wasp.position
	await frames(8)
	check(wasp.position != initial, "AI stopped")
	wasp.set_physics_process(false)
	bee.set_physics_process(false)
	var wing := visual.find_child("Wing_L",true,false) as Node3D
	check(wing != null and visual.find_child("Wing_R",true,false) != null, "Wings missing")
	var angle := wing.rotation
	var physical := wasp.position
	await frames(4)
	check(not wing.rotation.is_equal_approx(angle) and wasp.position == physical, "Wingbeat affected physics or stopped")
	for side in [-1.0,1.0]:
		bee.position = wasp.position + Vector3(side*2.0,0,0)
		wasp._update_facing()
		check(is_equal_approx(wasp.visual_root.rotation.y,-side*PI/2), "Facing failed")

	# Existing windup presentation survives replacing the mesh.
	wasp._begin_windup()
	check(wasp.telegraph.visible and not wasp.attack_hitbox.enabled, "Windup lost telegraph")
	wasp._begin_recovery()
	check(not wasp.telegraph.visible and wasp.visual_root.scale == Vector3.ONE, "Recovery visual not restored")

	# Real X projectile damages imported Wasp and flashes its meshes.
	bee.position = Vector3(-5.9,3,0)
	wasp.position = bee.position + Vector3(2,0,0)
	bee.facing_x = 1
	var flash := wasp.get_node("HitFlash3D") as HitFlash3D
	var count := flash.activation_count
	var shot_dmg := int(bee.weapon_profile()["damage"][0])
	var hp_before: int = wasp.health.current_health
	check(bee.fire() != null, "X refused")
	for i in 35:
		if wasp.health.current_health < hp_before: break
		await frames(1)
	check(wasp.health.current_health == hp_before - shot_dmg and flash.activation_count > count, "X/HitFlash failed")
	var meshes := visual.find_children("*","MeshInstance3D",true,false)
	check(not meshes.is_empty(), "Imported visual has no meshes")
	check(meshes[0].material_overlay != null, "Flash did not reach imported material")

	# Real melee overlap (LOTE 14: 30 damage kills the 20 HP wasp).
	wasp.position = bee.position + Vector3(0.75,0,0)
	count = flash.activation_count
	bee.set_physics_process(true) # Tanda E: the sting dash advances in Bee's own physics step
	check(bee.start_melee(), "Z refused")
	for i in 60:
		if wasp.health.current_health <= 0: break
		await frames(1)
	check(wasp.health.current_health <= 0, "Z kills the wasp (Tanda E: the killing blow no longer pulses the flash)")
	var stopped := wing.rotation
	await frames(4)
	check(wasp.is_defeated() and not visual.is_visible_in_tree(), "Death visual failed")
	check(wing.rotation == stopped and not wasp.telegraph.visible, "Death left feedback running")
	check(poc.stage == poc.Stage.PAUSE_B, "Encounter did not advance")

	# Actual R reload keeps the new asset on enemies.
	bee.health.invulnerable = false # Tanda E: the sting dash leaves Bee protected for a moment
	bee.health.take_damage(1000)
	await frames(2)
	var old_id := poc.get_instance_id()
	Input.action_press("restart")
	await frames(2)
	Input.action_release("restart")
	await frames(6)
	check(current_scene.get_instance_id() != old_id, "Restart failed")
	wasp = current_scene.get_node("Enemies/WaspA")
	check(wasp.health.current_health == 30 and not wasp.is_active(), "Restart state failed")
	check(wasp.has_node("VisualRoot/WaspEnemyVisual/Model"), "Restart lost visual")
	print("WASP_VISUAL_OK GLB collider hurtbox balance facing wings telegraph X Z HitFlash death progression restart")
	var done := current_scene
	current_scene = null
	done.queue_free()
	await process_frame
	quit(0)
