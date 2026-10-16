extends SceneTree
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
var stage: BeeShmupStage

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

func run() -> void:
	stage = LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	await frames(5)
	stage.set_physics_process(false)
	var wave := stage.wave as BeeLevel01Controller
	wave.set_physics_process(false)
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(0, 4, 0)
	wave._spawn({"family": "Mosquito", "event": 0, "slot": 0, "hard": false})
	var unit := wave.active_units.back() as AssetFauna
	preload("res://tests/levels/bee_teleport_fixture.gd").finish(unit)
	unit.set_physics_process(false)
	unit.global_position = Vector3(4, 4, 0)
	var gun := unit.get_child(unit.get_child_count() - 1) as BeeImplantShooter
	check(gun != null, "Implant weapon missing (T6e: the ladybird now hops, the mosquito keeps the implant gun fixture)")
	gun.set_physics_process(false)
	gun.clock = 0.0
	gun._physics_process(0.01)
	check(gun.warning != null and gun.volleys == 0, "Implant must warn before firing")
	check(gun.warning.global_position.distance_to(unit.global_position) < 0.5, "Warning must follow the implant on screen")
	gun._physics_process(0.55)
	check(gun.volleys == 0, "No shot before minimum telegraph")
	gun._physics_process(0.06)
	check(gun.volleys == 1 and get_nodes_in_group("alien_projectiles").size() == 1, "LOTE 14: an implant volley is ONE shot")
	for shot in get_nodes_in_group("alien_projectiles"):
		shot.queue_free()
	await frames(2)
	gun.clock = 0.0
	gun._physics_process(0.01)
	gun._physics_process(0.61)
	check(gun.volleys == 2 and get_nodes_in_group("alien_projectiles").size() == 1, "Second volley must be an aimed shot")
	var shot := get_nodes_in_group("alien_projectiles")[0] as AlienEnemyProjectile
	shot.set_physics_process(false)
	check(is_equal_approx(shot.hitbox.bee_damage_scale, BeeLevel01Controller.ROUTE_DAMAGE_SCALE), "Projectile must copy route damage tuning")
	unit.queue_free()
	await frames(2)
	bee.health.damage_blocked = false
	var applied := bee.hurtbox.receive_hit(shot.hitbox)
	check(applied == maxi(1, roundi(BeeImplantShooter.SHOT_DAMAGE * BeeLevel01Controller.ROUTE_DAMAGE_SCALE)), "Orphaned shot must retain its damage tuning")
	shot.queue_free()
	bee.health.damage_blocked = true
	var rock := stage.get_node("Scenery/FlightRock205") as BreakableRock
	check(rock.health.max_health == 96 and not rock.structural, "Large rock must have finite HP")
	rock.health.take_damage(96)
	await frames(2)
	check(rock.is_destroyed and rock.collider.disabled and rock.collision_layer == 0 and rock.hurtbox.collision_layer == 0, "Broken rock must release bodies, shots and bombs")
	var moments := stage.get_node("DirectorMoments") as BeeLevel01Moments
	var shell := moments.impact_surfaces[0] as ImpactSurface
	shell.health.take_damage(ImpactSurface.SURFACE_HP)
	await frames(2)
	for shape: CollisionShape3D in stage.get_node("LogObstacle").get_children():
		check(shape.disabled, "Broken log left an invisible shell")
	for surface: ImpactSurface in moments.impact_surfaces:
		check(surface.is_destroyed and surface.hurtbox.collision_layer == 0, "All broken log surfaces must stop absorbing shots")
	var checkpoint := stage.get_node("CheckpointQoL") as BeeCheckpointQoL
	var snapshot := checkpoint._build_snapshot(190.0, Vector3(190, 4, 0), 190.0, 190.0)
	check(str(shell.name) in snapshot["broken"], "Checkpoint must remember the broken log")
	var before := stage.get_node("Powerups").get_child_count() + stage.get_node("Pollen").get_child_count()
	shell.restore_broken()
	await frames(2)
	check(before == stage.get_node("Powerups").get_child_count() + stage.get_node("Pollen").get_child_count(), "Restoring destruction must never farm rewards")
	for obstacle: DestructibleObstacle3D in stage.get_node("Destructibles").get_children():
		if obstacle.item_kind == 4:
			check(obstacle.body.collision_layer == 0 and obstacle.hurtbox.collision_layer == 0, "Small peel must be nonblocking decoration")
	# Saturate both budgets with the same queue the director uses during play.
	wave.active_units.clear()
	wave._pending.clear()
	stage.distance = 300.0
	var units: Array = []
	for i in 10:
		units.append("Mosquito")
	for cap in [BeeLevel01Controller.MAX_ON_SCREEN, BeeLevel01Controller.MAX_ON_SCREEN_ARENA]:
		wave._arena = {} if cap == BeeLevel01Controller.MAX_ON_SCREEN else {"test": true}
		wave._queue_units({"units": units}, 0, 0)
		for i in 12:
			wave._clock += 1.0
			wave._spawn_pending()
		var allowed: int = mini(BeeLevel01Controller.threat_cap(stage.distance), cap) if cap == BeeLevel01Controller.MAX_ON_SCREEN else cap # LOTE 14: the roster route cap is 7 from X=96; LOTE 11: the route threat cap (6) is below the on-screen total (7, popcorn included).
		check(wave.alive_count() == allowed and wave._pending.size() == 10 - allowed, "Pending queue must enforce the route / arena cap")
		for enemy in wave.active_units:
			enemy.queue_free()
		wave.active_units.clear()
		wave._pending.clear()
	wave._arena = {}
	print("BEE_LOTE10_PRESSURE_V01_OK implant fan aimed telegraph damage_persistence rock log checkpoint small_decor")
	quit(0)
