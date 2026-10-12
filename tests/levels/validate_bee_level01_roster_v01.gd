extends SceneTree

# LOTE 12 · ETAPA 2 — Level 1 plays ONLY its roster (docs/art/LEVEL_01_ROSTER.md), behind LEVEL01_ROSTER_ONLY. Structure + the new species
# (never "fun"): allowed families, nothing that left the level (alien units, UFO, frog, fireflies), the arc (3 zones, breathing valley with
# supplies, walking robot as the last encounter), garden mushrooms (pollen, not solid, never shoot) and the species behaviours: 0.4 s
# minimum telegraph, erupting worm with a 1 s mark, cloud as one group unit, turtle tank with a ring warning.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const ALLOWED := ["FlyCommon", "FlyGreen", "FlyCloud", "Wasp", "Ladybird", "Ant", "Snail", "WormA", "WormB", "StagBeetle", "Spider", "MushroomCannon", "Walker"] # LOTE 13: no Turtle (its model is out of style until Rubén delivers a new one)
const FORBIDDEN := ["Turtle", "Probe", "EyeDrone", "Speeder", "Turret", "OrganicAlien", "Swarm", "Dragonfly", "Mosquito", "WaveDragonfly", "Moth", "SeedCarrier", "AlienFighter"]
const FORBIDDEN_MOMENTS := ["scale_event", "contaminated_garden", "last_silence", "human_aftermath", "walker_showcase", "bomb_reward"]

var stage: BeeShmupStage
var wave: BeeLevel01Controller
var bee: BeePlayer

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
	test_table()
	root.add_child(LEVEL.instantiate())
	current_scene = root.get_child(root.get_child_count() - 1)
	await frames(5)
	stage = current_scene as BeeShmupStage
	wave = stage.wave as BeeLevel01Controller
	bee = stage.bee
	stage.set_physics_process(false)
	wave.set_physics_process(false)
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	stage.get_node("Juice").set_physics_process(false)
	test_supplies_and_mushrooms()
	await test_mushroom_drop()
	await test_anthills()
	await test_flies()
	await test_cloud()
	await test_worm_a()
	await test_worm_b()
	await test_turtle()
	await test_kept_code()
	print("BEE_LEVEL01_ROSTER_V01_OK")
	quit(0)

func families_of(event: Dictionary) -> Array:
	var all: Array = (event["units"] as Array).duplicate()
	for zone_wave: Dictionary in event.get("arena", []):
		all.append_array(zone_wave["units"])
	return all

