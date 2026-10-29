extends "res://tests/levels/bee_t7b_fixture.gd"

const GUARD := preload("res://scripts/game/bee_boss_burst_guard.gd")
const BURST := [8, 10, 8, 8, 3] # Superposición de golpes observada en Furia.
const WINDOW_EXTRA_FRAMES := 2 # Margen para salir de la ventana móvil.

func hit(stage: BeeShmupStage, source: Node, amount: int) -> int:
	var hitbox := DamageHitbox3D.new()
	hitbox.damage = amount
	hitbox.collision_mask = 0
	stage.add_child(hitbox)
	hitbox.attacker = source
	hitbox.set_enabled(true)
	var applied := stage.bee.hurtbox.receive_hit(hitbox)
	hitbox.queue_free()
	return applied

func run() -> void:
	var stage := await fixture()
	var bee := stage.bee
	bee.health.damage_blocked = false
	var boss := spider(stage)
	boss.state = TarantulaBoss01.State.PHASE_4
	check(BeeGameSettings.BOSS_BURST_CAP_ENABLED and BeeGameSettings.BOSS_BURST_WINDOW_SECONDS == 1.0 and BeeGameSettings.BOSS_BURST_CAP_DAMAGE == 24, "Tope configurado")
	var received := 0
	for amount in BURST:
		received += hit(stage, boss, amount)
	check(received == BeeGameSettings.BOSS_BURST_CAP_DAMAGE and bee.health.current_health == bee.health.max_health - received, "Cinco golpes simultáneos no superan el tope")
	check(bee.boss_burst_absorbed_hits == 2, "Los golpes absorbidos conservan su respuesta visual y sonora")
	check((bee.get_node("HitFlash3D") as HitFlash3D).activation_count >= 3, "Los golpes absorbidos renuevan el flash")
	var helper := Node3D.new()
	helper.set_meta("boss_helper", "Spider")
	stage.add_child(helper)
	check(hit(stage, helper, TarantulaBoss01.HANG_DAMAGE) == 0, "La araña invocada comparte el presupuesto")
	var helper_wasp := Node3D.new()
	helper_wasp.set_meta("boss_helper", "Wasp")
	stage.add_child(helper_wasp)
	check(bee.take_boss_burst_damage(TarantulaBoss01.JUMP_DAMAGE, helper_wasp) == 0, "La explosión directa de una avispa invocada comparte el tope")
	var robot := preload("res://scripts/levels/walker_miniboss.gd").new()
	var ufo := preload("res://scripts/levels/ufo_boss_01.gd").new()
	check(not GUARD.is_tarantula_source(robot) and not GUARD.is_tarantula_source(ufo), "Robot y OVNI quedan fuera")
	check(hit(stage, robot, TarantulaBoss01.JUMP_DAMAGE) == TarantulaBoss01.JUMP_DAMAGE, "El daño del robot no cambia")
	check(hit(stage, ufo, TarantulaBoss01.CONTACT_DAMAGE) == TarantulaBoss01.CONTACT_DAMAGE, "El daño del OVNI no cambia")
	var ordinary_wasp := Node3D.new()
	check(bee.take_boss_burst_damage(TarantulaBoss01.SHOT_DAMAGE, ordinary_wasp) == TarantulaBoss01.SHOT_DAMAGE, "La explosión de una avispa común no cambia")
	for frame in ceili(BeeGameSettings.BOSS_BURST_WINDOW_SECONDS * Engine.physics_ticks_per_second) + WINDOW_EXTRA_FRAMES:
		await physics_frame
	check(hit(stage, boss, TarantulaBoss01.JUMP_DAMAGE) == TarantulaBoss01.JUMP_DAMAGE, "La ventana se reinicia")
	check(bee.start_roll(), "La pirueta arranca")
	check(hit(stage, boss, TarantulaBoss01.STOMP_DAMAGE) == 0, "La pirueta sigue bloqueando daño")
	bee._update_roll(bee.roll_duration)
	var before_shield := bee.health.current_health
	bee.health.pollen_protected = true
	check(hit(stage, boss, TarantulaBoss01.SHOT_DAMAGE) == 0 and bee.health.current_health == before_shield, "El escudo de polen sigue bloqueando daño")
	bee.health.pollen_protected = false
	check(hit(stage, boss, TarantulaBoss01.SHOT_DAMAGE) == TarantulaBoss01.SHOT_DAMAGE, "Golpes protegidos no gastan presupuesto")
	print("TANDA_O failures=", failures)
	done()
