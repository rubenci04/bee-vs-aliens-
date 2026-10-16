extends "res://tests/levels/bee_t7b_fixture.gd"
func run() -> void:
	var stage := await fixture()
	var wave := stage.wave as BeeLevel01Controller
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	var walker := robot(stage)
	juice._reset_combo()
	for i in 3: walker.health.take_damage(3)
	check(juice.combo == 3, "Robot hits start and grow combo from zero")
	var boss := spider(stage)
	for i in 3: boss.health.take_damage(3)
	check(juice.combo == 6, "Tarantula hits use the identical combo path")
	var score := juice.score
	boss.health.damage_blocked = true
	boss.health.take_damage(3)
	check(juice.combo == 6 and juice.score == score, "Blocked hits neither add combo nor score")
	boss.health.damage_blocked = false
	walker.cannon_health.take_damage(3)
	check(juice.combo == 7, "Robot cannon also reports applied damage")
	boss.health.take_damage(3)
	check(juice.combo == 8 and juice.frenzy_activations == 1 and juice.score == score, "Shared frenzy threshold; score remains a downing reward")
	wave._spawn({"family":"FlyCommon", "slot":0, "event":0, "hard":false})
	var common: Node = wave.active_units.back()
	common.set_physics_process(false)
	var hp := common.get_node("HealthComponent") as HealthComponent
	hp.max_health = 6
	hp.current_health = 6
	var before := juice.combo
	hp.take_damage(3)
	hp.take_damage(3)
	await frames(2)
	check(juice.combo == before + 2, "Common hits count equally, lethal hit and liberation are not doubled")
	juice.combo_left = 0.5
	wave.tarantula = null
	wave._tarantula_breather_left = 5.5
	juice._physics_process(6.0)
	check(juice.combo == before + 2 and juice.combo_left == 0.5, "Mandatory Robot-to-Tarantula breather preserves chain")
	wave.tarantula = boss
	boss.state = TarantulaBoss01.State.APPROACH
	juice._physics_process(4.0)
	check(juice.combo_left == 0.5, "Boss entrance preserves chain")
	boss.state = TarantulaBoss01.State.PHASE_1
	juice._physics_process(0.6)
	check(juice.combo == 0, "Three-second timeout resumes during actual combat")
	done()
