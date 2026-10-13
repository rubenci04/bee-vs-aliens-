extends SceneTree

# NOCHE 01 · ETAPA 2 — CLEANUP + CODEX ASSETS.
#   human     GIANT_HUMAN_ENABLED = false: the human is hidden and its event never stops the level
#   props     red bottle, matchbox, red/cream snack bag/wrapper gone; Codex bottle, tuna tin, banana peel, hose, fence,
#             distant house, pine cones, pines, hollow log, bellflowers in place (behind the flight plane, no collision)
#   toon      Bee and enemy shots, pickups and explosions use the Codex toon scenes (Level 01 only)
#   fighter   the alien interceptor warns >= 0.4 s, fires a fan of 3 and EXPLODES (technology, not freed)
#   title     main scene = title; Jugar / Dificultad / Salir; art collection only in debug; difficulty toggles
#   easy      EASY lowers enemy HP (and the UFO's) and the damage Bee takes
# With a rendering window it saves res://dev/visual_target/noche2_*.png.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/visual_target/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var report: Array[String] = []

func _initialize() -> void:
	BeeLevel01Controller.roster_only = false # LOTE 12: this test covers the pre-roster flow (alien enemies, frog, UFO), which stays intact behind LEVEL01_ROSTER_ONLY.
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
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "noche2_" + label + ".png"))

func load_level() -> void:
	if stage != null and is_instance_valid(stage):
		stage.queue_free()
		await frames(2)
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func arena(distance: float) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 3.0, 0)

func test_human() -> void:
	check(not BeeLevel01Controller.GIANT_HUMAN_ENABLED and not BeeLevel01Controller.giant_human_enabled, "The Giant Human must be switched off")
	check(not wave.human.visible, "Switched-off human must be hidden")
	var human_index := -1
	for i in BeeLevel01Controller.EVENTS_LEGACY.size():
		if bool(BeeLevel01Controller.EVENTS_LEGACY[i].get("human", false)):
			human_index = i
	wave.event_index = human_index
	wave._pending.clear()
	wave.active_units.clear()
	stage.distance = 140.5
	wave.set_physics_process(true)
	await frames(3)
	check(wave.event_index > human_index and not wave._waiting_for_human and stage.scroll_speed > 0.0, "The human event must be skipped without stopping the scroll")
	wave.set_physics_process(false)
	report.append("human off: event skipped, scroll %.1f m/s" % stage.scroll_speed)

func test_props() -> void:
	var bottle := stage.find_child("GiantBottle", true, false) as Node3D
	check(bottle == null or not bottle.visible, "The red bottle must be gone")
	for node in stage.find_children("wrapper_*", "Node3D", true, false):
		check(not (node as Node3D).visible, "The red/cream wrapper must be gone")
	for crate in stage.get_node("Destructibles").get_children():
		var kind := int(crate.get("item_kind"))
		check(kind != 1 and kind != 2, "Matchbox / snack bag still placed: " + str(crate.name))
		if kind >= 3:
			check(crate.get_node("VisualRoot").find_child("CodexItem", true, false) != null, "Codex litter missing in " + str(crate.name))
	var dressing := stage.get_node("AssetDressing") as BeeLevel01AssetDressing
	var wanted := ["glass_bottle", "open_tuna_tin", "banana_peel", "garden_hose", "garden_fence_module", "garden_distant_house", "pine_cone", "tall_pine", "umbrella_pine", "hollow_fallen_log", "garden_bellflower", "flowering_shrub", "garden_sapling"]
	var found := {}
	for item in dressing.litter:
		found[item.scene_file_path.get_file().get_basename()] = true
		check(item.global_position.z < -2.0, "Codex prop in the flight plane: " + str(item.name))
	for id in wanted:
		check(found.has(id), "Codex prop missing: " + id)
	check(dressing.find_children("*", "CollisionObject3D", true, false).is_empty(), "Scenery must not collide")
	arena(41.0)
	await frames(5)
	await capture("bottle")
	report.append("props: %d Codex props, red bottle/matchbox/wrapper gone" % dressing.litter.size())

