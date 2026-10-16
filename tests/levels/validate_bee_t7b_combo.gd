extends "res://tests/levels/bee_t7b_fixture.gd"
func run() -> void:
	var stage := await fixture()
	var wave := stage.wave as BeeLevel01Controller
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	var walker := robot(stage)
	juice._reset_combo()
	walker.health.max_health = 10000
	walker.health.current_health = 10000
	for i in 100:
		walker.health.take_damage(1)
		juice._physics_process(0.1)
	check(juice.combo == 20, "100 actual Robot hits in ten seconds add at most twenty (and exactly twenty when sustained)")
	check(juice.frenzy_activations == 2, "Frenzy still fires at eight and sixteen")
	var boss := spider(stage)
	boss.health.max_health = 10000
	boss.health.current_health = 10000
	boss._hull_tokens = 10000
	juice._reset_combo()
	for i in 100:
		boss.health.take_damage(1)
		juice._physics_process(0.1)
	check(juice.combo == 20, "Tarantula uses the same half-second damage clock")
	var score := juice.score
	boss.health.damage_blocked = true
	boss.health.take_damage(3)
	check(juice.combo == 20 and juice.score == score, "Blocked damage never counts")
	walker.cannon_health.take_damage(1)
	var after_cannon := juice.combo
	walker.health.take_damage(1)
	check(juice.combo == after_cannon, "Cannon and hull share the boss damage throttle")
	wave._spawn({"family":"FlyCommon", "slot":0, "event":0, "hard":false})
	var common: Node = wave.active_units.back()
	common.set_physics_process(false)
	var hp := common.get_node("HealthComponent") as HealthComponent
	hp.max_health = 6
	hp.current_health = 6
	var before := juice.combo
	hp.take_damage(3)
	check(juice.combo == before, "Nonlethal common hit does not increase combo")
	hp.take_damage(3)
	await frames(2)
	check(juice.combo == before + 1, "Common death or liberation adds exactly one")
	juice.combo_left = 0.5
	wave.tarantula = null
	wave._tarantula_breather_left = 5.5
	juice._physics_process(6.0)
	check(juice.combo == before + 1 and juice.combo_left == 0.5, "Mandatory boss breather preserves chain")
	wave.tarantula = boss
	boss.state = TarantulaBoss01.State.APPROACH
	juice._physics_process(4.0)
	check(juice.combo_left == 0.5, "Boss entrance preserves chain")
	boss.state = TarantulaBoss01.State.PHASE_1
	juice._physics_process(0.6)
	check(juice.combo == 0, "Three-second timeout resumes during combat")
	done()