func test_table() -> void:
	check(BeeLevel01Controller.LEVEL01_ROSTER_ONLY and BeeLevel01Controller.roster_only, "LEVEL01_ROSTER_ONLY must be on by default")
	check(BeeLevel01Controller.EVENTS == BeeLevel01Controller.EVENTS_ROSTER, "EVENTS must be the roster table")
	var seen := {}
	var arenas := 0
	var last_hard := ""
	var events := BeeLevel01Controller.EVENTS
	for i in events.size():
		var event: Dictionary = events[i]
		for family in families_of(event):
			check(not (family in FORBIDDEN), "Family outside the Level 1 roster: " + str(family))
			check(family in ALLOWED, "Unknown family " + str(family))
			seen[family] = int(seen.get(family, 0)) + 1
		check(not (str(event.get("moment", "")) in FORBIDDEN_MOMENTS), "Moment that left Level 1: " + str(event.get("moment", "")))
		check(not bool(event.get("human", false)), "No giant human in the roster level")
		if event.has("arena"):
			arenas += 1
			check((event["arena"] as Array).size() == 6, "Each zone plays 6 waves (LOTE 13)")
		if i > 0:
			check(float(event["at"]) >= float(events[i - 1]["at"]), "Events must ascend")
		if bool(event.get("hard", false)):
			last_hard = str(event["units"][0]) + "/" + ",".join(event["units"])
	for family in ALLOWED:
		check(seen.has(family), "Roster family missing from the timeline: " + family)
	check(arenas == 3, "Three combat zones")
	check("Walker" in (events[events.size() - 1]["units"] as Array) and bool(events[events.size() - 1].get("hard", false)), "The walking robot closes the level")
	var gate: Dictionary = events[events.size() - 1]
	check("Wasp" in gate["units"] and ("FlyCommon" in gate["units"] or "FlyGreen" in gate["units"]), "The walking robot comes with insect escorts")
	# LOTE 13: NO breathing valley any more: the stretch around checkpoint 1 (X=190) is the worm entrance, full of action.
	var longest := 0.0
	for i in range(1, events.size()):
		longest = maxf(longest, float(events[i]["at"]) - float(events[i - 1]["at"]))
	var near_checkpoint := events.filter(func(e): return float(e["at"]) > 179.0 and float(e["at"]) < 206.0 and not (e["units"] as Array).is_empty())
	var worms_near := near_checkpoint.filter(func(e): return "WormA" in e["units"] or "WormB" in e["units"])
	check(longest <= 18.0, "No long empty stretch in the table (%.0f m)" % longest)
	check(near_checkpoint.size() >= 8 and worms_near.size() >= 4, "Checkpoint 1 is the worm entrance: %d events, %d with worms" % [near_checkpoint.size(), worms_near.size()])
	check(not BeeLevel01AssetDressing.FIREFLIES_ENABLED, "Fireflies stay reserved for the forest")
	for family in ["FlyCommon", "FlyGreen", "FlyCloud", "WormA", "WormB", "Turtle"]:
		check(BeeLevel01Controller.LEVEL_HP.has(family) and BeeLevel01Controller.CAMERA_TIME.has(family), "Tuning missing for " + family)
	check(int(BeeLevel01Controller.LEVEL_HP["FlyCloud"]) <= int(bee_bomb_damage()), "The bomb must clear a fly cloud")
	check(int(BeeLevel01Controller.LEVEL_HP["Turtle"]) >= 200, "The turtle is a tank (lots of life)")
	print("LEVEL01_ROSTER table events=%d zones=%d longest_gap=%.0f m families=%s" % [events.size(), arenas, longest, str(seen)])

func bee_bomb_damage() -> int:
	return 32 # BeePlayer.bomb_damage default.

func test_supplies_and_mushrooms() -> void:
	var valley := stage.get_node_or_null("ValleySupply")
	check(valley != null and valley.get_child_count() == 3, "Valley supplies: two honey jars and a bomb capsule")
	var jars := 0
	var bombs := 0
	for item: Node3D in valley.get_children():
		check(item.global_position.x > 190.0 and item.global_position.x < 205.0, "Valley item outside the valley")
		check(item.has_node("ItemBeacon"), "Valley item needs its beacon")
		if item is BeePowerupPickup:
			bombs += 1
			check((item as BeePowerupPickup).kind == BeePowerupPickup.Kind.BOMB, "Valley capsule must be a bomb")
		else:
			jars += 1
	check(jars == 2 and bombs == 1, "Valley supplies mix")
	var gate_supply := stage.get_node_or_null("PreBossSupply") as Node3D
	check(gate_supply != null and gate_supply.get_node("SupplyBomb").global_position.x < 294.0 and gate_supply.get_node("SupplyBomb").global_position.x > 280.0, "Supply before the walking robot")
	var mushrooms := stage.get_node("GardenMushrooms") as BeeLevel01GardenMushrooms
	check(mushrooms.mushrooms.size() == BeeLevel01GardenMushrooms.PLACEMENTS.size() and mushrooms.mushrooms.size() >= 10, "Garden mushrooms missing")
	for mushroom in mushrooms.mushrooms:
		check(mushroom.collision_layer == 0 and not mushroom.is_in_group("breakable_rocks") and mushroom.is_in_group("garden_mushrooms"), "Mushrooms are not solid rocks")
		check(mushroom.find_children("*", "DamageHitbox3D", true, false).is_empty(), "A garden mushroom must never shoot or hurt")
		
	var kinds := {}
	for mushroom in mushrooms.mushrooms:
		kinds[mushroom.kind] = true
	check(kinds.size() == 4, "The three garden mushroom models and the bellflower are used")

