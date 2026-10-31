extends "res://tests/levels/bee_t7b_fixture.gd"
const POWERS := preload("res://scripts/game/bee_pollen_powers.gd")
const GUIDE := preload("res://scripts/game/bee_controls_guide.gd")

func run() -> void:
	var stage := await fixture()
	var bee := stage.bee
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	check(POWERS.POWERS.map(func(p): return p.id) == [&"heal", &"shield", &"double_shot"], "Pollen powers are data driven")
	check(POWERS.POLLEN_DOUBLE_SECONDS == 4.0 and POWERS.POLLEN_DOUBLE_MAX_SECONDS == 12.0, "Pollen double constants")
	check(preload("res://scripts/game/bee_pollen_nova_settings.gd").POLLEN_USE_COOLDOWN_SECONDS == 1.5, "Cartridges wait 1.5 seconds between uses")
	check(GUIDE.STEPS.size() == 6 and GUIDE.lines(false).all(func(line): return line.contains(" ")) and GUIDE.lines(true).any(func(line): return line.contains("LT")), "Six controls have keyboard and gamepad explanations")
	for spec in [["SpreadBeforeCloud", 123.0], ["SpreadRecharge", float(preload("res://scripts/game/bee_flow_fix_settings.gd").PICKUP_X["SpreadRecharge"]) if preload("res://scripts/game/bee_flow_fix_settings.gd").ENABLED else 200.0], ["SpreadBeforeSpiders", 248.0]]: # Tanda T: SpreadRecharge antes de la serie de moscas.
		var pickup := stage.get_node("Powerups/" + spec[0])
		check(pickup != null and is_equal_approx(pickup.position.x, spec[1]), "Spread ahead of combat at X=%s" % spec[1])
	check(is_equal_approx(stage.wave.PREBOSS_POWER_X, 282.0), "Robot Spread appears 12 m before X=294")
	bee.health.damage_blocked = false
	bee.health.take_damage(35)
	juice.add_pollen(21)
	check(juice.try_pollen_nova() and bee.pollen_double_left == 4.0 and bee.health.pollen_protected, "One cartridge heals, shields and doubles")
	check(juice.pollen_double_label.visible and juice.pollen_double_label.text.contains("4.0"), "HUD shows double timer")
	var hp := bee.health.current_health
	check(hp == bee.health.max_health - 10, "Pollen heals 25")
	for node in stage.get_children():
		if node is BeeEnergyProjectile: node.queue_free()
	await frames(2)
	var main := bee.fire()
	var shots := stage.get_children().filter(func(n): return n is BeeEnergyProjectile and not n.is_queued_for_deletion())
	check(shots.size() == 2 and shots.all(func(n): return n.damage == main.damage), "Base fires two parallel full damage shots")
	bee.collect_spread()
	for node in shots: node.queue_free()
	await frames(2)
	bee.fire()
	shots = stage.get_children().filter(func(n): return n is BeeEnergyProjectile and not n.is_queued_for_deletion())
	var damages := shots.map(func(n): return n.damage)
	damages.sort()
	check(shots.size() == 6 and damages == [1, 1, 1, 1, 3, 3], "Spread doubles every pellet at its original damage")
	bee.set_physics_process(false)
	juice._physics_process(1.49)
	check(not juice.try_pollen_nova(), "Second cartridge waits for the cooldown")
	juice._physics_process(0.02)
	check(juice.try_pollen_nova() and bee.pollen_double_left == 8.0, "Second cartridge adds four seconds")
	juice._physics_process(1.51)
	check(juice.try_pollen_nova() and bee.pollen_double_left == 12.0, "Third cartridge reaches 12 second cap")
	bee.add_pollen_double(4.0, POWERS.POLLEN_DOUBLE_MAX_SECONDS)
	check(bee.pollen_double_left == 12.0, "Further additions respect cap")
	bee.spread_ammo = 44.0
	bee.collect_spread()
	check(bee.spread_ammo <= BeeGameSettings.SPREAD_MAX_DURATION_SEC, "Spread never exceeds 45 seconds")
	print("TANDA_K failures=", failures)
	done()