func test_toon() -> void:
	check(bee.projectile_scene.resource_path.contains("bee_level_toon_bolt"), "Bee must fire the toon bolt")
	for item in stage.get_node("Pollen").get_children():
		check(item.scene_file_path.contains("items/toon/pollen"), "Pollen pickup not toon: " + str(item.name))
	for item in stage.get_node("Powerups").get_children():
		check(item.scene_file_path.contains("items/toon/"), "Powerup not toon: " + str(item.name))
	check(BeeCombatVFX.toon_bursts, "Level 01 explosions must be toon bursts")
	arena(160.0)
	wave._spawn({"family": "Probe", "slot": 0, "event": 0, "hard": false, "y": 4.4})
	var probe: Node3D = wave.active_units.back()
	check((probe.get("projectile_scene") as PackedScene).resource_path.contains("projectiles/toon/alien_bolt"), "Enemies must fire the toon alien bolt")
	var before := get_nodes_in_group("bee_combat_vfx").size()
	BeeCombatVFX.spawn(stage, Vector3(stage.distance, 3, 0), &"tech_death")
	await frames(1)
	var burst_found := false
	for node in get_nodes_in_group("bee_combat_vfx"):
		if node.get("kind") == &"tech_death" and node.has_signal("finished"):
			burst_found = true

	check(get_nodes_in_group("bee_combat_vfx").size() > before, "tech_death must spawn the toon burst")
	var shot := bee.fire()
	check(shot != null and shot.get_script().resource_path.contains("bee_level_toon_bolt"), "Toon bolt did not fire")
	await capture("toon_shots")
	for unit in wave.active_units:
		unit.queue_free()
	wave.active_units.clear()
	report.append("toon: bee/enemy bolts, %d pollen + %d powerups, toon bursts" % [stage.get_node("Pollen").get_child_count(), stage.get_node("Powerups").get_child_count()])

func test_fighter() -> void:
	arena(290.0)
	wave._spawn({"family": "AlienFighter", "slot": 0, "event": 0, "hard": false, "y": 5.0})
	var fighter := wave.active_units.back() as AssetFauna
	check(fighter != null and bool(fighter.config.get("machine", false)), "Alien fighter is technology")
	var seen := -1
	for i in 900:
		await physics_frame
		if not fighter.telegraphs.is_empty():
			seen = i
			break
	check(seen >= 0 and fighter.telegraphs[0] >= AssetFauna.MIN_TELEGRAPH - 0.03, "Fighter must warn >= 0.4 s")
	for i in 30:
		await physics_frame
	check(fighter.shots_fired == 3, "Fighter fires a fan of 3 (%d)" % fighter.shots_fired)
	await capture("fighter")
	var freed := wave.liberated_count
	fighter.health.take_damage(99999)
	await frames(3)
	check(not fighter.is_in_group("bee_liberated") and wave.liberated_count == freed, "The fighter explodes, it is never freed")
	report.append("fighter: telegraph %.2fs, fan of 3, explodes" % fighter.telegraphs[0])

func test_title() -> void:
	check(str(ProjectSettings.get_setting("application/run/main_scene")) == BeeGameSettings.TITLE_SCENE, "Main scene must be the title")
	var title := (load(BeeGameSettings.TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	for i in 6:
		await process_frame
	var texts := []
	for b: Button in title.find_children("*", "Button", true, false):
		texts.append(b.text)
	check("Jugar" in texts and "Salir" in texts and texts.any(func(t): return str(t).begins_with("Dificultad")), "Title menu: " + str(texts))
	var lake_shown := texts.any(func(t): return str(t).contains("Laguna"))
	check(lake_shown == title.call("debug_menu_enabled"), "Lake prototype only in debug mode")
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	title.call("_toggle_difficulty")
	check(BeeGameSettings.difficulty == BeeGameSettings.EASY and (title.get("difficulty_button") as Button).text.ends_with("FÁCIL"), "Difficulty toggle")
	title.queue_free()
	report.append("title: %s" % str(texts))

func test_easy() -> void:
	BeeGameSettings.difficulty = BeeGameSettings.EASY
	await load_level()
	check(is_equal_approx(bee.health.damage_scale, BeeGameSettings.EASY_DAMAGE_TAKEN), "EASY: Bee takes less damage")
	arena(120.0)
	wave._spawn({"family": "Probe", "slot": 0, "event": 0, "hard": false, "y": 4.4})
	var probe: Node3D = wave.active_units.back()
	var hp := (probe.get_node("HealthComponent") as HealthComponent).max_health
	check(hp == BeeGameSettings.scaled_hp(int(BeeLevel01Controller.LEVEL_HP["Probe"])) and hp < int(BeeLevel01Controller.LEVEL_HP["Probe"]), "EASY: Probe HP %d" % hp)
	bee.health.damage_blocked = false
	var before := bee.health.current_health
	bee.health.take_damage(10)
	check(before - bee.health.current_health == 6, "EASY: 10 damage must become 6")
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	report.append("easy: enemy HP x%.2f (Probe %d), damage taken x%.1f" % [BeeGameSettings.EASY_ENEMY_HP, hp, BeeGameSettings.EASY_DAMAGE_TAKEN])

func run() -> void:
	create_timer(400.0, true, false, true).timeout.connect(func(): quit(1))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	await load_level()
	await test_human()
	await test_props()
	await test_toon()
	await test_fighter()
	await test_title()
	await test_easy()
	for line in report:
		print("CLEANUP ", line)
	print("BEE_ASSETS_CLEANUP_V02_OK")
	quit(0)
