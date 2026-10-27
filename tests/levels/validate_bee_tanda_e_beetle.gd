extends SceneTree
## Tanda E · ETAPA 3 - the stag beetle fires as soon as it has walked on screen: first grenade <= 1.5 s after it materialises, then a slow
## reload (4-5 s launch to launch), two weapons that alternate (QUAKE: big ground shockwave / FAN: 3 aimed shots), brown-orange colours,
## 0.5 s warning, at most two attackers, HP unchanged.
var failures := 0
var grenades: Array[BeetleGrenade] = []
var launch_times: Array[float] = []
var records: Array[Dictionary] = [] ## one per landed grenade, read while it is alive
var kinds: Array[StringName] = []
var clock := 0.0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _added(node: Node) -> void:
	if node is BeetleGrenade:
		grenades.append(node)
		launch_times.append(clock)
		kinds.append(node.kind)
func run() -> void:
	Engine.time_scale = 2.0
	var stage := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	for i in 4: await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.distance = 200
	stage._update_camera_and_bounds()
	stage.bee.global_position = Vector3(195, 3, 0)
	stage.bee.health.damage_blocked = true
	node_added.connect(_added, CONNECT_DEFERRED)
	stage.wave._spawn({"family": "StagBeetle", "slot": 0, "event": 0, "hard": false})
	var beetle := stage.wave.active_units.back() as AssetFauna
	check(beetle.health.max_health == BeeGameSettings.scaled_hp(BeeLevel01Controller.level_hp("StagBeetle")), "HP unchanged")
	var cannon: BeetleCannon = null
	for child in beetle.get_children():
		if child is BeetleCannon: cannon = child
	check(cannon != null, "The beetle carries its cannon")
	# materialised = active, not teleporting and inside the frame
	var cam: Camera3D = stage.camera
	var half := BeeLevel01Framing.half_width_min(BeeLevel01Framing.view_aspect(root))
	var visible_at := -1.0
	var max_slots := 0
	var waves_seen: Array[BeeGroundShockwave] = []
	var spot := func(node: Node):
		if node is BeeGroundShockwave: waves_seen.append(node)
	node_added.connect(spot)
	for frame in 60 * 40:
		await physics_frame
		clock += Engine.time_scale / 60.0
		max_slots = maxi(max_slots, get_nodes_in_group(BeeCommonSlots.GROUP).size())
		for g in grenades:
			if is_instance_valid(g) and g.landed and not g.has_meta("recorded"):
				g.set_meta("recorded", true)
				var wave_data: Array = g.waves.map(func(w): return {"damage": w.hitbox.damage, "height": w.height, "width": w.width, "foot": w.foot_color, "crown": w.crown_color})
				var shard_data: Array = g.shards.map(func(s): return {"damage": s.damage, "velocity": s.velocity, "rim": s.RIM, "core": s.CORE})
				records.append({"kind": g.kind, "waves": wave_data, "shards": shard_data})
		if visible_at < 0.0 and beetle.is_active() and not bool(beetle.get_meta("teleporting", false)) and absf(beetle.global_position.x - cam.global_position.x) <= half - BeetleCannon.SCREEN_MARGIN:
			visible_at = clock
	check(visible_at >= 0.0, "The beetle walked into the frame")
	check(grenades.size() >= 4 and records.size() >= 2, "It fired at least 4 grenades in 40 s (%d)" % grenades.size())
	if grenades.size() >= 1:
		var first := launch_times[0] - visible_at
		check(first <= 1.5, "First grenade <= 1.5 s after materialising (%.2f s)" % first)
		print("TANDA_E_BEETLE first_shot=%.2fs" % first)
	for i in range(1, launch_times.size()):
		var gap := launch_times[i] - launch_times[i - 1]
		check(gap >= BeetleCannon.RECHARGE_MIN - 0.25 and gap <= BeetleCannon.RECHARGE_MAX + 2.5, "Reload %.2f s (4-5 s, plus any ram in between)" % gap)
	check(BeetleCannon.RECHARGE_MIN == 4.0 and BeetleCannon.RECHARGE_MAX == 5.0 and BeetleCannon.WARNING == 0.5, "Reload constants")
	for i in kinds.size():
		check(kinds[i] == (BeetleGrenade.KIND_QUAKE if i % 2 == 0 else BeetleGrenade.KIND_FAN), "Weapons alternate (shot %d is %s)" % [i, kinds[i]])
	var quake_checked := false
	var fan_checked := false
	for g in records:
		if g["kind"] == BeetleGrenade.KIND_QUAKE and not quake_checked:
			quake_checked = true
			check(g["waves"].size() == 2, "The quake grenade sends a wave each way")
			for w in g["waves"]:
				check(w["damage"] == BeetleGrenade.WAVE_DAMAGE and BeetleGrenade.WAVE_DAMAGE == 8, "Wave damage 8")
				check(w["height"] >= 2.0 and w["width"] >= 1.4, "BIG wave (%.1f x %.1f m)" % [w["height"], w["width"]])
				check(w["foot"].r > 0.6 and w["foot"].b < 0.2 and w["crown"].r < 0.35 and w["crown"].b < 0.15, "Wave is burnt orange with a dark crown")
		if g["kind"] == BeetleGrenade.KIND_FAN and not fan_checked:
			fan_checked = true
			check(g["shards"].size() == 3, "The fan grenade sheds exactly 3 shots (%d)" % g["shards"].size())
			for s in g["shards"]:
				check(s["damage"] == BeetleGrenade.FAN_DAMAGE, "Shot damage")
				check(s["rim"].r > 0.6 and s["rim"].b < 0.2 and s["core"].r < 0.2, "Shot is burnt orange with a dark core")
			if g["shards"].size() == 3:
				var a0: float = g["shards"][0]["velocity"].angle_to(g["shards"][1]["velocity"])
				var a2: float = g["shards"][2]["velocity"].angle_to(g["shards"][1]["velocity"])
				check(absf(rad_to_deg(a0) - BeetleGrenade.FAN_HALF_ANGLE_DEG) < 0.5 and absf(rad_to_deg(a2) - BeetleGrenade.FAN_HALF_ANGLE_DEG) < 0.5, "Thin fan (+-9 deg)")
	check(quake_checked and fan_checked, "Both weapons landed during the run")
	for t in cannon.warnings: check(absf(t - 0.5) < 0.01, "0.5 s warning")
	check(max_slots <= 2, "At most two attackers (%d)" % max_slots)
	# the wave really hurts Bee for 8 when she stays on the ground
	var wave_node: BeeGroundShockwave = null
	var bee := stage.bee
	beetle.health.take_damage(99999)
	for i in 240: await physics_frame # its own waves and shots die out first
	bee.health.damage_blocked = false
	bee.health.restore_health(100)
	var hp0 := bee.health.current_health
	var test_wave := BeeGroundShockwave.launch(stage, null, 190.0, 205.0, BeetleGrenade.WAVE_DAMAGE, BeetleGrenade.WAVE_SPEED, BeetleGrenade.WAVE_HEIGHT, BeetleGrenade.WAVE_FOOT, BeetleGrenade.WAVE_CROWN, BeetleGrenade.WAVE_WIDTH)
	bee.global_position = Vector3(193.0, 1.0, 0.0)
	for i in 90: await physics_frame
	check(bee.health.current_health == hp0 - BeetleGrenade.WAVE_DAMAGE, "The wave takes 8 HP from a grounded Bee (%d -> %d)" % [hp0, bee.health.current_health])
	for i in 4: await physics_frame
	check(get_nodes_in_group(BeeCommonSlots.GROUP).is_empty(), "Liberation releases the attack slots")
	Engine.time_scale = 1.0
	print("TANDA_E_BEETLE failures=", failures, " grenades=", grenades.size(), " gaps=", launch_times.size() - 1)
	quit(1 if failures else 0)
