extends SceneTree
const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var controller: Script = load("res://scripts/levels/bee_level_01_controller.gd")
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	await process_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	# T6a replaces the old Lote 15 one/two-hit contract, keeping the real damage path.
	var before := {"FlyCommon": 10, "FlyCloud": 10, "FlyGreen": 20, "Wasp": 20, "Ant": 20}
	var base_damage := int(BeePlayer.SHOOTING.WEAPON_MODES[&"base"]["damage"][0])
	var failed := false
	for family in BeeGameSettings.SMALL_ENEMY_HP:
		var counts: Array[int] = []
		for hp in [before[family], controller.call("level_hp", family)]:
			var health := HealthComponent.new()
			health.max_health = hp
			root.add_child(health)
			var hits := 0
			while health.current_health > 0:
				health.take_damage(base_damage)
				hits += 1
			counts.append(hits)
			health.queue_free()
		print("HITS %s: %d -> %d" % [family, counts[0], counts[1]])
		failed = failed or counts[1] != ceili(float(BeeGameSettings.SMALL_ENEMY_HP[family])/base_damage)
		# Actual projectile -> hitbox -> body hurtbox -> enemy health path, both tap and sustained BASE.
		for damage in [base_damage]:
			var wave := stage.wave as BeeLevel01Controller
			wave._spawn({"family": family, "slot": 0, "event": 0, "hard": false, "y": 3.0})
			var unit: Node3D = wave.active_units.back()
			unit.set_physics_process(false)
			var hurt: DamageHurtbox3D
			if unit is AssetFauna:
				hurt = (unit as AssetFauna).body_hurtbox if (unit as AssetFauna).body_hurtbox != null else (unit as AssetFauna).hurtbox
			else:
				hurt = unit.get_node("Hurtbox3D") as DamageHurtbox3D
			var health := unit.get_node("HealthComponent") as HealthComponent
			var hits := 0
			while health.current_health > 0 and hits < 128:
				var shot := stage.bee._spawn_projectile(Vector3.RIGHT, damage)
				shot.hitbox.ignores_weak_points = true
				shot.hitbox._on_area_entered(hurt)
				hits += 1
			print("LIVE HITS %s BASE pellet=%d: %d" % [family, damage, hits])
			failed = failed or hits != counts[1]
	stage.queue_free()
	await process_frame
	quit(1 if failed else 0)
