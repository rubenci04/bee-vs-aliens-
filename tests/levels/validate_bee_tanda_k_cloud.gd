extends "res://tests/levels/bee_t7b_fixture.gd"
const FLY := preload("res://scripts/game/bee_fly_cloud_settings.gd")

func run() -> void:
	var stage := await fixture()
	var wave := stage.wave
	var cloud_event: Dictionary = {}
	for event in wave.EVENTS_ROSTER:
		if is_equal_approx(float(event.at), 138.0):
			cloud_event = event
			break
	check(not cloud_event.is_empty() and cloud_event.arena.size() == 1 and cloud_event.arena[0].units == ["Ant", "FlyCloud", "Ant"], "Cloud zone has opening plus one Ant/Cloud/Ant wave")
	check(FLY.FLY_HP == roundi(FLY.FLY_HP_BEFORE_K * 0.75), "Cloud fly HP reduced by 25 percent, rounded")
	stage.distance = 138.0
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(134, 4, 0)
	stage.bee.health.damage_blocked = true
	wave.instant_arrival = true
	wave.event_index = wave.EVENTS_ROSTER.size()
	wave._queue_units(cloud_event, 1000, 0)
	wave._begin_arena(cloud_event, 1000)
	var ages := {}
	var elapsed := 0.0
	while wave.in_arena() and elapsed < 36.0:
		await physics_frame
		var dt := 1.0 / float(Engine.physics_ticks_per_second)
		elapsed += dt
		wave._physics_process(dt)
		for unit in wave.active_units.duplicate():
			if not is_instance_valid(unit):
				continue
			if str(unit.name).begins_with("FlyCloud_"):
				for member in unit.members:
					if not member.node.alive:
						continue
					var member_id: int = member.node.get_instance_id()
					if not ages.has(member_id):
						ages[member_id] = elapsed
					if elapsed - float(ages[member_id]) >= 3.0 + float(member_id % 4):
						member.hp.damage_blocked = false
						member.hp.take_damage(100)
			else:
				var id: int = unit.get_instance_id()
				if not ages.has(id):
					ages[id] = elapsed
				if elapsed - float(ages[id]) >= 3.0 + float(id % 4):
					unit.health.damage_blocked = false
					unit.health.take_damage(1000)
	check(not wave.in_arena() and elapsed < 35.0, "Slow bot clears cloud zone in under 35 s (%.1f)" % elapsed)
	print("TANDA_K_CLOUD seconds=%.2f failures=%d" % [elapsed, failures])
	done()
