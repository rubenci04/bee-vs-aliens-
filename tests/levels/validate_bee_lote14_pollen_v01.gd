extends SceneTree

# LOTE 14 scarcity and real common damage. T3m replaces the full-bar heal with a charged Nova.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")


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


func run() -> void:
	create_timer(60.0, true, false, true).timeout.connect(func(): quit(1))
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	var bee := stage.bee
	var juice := stage.get_node("Juice") as BeeLevel01Juice
	juice.set_physics_process(false) # No magnet / no combo timers: only what the test does.
	stage.wave.set_physics_process(false)

	# --- constants ---------------------------------------------------------------------------------------------------------
	check(BeeLevel01Juice.POLLEN_PER_HEAL == 21 and is_zero_approx(BeeLevel01Juice.POLLEN_HEAL_FRACTION), "21 grains fill three cartridges; automatic healing removed")
	check(BeeLevel01Juice.LIBERATION_POLLEN_EVERY == 3, "A liberation drops pollen one time in three")
	check(is_equal_approx(BeeLevel01Controller.ROUTE_DAMAGE_SCALE, 1.0), "ROUTE_DAMAGE_SCALE is back to 1.0 (the chip-damage hack is gone)")
	check(BeeImplantShooter.SHOT_DAMAGE >= 3 and BeeImplantShooter.SHOT_DAMAGE <= 5, "Common implant bullets do 3-5")
	for kind in ["fly_common", "fly_green", "worm_compost", "snail"]:
		var damage := int(AssetFauna.KINDS[StringName(kind)].get("shot_damage", 0))
		check(damage >= 3 and damage <= 5, "%s bullet damage %d must be 3-5" % [kind, damage])
	check(BeeLevel01Controller.ROSTER_TUNING["Wasp"]["sting_damage"] >= 3 and BeeLevel01Controller.ROSTER_TUNING["Wasp"]["sting_damage"] <= 5, "Wasp needles do 3-5")

	# --- T3m: 20 pollen charge Nova without healing ----------------------------------------------------------------------------------------------
	bee.health.take_damage(50)
	var hp := bee.health.current_health
	juice.add_pollen(19)
	check(bee.health.current_health == hp and juice.pollen_heals == 0, "19 pollen do not heal")
	juice.add_pollen(1)
	check(juice.pollen_progress() == 20 and juice.pollen_heals == 0 and bee.health.current_health == hp, "20 pollen stay charged without healing: %d -> %d" % [hp, bee.health.current_health])

	# --- a full bar at full health never banks healing ----------------------------------------------------------------------
	bee.health.restore_health(100)
	juice._pollen_window.clear()
	juice.add_pollen(20)
	check(juice.banked_heals == 0 and juice.pollen_progress() == 21 and bee.health.current_health == bee.health.max_health, "Full charge remains available, no healing is banked")
	var before := bee.health.current_health
	bee.health.take_damage(30)
	await frames(2)
	check(juice.banked_heals == 0 and bee.health.current_health == before - 30, "Taking damage no longer releases a heal (%d)" % bee.health.current_health)

	# --- rolling-minute cap ----------------------------------------------------------------------------------------------------
	juice._pollen_window.clear()
	juice._pollen_clock = 1000.0
	var total_before := juice.pollen_total
	juice.add_pollen(BeeLevel01Juice.POLLEN_CAP_PER_MINUTE + 25)
	check(juice.pollen_total - total_before == BeeLevel01Juice.POLLEN_CAP_PER_MINUTE and juice.pollen_lost_to_cap >= 25, "No more than %d pollen per minute" % BeeLevel01Juice.POLLEN_CAP_PER_MINUTE)
	juice._pollen_clock += BeeLevel01Juice.POLLEN_CAP_WINDOW + 1.0
	total_before = juice.pollen_total
	juice.add_pollen(5)
	check(juice.pollen_total - total_before == 5, "The cap window rolls: 5 pollen fit a minute later")

	# --- liberations: pollen one time in three ------------------------------------------------------------------------------------
	juice._pollen_window.clear()
	juice.liberations_seen = 0
	var pollen_at_start := juice.pollen_total
	var unit := Node3D.new()
	stage.add_child(unit)
	for i in 6:
		stage.wave.unit_downed.emit(unit, true)
	check(juice.pollen_total - pollen_at_start == 2 * BeeLevel01Juice.POLLEN_PER_LIBERATION, "6 liberations drop pollen twice (got %d)" % (juice.pollen_total - pollen_at_start))

	# --- loose pollen is thinned ----------------------------------------------------------------------------------------------------
	check(stage.get_node("Pollen").get_child_count() == 9, "Half of the 17 loose pollen pickups stay (%d)" % stage.get_node("Pollen").get_child_count())
	print("BEE_LOTE14_POLLEN_V01_OK bar=20/Nova bank=0 cap=%d/min liberation_every=3 damage_scale=1.0 bullets=3-5" % BeeLevel01Juice.POLLEN_CAP_PER_MINUTE)
	quit(0)
