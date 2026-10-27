extends SceneTree

# LEVEL 01 TRANSFORMATION PASS 01 — PHASE C: CONTROLLED FAUNA (the dragonfly).
#   Only the implant has health; LOTE 9: a body shot damages it at 1x, a direct implant hit at 2x (was: neutral body).
#   Auto-aim targets the implant (generous hurtbox). Implant HP gives ~1.5-2.5 s of reasonable Base fire.
#   Up to 3 broad passes, each locked at the telegraph (no homing), contact only during the pass.
#   Breaking the implant liberates the dragonfly at once: attack cancelled, device off, glow off, natural colours,
#   free flight away, no corpse. First appearance alone at X~124 with a one-off hint; at most 3 in Level 01.
#   Checkpoint: a dragonfly freed before X=190 never comes back after a respawn (no farming); full restart restores it.
# Dev filter: -- only=static|body|aim|passes|liberation|checkpoint

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var only := ""

func _initialize() -> void:
	BeeLevel01Controller.roster_only = false # LOTE 12: this test covers the pre-roster flow (alien enemies, frog, UFO), which stays intact behind LEVEL01_ROSTER_ONLY.
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

func arena(distance := 120.0) -> void:
	for unit in wave.active_units.duplicate():
		wave.active_units.erase(unit)
		unit.queue_free()
	stage.scroll_speed = 0.0
	stage.distance = distance
	stage._update_camera_and_bounds()
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.current_health = bee.health.max_health
	bee.health.damage_blocked = true
	bee.global_position = Vector3(stage.camera.global_position.x - 3.0, 3.6, 0)
	bee.facing_x = 1.0
	await frames(3)

func spawn_dragonfly(slot := 0) -> ControlledDragonfly:
	wave._spawn({"family": "Dragonfly", "slot": slot, "event": 0, "hard": false})
	var fly := wave.active_units.back() as ControlledDragonfly
	fly.max_passes = 3 # LOTE 7: Level 01 keeps it until CAMERA_TIME (99 passes); the 3-pass pattern is what is tested here.
	return fly

func wait_state(fly: ControlledDragonfly, wanted: int, limit := 600) -> bool:
	for i in limit:
		if fly.state == wanted:
			return true
		await physics_frame
	return false

func albedo(fly: ControlledDragonfly, part: String) -> Color:
	return (fly._body_materials[part] as ShaderMaterial).get_shader_parameter("albedo")

# --- placement ------------------------------------------------------------------------------------------

func test_static() -> void:
	var placements: Array = []
	for event: Dictionary in BeeLevel01Controller.EVENTS_LEGACY:
		if "Dragonfly" in event["units"]:
			placements.append(event)
	check(placements.size() >= 2 and placements.size() <= 3, "Level 01 must have 2-3 dragonflies (%d)" % placements.size())
	check(float(placements[0]["at"]) >= 118.0 and float(placements[0]["at"]) <= 130.0 and placements[0]["units"] == ["Dragonfly"], "The first dragonfly must appear alone at X~124, before the Giant Human")
	check(float(placements[1]["at"]) > 190.0, "The second dragonfly must be after the checkpoint (light combination)")
	check(int(BeeLevel01Controller.LEVEL_HP["Dragonfly"]) > 0, "Implant HP missing")
	print("FAUNA_STATIC placements=%s" % str(placements.map(func(e): return "%.0f:%s" % [e["at"], str(e["units"])])))

# --- the body is not the target ----------------------------------------------------------------------------

func test_body() -> void:
	await arena()
	var fly := spawn_dragonfly()
	check(fly.health.max_health == int(BeeLevel01Controller.LEVEL_HP["Dragonfly"]), "Implant HP not set by the level")
	check(fly.find_children("*", "HealthComponent", true, false).size() == 1, "Only the implant holds health (LOTE 9: the body damages it at 1x)")
	await wait_state(fly, ControlledDragonfly.State.HOVER)
	fly.set_physics_process(false) # Hold still for exact body shots.
	await frames(2)
	var implant_hp := fly.health.current_health
	# Shoot the abdomen tip (far from the implant): absorbed with neutral feedback, no damage anywhere.
	var tip := fly.get_node("VisualRoot/Body/Abdomen") as Node3D
	var aim_point := tip.global_position + (tip.global_transform.basis.y.normalized() * 1.4)
	aim_point.z = 0.0
	# From behind the animal, so the abdomen is the first thing the shot meets.
	bee.global_position = Vector3(aim_point.x + 2.5, aim_point.y, 0)
	bee.facing_x = -1.0
	var shot := bee._spawn_projectile(Vector3.LEFT)
	for i in 30:
		await physics_frame
		if not is_instance_valid(shot):
			break
	# LOTE 9: a body hit damages the implant at 1x (it was absorbed with a neutral puff); the animal is still never killed.
	check(implant_hp - fly.health.current_health == 10 and fly.body_absorbed >= 1 and not is_instance_valid(shot), "A body shot must damage the implant at 1x (%d)" % (implant_hp - fly.health.current_health))
	check(fly.is_active() and not fly.liberated, "One body shot must not free it")
	print("FAUNA_BODY body_hits=%d implant_hp=%d (-10, 1x)" % [fly.body_absorbed, fly.health.current_health])
	fly.set_physics_process(true)

