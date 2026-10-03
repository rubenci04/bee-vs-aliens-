extends SceneTree
## DEV ONLY. Base vs Spread damage per second against UFO BOSS 01 (moving, attacking) at several
## Bee-to-boss distances. Bee is invulnerable and follows the boss height with her real vertical speed;
## she taps X at TAP_HZ. Pure measurement: nothing in the game is changed.
## godot --headless --fixed-fps 60 --path . --script res://dev/level01_challenge_review/spread_vs_ufo.gd -- label=before
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const TAP_HZ := 3.3
const SECONDS := 12.0
const DISTANCES := [2.0, 3.0, 4.0, 5.0, 6.0, 8.0]

var stage: BeeShmupStage
var bee: BeePlayer
var boss: UfoBoss01
var label := "run"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("label="):
			label = arg.substr(6)
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func follow(delta: float, gap: float) -> void:
	var wanted_y := clampf(boss.global_position.y, bee.flight_min.y, bee.flight_max.y)
	bee.global_position.x = boss.global_position.x - gap
	bee.global_position.y = move_toward(bee.global_position.y, wanted_y, bee.vertical_speed * delta * 0.8)
	bee.facing_x = 1.0

func tap_for(gap: float, spread: bool) -> float:
	boss.health.current_health = boss.health.max_health
	if spread:
		bee.collect_spread()
	else:
		bee.spread_ammo = 0
	var interval := 1.0 / TAP_HZ
	var next := 0.0
	var time := 0.0
	var dt := 1.0 / 60.0
	var bursts := 0
	while time < SECONDS:
		follow(dt, gap)
		if time >= next:
			bee.fire()
			bursts += 1
			next += interval
		await physics_frame
		time += dt
	await frames(70) # Let the last projectiles land.
	return float(boss.health.max_health - boss.health.current_health) / SECONDS

func run() -> void:
	create_timer(600.0, true, false, true).timeout.connect(func(): quit(1))
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
	boss.health.max_health = 1000000
	boss.set_physics_process(true)
	print("SPREAD_VS_UFO_%s hurtbox=%s ratio=%.2f tap_hz=%.1f" % [label, boss.hurtbox.get_node("CollisionShape3D").shape.get_class(), bee.spread_damage_ratio, TAP_HZ])
	for gap in DISTANCES:
		var base := await tap_for(gap, false)
		var spread := await tap_for(gap, true)
		print("SPREAD_VS_UFO_%s gap=%.0fm base_dps=%.1f spread_dps=%.1f ratio=%.2f" % [label, gap, base, spread, spread / maxf(base, 0.001)])
	quit(0)
