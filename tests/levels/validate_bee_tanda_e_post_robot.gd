extends SceneTree
## Tanda E · ETAPA 1 - regression: after the walking robot falls (gate X=294) the tarantula must enter in < 12 s whatever is left
## on the field (escorts alive, only escorts, everything dead, Bee hurt), the escorts fall with the robot, the gate's pending
## requests are dropped, the safety net forces the sequence at 8 s, and the supplies (Spread, Bomb) are in view.
const MAX_SECONDS := 12.0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func make_stage() -> BeeShmupStage:
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 293.0
	stage._update_camera_and_bounds()
	(stage.wave as BeeLevel01Controller).resume_after_checkpoint(293.0)
	stage.bee.global_position = Vector3(stage.camera.global_position.x - 2.0, 3.0, 0)
	return stage
func run_case(mode: String) -> void:
	var stage := await make_stage()
	var wave := stage.wave as BeeLevel01Controller
	stage.bee.health.damage_blocked = true
	if mode == "hurt": stage.bee.health.current_health = maxi(1, stage.bee.health.max_health / 5)
	var guard := 0
	while wave.miniboss == null and guard < 60 * 10:
		await physics_frame
		guard += 1
	check(wave.miniboss != null, "%s: robot spawned" % mode)
	for i in 60 * 7: await physics_frame # the escorts walk in
	var escorts := 0
	for u in wave.active_units:
		if is_instance_valid(u) and not u is WalkerMiniboss: escorts += 1
	check(escorts >= 2, "%s: the escorts are on the field (%d)" % [mode, escorts])
	if mode == "only_escorts":
		for u in wave.active_units.duplicate():
			if is_instance_valid(u) and not u is WalkerMiniboss: u.get_node("HealthComponent").take_damage(99999)
		for i in 30: await physics_frame
	if mode == "queued":
		wave._queue_units({"units": ["Wasp", "Wasp"], "delays": [30.0, 31.0]}, 0, 300) # still pending when the robot falls
	if mode == "hurt": stage.bee.health.damage_blocked = false
	wave.miniboss.get_node("HealthComponent").take_damage(99999)
	if mode == "all":
		for u in wave.active_units.duplicate():
			if is_instance_valid(u) and not u is WalkerMiniboss: u.get_node("HealthComponent").take_damage(99999)
	check(wave._pending.is_empty(), "%s: pending gate requests dropped on the robot's death" % mode)
	var frames := 0
	while wave.tarantula == null and frames < 60 * 20:
		await physics_frame
		frames += 1
	var seconds := frames / 60.0 * Engine.time_scale
	check(wave.tarantula != null and seconds < MAX_SECONDS, "%s: tarantula enters in %.1f s (< %.0f s)" % [mode, seconds, MAX_SECONDS])
	check(wave.active_units.is_empty() or wave.active_units.all(func(u): return not is_instance_valid(u) or u is TarantulaBoss01), "%s: no escort left behind" % mode)
	# supplies in view once the advance ends
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(root))
	var cam_x := stage.camera.global_position.x
	var in_view := 0
	for item in stage.get_children():
		if item is BeePowerupPickup and absf(item.global_position.x - cam_x) <= half: in_view += 1
	check(in_view >= 2, "%s: Spread and Bomb medallions are in view (%d)" % [mode, in_view])
	var recharge := stage.get_node("Powerups/BombRecharge") as Node3D
	check(absf(recharge.global_position.x - cam_x) <= half, "%s: BombRecharge reachable on the final screen" % mode)
	print("TANDA_E_POST_ROBOT mode=%s tarantula_in=%.1fs" % [mode, seconds])
	stage.queue_free()
	await physics_frame
func run() -> void:
	Engine.time_scale = 3.0
	for mode in ["escorts", "only_escorts", "all", "hurt", "queued"]:
		await run_case(mode)
	# the safety net on its own: an escort that cannot die (stuck inert) is released at 8 s
	var stage := await make_stage()
	var wave := stage.wave as BeeLevel01Controller
	stage.bee.health.damage_blocked = true
	while wave.miniboss == null: await physics_frame
	for i in 60 * 7: await physics_frame
	var stuck := wave.active_units.filter(func(u): return is_instance_valid(u) and not u is WalkerMiniboss)[0] as Node3D
	var hp := stuck.get_node("HealthComponent") as HealthComponent
	hp.invulnerable = true # nothing can kill it
	wave.miniboss.get_node("HealthComponent").take_damage(99999)
	var frames := 0
	while wave.tarantula == null and frames < 60 * 20:
		await physics_frame
		frames += 1
	check(wave.tarantula != null and frames / 60.0 * Engine.time_scale < MAX_SECONDS, "Safety net: stuck escort, tarantula enters in %.1f s" % (frames / 60.0 * Engine.time_scale))
	print("TANDA_E_SAFETY_NET tarantula_in=%.1fs" % (frames / 60.0 * Engine.time_scale))
	Engine.time_scale = 1.0
	print("TANDA_E_POST_ROBOT failures=", failures)
	quit(1 if failures > 0 else 0)
