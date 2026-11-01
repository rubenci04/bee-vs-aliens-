extends "res://tests/levels/bee_t7b_fixture.gd"
## Tanda V: golpes con peso y Enjambre libre. Congelados al liberar (chico / grande), zoom del golpe, bomba con destello y
## onda del radio real, bombas al entrar a una zona, tope de sacudidas, carga / duración / disparos del enjambre y daño a
## la mitad contra jefes (nunca durante su entrada).
const IMPACT := preload("res://scripts/game/bee_impact_settings.gd")
const SWARM := preload("res://scripts/game/bee_free_swarm_settings.gd")
const BEE_IMPACT := preload("res://scripts/vfx/bee_impact.gd")
const HIT_STOP := preload("res://scripts/vfx/bee_local_hit_stop.gd")

func run() -> void:
	root.size = Vector2i(1280, 720)
	BeeJuice.hit_stop_enabled = true
	var stage := await fixture()
	BeeJuice.hit_stop_enabled = true # El fixture lo apaga; esta suite lo mide.
	var bee := stage.bee
	var wave := stage.wave as BeeLevel01Controller
	BeeLevel01Controller.instant_arrival = true

	# A. Congelado al liberar: 40 ms un enemigo común, 70 ms uno grande.
	var stop := HIT_STOP.for_host(bee)
	var fly := Node3D.new()
	fly.name = "FlyCommon_test"
	fly.add_child(HealthComponent.new())
	fly.get_child(0).name = "HealthComponent"
	stage.add_child(fly)
	fly.global_position = bee.global_position + Vector3(2, 0, 0)
	stop.cooldown = 0.0
	BEE_IMPACT.freed(stage, fly, fly.global_position)
	check(is_equal_approx(stop.remaining, IMPACT.FREE_SMALL_STOP), "Liberar un común congela %.2f s (fue %.3f)" % [IMPACT.FREE_SMALL_STOP, stop.remaining])
	stop.restore()
	var beetle := Node3D.new()
	beetle.name = "StagBeetle_test"
	beetle.add_child(HealthComponent.new())
	beetle.get_child(0).name = "HealthComponent"
	stage.add_child(beetle)
	beetle.global_position = bee.global_position + Vector3(2, 0, 0)
	check(BEE_IMPACT.is_big(beetle) and not BEE_IMPACT.is_big(fly), "El escarabajo cuenta como grande y la mosca no")
	stop.cooldown = 0.0
	BEE_IMPACT.freed(stage, beetle, beetle.global_position)
	check(is_equal_approx(stop.remaining, IMPACT.FREE_BIG_STOP), "Liberar uno grande congela %.2f s" % IMPACT.FREE_BIG_STOP)
	stop.restore()
	stop.cooldown = 0.0

	# B. Golpe que conecta: zoom corto que vuelve a 1.
	BEE_IMPACT.melee_connect()
	var mid := BEE_IMPACT.fov_factor(IMPACT.MELEE_ZOOM_SECONDS * 0.5)
	check(mid < 1.0 and mid >= 1.0 - IMPACT.MELEE_ZOOM - 0.001, "Zoom del %d %% al conectar (factor %.3f)" % [int(IMPACT.MELEE_ZOOM * 100), mid])
	BEE_IMPACT.fov_factor(1.0)
	check(is_equal_approx(BEE_IMPACT.fov_factor(0.016), 1.0), "El zoom vuelve a la normalidad")

	# C. Bomba: destello de pantalla, onda que llega al radio real.
	var bomb := Node3D.new()
	stage.add_child(bomb)
	bomb.global_position = bee.global_position + Vector3(3, 0, 0)
	BEE_IMPACT.bomb(bomb, bee.bomb_radius)
	check(stage.find_child("BombFlash", true, false) != null, "Destello de pantalla al explotar")
	var ring := stage.find_child("BombWave", true, false) as Node3D
	check(ring != null, "Onda visible de la bomba")
	if ring != null:
		for i in int(IMPACT.BOMB_WAVE_SECONDS * 60.0 * 0.9): await process_frame
		if is_instance_valid(ring):
			check(ring.scale.x > bee.bomb_radius * 0.7 and ring.scale.x <= bee.bomb_radius + 0.001, "La onda crece hasta el radio real (%.2f de %.2f)" % [ring.scale.x, bee.bomb_radius])

	# C. Cada zona de combate empieza con al menos 2 bombas, y el HUD las marca.
	bee.bomb_charges = 0
	var arena_event: Dictionary = {}
	for event in BeeLevel01Controller.EVENTS_ROSTER:
		if (event as Dictionary).has("arena"):
			arena_event = event
			break
	wave._begin_arena(arena_event, 0)
	var hud := stage.get_node("CanvasLayer/WeaponsHUD")
	check(bee.bomb_charges >= IMPACT.BOMBS_AT_ZONE_START, "Al entrar a la zona hay al menos %d bombas (hay %d)" % [IMPACT.BOMBS_AT_ZONE_START, bee.bomb_charges])
	check(float(hud.bomb_highlight_left) > 0.0, "El HUD ilumina las bombas al entrar a la zona")
	wave._arena = {}
	stage.scroll_speed = 0.0

	# D. Dos sacudidas grandes casi juntas: la segunda no pasa.
	BeeGameSettings.screen_shake_enabled = true
	var camera := stage.get_viewport().get_camera_3d()
	camera.remove_meta("last_big_shake") if camera.has_meta("last_big_shake") else null
	BeeCameraShake.kick(bee, IMPACT.BIG_SHAKE, 0.2, Vector2.UP)
	var first_time := float(camera.get_meta("last_big_shake", -1.0))
	await create_timer(0.05, true, false, true).timeout
	BeeCameraShake.kick(bee, IMPACT.BIG_SHAKE + 0.01, 0.2, Vector2.UP)
	check(first_time > 0.0 and is_equal_approx(float(camera.get_meta("last_big_shake")), first_time), "La segunda sacudida grande dentro de %.2f s se ignora" % IMPACT.SHAKE_GAP_SECONDS)

	# Enjambre: cada liberado suma 1; lleno se llama; 6 aliados durante 6 s que disparan.
	var swarm := stage.get_node("FreeSwarm")
	check(swarm != null and InputMap.has_action(SWARM.ACTION), "Existe el Enjambre libre y su acción")
	swarm.charge = 0
	check(not swarm.activate(), "Con la barra vacía no sale")
	for i in SWARM.SWARM_CHARGE_NEEDED:
		preload("res://scripts/bee_prototype/bee_feelings.gd").liberated(self)
	check(swarm.charge == SWARM.SWARM_CHARGE_NEEDED and swarm.is_ready(), "%d liberados llenan la barra" % SWARM.SWARM_CHARGE_NEEDED)
	stage.distance = 120.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(116.0, 4.0, 0.0)
	wave._spawn({"family": "FlyCommon", "slot": 0, "event": 900, "hard": false})
	var target: Node3D = wave.active_units.back() if not wave.active_units.is_empty() else null
	if target != null:
		target.global_position = Vector3(121.0, 4.0, 0.0)
		target.set_physics_process(false)
	check(swarm.activate() and swarm.charge == 0 and swarm.allies.size() == SWARM.SWARM_ALLIES, "Sale con %d aliados y vacía la barra" % SWARM.SWARM_ALLIES)
	swarm.add_charge(5)
	check(swarm.charge == 0, "Mientras está afuera no carga")
	var shots_before: int = swarm.shots
	await frames(int(SWARM.SWARM_SECONDS * 0.5 * 60.0))
	check(swarm.is_active() and swarm.shots > shots_before, "A mitad de tiempo sigue afuera y ya disparó (%d)" % (swarm.shots - shots_before))
	await frames(int(SWARM.SWARM_SECONDS * 0.5 * 60.0) + 10)
	check(not swarm.is_active() and swarm.allies.is_empty(), "A los %.0f s se va" % SWARM.SWARM_SECONDS)

	# Contra jefes: nunca en su entrada, y la mitad de daño.
	stage.distance = 294.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(291.0, 4.0, 0.0)
	wave._start_tarantula()
	var boss := wave.tarantula as TarantulaBoss01
	boss.set_physics_process(false)
	boss.global_position = Vector3(296.0, 0.0, 0.0)
	check(not boss.is_active() and swarm.nearest_target(bee.global_position) != boss, "Durante su entrada el enjambre no le apunta a la tarántula")
	boss.state = TarantulaBoss01.State.PHASE_1
	boss.health.damage_blocked = false
	var normal := bee.projectile_scene.instantiate() as BeeEnergyProjectile
	normal.damage = SWARM.SWARM_SHOT_DAMAGE
	normal.configured_weapon_damage = true
	stage.add_child(normal)
	normal.launch(Vector3.RIGHT, bee)
	var swarm_shot := bee.projectile_scene.instantiate() as BeeEnergyProjectile
	swarm_shot.damage = SWARM.SWARM_SHOT_DAMAGE
	swarm_shot.configured_weapon_damage = true
	swarm_shot.set_meta("swarm_shot", true)
	stage.add_child(swarm_shot)
	swarm_shot.launch(Vector3.RIGHT, bee)
	var hp := boss.health.current_health
	var normal_applied := boss.body_hurtbox.receive_hit(normal.hitbox)
	var mid_hp := boss.health.current_health
	var swarm_applied := boss.body_hurtbox.receive_hit(swarm_shot.hitbox)
	check(normal_applied > 0 and swarm_applied == maxi(1, roundi(float(normal_applied) * SWARM.SWARM_BOSS_FACTOR)), "Contra el jefe el enjambre hace la mitad (%d contra %d; vida %d -> %d -> %d)" % [swarm_applied, normal_applied, hp, mid_hp, boss.health.current_health])

	BeeLevel01Controller.instant_arrival = false
	print("TANDA_V failures=", failures)
	done()
