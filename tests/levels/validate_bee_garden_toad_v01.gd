extends SceneTree
# The garden toad (Lote 10 frog) belongs to LEVEL 2 (laguna): LOTE 12 hosts this test in the Level 2 stage and drives the
# encounter directly, so it no longer depends on Level 1 (its event table, its scroll or its director). The Level 1 wrapper
# (BeeLevel01ScaleEvent) is covered by validate_bee_level01_roster_v01 (the code stays intact, switched off by LEVEL01_ROSTER_ONLY).
const LEVEL := preload("res://scenes/levels/bee_level_02_lake.tscn")
var errors: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)
		push_error(message)
func frames(count: int) -> void:
	for i in count:
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
	stage.bee.global_position = Vector3(stage.camera.global_position.x, 5, 0)
	var frog := BeeGardenToadEncounter.new()
	stage.add_child(frog)
	var landings := [0]
	frog.landing.connect(func(): landings[0] += 1)
	check(frog.activate(stage.bee), "The toad did not activate")
	check(frog.visual.find_child("AlienControlDevice", true, false) != null, "Lake model/implant not reused")
	var locked_checked := false
	for i in 60 * 55:
		await physics_frame
		if frog.state == BeeLakeToadBoss.State.TONGUE and not locked_checked:
			var locked := frog._aim
			stage.bee.global_position += Vector3(0, 2, 0)
			await frames(2)
			check(frog._aim == locked, "Tongue must not home after launch")
			locked_checked = true
	check(frog.crossings >= 2 and landings[0] >= 8, "Frog must cross at least twice by hopping (%d crossings, %d landings)" % [frog.crossings, landings[0]])
	check(frog.variants.has(0) and frog.variants.has(1) and frog.variants.has(2), "All three tongue variants must run")
	check(frog.telegraphs.all(func(t): return t >= 0.6), "Tongue warnings too short")
	check(locked_checked and frog.expired and not frog.is_visible_in_tree() and not frog.is_physics_processing(), "50-second timeout must finish the encounter")
	var free_frog := BeeGardenToadEncounter.new()
	stage.add_child(free_frog)
	free_frog.activate(stage.bee)
	free_frog.set_physics_process(false)
	free_frog.global_position = Vector3(stage.camera.global_position.x + 1.0, 0, 0)
	stage.bee.global_position = free_frog.hurtbox.global_position - Vector3(2, 0, 0)
	var started := 0.0
	for i in 60 * 9:
		if i % 20 == 0:
			stage.bee.set_aim_point(free_frog.hurtbox.global_position)
			stage.bee.fire()
		await physics_frame
		started += 1.0 / 60.0
		if free_frog.liberated:
			break
	check(free_frog.liberated and started >= 6.0 and started <= 8.0, "Accurate Base liberation must take 6-8s: " + str(started))
	check(not free_frog._tongue_box.enabled and free_frog.is_in_group("bee_liberated"), "Liberation must cancel attacks")
	free_frog.set_physics_process(true)
	await frames(190)
	check(not free_frog.visible, "Liberated frog must hop away")
	print("GARDEN_TOAD (level 2 host) crossings=", frog.crossings, " variants=", frog.variants, " warnings=", frog.telegraphs, " base_liberation=", started)
	quit(0 if errors.is_empty() else 1)
