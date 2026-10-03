extends SceneTree
## DEV ONLY. Measures Bee's real damage per second against UFO BOSS 01 (moving, attacking) for a
## "reasonable player": stays ~6 m left of the boss, follows its height with Bee's real vertical
## speed, taps fire at TAP_HZ. Bee is invulnerable here (damage is measured, not survival).
## Run: godot --headless --path . --script res://dev/ufo_boss_01_review/measure_dps.gd
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const TAP_HZ := 3.3
const BASE_SECONDS := 30.0

var stage: BeeShmupStage
var bee: BeePlayer
var boss: UfoBoss01

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func follow(delta: float) -> void:
	var cam_x := stage.camera.global_position.x
	var wanted_y := clampf(boss.global_position.y, bee.flight_min.y, bee.flight_max.y)
	bee.global_position.x = cam_x - 3.0
	bee.global_position.y = move_toward(bee.global_position.y, wanted_y, bee.vertical_speed * delta * 0.8)
	bee.facing_x = 1.0

func tap_for(seconds: float, spread: bool) -> int:
	var before := boss.health.current_health
	var interval := 1.0 / TAP_HZ
	var next := 0.0
	var time := 0.0
	var dt := 1.0 / 60.0
	while time < seconds:
		follow(dt)
		if time >= next:
			bee.fire()
			next += interval
			if spread and bee.spread_ammo <= 0:
				break
		await physics_frame
		time += dt
	await frames(60)
	return before - boss.health.current_health

func run() -> void:
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	bee = stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	var wave := stage.wave as BeeLevel01Controller
	wave.event_index = BeeLevel01Controller.EVENTS.size()
	stage.distance = 352.0
	stage._update_camera_and_bounds()
	for i in 900:
		await physics_frame
		if wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1:
			break
	boss = wave.boss
	print("DPS approach_ok=", boss != null)
	boss.health.max_health = 100000
	boss.health.current_health = 100000
	var base_damage := await tap_for(BASE_SECONDS, false)
	var taps := int(BASE_SECONDS * TAP_HZ)
	print("DPS base damage=%d taps=%d hit_ratio=%.2f dps=%.1f" % [base_damage, taps, float(base_damage) / (taps * 10.0), base_damage / BASE_SECONDS])
	bee.collect_spread()
	var spread_shots := bee.spread_ammo
	var spread_damage := await tap_for(30.0, true)
	print("DPS spread load=%d bursts damage=%d per_burst=%.1f" % [spread_shots, spread_damage, float(spread_damage) / spread_shots])
	bee.global_position = Vector3(boss.global_position.x - 2.6, boss.global_position.y, 0)
	bee.collect_bomb()
	var hp := boss.health.current_health
	bee.use_bomb()
	await frames(10)
	print("DPS bomb damage at 2.6 m=%d" % (hp - boss.health.current_health))
	quit(0)
