extends SceneTree

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const REVIEW := "res://dev/checkpoint_qol_review/"
var stage: BeeShmupStage
var bee: BeePlayer
var qol: BeeCheckpointQoL
var failed := false

func _initialize() -> void:
	BeeLevel01Controller.roster_only = false # LOTE 12: this test covers the pre-roster flow (alien enemies, frog, UFO), which stays intact behind LEVEL01_ROSTER_ONLY.
	BeeLevel01Controller.giant_human_enabled = true # NOCHE 01: the human is off in the game (GIANT_HUMAN_ENABLED); this test covers it.
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(REVIEW + name + ".png") == OK, "Capture failed")

func bind_stage() -> void:
	stage = current_scene as BeeShmupStage
	bee = stage.bee
	qol = stage.get_node("CheckpointQoL")

func sample_performance() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# Same quiet restored scene, with/without the QoL process; no gameplay changes.
	for enabled in [false, true]:
		qol.set_process(enabled)
		await frames(10)
		var previous := Time.get_ticks_usec()
		var total := 0.0
		var worst := 0.0
		for i in 180:
			await process_frame
			var now := Time.get_ticks_usec()
			var ms := (now - previous) / 1000.0
			previous = now
			total += ms
			worst = maxf(worst, ms)
		print("CHECKPOINT_PERF enabled=%s fps=%.2f worst_ms=%.3f nodes=%d" % [enabled, 180000.0 / total, worst, root.get_tree().get_node_count()])

func press(action: String) -> void:
	await process_frame
	Input.action_press(action)
	await frames(5)
	Input.action_release(action)
	bind_stage()

func progress_to(destination: float) -> void:
	Engine.time_scale = 6.0
	bee.set_physics_process(false)
	bee.health.damage_blocked = true # Fixture protection, not checkpoint behavior.
	stage.set_physics_process(true)
	stage.wave.set_physics_process(true)
	for i in 14000:
		bee.global_position = Vector3(stage.distance - 3.0, 7.0, 0)
		bee.health.damage_blocked = true # LOTE 14: the checkpoint protection ends mid-run and the popcorn now hits for real (ROUTE_DAMAGE_SCALE 1.0): keep the fixture protected.
		for unit in stage.wave.active_units.duplicate():
			unit.get_node("HealthComponent").take_damage(9999)
		if stage.wave.boss != null and stage.wave.boss.is_active(): # UFO BOSS 01 locks the arena at the end.
			stage.wave.boss.health.take_damage(9999)
		await process_frame
		if stage.distance >= destination or stage.sector_complete:
			break
	Engine.time_scale = 1.0
	bee.health.damage_blocked = false
	check(stage.distance >= destination, "Runtime progression did not reach destination")

