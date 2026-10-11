extends SceneTree
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
var errors: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
		push_error(message)
func frames(n: int) -> void:
	for i in n:
		await physics_frame
func run() -> void:
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	var stage := current_scene as BeeShmupStage
	stage.wave.set_physics_process(false)
	stage.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.bee.health.damage_blocked = true
	stage.distance = 340.0
	stage._update_camera_and_bounds()
	stage.wave._start_boss()
	var boss := stage.wave.boss as UfoBoss01
	await frames(200)
	var shot := DamageHitbox3D.new()
	shot.damage = 24
	shot.team_id = &"bee"
	shot.enabled = true
	stage.add_child(shot)
	var hp := boss.health.current_health
	for i in 120:
		shot.hit_healths.clear()
		boss.hurtbox.receive_hit(shot)
		await frames(1)
	var budget := ceili(boss.max_hp * UfoBoss01.HULL_DPS_RATIO * 2.0 + UfoBoss01.HULL_BURST)
	check(hp - boss.health.current_health <= budget, "Sustained Spread exceeds hull DPS budget")
	# Bomb is neither capped by empty tokens nor doubled by a shield damage window.
	boss._hull_tokens = 0
	boss.health.damage_scale = UfoBoss01.WINDOW_DAMAGE_SCALE
	var bomb := BeeAlienBomb.new()
	stage.add_child(bomb)
	bomb.set_physics_process(false)
	bomb.team_id = &"bee"
	bomb.enabled = true
	bomb.damage = boss.bomb_damage_for(32)
	bomb.ignores_weak_points = true
	var applied := boss.hurtbox.receive_hit(bomb)
	check(applied == roundi(boss.max_hp * 0.08), "Bomb must stay exactly 8% even in shield window")
	bomb.queue_free()
	boss.health.damage_scale = 1.0
	boss._change_state(UfoBoss01.State.PHASE_3)
	boss._attack_step = &"cooldown"
	boss._attack_left = 10.0
	boss._side_timer = 10.0
	boss.assault.clock = 0.0
	await frames(100)
	check(boss.assault.sweeps == 1, "Wide laser sweep missing")
	for area in boss.assault.boxes:
		var shape := area.get_child(0).shape as BoxShape3D
		for gap in [boss.assault.gap_centres.x, boss.assault.gap_centres.y]:
			check(absf(area.global_position.y - gap) >= shape.size.y * 0.5 + 0.7, "Marked safe laser gap must be physically safe")
	await frames(90)
	boss.assault.clock = 0
	boss._attack_step = &"cooldown"
	boss._attack_left = 10.0
	boss._side_timer = 10.0
	boss.crossing = false
	await frames(140)
	check(boss.assault.rams == 1, "Telegraphed lateral ram missing")
	check(boss.hazards.filter(func(h): return h.kind in [&"ram", &"sweep"]).all(func(h): return h.telegraph >= 0.8), "Assault warning under 0.8s")
	boss._change_state(UfoBoss01.State.PHASE_5)
	check(boss.is_active() and boss.is_fury() and boss.honey_spawned == 2, "Overload must be active with two interphase honey jars")
	boss.health.take_damage(99999)
	check(not boss.assault.busy and boss.assault.boxes.is_empty(), "Death must clear assault hazards")
	print("UFO_OVERLOAD budget=",budget," bomb=",applied," sweep=OK ram=OK safe_gaps=OK honey=2 phase5=OK")
	quit(0 if errors.is_empty() else 1)
