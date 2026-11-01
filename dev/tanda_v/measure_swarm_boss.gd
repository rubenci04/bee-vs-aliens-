extends "res://tests/levels/bee_t7b_fixture.gd"
## Tanda V: daño real de UNA salida del Enjambre libre (6 s) contra la tarántula activa y quieta, comparado con su vida.
## El bot experto del test largo no termina la pelea desde antes de la Tanda R, así que la regla del 15 % se mide así.
const SWARM := preload("res://scripts/game/bee_free_swarm_settings.gd")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var stage := await fixture()
	var bee := stage.bee
	var wave := stage.wave as BeeLevel01Controller
	stage.distance = 296.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(292.5, 3.4, 0.0)
	wave._start_tarantula()
	var boss := wave.tarantula as TarantulaBoss01
	boss.set_physics_process(false)
	boss.global_position = Vector3(297.5, 0.0, 0.0)
	boss.state = TarantulaBoss01.State.PHASE_1
	boss._enter_fight() # Como en la pelea real: hurtboxes activas y objetivo del auto-apuntado.
	await frames(5)
	var swarm := stage.get_node("FreeSwarm")
	swarm.charge = SWARM.SWARM_CHARGE_NEEDED
	var before := boss.health.current_health
	swarm.activate()
	await frames(int(SWARM.SWARM_SECONDS * 60.0) + 30)
	var dealt := before - boss.health.current_health
	print("SWARM_BOSS dealt=%d boss_max=%d share=%.1f%% shots=%d" % [dealt, boss.health.max_health, 100.0 * float(dealt) / float(boss.health.max_health), swarm.shots])
	quit(0)
