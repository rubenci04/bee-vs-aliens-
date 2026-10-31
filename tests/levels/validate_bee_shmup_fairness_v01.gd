extends SceneTree

# BEE SHMUP FAIRNESS PASS 01: Bee lethal volume vs her silhouette, enemy projectile volume vs its
# visible core, no off-screen / rear fire, projectile readability, and Bomb staying offensive only.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const BEE := preload("res://scenes/bee_prototype/bee_player.tscn")
const PROJECTILE := preload("res://scenes/bee_prototype/alien_enemy_projectile.tscn")

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer
var total_shots := 0
var fired_unreadable := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func spawn(family: String, x: float, y: float) -> Node3D:
	wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false})
	var unit: Node3D = wave.active_units.back()
	preload("res://tests/levels/bee_teleport_fixture.gd").finish(unit)
	unit.global_position = Vector3(x, y, 0)
	unit.set_physics_process(false) # Direct fire calls below; the playtest re-enables AI.
	return unit

func fire(unit: Node3D) -> void:
	if unit is GroundWalkerEnemy:
		unit._fire_projectile()
	elif unit is EyeDroneEnemy:
		unit._shoot_at_bee()
	else:
		unit._shoot()

func on_fired(_projectile: Node, unit: Node3D) -> void:
	total_shots += 1
	if not BeeShmupFairness.is_readable(unit):
		fired_unreadable += 1

