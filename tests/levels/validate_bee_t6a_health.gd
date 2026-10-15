extends SceneTree
const H := preload("res://scripts/game/bee_enemy_health_settings.gd")
const W := preload("res://scripts/game/bee_shooting_settings.gd")
## Historical audit fixture only, never a runtime HP source.
const BEFORE_T6B := {
	"FlyCommon":42,"FlyGreen":45,"FlyCloud":75,"Wasp":45,
	"Ant":42,"Ladybird":45,"WormA":60,"WormB":60,
	"StagBeetle":60,"Snail":60,"Spider":90,"MushroomCannon":60,
}
var failures := 0
var stage: BeeShmupStage
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func body(unit: Node3D) -> DamageHurtbox3D:
	if unit is AssetFauna:
		return unit.body_hurtbox if unit.body_hurtbox != null else unit.hurtbox
	return unit.get_node("Hurtbox3D")
func spawn(family: String, slot := 0) -> Node3D:
	stage.wave._spawn({"family":family,"event":600,"slot":slot,"hard":false})
	var unit: Node3D = stage.wave.active_units.back()
	unit.set_physics_process(false) # Keep collision areas active for real projectile checks.
	return unit
func run() -> void:
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	stage = preload("res://scenes/levels/bee_level_01_vertical_slice.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(4)
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.get_node("CheckpointQoL").set_process(false)
	stage.get_node("Juice").set_physics_process(false)
	stage.distance = 25
	stage._update_camera_and_bounds()
	var bee := stage.bee
	bee.set_physics_process(false)
	bee.health.damage_blocked = true
	bee.global_position = Vector3(23,3,0)
	check(W.FIRE_INTERVAL == 1.0/12.0 and W.WEAPON_MODES[&"base"]["damage"] == [3] and W.WEAPON_MODES[&"triple"]["damage"] == [3,1,1], "Bee profiles and DPS unchanged")
	check(BeeLevel01Controller.MINIBOSS_HP == 600 and BeeLevel01Controller.LEVEL_HP["Walker"] == 100, "Robot and legacy walker unchanged")
	check(bee.melee_damage == 30, "T6b preserves Aguijon damage")
	check(H.COMMON_MAX_TTK == 1.5 and H.LARGE_MAX_TTK == 2.0, "T6b caps remain 1.5 seconds, or 2 for large families")
	check(H.COMMON_HP.size() == BEFORE_T6B.size(), "Every current common family is covered by the before/after audit")
	var base_damage := int(W.WEAPON_MODES[&"base"]["damage"][0])
	var base_dps := base_damage / W.FIRE_INTERVAL
	for family in H.COMMON_HP:
		if family == "FlyCloud": continue # T6c replaces shared HP with one-hit members; validate_bee_t6c_cloud covers it.
		var hp := int(H.COMMON_HP[family])
		var target := H.target_time(family)
		var expected_hits := ceili(float(hp)/base_damage)
		var before_hits := ceili(float(BEFORE_T6B[family])/base_damage)
		var reduced_hits := maxi(1,ceili(before_hits*0.55)) if before_hits <= 5 else maxi(2,before_hits-3)
		var max_hits := floori(target.y*base_dps/base_damage)
		check(hp == mini(reduced_hits,max_hits)*base_damage, "%s applies the T6b reduction and class TTK cap" % family)
		check(hp > 0 and hp % base_damage == 0 and expected_hits >= 1, "%s needs at least one whole Base impact, never zero" % family)
		check(expected_hits < before_hits, "%s needs fewer impacts than T6a" % family)
		check(float(hp)/base_dps <= target.y, "%s continuous TTK %.3f <= %.3f seconds" % [family,float(hp)/base_dps,target.y])
		var time := (expected_hits-1)*W.FIRE_INTERVAL
		check(time >= target.x and time <= target.y, "%s perfect Base TTK %.3f in %s" % [family,time,target])
		check(BeeLevel01Controller.level_hp(family,false) == hp, "%s escorts use the same HP, no hidden multiplier" % family)
		check(BeeLevel01Controller.level_hp(family,true) == hp, "%s route uses the same HP" % family)
		for spread in [false,true]:
			var unit := spawn(family)
			var health := unit.get_node("HealthComponent") as HealthComponent
			check(health.max_health == hp and not health.invulnerable and not health.damage_blocked, "%s factory HP and no invisible protection" % family)
			unit.global_position = Vector3(28,3,0)
			bee.spread_ammo = 20 if spread else 0
			var volleys := 0
			while health.current_health > 0 and volleys < 100:
				var pellet_damage: Array = W.WEAPON_MODES[&"triple" if spread else &"base"]["damage"]
				for damage in pellet_damage:
					var shot := bee._spawn_projectile(Vector3.RIGHT,int(damage))
					shot.hitbox.ignores_weak_points = true
					body(unit).receive_hit(shot.hitbox)
					shot.queue_free()
				volleys += 1
			check(volleys == ceili(float(hp)/(5 if spread else 3)), "%s real hurtbox path preserves damage per volley" % family)
			print("T6A_TTK ",family," hp=",hp," spread=",spread," volleys=",volleys," seconds=",(volleys-1)*W.FIRE_INTERVAL)
			unit.queue_free()
			await frames(2)
	# T6c's individual fly targets/reserve and continuous-fire bank replace the shared-body cloud contract.
	# See validate_bee_t6c_cloud.gd; the other eleven families retain all real Base/Spread checks above.
	print("T6A_OK failures=",failures)
	quit(1 if failures else 0)
