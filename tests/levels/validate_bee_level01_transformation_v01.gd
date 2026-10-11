extends SceneTree

# LEVEL 01 TRANSFORMATION PASS 01 — end to end (structure, never "fun").
#   escalation  nature before the checkpoint, alien pylons only after it; contaminated garden with a shootable
#               control device that frees the flower; the last silence (shadow + hum) before the unchanged UFO
#   run         the whole level with a fast harness: acts 1-5, director moments in order, formation heights on entry,
#               both dragonflies liberated (never "killed"), destructibles intact, Giant Human crossed once,
#               no hostile shot born off screen, threat cap, UFO 500 HP, Level Complete
#   checkpoint  resume in act 3 after X=190 without the first dragonfly, Giant Human or earlier moments
# Dev filter: -- only=escalation|run|checkpoint

## LOTE 9 · ETAPA C: the NODO ALIEN has 1200 HP and 4 phases (was 500 HP, 3 phases).
const BOSS_HP := 1200
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var only := ""

func _initialize() -> void:
	BeeLevel01Controller.giant_human_enabled = true # NOCHE 01: the human is off in the game (GIANT_HUMAN_ENABLED); this test covers it.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			only = arg.substr(5)
	call_deferred("run")

func wants(section: String) -> bool:
	return only.is_empty() or only == section

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func bind(value: Node) -> void:
	stage = value as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee

func reloaded(old: Node) -> void:
	for i in 120:
		await process_frame
		if current_scene != null and current_scene != old and current_scene.is_node_ready():
			break
	await frames(3)

func fresh() -> void:
	var old := stage
	stage.checkpoint.restart_level(true)
	await reloaded(old)
	bind(current_scene)

# --- alien escalation ------------------------------------------------------------------------------------

func test_escalation() -> void:
	var escalation := stage.get_node("AlienEscalation") as BeeLevel01AlienEscalation
	check(escalation != null and escalation.pylons.size() >= 6, "Alien escalation dressing missing")
	for pylon in escalation.pylons:
		check(pylon.global_position.x > 190.0 and pylon.global_position.z < -3.0, "Alien pylons must appear after the checkpoint and behind the flight plane")
	check(escalation.pylons.back().scale.x > escalation.pylons[0].scale.x, "The alien presence should grow towards the sunset")
	# Contaminated garden: the device in Bee's plane can be shot; the flower recovers.
	check(not escalation.flower_freed and escalation.device_hurtbox.monitorable, "Device must start active")
	stage.scroll_speed = 0.0
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	stage.distance = escalation.device.global_position.x - 2.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(escalation.device.global_position.x - 2.6, escalation.device.global_position.y, 0)
	bee.facing_x = 1.0
	await frames(3)
	for i in 4:
		bee._spawn_projectile(Vector3.RIGHT)
		await frames(14)
	check(escalation.flower_freed and not escalation.device.visible or escalation.device.position.y < 1.0, "Shooting the control device must free the flower")
	# The last silence: shadow + hum, then the unchanged reveal.
	check(BeeLevel01Controller.BOSS_BREATHER >= 2.0, "The last silence needs a little time before the reveal")
	wave.director_moment.emit(&"last_silence")
	await frames(5)
	check(escalation.silence_played and is_instance_valid(escalation.ufo_shadow) and is_instance_valid(escalation.hum), "Last silence: no UFO shadow or hum")
	var shadow_x := escalation.ufo_shadow.global_position.x
	await frames(30)
	check(escalation.ufo_shadow.global_position.x < shadow_x - 1.0, "The UFO shadow must sweep across the garden")
	print("TRANSFORMATION_ESCALATION pylons=%d device_freed=OK shadow=OK hum=OK" % escalation.pylons.size())

# --- whole level -----------------------------------------------------------------------------------------