func test_mushroom_drop() -> void:
	var mushroom := (stage.get_node("GardenMushrooms") as BeeLevel01GardenMushrooms).mushrooms[0]
	var pollen_before := stage.get_node("Pollen").get_child_count()
	check(mushroom.health.max_health == BeeGameSettings.scaled_hp(20), "Mushroom HP")
	mushroom.health.take_damage(5)
	check(not mushroom.is_destroyed, "A hit does not break it")
	mushroom.health.take_damage(9999)
	await frames(2)
	check(mushroom.is_destroyed and stage.get_node("Pollen").get_child_count() == pollen_before + BeeGardenMushroom.POLLEN_DROPS, "A broken mushroom drops pollen")
	var drop := stage.get_node("Pollen").get_child(stage.get_node("Pollen").get_child_count() - 1) as BeePollenPickup
	check(drop != null and drop.global_position.y >= 1.0, "The pollen drop must be collectable by Bee")
	for mesh: MeshInstance3D in mushroom.find_children("*", "MeshInstance3D", true, false):
		check(not mesh.visible, "A broken mushroom disappears")
	print("LEVEL01_ROSTER mushrooms=%d pollen_drop=OK not_solid=OK" % (stage.get_node("GardenMushrooms") as BeeLevel01GardenMushrooms).mushrooms.size())

func prepare() -> void:
	for unit in wave.active_units + wave.swarm_units:
		if is_instance_valid(unit):
			unit.queue_free()
	wave.active_units.clear()
	wave.swarm_units.clear()
	stage.distance = 70.0
	stage._update_camera_and_bounds()
	bee.global_position = Vector3(stage.camera.global_position.x - 4.0, 3.5, 0.0)

func spawn(family: String, y := 4.2) -> Node3D:
	wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false, "y": y})
	return wave.active_units.back()

func test_flies() -> void:
	prepare()
	await frames(2)
	var common := spawn("FlyCommon") as AssetFauna
	var green := spawn("FlyGreen", 3.0) as AssetFauna
	check(common.kind == &"fly_common" and green.kind == &"fly_green", "Fly kinds")
	check(common.has_implant() and green.has_implant(), "Flies carry the cyan implant")
	for i in 60 * 14:
		await physics_frame
		bee.global_position.y = 3.5 + 1.2 * sin(float(i) * 0.05)
		if green.shots_fired >= 2 and common.telegraphs.size() >= 2:
			break
	check(common.telegraphs.size() >= 2 and common.telegraphs.all(func(t): return t >= AssetFauna.MIN_TELEGRAPH - 0.02), "Common fly: dash warnings >= 0.4 s")
	check(green.shots_fired >= 1, "Green fly spits aimed drops")
	check(float(green.config["shot_speed"]) <= 4.2, "Green fly drops are slow")
	check(green.telegraphs.all(func(t): return t >= AssetFauna.MIN_TELEGRAPH - 0.02), "Green fly: warning >= 0.4 s")
	var flies_ys := green.global_position.y
	check(flies_ys > 1.0 and flies_ys < 6.0, "Green fly stays in the playfield")
	print("LEVEL01_ROSTER flies common_warn=%s green_shots=%d" % [str(common.telegraphs.slice(0, 2)), green.shots_fired])

func test_cloud() -> void:
	prepare()
	await frames(2)
	var cloud := spawn("FlyCloud") as AssetFauna
	check(cloud.kind == &"fly_cloud" and cloud.config.get("whole_body", false), "Fly cloud is a whole-body group unit")
	check(cloud.hurtbox.get_child(0).shape is BoxShape3D and cloud.body_hurtbox == null, "One hurtbox over the whole cloud, no implant weak point")
	await frames(30)
	var hp := cloud.health.max_health
	check(hp == BeeGameSettings.scaled_hp(24) and hp <= 32, "A bomb (32) clears the cloud (HP %d)" % hp)
	# Anywhere on the cloud is a normal hit.
	cloud.set_physics_process(false)
	cloud.global_position = bee.global_position + Vector3(4.0, 0.4, 0.0)
	await frames(2)
	var aim := (cloud.hurtbox.get_child(0) as CollisionShape3D).global_position # The box sits above the model origin.
	var shot := bee._spawn_projectile((aim - bee.global_position).normalized())
	for i in 60:
		await physics_frame
		if cloud.health.current_health < hp:
			break
	check(cloud.health.current_health == hp - 10, "A Base shot does 10 to the cloud (%d)" % (hp - cloud.health.current_health))
	cloud.health.take_damage(9999)
	await frames(3)
	check(cloud.liberated, "The cloud frees its flies")
	print("LEVEL01_ROSTER cloud whole_body hp=%d" % hp)

