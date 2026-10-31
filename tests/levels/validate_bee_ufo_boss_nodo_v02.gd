extends SceneTree

# UFO BOSS 01 (batch 4) — NODO ALIEN: warning + supplies, scale, HP 500, Spread / Bomb damage, phase 2 drones,
# phase 3 tractor beam (mark 1 s before, 15 damage once per exposure, dodgeable), SECTOR DESPEJADO only after the
# explosion, no damage after the win, boss checkpoint (respawn at the start of the fight, HP >= 60) and F9 debug.
# With a rendering window it also saves captures in res://dev/visual_target/.

## LOTE 9 · ETAPA C: the NODO ALIEN has 1200 HP and 4 phases (was 500 HP, 3 phases).
const BOSS_HP := 1200
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/visual_target/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var boss: UfoBoss01

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
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + label + ".png"))

func bind() -> void:
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func load_level() -> void:
	var level := LEVEL.instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	bind()

func reload(action: Callable) -> void:
	action.call()
	for i in 10:
		await process_frame
	await frames(3)
	bind()

func to_boss_entry(distance := 352.0) -> void:
	wave.event_index = BeeLevel01Controller.EVENTS_LEGACY.size()
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.distance - 3.2, 3.4, 0)

func wait_phase(wanted: int, limit := 900) -> bool:
	for i in limit:
		await frames(1)
		if wave.boss != null and is_instance_valid(wave.boss) and wave.boss.state == wanted:
			return true
	return false

func wait_beam_telegraph(limit := 3000) -> bool:
	for i in limit:
		await frames(1)
		bee.health.current_health = bee.health.max_health
		if boss._attack_step == &"beam_tele":
			return true
	return false