# --- auto-aim and implant HP ---------------------------------------------------------------------------------

func test_aim() -> void:
	await arena()
	var fly := spawn_dragonfly()
	await wait_state(fly, ControlledDragonfly.State.HOVER)
	var picked := bee.refresh_auto_aim()
	check(picked == fly and bee._target_point(fly).distance_to(fly.hurtbox.global_position) < 0.01, "Auto-aim must pick the dragonfly and aim at its implant")
	check((fly.hurtbox.get_node("CollisionShape3D").shape as SphereShape3D).radius >= 0.45, "Implant hurtbox too small (pixel hunting)")
	# Reasonable Base fire (3.3 Hz) while following its height: time from the first hit to the liberation.
	var first_hit := -1.0
	var time := 0.0
	var next := 0.0
	while time < 8.0 and not fly.liberated:
		bee.global_position.y = move_toward(bee.global_position.y, clampf(fly.hurtbox.global_position.y, 1.0, 6.4), bee.vertical_speed / 60.0 * 0.8)
		if time >= next:
			bee.fire()
			next += 1.0 / 3.3
		await physics_frame
		time += 1.0 / 60.0
		if first_hit < 0.0 and fly.health.current_health < fly.health.max_health:
			first_hit = time
	check(fly.liberated, "Reasonable Base fire did not free the dragonfly in 8 s")
	var ttk := time - first_hit
	check(ttk >= 1.2 and ttk <= 3.0, "Implant breaks in %.2f s of fire (target ~1.5-2.5 s)" % ttk)
	print("FAUNA_AIM autoaim=implant hp=%d break_time=%.2fs body_absorbed=%d" % [fly.health.max_health, ttk, fly.body_absorbed])

# --- passes ------------------------------------------------------------------------------------------------

func test_passes() -> void:
	await arena()
	var fly := spawn_dragonfly()
	var passes := 0
	var hitbox_outside_pass := false
	var homing := false
	var locked_to := Vector3.ZERO
	var telegraph_seen := false
	for i in 60 * 24:
		bee.global_position.y = 3.6 + sin(float(i) / 60.0 * 1.8) * 1.2 # Bee keeps moving: the pass must not follow her.
		await physics_frame
		if fly.state == ControlledDragonfly.State.TELEGRAPH:
			telegraph_seen = true
		if fly.state == ControlledDragonfly.State.PASS:
			if locked_to == Vector3.ZERO:
				locked_to = fly._pass_to
				passes += 1
			homing = homing or not fly._pass_to.is_equal_approx(locked_to)
		else:
			locked_to = Vector3.ZERO
			hitbox_outside_pass = hitbox_outside_pass or fly.pass_hitbox.enabled
		if fly.state == ControlledDragonfly.State.EXIT:
			break
	check(telegraph_seen and passes == 3 and fly.passes_done == 3, "The dragonfly must telegraph and make 3 passes (%d)" % passes)
	check(not homing, "A pass changed its target mid-flight (homing)")
	check(not hitbox_outside_pass, "Contact damage outside a pass")
	check(fly.state == ControlledDragonfly.State.EXIT, "The dragonfly must leave (still controlled) after its passes")
	print("FAUNA_PASSES passes=3 locked=OK contact_only_in_pass=OK exit=OK")

# --- liberation ----------------------------------------------------------------------------------------------