func run() -> void:
	create_timer(180.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	bind_stage()
	check(not qol.checkpoint_active and InputMap.has_action("bee_pause") and InputMap.has_action("bee_full_restart"), "Initial state/inputs")
	check(str(stage.get_node("CanvasLayer/WeaponsHUD").call("control_text")).contains("BOMBA C"), "HUD controls missing")
	bee.health.take_damage(9999)
	check("R TO RESTART" in stage.status.text, "Before-checkpoint defeat UI")
	await capture("03_defeat_before")
	var old_id := stage.get_instance_id()
	await press("restart")
	check(stage.get_instance_id() != old_id and stage.distance < 1 and not qol.checkpoint_active and bee.health.current_health == 100, "R before checkpoint must start fresh")
	stage.get_node("Juice").set_physics_process(false) # LOTE 11: no item magnet in this fixture (it would collect extra pollen).
	stage.get_node("Juice").pollen_heal_enabled = false # LOTE 13: freed animals add pollen; the pollen bar would heal during the traversal.
	# Prepare real collected state before a real traversal of the timeline.
	stage.get_node("Pollen/PollenA").collect(bee)
	stage.get_node("Powerups/SpreadFirst").collect(bee)
	stage.get_node("Powerups/BombFirst").collect(bee)
	stage.get_node("Destructibles/GardenCrate").health.take_damage(9999)
	bee.spread_ammo = 5
	bee.bomb_charges = 0
	bee.weapon_state_changed.emit()
	bee.health.take_damage(53)
	await progress_to(189.0)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	bee.global_position = Vector3(189, 4, 0)
	stage.camera.set_stage_x(190)
	await capture("01_checkpoint_visual")
	await progress_to(190.05)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	await frames(3)
	check(qol.checkpoint_active and qol.activation_count == 1 and qol.notice.text == "CHECKPOINT" and not qol.notice.visible and stage.has_node("HUDNotices"), "Checkpoint trigger/message routed to upper banner")
	check(stage.wave.event_index == checkpoint_event() and stage.wave.human.crossings_exited == 1, "Checkpoint must follow real earlier encounters/human")
	check(qol.snapshot.hp == 60 and qol.snapshot.spread == 5 and qol.snapshot.bomb == 0 and qol.snapshot.pollen == 1, "Snapshot/heal/state incorrect")
	stage._physics_process(0.0) # Refresh HUD after the fixture stopped stage physics.
	await capture("02_checkpoint_message")
	qol.activate_checkpoint()
	check(qol.activation_count == 1, "Checkpoint duplicated")
	# Damage/consumption in the future segment must not alter the committed snapshot.
	stage.get_node("Pollen/PollenI").collect(bee)
	stage.get_node("Powerups/SpreadRecharge").collect(bee)
	stage.get_node("Powerups/BombRecharge").collect(bee)
	stage.get_node("Destructibles/OrganicCrate").health.take_damage(9999)
	bee.global_position = Vector3(295, 4, 0)
	stage.distance = 275 # LOTE 7: before the second checkpoint (281), so the defeat respawns at the first one.
	stage._update_camera_and_bounds()
	stage.wave.set_physics_process(true)
	await frames(60)
	check(stage.wave.event_index > checkpoint_event(), "Future runtime events did not begin")
	bee.fire()
	bee.use_bomb()
	BeeAudio.play(stage, &"human_warning")
	bee.health.take_damage(9999)
	check("R TO RESPAWN" in stage.status.text, "After-checkpoint defeat UI")
	await capture("04_defeat_after")
	old_id = stage.get_instance_id()
	await press("restart")
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	check(stage.get_instance_id() != old_id and absf(stage.distance - 190) < 0.5 and absf(stage.camera.global_position.x - 190) < 0.5, "Camera/progress restore")
	check(bee.global_position.is_equal_approx(Vector3(190, 5.4, 0)), "Safe spawn position")
	check(bee.health.current_health == 60 and bee.spread_ammo > 4.8 and bee.spread_ammo <= 5.0 and bee.bomb_charges == 0 and stage.pollen_count == 1, "Restore inventory/HP/pollen")
	check(stage.wave.event_index == checkpoint_event() and stage.wave.active_units.is_empty() and stage.wave._pending.is_empty(), "Old/future encounters not reset")
	check(stage.wave.human.current_phase == GiantHumanCrossingHazard.Phase.EXITED and not stage.wave._waiting_for_human, "Human repeated")
	check(bee.current_auto_target == null and not bee.target_indicator.visible, "Old target survived")
	check(get_nodes_in_group("bee_audio_voice").is_empty() and get_nodes_in_group("bee_combat_vfx").is_empty(), "Audio/VFX survived respawn")
	for node in stage.find_children("*", "Area3D", true, false):
		check(not node is BeeEnergyProjectile and not node is BeeAlienBomb, "Old projectile/Bomb survived")
	for item in stage.get_node("Pollen").get_children():
		check(item.position.x >= 190, "Old pollen respawned")
	for item in stage.get_node("Powerups").get_children():
		check(item.position.x >= 190, "Old powerup respawned")
	check(stage.has_node("Pollen/PollenI") and stage.has_node("Powerups/BombRecharge"), "Future pickups missing")
	var old_crate = stage.get_node("Destructibles/GardenCrate")
	var new_crate = stage.get_node("Destructibles/OrganicCrate")
	check(old_crate.is_destroyed and old_crate.collider.disabled and not new_crate.is_destroyed, "Destructibles restoration")
	check(new_crate.item_kind == 4 and new_crate.collider.disabled and new_crate.body.collision_layer == 0 and new_crate.hurtbox.collision_layer == 0, "Restored small peel must remain nonblocking decoration")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = bee.get_node("CollisionShape3D").shape
	query.transform = bee.global_transform
	query.collision_mask = 1
	query.exclude = [bee.get_rid()]
	check(bee.get_world_3d().direct_space_state.intersect_shape(query).is_empty(), "Respawn inside world collider")
	check(qol.protection_left > 0 and bee.health.take_damage(20) == 0, "Spawn protection failed")
	check(bee.fire() != null, "Protection blocked weapons")
	bee.set_physics_process(true)
	await press("move_right")
	check(bee.global_position.x > 190, "Protection blocked movement")
	while not bee.visual_root.visible and qol.protection_left > 0:
		await process_frame
	await capture("05_respawn_position")
	while bee.visual_root.visible and qol.protection_left > 0:
		await process_frame
	check(qol.protection_left > 0 and not bee.visual_root.visible, "Protection blink absent")
	await capture("06_protection_blink")
	await create_timer(1.4).timeout
	check(not bee.health.damage_blocked and bee.visual_root.visible and bee.health.take_damage(5) == 5, "Protection did not expire")
	await sample_performance()
	# Repeat future collection/death: no charge/pollen accumulation across retries.
	stage.get_node("Powerups/BombRecharge").collect(bee)
	stage.get_node("Pollen/PollenI").collect(bee)
	check(bee.bomb_charges == bee.bomb_pickup_charges and stage.pollen_count == 2, "Future pickups wrong: bomb=%d pollen=%d (LOTE 9: a bomb pickup gives 3)" % [bee.bomb_charges, stage.pollen_count])
	bee.health.take_damage(9999)
	await press("restart")
	check(bee.bomb_charges == 0 and stage.pollen_count == 1, "Bomb/pollen farming exploit")
	await press("bee_pause")
	check(paused and qol.pause_label.visible, "Esc did not pause")
	var before_pause := stage.distance
	await create_timer(0.25, true).timeout
	check(is_equal_approx(stage.distance, before_pause), "Paused progression advanced")
	await capture("07_pause_overlay")
	await press("bee_pause")
	check(not paused and not qol.pause_label.visible, "Esc did not resume")
	await progress_to(360)
	for i in 1500: # Includes the UFO boss (approach + fight + death) before completion.
		for unit in stage.wave.active_units.duplicate():
			unit.get_node("HealthComponent").take_damage(9999)
		if stage.wave.boss != null and stage.wave.boss.is_active():
			stage.wave.boss.health.take_damage(9999)
		await process_frame
		if stage.sector_complete:
			break
	check(stage.sector_complete and stage.status.text.begins_with("SECTOR DESPEJADO"), "Completion after checkpoint respawn failed")
	for entry in stage.wave.spawn_history:
		check(entry.event >= checkpoint_event(), "Earlier encounter regenerated")
	await capture("08_final_unaffected")
	await press("bee_full_restart")
	check(stage.distance < 1 and not qol.checkpoint_active and bee.health.current_health == 100 and bee.bomb_charges == 1 and stage.pollen_count == 0, "Shift+R did not reset entire session")
	check(stage.get_node("Pollen").get_child_count() == 17 and stage.get_node("Powerups").get_child_count() == 5 and not has_meta(BeeCheckpointQoL.HANDOFF), "Full restart world/handoff not cleared")
	if not failed:
		print("BEE_CHECKPOINT_QOL_V01_OK x=190 hp_min=60 saved_inventory pollen encounters human colliders cleanup invulnerability=1.25 pause real_R full_restart completion")
	quit(1 if failed else 0)

## First event after the checkpoint (X=190) in the current event table (EVENTS V2 changed the count).
func checkpoint_event() -> int:
	var index := 0
	for event: Dictionary in BeeLevel01Controller.EVENTS_LEGACY:
		if float(event["at"]) < 190.0:
			index += 1
	return index