func test_worm_a() -> void:
	prepare()
	await frames(2)
	var worm := spawn("WormA") as AssetFauna
	check(worm.kind == &"worm_rose" and worm.is_ground(), "Worm A is a ground burrower")
	var marked := false
	var erupted := false
	var mark_frames := 0
	for i in 60 * 14:
		await physics_frame
		if worm.state == AssetFauna.State.TELEGRAPH:
			marked = true
			mark_frames += 1
			check(worm.buried and not worm.visual.visible and not worm.is_in_group("bee_auto_aim_targets"), "Underground: invisible and not targetable")
			check(worm._warn.size() >= 1 and is_instance_valid(worm._warn[0]) and (worm._warn[0] as Node3D).visible, "The ground mark is shown during the warning")
		if worm.state == AssetFauna.State.ATTACK and not erupted:
			erupted = true
			check(not worm.buried and worm.visual.visible and worm.is_in_group("bee_auto_aim_targets"), "Erupted: visible and targetable")
			check(worm.attack_hitbox.enabled, "The eruption hits")
		if erupted and worm.state == AssetFauna.State.RECOVER:
			check(not worm.buried, "Surfaced and vulnerable")
			break
	check(marked and erupted, "Worm A marks the soil, then erupts")
	check(worm.telegraphs.size() >= 1 and worm.telegraphs[0] >= 0.95 and worm.telegraphs[0] <= 1.2, "Worm A warning ~1 s (%s)" % str(worm.telegraphs))
	for i in 60 * 6:
		await physics_frame
		if worm.buried:
			break
	check(worm.buried, "It digs back in after being surfaced")
	print("LEVEL01_ROSTER worm_a warning=%.2fs erupts=OK reburies=OK" % worm.telegraphs[0])

func test_worm_b() -> void:
	prepare()
	await frames(2)
	var worm := spawn("WormB") as AssetFauna
	check(worm.kind == &"worm_compost" and worm.is_ground() and worm.config["mode"] == &"lunge", "Worm B: low crawling lunge")
	for i in 60 * 12:
		await physics_frame
		if worm.telegraphs.size() >= 1:
			break
	check(worm.telegraphs.size() >= 1 and worm.telegraphs[0] >= AssetFauna.MIN_TELEGRAPH - 0.02, "Worm B warning >= 0.4 s")
	check(is_equal_approx(worm.global_position.y, worm.ground_y) or worm.global_position.y < 0.5, "Worm B stays on the soil")
	print("LEVEL01_ROSTER worm_b lunge warning=%.2fs" % worm.telegraphs[0])

func test_turtle() -> void:
	prepare()
	await frames(2)
	var turtle := spawn("Turtle") as BeeGardenTurtle
	check(turtle != null and turtle.is_ground() and turtle.is_active(), "Garden turtle tank")
	check(turtle.get_node("HealthComponent").max_health == BeeGameSettings.scaled_hp(int(BeeLevel01Controller.LEVEL_HP["Turtle"])), "Turtle HP from the director")
	var start_x := turtle.global_position.x
	var checked_ring := false
	for i in 60 * 10:
		await physics_frame
		if turtle._warn_left >= 0.0 and not checked_ring:
			checked_ring = true
			check(turtle._warn_nodes.size() == 1 and BeeGardenTurtle.SLAM_WARN >= 0.4, "Ground ring warns the shell slam")
		if turtle.slams >= 1:
			break
	check(checked_ring and turtle.slams >= 1 and turtle.slam_warnings.all(func(t): return t >= 0.4), "Shell slam with a >= 0.4 s warning")
	check(turtle.global_position.x < start_x - 2.0, "The turtle walks slowly towards -X")
	var defeated := [false]
	turtle.defeated.connect(func(_t): defeated[0] = true)
	turtle.get_node("HealthComponent").take_damage(9999)
	check(turtle.liberated and not turtle.is_active(), "Breaking the implant frees the turtle")
	for i in 60 * 4:
		await physics_frame
		if defeated[0]:
			break
	check(defeated[0], "The freed turtle walks off and leaves play")
	print("LEVEL01_ROSTER turtle slam_warning=%.1fs slams=%d freed=OK" % [BeeGardenTurtle.SLAM_WARN, turtle.slams])

