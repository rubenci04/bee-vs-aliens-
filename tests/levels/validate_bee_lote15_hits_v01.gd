extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var before := {"FlyCommon": 50, "FlyCloud": 24, "FlyGreen": 62, "Wasp": 56, "Ant": 92}
	var failed := false
	for family in BeeGameSettings.SMALL_ENEMY_HP:
		var counts: Array[int] = []
		for hp in [before[family], BeeLevel01Controller.level_hp(family)]:
			var health := HealthComponent.new()
			health.max_health = hp
			root.add_child(health)
			var hits := 0
			while health.current_health > 0:
				health.take_damage(10)
				hits += 1
			counts.append(hits)
			health.queue_free()
		print("HITS %s: %d -> %d" % [family, counts[0], counts[1]])
		failed = failed or counts[1] != (1 if family in ["FlyCommon", "FlyCloud"] else 2)
	quit(1 if failed else 0)