func run() -> void:
	create_timer(280.0, true, false, true).timeout.connect(func(): quit(1))
	await load_level()
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.spread_ammo = 10
	bee.bomb_charges = 1 # Tanda T: Bee arranca con bombas llenas; la bomba del jefe solo aparece con pocas cargas.

	# 1. Warning + supplies before the boss; name and HP.
	to_boss_entry()
	await frames(20)
	check(wave.player_label == "SEÑAL DESCONOCIDA", "Missing SEÑAL DESCONOCIDA warning (%s)" % wave.player_label)
	check(stage.get_node_or_null("BossBomb") != null, "No bomb pickup before the boss")
	for pollen_item in stage.get_node("Pollen").get_children():
		check(pollen_item.position.x < 340.0, "No pollen before the arena") # Tanda E: loose pollen was thinned (PollenM no longer exists)
	check(UfoBoss01.DISPLAY_NAME == "NODO ALIEN", "Boss name wrong")
	for i in 400:
		await frames(1)
		if wave.boss != null:
			break
	boss = wave.boss
	check(boss != null and boss.max_hp == BOSS_HP, "Boss did not appear with %d HP" % BOSS_HP)
	check(stage.checkpoint.checkpoint_active and stage.checkpoint.boss_checkpoint_count == 1, "No boss checkpoint")
	await wait_phase(UfoBoss01.State.PHASE_1)
	check(boss.state == UfoBoss01.State.PHASE_1 and boss.health_bar_visible(), "Phase 1 did not start")
	var width := 2.0 * 1.7 * UfoBoss01.VISUAL_SCALE
	check(width >= 5.0 and width <= 6.2, "Boss width %.1f m" % width)
	var half := BeeShmupFairness.visible_half_width(stage.camera, boss.global_position, BeeLevel01Framing.view_aspect(root))
	check(absf(boss.global_position.x - stage.camera.global_position.x) < half - 2.0, "Boss off screen")
	await capture("ufo_boss_phase1")

	# 2. Spread and Bomb damage it.
	var hp := boss.health.current_health
	bee.global_position = Vector3(boss.global_position.x - 3.0, boss.global_position.y, 0)
	await frames(2)
	bee.spread_ammo = 5
	bee.fire()
	await frames(40)
	check(boss.health.current_health < hp, "Spread did not hurt the boss")
	hp = boss.health.current_health
	bee.bomb_charges = 1
	bee.global_position = Vector3(boss.global_position.x - 2.4, boss.global_position.y, 0)
	await frames(1)
	check(bee.use_bomb() != null, "Bomb refused")
	bee.active_bomb.detonate()
	await frames(18)
	check(hp - boss.health.current_health == roundi(boss.max_hp * UfoBoss01.BOMB_FRACTION), "LOTE 9: the bomb must take %d %% of the UFO (%d)" % [roundi(UfoBoss01.BOMB_FRACTION * 100.0), hp - boss.health.current_health])
	bee.global_position = Vector3(stage.distance - 4.0, 2.2, 0)

	# 3. LOTE 9 — Phase 2 at 70 %: the cyan shield powered by orbiting nodes (no drones any more).
	boss.health.take_damage(boss.health.current_health - int(boss.max_hp * 0.6))
	check(await wait_phase(UfoBoss01.State.PHASE_2, 120), "Phase 2 not reached")
	await frames(30)
	var drones := wave.boss_minions().size()
	check(boss.shield_up and boss.shield_nodes.size() == UfoBoss01.SHIELD_NODES and drones == 0, "Phase 2: shield + %d nodes, no drones (%d nodes, %d drones)" % [UfoBoss01.SHIELD_NODES, boss.shield_nodes.size(), drones])
	await capture("ufo_boss_phase2")

	# 4. Phase 3 at 40 %: tractor beam with its ground mark (BEAM_TELEGRAPH_BY_PHASE); BEAM_DAMAGE once.
	for node in boss.shield_nodes.duplicate():
		node.health.take_damage(9999)
	await frames(2)
	boss.health.take_damage(ceili(float(boss.health.current_health - int(boss.max_hp * 0.3)) / boss.health.damage_scale)) # The open shield window doubles damage.
	check(await wait_phase(UfoBoss01.State.PHASE_3, 120), "Phase 3 not reached")
	bee.health.damage_blocked = false
	var mark: MeshInstance3D = boss.get_node("BeamGroundMark")
	var beam_hits: Array[int] = []
	boss._beam_box.hit_confirmed.connect(func(_h: DamageHurtbox3D, applied: int): beam_hits.append(applied))
	check(await wait_beam_telegraph(), "Beam never announced")
	check(mark.visible and boss.beams >= 1, "Beam has no ground mark")
	check(not boss.beam_active() and not boss._beam_box.enabled, "Beam active during its telegraph")
	await capture("ufo_boss_beam_mark")
	var beam_x := boss._beam_x
	var tele_frames := 0
	while boss._attack_step == &"beam_tele":
		await frames(1)
		tele_frames += 1
		bee.global_position = Vector3(beam_x - 4.5, 3.0, 0) # Dodging: well outside the column.
	check(absf(float(tele_frames) / 60.0 - float(UfoBoss01.BEAM_TELEGRAPH_BY_PHASE[UfoBoss01.State.PHASE_3])) < 0.1, "Beam telegraph lasted %.2f s" % (float(tele_frames) / 60.0))
	check(boss.beam_active() and boss._beam_box.enabled, "Beam did not fire after the telegraph")
	await capture("ufo_boss_beam")
	while boss.beam_active():
		await frames(1)
	check(beam_hits.is_empty(), "Dodging Bee was hit by the beam")
	# Standing inside the column: exactly one hit of 15 per exposure.
	check(await wait_beam_telegraph(), "Second beam not announced")
	var locked_x := boss._beam_x
	while boss._attack_step == &"beam_tele":
		await frames(1)
		bee.global_position = Vector3(locked_x, 3.0, 0)
	while boss.beam_active():
		await frames(1)
		bee.global_position = Vector3(locked_x, 3.0, 0)
	check(beam_hits == [UfoBoss01.BEAM_DAMAGE], "Beam must hit exactly once for %d (%s)" % [UfoBoss01.BEAM_DAMAGE, str(beam_hits)])
	bee.health.damage_blocked = true
	bee.health.current_health = bee.health.max_health
	await capture("ufo_boss_phase3")

	# 5. Death: explosion, beam off, SECTOR DESPEJADO only after, no damage after the win.
	boss.health.take_damage(99999)
	check(boss.state == UfoBoss01.State.DEATH and not boss._beam_box.enabled and not boss._beam_visual.visible, "Beam left on at death")
	check(not stage.sector_complete, "Level complete before the explosion")
	var captured := false
	for i in 400:
		await frames(1)
		if not captured and i == 95:
			captured = true
			await capture("ufo_boss_explosion")
		if not is_instance_valid(boss):
			break
	for i in 600:
		await frames(1)
		if stage.sector_complete:
			break
	check(stage.sector_complete and (stage.status.text.begins_with("SECTOR DESPEJADO") or stage.has_node("ResultsScreen")), "SECTOR DESPEJADO did not appear after the explosion")
	await frames(5)
	check(bee.health.damage_blocked, "Bee must be invulnerable after the win")
	var hp_win := bee.health.current_health
	bee.health.take_damage(50)
	await frames(60)
	check(bee.health.current_health == hp_win and bee.health.damage_blocked, "Bee took damage after winning")

	# 6. Boss respawn: Bee dies in the fight and comes back at its start with HP >= 60.
	await reload(func(): stage.checkpoint.restart_level(true))
	bee.set_physics_process(false)
	to_boss_entry()
	bee.health.current_health = 30
	check(await wait_phase(UfoBoss01.State.PHASE_1, 900), "Boss did not start")
	check(bee.health.current_health >= 60, "Boss checkpoint must raise HP to >= 60 (%d)" % bee.health.current_health)
	wave.boss.health.take_damage(250)
	bee.health.damage_blocked = false
	bee.health.take_damage(99999)
	await frames(2)
	check(bee.is_defeated, "Bee did not die")
	await reload(func(): stage.checkpoint.restart_level(false))
	check(stage.distance >= 352.0 and bee.health.current_health >= 60 and not bee.is_defeated and wave.boss == null, "Respawn at the boss start failed (distance %.1f hp %d)" % [stage.distance, bee.health.current_health])
	check(await wait_phase(UfoBoss01.State.PHASE_1, 900), "Boss not rebuilt after respawn")
	check(wave.boss.health.current_health == BOSS_HP, "Boss kept damage after respawn")

	# 7. F9 debug: jump to the start of the fight with the DEBUG label.
	await reload(func(): stage.checkpoint.restart_level(true))
	check(not stage.checkpoint.debug_label.visible, "DEBUG label visible in a normal run")
	await reload(func(): stage.checkpoint.debug_jump_to_boss())
	check(stage.checkpoint.debug_label.visible and stage.checkpoint.debug_active, "No DEBUG label after F9")
	check(stage.distance >= 340.0 and wave.event_index == BeeLevel01Controller.EVENTS_LEGACY.size() and bee.bomb_charges == 2 and bee.spread_ammo == 0, "F9 must land at the boss start with Base weapon and 2 bombs")
	check(await wait_phase(UfoBoss01.State.PHASE_1, 900), "Boss did not start after F9")
	await reload(func(): stage.checkpoint.restart_level(true))
	check(not stage.checkpoint.debug_label.visible, "DEBUG label survived a full restart")
	print("UFO_BOSS_NODO_OK")
	quit(0)