func test_kept_code() -> void:
	# Everything that left Level 1 still exists and loads: UFO (Level 7), frog (Level 2), alien families, old table.
	check(load("res://scenes/levels/ufo_boss_01.tscn") != null and UfoBoss01.State.PHASE_1 >= 0, "UFO code kept for Level 7")
	check(BeeLevel01Controller.EVENTS_LEGACY.size() == 72, "The pre-roster table is intact")
	check(ResourceLoader.exists("res://scripts/levels/level_02_lake/garden_toad_encounter.gd") and ResourceLoader.exists("res://scenes/levels/level_02_lake/lake_toad_miniboss_visual.tscn"), "Frog code and scene live under level_02_lake")
	# The frog wrapper still works when asked (it is just not in the Level 1 table any more).
	wave.director_moment.emit(&"scale_event")
	var event := stage.get_node("ScaleEvent") as BeeLevel01ScaleEvent
	check(event.played and event.frog != null, "The frog wrapper still plays when its moment is emitted")
	event.frog.queue_free()
	for family in FORBIDDEN:
		check(wave.spawned_by_family.get(family, 0) == 0 or family == "Turtle", "Nothing outside the roster was spawned in this test: " + family) # The turtle is parked (behaviour tests spawn it by hand), never in the table.
	print("LEVEL01_ROSTER kept_code UFO/frog/legacy table OK")


# LOTE 13 · ETAPA 1: anthills on the soil; ants of marked events grow out of one and hop down before they act.
func test_anthills() -> void:
	var anthills := stage.get_node("Anthills") as BeeLevel01Anthills
	check(anthills != null and anthills.hills.size() == BeeLevel01Anthills.PLACEMENTS.size() and anthills.hills.size() >= 6, "Anthills placed")
	for hill in anthills.hills:
		check(float((hill["entrance"] as Vector3).y) > 0.2, "Each anthill has an entrance above the soil")
	var ant_events := 0
	for event: Dictionary in BeeLevel01Controller.EVENTS_ROSTER:
		if bool(event.get("anthill", false)):
			ant_events += 1
	check(ant_events >= 5, "Several ant groups are marked to come out of anthills")
	stage.distance = 15.0
	stage._update_camera_and_bounds()
	wave._spawn({"family": "Ant", "slot": 0, "event": 0, "due": 0.0, "hard": false, "anthill": true})
	var ant := wave.active_units.back() as AssetFauna
	var hill := anthills.pick(stage.camera.global_position.x)
	check(ant != null and not hill.is_empty() and anthills.emerged == 1, "The ant is born at an anthill on screen")
	check(not ant.is_active() and ant.scale.x < 1.0 and absf(ant.global_position.x - float((hill["entrance"] as Vector3).x)) < 0.6, "It starts inside the mound, small and inactive")
	check(not ant.is_in_group("bee_auto_aim_targets"), "It cannot be targeted while it comes out")
	for i in 150:
		await physics_frame
		if ant.is_active():
			break
	check(ant.is_active() and is_equal_approx(ant.scale.x, 1.0) and absf(ant.global_position.y - BeeLevel01Anthills.GROUND_Y) < 0.05 and ant.is_in_group("bee_auto_aim_targets"), "After the hop it is on the ground, full size and active")
	wave.active_units.erase(ant)
	ant.queue_free()
	print("LEVEL01_ROSTER anthills=%d emerge=%.1fs hop=%.1fs OK" % [anthills.hills.size(), BeeLevel01Anthills.EMERGE_SECONDS, BeeLevel01Anthills.HOP_SECONDS])
