extends SceneTree
## Tanda D (T7f-T7i) — TARANTULA: no armour hint, big black spiders by thread in phases 2 and 4 (3 / 5 per wave), kamikaze wasps from the right
## every 15 s in phase 3, web rain in fury (3 small rings, at most 2 live), a trapping net that a roll or 3 shots tears, and a fury of >= 60 s
## at the base weapon's DPS (36), even if every hit lands on the exposed implant.
const SHOT_INTERVAL := 1.0 / 12.0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func damage_to(boss: TarantulaBoss01, ratio: float) -> void:
	boss.health.take_damage(maxi(0, boss.health.current_health - int(boss.health.max_health * ratio)))
func run() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/levels/tarantula_boss_01.gd")
	check(not source.contains("BLINDADAS"), "The armour hint text is gone from the boss")
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(6)
	var wave := stage.wave as BeeLevel01Controller
	var bee := stage.bee
	stage.scroll_speed = 0.0
	stage.distance = 296.0
	stage._update_camera_and_bounds()
	wave.event_index = BeeLevel01Controller.EVENTS_ROSTER.size()
	for unit in wave.active_units:
		unit.queue_free()
	wave.active_units.clear()
	bee.global_position = Vector3(stage.camera.global_position.x - 3.5, 3.4, 0.0)
	bee.health.damage_blocked = true
	wave._tarantula_breather_left = 0.01
	var boss: TarantulaBoss01
	for i in 900:
		await physics_frame
		boss = wave.tarantula
		if boss != null and boss.state == TarantulaBoss01.State.PHASE_1:
			break
	check(boss != null and boss.state == TarantulaBoss01.State.PHASE_1, "The tarantula starts phase 1")
	# --- phase 2: black spiders ---
	damage_to(boss, 0.74)
	var max_slots := 0
	var helpers_seen := 0
	var entered_from_above := false
	for i in 60 * 14:
		await physics_frame
		max_slots = maxi(max_slots, get_nodes_in_group(BeeCommonSlots.GROUP).size())
		for unit in wave.active_units:
			if is_instance_valid(unit) and str(unit.get_meta("boss_helper", "")) == "Spider":
				helpers_seen = maxi(helpers_seen, wave._helpers_alive("Spider"))
				if unit is ControlledSpider and unit.web_mode and unit.global_position.y > BeeLevel01Framing.top_y():
					entered_from_above = true
	check(boss.state == TarantulaBoss01.State.PHASE_2, "Phase 2 reached")
	check(boss.spider_waves >= 1 and boss.spiders_requested >= 3, "Phase 2 sends a black-spider wave of 3 (%d waves)" % boss.spider_waves)
	check(helpers_seen == 3, "Three big spiders alive at once in phase 2 (%d)" % helpers_seen)
	check(entered_from_above, "They come down by thread from above the top edge")
	check(max_slots <= 2, "At most two attackers at once (max %d)" % max_slots)
	check(boss.spiders_dropped == 0, "The small drop-spiders are replaced in phase 2")
	# --- phase 3: kamikaze wasps ---
	damage_to(boss, 0.49)
	var call_times: Array[float] = []
	var seen_calls := boss.wasp_calls
	var clock := 0.0
	var wasp_variants := {}
	var came_from_right := false
	for i in 60 * 36:
		await physics_frame
		clock += 1.0 / 60.0
		if boss.wasp_calls > seen_calls:
			seen_calls = boss.wasp_calls
			call_times.append(clock)
		for unit in wave.active_units:
			if is_instance_valid(unit) and str(unit.get_meta("boss_helper", "")) == "Wasp":
				wasp_variants[unit.variant] = true
				if unit.global_position.x > stage.camera.global_position.x + 4.5:
					came_from_right = true
	check(boss.state == TarantulaBoss01.State.PHASE_3, "Phase 3 reached")
	check(call_times.size() >= 2, "At least two wasp calls in 36 s (%d)" % call_times.size())
	for i in range(1, call_times.size()):
		check(absf((call_times[i] - call_times[i - 1]) - 15.0) < 0.3, "A wasp call every 15 s (gap %.2f)" % (call_times[i] - call_times[i - 1]))
	check(boss.wasps_requested >= 2 * boss.wasp_calls - 1 and boss.wasps_requested <= 3 * boss.wasp_calls, "Each call brings 2-3 wasps (%d in %d calls)" % [boss.wasps_requested, boss.wasp_calls])
	check(wasp_variants.keys() == [&"kamikaze"], "The helper wasps are all kamikaze (%s)" % str(wasp_variants.keys()))
	check(came_from_right, "They enter from the right edge")
	# --- net: roll or 3 shots ---
	check(TarantulaWebNet.TEARS_NEEDED == 3 and TarantulaWebNet.GRACE_SECONDS <= 1.0, "Net: 3 shots to tear it, shorter grace")
	for pass_index in 2:
		boss._web_immune_left = 0.0
		var net := TarantulaWebNet.launch(stage, boss, bee, bee.global_position + Vector3(0.3, 0, 0), Vector3.LEFT)
		var freed_by := [&""]
		net.tree_exiting.connect(func(): freed_by[0] = net.freed_by)
		await frames(4)
		check(net.trapping and bee.web_locked, "The net traps Bee")
		if pass_index == 0:
			bee.start_roll()
			await frames(2)
			check(not bee.web_locked and freed_by[0] == &"roll", "A roll tears the net at once (freed by %s)" % str(freed_by[0]))
		else:
			for shot in 3:
				bee.fire_trigger_count += 1
			await frames(2)
			check(not bee.web_locked and freed_by[0] == &"shots", "Three shot triggers tear the net (freed by %s)" % str(freed_by[0]))
	# --- phase 4: spiders (5), rain, duration ---
	damage_to(boss, 0.19)
	var fury_clock := 0.0
	var fury_spiders := 0
	var rain_ring_radius := 0.0
	var fury_seen := false
	var next_shot := 0.0
	while boss.health.current_health > 0 and fury_clock < 200.0:
		await physics_frame
		if boss.state != TarantulaBoss01.State.PHASE_4:
			continue
		fury_seen = true
		fury_clock += 1.0 / 60.0
		max_slots = maxi(max_slots, get_nodes_in_group(BeeCommonSlots.GROUP).size())
		fury_spiders = maxi(fury_spiders, wave._helpers_alive("Spider"))
		for node in boss._warnings:
			if is_instance_valid(node) and node is MeshInstance3D and node.mesh is TorusMesh:
				rain_ring_radius = maxf(rain_ring_radius, node.scale.x)
		while next_shot <= fury_clock:
			boss.implant_hurtbox.last_hit_weak = true # worst case: every shot is a hit on the exposed implant
			var permitted := boss.limit_hull_damage(3, null)
			if permitted > 0:
				boss.health.take_damage(permitted)
			next_shot += SHOT_INTERVAL
	check(fury_seen, "Fury reached")
	check(boss.health.current_health <= 0, "The implant finally breaks")
	check(fury_clock >= 60.0, "Fury lasts >= 60 s at Base DPS, all shots on the exposed implant (got %.1f s)" % fury_clock)
	check(fury_spiders == 5, "Five big spiders in the fury wave (%d)" % fury_spiders)
	check(boss.rains >= 1 and boss.rain_spots_started >= 3 * boss.rains - 2, "Web rain ran (%d rains, %d spots)" % [boss.rains, boss.rain_spots_started])
	check(boss.rain_max_active <= 2 and boss.rain_max_active >= 1, "At most 2 rain spots live at once (max %d)" % boss.rain_max_active)
	check(rain_ring_radius <= 1.0 and rain_ring_radius > 0.3, "Small impact rings (%.2f)" % rain_ring_radius)
	check(max_slots <= 2, "Attack slots never above two (max %d)" % max_slots)
	print("TANDA_D_TARANTULA failures=", failures, " fury=", snappedf(fury_clock, 0.1), " spider_waves=", boss.spider_waves, " wasp_calls=", boss.wasp_calls, " wasps=", boss.wasps_requested, " rains=", boss.rains, " rain_max=", boss.rain_max_active, " slots=", max_slots, " gaps=", call_times)
	quit(1 if failures else 0)
