extends SceneTree
## DEV ONLY. Review captures of THREAT, CAMERA & BOSS REBUILD 03 (render required, writes PNGs here).
##   godot --path . --resolution 1152x648 --script res://dev/threat_camera_boss_v03_review/review_capture.gd -- shots=all
## Camera D/E comparison frames come from camera_compare.gd (cam_D_* / cam_E_*). Nothing in the game changes.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const OUT := "res://dev/threat_camera_boss_v03_review/"

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var wanted: PackedStringArray = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			wanted = arg.substr(6).split(",")
	call_deferred("run")

func want(name: String) -> bool:
	return wanted.is_empty() or "all" in wanted or name in wanted

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + file + ".png")
	print("SHOT ", file)

func fresh() -> void:
	if stage != null:
		stage.queue_free()
		await frames(2)
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	wave.set_physics_process(false)

func at(distance: float, y := 3.6) -> void:
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x + BeeLevel01Framing.player_anchor_offset(BeeLevel01Framing.view_aspect(root)), y, 0)
	bee.facing_x = 1.0
	await frames(3)

func spawn(family: String, slot := 0, y := -99.0, extra := {}) -> Node3D:
	var request := {"family": family, "slot": slot, "event": 0, "hard": false}
	if y > -50.0:
		request["y"] = y
	request.merge(extra, true)
	wave._spawn(request)
	return wave.swarm_units.back() if family == "Swarm" else wave.active_units.back()

## Bee bobs (no input) until `until` is true or the time runs out.
func live_until(seconds: float, until: Callable = Callable()) -> void:
	for i in int(seconds * 60.0):
		bee.global_position.y = 3.6 + sin(float(i) / 60.0 * 2.0) * 1.0
		await physics_frame
		if until.is_valid() and until.call():
			return

func run() -> void:
	root.size = Vector2i(1152, 648)
	if want("wasp"):
		await fresh()
		await at(160.0)
		var wasp := spawn("Wasp", 1, 4.6, {}) as WaspEnemy
		wasp.sting_shots = 2
		await live_until(6.0, func(): return wasp.sting_count >= 1)
		await frames(6)
		await shot("03_wasp_implant_sting")
		wasp.overload_enabled = true
		wasp.health.take_damage(int(wasp.health.max_health * 0.7))
		await live_until(1.0, func(): return wasp.current_state == WaspEnemy.State.OVERLOAD and wasp._overload_line != null)
		await shot("04_wasp_overload")
		await live_until(2.0, func(): return wasp.current_state == WaspEnemy.State.KAMIKAZE)
		await frames(10)
		await shot("05_wasp_dash")
	if want("organic"):
		await fresh()
		await at(214.0)
		var organic := spawn("OrganicAlien", 0, 4.0) as OrganicAlienEnemy
		await live_until(4.0, func(): return organic.orbs_fired >= 3)
		await frames(14)
		await shot("06_organic_ranged")
		await live_until(6.0, func(): return organic.current_state == OrganicAlienEnemy.State.LUNGE)
		await frames(6)
		await shot("07_organic_lunge")
	if want("walker"):
		await fresh()
		await at(238.0, 4.6)
		var walker := spawn("Walker", 0) as GroundWalkerEnemy
		await live_until(6.0, func(): return walker.projectile_fire_count >= 2)
		await frames(10)
		await shot("08_walker_burst")
		await live_until(8.0, func(): return walker._sweeping and walker.current_state == GroundWalkerEnemy.State.SHOOT and walker._shots_done >= 3)
		await frames(8)
		await shot("09_walker_sweep")
	if want("speeder"):
		await fresh()
		await at(152.0)
		var speeder := spawn("Speeder", 0, 5.6) as SpeederEnemy
		await live_until(4.0, func(): return speeder.current_state == SpeederEnemy.Phase.TELEGRAPH)
		await frames(20)
		await shot("09b_speeder_lane")
	if want("three"):
		await fresh()
		await at(206.0)
		spawn("Turret", 0)
		spawn("Probe", 1, 5.6)
		spawn("Wasp", 2, 3.0, {"sting_shots": 2})
		await live_until(3.0)
		await shot("10_three_threats")
	if want("four"):
		await fresh()
		await at(296.0)
		spawn("Walker", 0)
		spawn("EyeDrone", 1, 5.8)
		spawn("Wasp", 2, 3.0, {"sting_shots": 2, "overload_enabled": true})
		spawn("Probe", 3, 4.6)
		await live_until(4.0)
		await shot("11_four_threat_peak")
	if want("frog"):
		await fresh()
		await at(188.0, 5.4)
		stage.scroll_speed = 2.0
		stage.set_physics_process(true)
		wave.director_moment.emit(&"scale_event")
		var frog_event := stage.get_node("ScaleEvent") as BeeLevel01ScaleEvent
		await live_until(8.0, func(): return frog_event._phase == &"snap")
		await frames(10)
		await shot("12_frog_corrected")
		stage.scroll_speed = 0.0
	if want("leaves"):
		await fresh()
		await at(30.0, 3.6)
		await frames(200)
		await shot("13_dry_leaves")
	if want("power"):
		await fresh()
		await at(331.0, 3.8)
		wave.director_moment.emit(&"preboss_power")
		await frames(26)
		await shot("14_s_plus")
	if want("boss"):
		await fresh()
		await at(340.0)
		wave.event_index = BeeLevel01Controller.EVENTS.size()
		wave.set_physics_process(true)
		await live_until(15.0, func(): return wave.boss != null and wave.boss.state == UfoBoss01.State.PHASE_1 and wave.boss._state_time > 3.0)
		await shot("15_boss_phase1")
		wave.boss.health.take_damage(wave.boss.health.current_health - int(wave.boss.max_hp * 0.6))
		await live_until(8.0, func(): return wave.boss.state == UfoBoss01.State.PHASE_2 and str(wave.boss._attack_step) == "summon" and wave.boss._attack_left < 0.4)
		await shot("16_boss_summon")
		await live_until(6.0, func(): return wave.boss.minions_alive >= 2 and wave.boss.live_projectiles().size() >= 3)
		await shot("17_boss_phase2")
		wave.boss.health.take_damage(wave.boss.health.current_health - int(wave.boss.max_hp * 0.3))
		await live_until(8.0, func(): return wave.boss.state == UfoBoss01.State.PHASE_3 and wave.boss.live_projectiles().size() >= 5)
		await shot("18_boss_phase3")
	quit(0)
