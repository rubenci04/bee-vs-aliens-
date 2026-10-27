extends SceneTree

# NOCHE 01 · ETAPA 4 — Level 02 "Laguna" PROTOTYPE.
#   scene     loads with Level 01's camera/controls/HUD/free aim/toon shots, water plane + lake props behind the flight plane
#   enemies   water strider (lunge on the surface), dragonfly nymph (slow spit), perch (warning on the water, then a leap) —
#             every attack warned >= 0.4 s; animals are freed (counted), never killed
#   boss      toad: tongue (line warning) and jump (landing ring) both >= 0.4 s; the landing sends a low shockwave; breaking
#             the implant FREES it and completes the level ("LIBERADOS n/N")
#   run       a bot plays it from start to end and measures its length (~90 s target)
#   access    only from the title's debug menu; Level 01 / the main scene are unchanged
# With a rendering window it saves res://dev/visual_target/noche4_*.png.

const LEVEL := preload("res://scenes/levels/bee_level_02_lake.tscn")
const OUT := "res://dev/visual_target/"

var stage: BeeShmupStage
var wave: BeeLevel02Controller
var bee: BeePlayer
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
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "noche4_" + label + ".png"))

func load_level() -> void:
	if stage != null and is_instance_valid(stage):
		stage.queue_free()
		await frames(2)
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_children().filter(func(n): return n.name != "SceneFade").back() # Tanda E: the scene-fade cover is added after the level
	await frames(5)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel02Controller
	bee = stage.bee

func arena(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 2.0, 0)

func spawn(family: String, y := 0.0) -> AssetFauna:
	wave._spawn({"family": family, "due": 0.0, "y": y, "slot": 0})
	return wave.active_units.back() as AssetFauna

func test_scene() -> void:
	var scenery := stage.get_node("LakeScenery") as BeeLevel02LakeScenery
	check(scenery.water != null and scenery.water.mesh.surface_get_material(0) is ShaderMaterial, "Water plane missing")
	for prop in scenery.props:
		check(prop.global_position.z <= -2.5, "Lake prop in the flight plane: " + str(prop.name))
	check(bee.projectile_scene.resource_path.contains("bee_level_toon_bolt"), "Level 02 uses the toon bolt")
	check(stage.get_node_or_null("CanvasLayer/Crosshair") != null and stage.get_node_or_null("CanvasLayer/WeaponsHUD") != null, "Crosshair + HUD")
	await capture("start")
	report.append("scene: water + %d lake props behind the plane" % scenery.props.size())

func test_family(family: String, y: float) -> AssetFauna:
	arena(40.0)
	var unit := spawn(family, y)
	var seen := -1
	for i in 900:
		await physics_frame
		bee.global_position.y = 2.0 + 0.8 * sin(float(i) * 0.03)
		if not unit.telegraphs.is_empty():
			seen = i
			break
	check(seen >= 0, "%s never attacked" % family)
	check(unit.telegraphs[0] >= AssetFauna.MIN_TELEGRAPH - 0.03, "%s warned %.2f s < 0.4" % [family, unit.telegraphs[0]])
	report.append("%s telegraph %.2fs" % [family, unit.telegraphs[0]])
	return unit

func test_enemies() -> void:
	var strider := await test_family("Strider", 0.0)
	check(absf(strider.global_position.y + 0.2) < 0.1, "The strider skims the water surface")
	await capture("strider")
	await clear_units()
	var nymph := await test_family("Nymph", 0.0)
	await frames(10)
	check(nymph.shots_fired >= 1, "The nymph spits")
	await clear_units()
	var perch := await test_family("Perch", 0.0)
	var top := -10.0
	for i in 70:
		await physics_frame
		top = maxf(top, perch.global_position.y)
	check(top > 2.0, "The perch must leap out of the water (top %.1f m)" % top)
	await capture("perch")
	var before := wave.liberated_count
	perch.health.take_damage(9999)
	await frames(3)
	check(wave.liberated_count == before + 1 and perch.is_in_group("bee_liberated"), "The perch is freed, not killed")
	await clear_units()

func clear_units() -> void:
	for unit in wave.active_units:
		if is_instance_valid(unit):
			unit.queue_free()
	wave.active_units.clear()
	for node in get_nodes_in_group("alien_projectiles"):
		node.queue_free()
	BeeAttackTokens.reset()
	await frames(2)