func test_run() -> void:
	var moments: Array[String] = []
	wave.director_moment.connect(func(id: StringName): moments.append(str(id)))
	var liberated := [0]
	var killed_fauna := [0]
	bee.set_physics_process(false)
	bee.hurtbox.monitorable = false
	Engine.time_scale = 3.0
	var seen := {}
	var heights_ok := 0
	var heights_checked := 0
	var offscreen_births := 0
	var seen_shots := {}
	var acts := {}
	var rocks_before := get_nodes_in_group("breakable_rocks").size()
	for frame in 30000:
		await physics_frame
		bee.global_position = Vector3(stage.distance - 4.8, 7.0, 0)
		acts[wave.current_act] = true
		var cap := BeeLevel01Controller.MAX_ON_SCREEN_ARENA if wave.in_arena() else BeeLevel01Controller.threat_cap(stage.distance)
		check(wave.active_units.size() <= cap, "Threat cap exceeded")
		var camera_x := stage.camera.global_position.x
		for shot in get_nodes_in_group("alien_projectiles"):
			var id := shot.get_instance_id()
			if shot is AlienMortarShell:
				continue # LOTE 6: the shell node itself rests at the origin (its parts are top-level); the turret fires it from on screen.
			if not seen_shots.has(id):
				seen_shots[id] = true
				if absf((shot as Node3D).global_position.x - camera_x) > 7.0:
					offscreen_births += 1
		for unit in wave.active_units.duplicate():
			if CinematicDepthEntry.is_in_depth(unit):
				continue # REBUILD 02: formation heights are checked once the unit reaches the flight plane.
			var id: int = unit.get_instance_id()
			if not seen.has(id):
				seen[id] = wave._clock
				var parts := str(unit.name).split("_")
				var event: Dictionary = BeeLevel01Controller.EVENTS[int(parts[1])]
				var slot := int(parts[2])
				var planned: Array = event.get("y", [])
				# The spider drops in from above the top edge (GARDEN IDENTITY 04): no formation height, like ground units.
				if slot < planned.size() and str(parts[0]) not in ["Turret", "Walker", "Spider"]:
					heights_checked += 1
					if absf((unit as Node3D).global_position.y - minf(float(planned[slot]), BeeLevel01Framing.max_entity_y())) < 0.5:
						heights_ok += 1
				if unit is ControlledDragonfly:
					(unit as ControlledDragonfly).liberated_now.connect(func(_u): liberated[0] += 1)
			var full: bool = wave.active_units.size() >= cap
			if (wave._pending.is_empty() or full) and wave._clock - float(seen[id]) > 2.0:
				unit.get_node("HealthComponent").take_damage(9999)
		if wave._waiting_for_human:
			bee.global_position = Vector3(stage.distance - 5.1, 7.0, 0)
		if wave.boss != null and wave.boss.is_active():
			check(wave.boss.max_hp == BOSS_HP, "UFO HP changed")
			wave.boss.health.take_damage(99999)
		if stage.sector_complete:
			break
	Engine.time_scale = 1.0
	check(stage.sector_complete and stage.status.text.begins_with("SECTOR DESPEJADO"), "Level Complete missing")
	check(acts.size() == 5, "Not every act was reached: " + str(acts.keys()))
	check(moments == ["opening_can", "human_aftermath", "walker_showcase", "scale_event", "contaminated_garden", "bomb_reward", "preboss_power", "last_silence"], "Director moments out of order: " + str(moments))
	check(heights_checked >= 10 and heights_ok == heights_checked, "Formation heights not applied (%d/%d)" % [heights_ok, heights_checked])
	check(liberated[0] == 2, "Both dragonflies must be liberated, never killed (%d)" % liberated[0])
	check(offscreen_births == 0, "%d hostile shots were born off screen" % offscreen_births)
	check(wave.human.crossings_exited == 1, "The Giant Human must cross exactly once")
	check(get_nodes_in_group("breakable_rocks").size() == rocks_before and stage.get_node("Destructibles").get_child_count() == 8, "Destructibles changed")
	print("TRANSFORMATION_RUN acts=5 moments=%d formations_y=%d/%d dragonflies_freed=%d offscreen=0 complete=OK" % [moments.size(), heights_ok, heights_checked, liberated[0]])

# --- checkpoint ------------------------------------------------------------------------------------------

func test_checkpoint() -> void:
	stage.distance = 190.05
	stage.checkpoint.activate_checkpoint()
	var old := stage
	stage.checkpoint.restart_level(false)
	await reloaded(old)
	bind(current_scene)
	check(wave.current_act == 3 and wave.fauna_hint_shown, "Checkpoint must resume in act 3 with the fauna lesson learnt")
	for index in range(wave.event_index, BeeLevel01Controller.EVENTS.size()):
		var event: Dictionary = BeeLevel01Controller.EVENTS[index]
		check(float(event["at"]) >= 190.0, "An event before the checkpoint would replay")
		check(str(event.get("moment", "")) != "opening_can" and str(event.get("moment", "")) != "human_aftermath", "An earlier moment would replay")
	check(wave.human.current_phase == GiantHumanCrossingHazard.Phase.EXITED, "The Giant Human must not repeat")
	print("TRANSFORMATION_CHECKPOINT act=3 no_replays=OK")

func run() -> void:
	create_timer(600.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	bind(current_scene)
	if wants("escalation"):
		await test_escalation()
		if only.is_empty():
			await fresh()
	if wants("checkpoint"):
		await test_checkpoint()
		if only.is_empty():
			await fresh()
	if wants("run"):
		await test_run()
	print("BEE_LEVEL01_TRANSFORMATION_V01_OK")
	quit(0)