func run() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func(): quit(1))

	# 1. Bee: lethal volume is smaller than her silhouette but not tiny; body collision unchanged.
	var lone := BEE.instantiate() as BeePlayer
	root.add_child(lone)
	await process_frame
	var visual := lone.get_node("VisualRoot") as Node3D
	visual.rotation = Vector3.ZERO
	var body_box := AABB()
	var first := true
	for mesh: MeshInstance3D in visual.find_children("*", "MeshInstance3D", true, false):
		if str(mesh.name).begins_with("Wing"):
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		body_box = box if first else body_box.merge(box)
		first = false
	body_box.size /= visual.scale.x / BeeGameSettings.BEE_VISUAL_SCALE # Tanda S: Bee is drawn bigger on purpose with the same hurtbox; judge it against the unscaled silhouette.
	var hurt_radius := ((lone.get_node("Hurtbox3D/CollisionShape3D") as CollisionShape3D).shape as SphereShape3D).radius
	check(is_equal_approx(((lone.get_node("CollisionShape3D") as CollisionShape3D).shape as SphereShape3D).radius, 0.28), "Bee body collision changed")
	check(hurt_radius < 0.28 and hurt_radius * 2.0 < body_box.size.y and hurt_radius * 2.0 >= body_box.size.y * 0.5, "Bee lethal volume out of range: diameter %.2f vs silhouette height %.2f" % [hurt_radius * 2.0, body_box.size.y]) # v02 adds a taller head/armor silhouette while the approved hurtbox stays unchanged.
	check(lone.health.max_health == 100, "Bee HP changed")
	lone.queue_free()

	# 2. Enemy projectile: lethal sphere below the visible core; damage and speed untouched.
	var projectile := PROJECTILE.instantiate() as AlienEnemyProjectile
	root.add_child(projectile)
	await process_frame
	var core := (projectile.get_node("Visual") as MeshInstance3D).mesh as SphereMesh
	var lethal := ((projectile.get_node("Hitbox3D/CollisionShape3D") as CollisionShape3D).shape as SphereShape3D).radius
	check(lethal < core.radius and lethal >= core.radius * 0.55, "Projectile lethal radius %.2f vs visible %.2f" % [lethal, core.radius])
	check(projectile.damage == 8 and is_equal_approx(projectile.speed, 6.0) and is_equal_approx(projectile.lifetime, 2.5), "Projectile damage/speed changed")
	var material := core.material as StandardMaterial3D
	check(material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and material.render_priority >= 50, "Projectile must draw over VFX")
	check(projectile.is_in_group("alien_projectiles"), "Projectile group missing")
	projectile.queue_free()

	# 3. Level 01 set-up (frozen scroll; enemies are driven by the test).
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await frames(3)
	wave = stage.wave as BeeLevel01Controller
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	bee = stage.bee
	bee.set_physics_process(false)
	stage.distance = 100.0
	stage._update_camera_and_bounds()
	await frames(3)
	var camera_x := stage.camera.global_position.x
	var half := BeeShmupFairness.visible_half_width(stage.camera, Vector3(camera_x, 3.0, 0.0), BeeLevel01Framing.view_aspect(root))
	check(half > BeeLevel01Framing.half_width_min(BeeLevel01Framing.DESIGN_ASPECT) - 0.05 and half < BeeLevel01Framing.half_width_max(BeeLevel01Framing.DESIGN_ASPECT) + 0.05, "Unexpected visible half width %.2f" % half) # Camera-aware (REBUILD 03).
	bee.global_position = Vector3(camera_x, 3.0, 0)

	# 4. Off-screen fire and rear ceasefire for every ranged family.
	for spec in [["Probe", 3.0], ["EyeDrone", 3.0], ["Turret", 0.0], ["Walker", 0.0]]:
		for shot in get_nodes_in_group("alien_projectiles"):
			shot.free() # REBUILD 02: each family starts below the Level 01 live-shot ceiling (checked on its own below).
		var unit := spawn(spec[0], camera_x + half - 1.0, spec[1])
		unit.target = bee
		var before: int = unit.projectile_fire_count
		var volley: int = (1 if unit.mortar_mode else maxi(int(unit.get("fan_count")), 1)) if unit is GroundTurretEnemy else 1 # A Turret volley is a fan (pass 02); COMBAT VARIETY 01: one mortar shell in Level 01.
		fire(unit)
		check(unit.projectile_fire_count == before + volley, spec[0] + " must fire when readable")
		unit.global_position.x = camera_x + half + 2.5 # Not entered yet.
		fire(unit)
		check(unit.projectile_fire_count == before + volley and unit.suppressed_shot_count == 1, spec[0] + " fired from the right, outside the screen")
		unit.global_position.x = camera_x - half - 2.5 # Left behind.
		fire(unit)
		check(unit.projectile_fire_count == before + volley and unit.suppressed_shot_count == 2, spec[0] + " fired from behind, outside the screen")
		unit.global_position.x = camera_x - half + 1.0
		fire(unit)
		check(unit.projectile_fire_count == before + 2 * volley, spec[0] + " must fire again once readable")
		# Entry margin: the centre must be clearly inside the edge.
		unit.global_position.x = camera_x + half - BeeShmupFairness.ENTRY_MARGIN + 0.1
		fire(unit)
		check(unit.suppressed_shot_count == 3, spec[0] + " fired while only half visible")

	# 4b. ARCADE REBUILD 02: live-shot ceiling (Level 01 units only) and screen-bound combat.
	for node in get_nodes_in_group("alien_projectiles"):
		node.free()
	check(BeeShmupFairness.live_shot_ceiling == BeeLevel01Controller.LIVE_SHOT_CEILING and BeeShmupFairness.screen_bound_combat, "Level 01 rules not set")
	for i in BeeLevel01Controller.LIVE_SHOT_CEILING:
		var filler := PROJECTILE.instantiate() as AlienEnemyProjectile
		stage.add_child(filler)
		filler.global_position = Vector3(camera_x, 9.0, 0)
		filler.launch(Vector3.LEFT, null)
	var capped := spawn("Probe", camera_x + 2.0, 3.0)
	capped.target = bee
	capped._fire_one()
	check(capped.projectile_fire_count == 0 and capped.suppressed_shot_count == 1, "A Level 01 unit fired past the live-shot ceiling")
	for node in get_nodes_in_group("alien_projectiles"):
		node.free()
	capped._fire_one()
	check(capped.projectile_fire_count == 1, "Below the ceiling the unit must fire again")
	var outside := spawn("Probe", camera_x + half + 1.5, 3.0) # Not entered yet: never an auto-aim lock.
	outside.target = bee
	outside.activate(bee)
	bee.facing_x = 1.0
	check(not bee._is_valid_target(outside) and bee._is_valid_target(capped), "Auto-aim locked onto an enemy outside the screen")
	var bee_shot := bee._spawn_projectile(Vector3.RIGHT)
	bee_shot.global_position = Vector3(camera_x + half + 0.6, 3.0, 0)
	await frames(2)
	check(not is_instance_valid(bee_shot), "Bee's shot must vanish once it leaves the screen")
	for node in [capped, outside]:
		wave.active_units.erase(node)
		node.queue_free()
	print("FAIRNESS_REBUILD02 ceiling=%d screen_bound=OK" % BeeLevel01Controller.LIVE_SHOT_CEILING)

	# 5. Bomb stays offensive only: a nearby enemy projectile survives the discharge.
	for node in get_nodes_in_group("alien_projectiles"):
		node.queue_free()
	await frames(2)
	var shot := PROJECTILE.instantiate() as AlienEnemyProjectile
	stage.add_child(shot)
	shot.global_position = bee.global_position + Vector3(1.5, 0, 0)
	shot.speed = 0.0 # Isolate cancellation from a later collision with Bee.
	shot.launch(Vector3.LEFT, null)
	bee.collect_bomb()
	check(bee.use_bomb() != null, "Bomb refused")
	bee.active_bomb.detonate()
	await frames(18)
	check(is_instance_valid(shot) and not shot.is_queued_for_deletion(), "Bomb must not cancel enemy projectiles (decision A)")
	shot.queue_free()

	# 6. Automatic playtest: the four ranged families fighting Bee at once, frozen camera.
	for node in wave.active_units.duplicate():
		wave.active_units.erase(node)
		node.queue_free()
	for node in get_nodes_in_group("alien_projectiles"):
		node.queue_free()
	await frames(3)
	bee.health.damage_blocked = true
	total_shots = 0
	fired_unreadable = 0
	var peak := 0
	var units: Array[Node3D] = []
	for spec in [["Probe", 3.5, 4.4], ["EyeDrone", 4.5, 3.0], ["Turret", 3.4, 0.0], ["Walker", 4.8, 0.0]]:
		wave._spawn({"family": spec[0], "slot": 0, "event": 0, "hard": false})
		var unit: Node3D = wave.active_units.back()
		preload("res://tests/levels/bee_teleport_fixture.gd").finish(unit)
		if spec[0] == "Turret" or spec[0] == "Walker":
			unit.global_position = Vector3(camera_x + spec[1], spec[2], 0)
		else:
			unit.global_position = Vector3(camera_x + half + spec[1], spec[2], 0) # Born past the right edge.
		unit.projectile_fired.connect(on_fired.bind(unit))
		units.append(unit)
	for i in 720:
		await physics_frame
		peak = maxi(peak, get_nodes_in_group("alien_projectiles").size())
	check(total_shots >= 6, "Playtest produced too few shots (%d)" % total_shots)
	check(fired_unreadable == 0, "%d shots came from outside the readable area" % fired_unreadable)
	var suppressed := 0
	for unit in units:
		suppressed += unit.suppressed_shot_count
	print("SHMUP_FAIRNESS_OK shots=%d suppressed=%d peak_simultaneous_projectiles=%d hurt_radius=%.2f projectile_radius=%.2f" % [total_shots, suppressed, peak, hurt_radius, lethal])
	quit(0)