func test_liberation() -> void:
	await arena()
	var fly := spawn_dragonfly()
	check(albedo(fly, "thorax").is_equal_approx((ControlledDragonfly.NATURAL["thorax"] as Color).lerp(ControlledDragonfly.CONTROLLED_TINT, 0.6)), "Controlled tint missing")
	await wait_state(fly, ControlledDragonfly.State.PASS, 900)
	check(fly.pass_hitbox.enabled, "Pass hitbox not active during the pass")
	var defeated := [false]
	fly.defeated.connect(func(_unit): defeated[0] = true)
	fly.health.take_damage(fly.health.max_health) # Break the implant in the middle of the attack.
	await frames(2)
	check(fly.liberated and fly.state == ControlledDragonfly.State.LIBERATED and not fly.pass_hitbox.enabled, "Liberation must cancel the attack at once")
	check(not fly.is_in_group("bee_auto_aim_targets") and not fly.is_active(), "A freed dragonfly is still a target")
	check(float(fly._core_material.get_shader_parameter("emission_energy")) == 0.0, "The alien glow must die")
	var neighbours := wave.active_units.size()
	await frames(60)
	check(not fly.implant.visible or fly.implant.scale.x < 0.5, "The implant did not crack off")
	check(albedo(fly, "thorax").is_equal_approx(ControlledDragonfly.NATURAL["thorax"]), "Natural colours did not return")
	check(is_instance_valid(fly) and fly.visible, "No explosion of the animal: it must fly away")
	for i in 200:
		if defeated[0]:
			break
		await physics_frame
	check(defeated[0], "The liberation never finished")
	check(neighbours >= 0, "")
	print("FAUNA_LIBERATION cancel=OK device_off=OK glow_off=OK natural_colours=OK fly_away=OK")

# --- hint, checkpoint and restart ---------------------------------------------------------------------------

func test_checkpoint() -> void:
	# Real flow to the first appearance: one dragonfly with its hint, alongside the new patrols.
	stage.distance = 120.0
	stage._update_camera_and_bounds()
	wave.event_index = 0
	while wave.event_index < BeeLevel01Controller.EVENTS_LEGACY.size() and float(BeeLevel01Controller.EVENTS_LEGACY[wave.event_index]["at"]) < 120.0:
		wave.event_index += 1
	wave.set_physics_process(true)
	stage.scroll_speed = 2.0
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	var fly: ControlledDragonfly
	for i in 600:
		await physics_frame
		for unit in wave.active_units:
			if unit is ControlledDragonfly:
				fly = unit
		if fly != null:
			break
	check(fly != null and wave.active_units.filter(func(unit): return unit is ControlledDragonfly).size() == 1, "The first encounter must introduce exactly one dragonfly")
	check(wave.alive_count() <= BeeLevel01Controller.MAX_ON_SCREEN, "Dragonfly escort exceeds route cap")
	check(wave.player_label == BeeLevel01Controller.FAUNA_HINT, "One-off hint missing")
	fly.health.take_damage(9999)
	await frames(10)
	# Checkpoint after it: a respawn never brings it back.
	stage.distance = 190.05
	wave.set_physics_process(false)
	stage.checkpoint.activate_checkpoint()
	var old := stage
	stage.checkpoint.restart_level(false)
	await reloaded(old)
	bind(current_scene)
	for event_index in range(wave.event_index):
		check(not ("Dragonfly" in BeeLevel01Controller.EVENTS_LEGACY[event_index]["units"]) or float(BeeLevel01Controller.EVENTS_LEGACY[event_index]["at"]) < 190.0, "")
	var first_after := -1
	for event_index in range(wave.event_index, BeeLevel01Controller.EVENTS_LEGACY.size()):
		if "Dragonfly" in BeeLevel01Controller.EVENTS_LEGACY[event_index]["units"]:
			first_after = event_index
			break
	check(first_after > 0 and float(BeeLevel01Controller.EVENTS_LEGACY[first_after]["at"]) > 190.0, "Only the post-checkpoint dragonfly may remain after a respawn")
	check(wave.fauna_hint_shown, "The hint must not repeat after a checkpoint respawn")
	# Full restart: the first dragonfly is back (event table from zero) and the hint shows again.
	var old2 := stage
	stage.checkpoint.restart_level(true)
	await reloaded(old2)
	bind(current_scene)
	check(wave.event_index == 0 and not wave.fauna_hint_shown, "Full restart must restore the first dragonfly and its hint")
	print("FAUNA_CHECKPOINT introduction=OK escort_cap=OK hint=OK no_farming=OK restart=OK")

func run() -> void:
	create_timer(420.0, true, false, true).timeout.connect(func(): quit(1))
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_children().filter(func(n): return n.name != "SceneFade").back() # Tanda E: the scene-fade cover is added after the level
	await frames(5)
	bind(current_scene)
	if wants("static"):
		test_static()
	if wants("body"):
		await test_body()
	if wants("aim"):
		await test_aim()
	if wants("passes"):
		await test_passes()
	if wants("liberation"):
		await test_liberation()
	if wants("checkpoint"):
		if only.is_empty(): # Fresh level: earlier sections already showed the one-off hint.
			var old := stage
			stage.checkpoint.restart_level(true)
			await reloaded(old)
			bind(current_scene)
		await test_checkpoint()
	print("BEE_CONTROLLED_FAUNA_V01_OK")
	quit(0)