func test_boss() -> void:
	arena(112.0)
	wave._start_boss()
	var toad := wave.boss
	for i in 900:
		await physics_frame
		bee.global_position.y = 2.0 + 1.5 * sin(float(i) * 0.02)
		if toad.tongues >= 1 and toad.jumps >= 1 and toad.waves >= 1:
			break
		if toad.state == BeeLakeToadBoss.State.TONGUE and toad.tongues == 1 and i % 30 == 0:
			await capture("toad_tongue")
	check(toad.tongues >= 1 and toad.jumps >= 1 and toad.waves >= 1, "Toad must use tongue, jump and shockwave (%d/%d/%d)" % [toad.tongues, toad.jumps, toad.waves])
	for t in toad.telegraphs:
		check(t >= 0.4 - 0.03, "Toad warning %.2f s < 0.4" % t)
	report.append("toad: tongue %.2fs, jump %.2fs warnings, shockwave" % [BeeLakeToadBoss.TONGUE_TELEGRAPH, BeeLakeToadBoss.JUMP_TELEGRAPH])
	wave.set_physics_process(true)
	stage.set_physics_process(true)
	toad.health.take_damage(99999)
	for i in 600:
		await physics_frame
		if stage.sector_complete:
			break
	check(toad.liberated and toad.is_in_group("bee_liberated"), "The toad is freed")
	check(stage.sector_complete and stage.status.text.begins_with("LAGUNA DESPEJADA · LIBERADOS"), "Level 02 must complete after the toad: " + stage.status.text)
	await capture("complete")

func test_run() -> void:
	await load_level()
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	Engine.time_scale = 4.0
	var tick := 4.0 / float(Engine.physics_ticks_per_second)
	var fire_left := 0.0
	var boss_at := -1.0
	for frame in 60 * 300:
		await physics_frame
		if frame % 900 == 0 and OS.get_cmdline_user_args().has("trace"):
			print("TRACE t=%.0f d=%.1f ev=%d units=%d pending=%d boss=%s hp=%s scroll=%.1f" % [stage.elapsed_seconds, stage.distance, wave.event_index, wave.active_units.size(), wave.pending.size(), str(wave.boss.state) if wave.boss != null else "-", str(wave.boss.health.current_health) if wave.boss != null else "-", stage.scroll_speed])
		if wave.boss != null and boss_at < 0.0:
			boss_at = stage.elapsed_seconds
		if stage.sector_complete:
			break
		var goal_y := 3.0
		var best := INF
		var aim: Variant = null
		for node in get_nodes_in_group("bee_auto_aim_targets"):
			var t := node as Node3D
			if t == null or not t.is_visible_in_tree() or not BeeShmupFairness.is_on_screen(t, -0.4):
				continue
			if t.has_method("is_active") and not bool(t.call("is_active")):
				continue
			var hurt := t.get_node_or_null("Hurtbox3D") as Node3D
			var p := hurt.global_position if hurt != null else t.global_position
			var d := p.distance_to(bee.global_position)
			if d < best:
				best = d
				aim = p
				goal_y = clampf(p.y + 1.2, 1.2, 6.0)
		var pos := bee.global_position
		pos.x = move_toward(pos.x, stage.camera.global_position.x - 3.0, 5.0 * tick)
		pos.y = move_toward(pos.y, goal_y, 5.0 * tick)
		bee.global_position = pos
		if aim != null:
			bee.set_aim_point(aim)
		fire_left -= tick
		if fire_left <= 0.0:
			fire_left = 1.0 / 3.0
			bee.fire()
	Engine.time_scale = 1.0
	check(stage.sector_complete, "The bot could not finish the lake prototype")
	var total: float = stage.elapsed_seconds
	check(total >= 60.0 and total <= 150.0, "Lake prototype length %.0f s outside 60-150 s" % total)
	report.append("run: toad at %.0fs, complete at %.0fs (%s)" % [boss_at, total, wave.liberation_text()])

func test_access() -> void:
	check(str(ProjectSettings.get_setting("application/run/main_scene")) == BeeGameSettings.TITLE_SCENE, "Main scene unchanged (title)")
	var title := (load(BeeGameSettings.TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	for i in 6:
		await process_frame
	var texts := []
	for b: Button in title.find_children("*", "Button", true, false):
		texts.append(b.text)
	var shown := texts.any(func(t): return str(t).contains("Laguna"))
	check(shown == title.call("debug_menu_enabled"), "The lake prototype is only in the debug menu: " + str(texts))
	title.queue_free()

func run() -> void:
	create_timer(500.0, true, false, true).timeout.connect(func(): quit(1))
	await load_level()
	await test_scene()
	await test_enemies()
	await test_boss()
	await test_run()
	await test_access()
	for line in report:
		print("LAKE ", line)
	print("BEE_LEVEL02_LAKE_PROTO_OK")
	quit(0)
