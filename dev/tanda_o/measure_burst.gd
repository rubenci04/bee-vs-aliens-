extends SceneTree
## Reproduce una superposición de ataques de Furia por el camino hitbox -> hurtbox -> salud.

const LEVEL := preload("res://scenes/levels/bee_level_01_vertical_slice.tscn")
const BOSS := preload("res://scenes/levels/tarantula_boss_01.tscn")
const WINDOW_SECONDS := 1.0 # Ventana de medición del daño recibido.
const TICKS_PER_SECOND := 60.0 # Frecuencia de la simulación.
const HIT_FRAMES := [0, 6, 12, 18, 24, 30, 42] # Separación reproducible de los impactos.
const HIT_KINDS := [&"stomp", &"jump", &"hang", &"contact", &"shot", &"stomp", &"rain"]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	BeeGameSettings.difficulty = BeeGameSettings.NORMAL
	var stage := LEVEL.instantiate() as BeeShmupStage
	root.add_child(stage)
	current_scene = stage
	await physics_frame
	stage.set_physics_process(false)
	stage.wave.set_physics_process(false)
	stage.bee.set_physics_process(false)
	var bee := stage.bee as BeePlayer
	bee.health.damage_blocked = false
	bee.health.invulnerable = false
	bee.health.pollen_protected = false
	var boss := BOSS.instantiate() as TarantulaBoss01
	stage.add_child(boss)
	var helper := Node3D.new()
	helper.name = "TarantulaHelperSpider"
	helper.set_meta("boss_helper", "Spider")
	stage.add_child(helper)
	var hits: Array[Vector2] = []
	var previous_frame := 0
	for index in HIT_FRAMES.size():
		for step in HIT_FRAMES[index] - previous_frame:
			await physics_frame
		previous_frame = HIT_FRAMES[index]
		var kind: StringName = HIT_KINDS[index]
		var amount := _damage(kind)
		var attacker: Node = helper if kind == &"shot" else boss # La bala de telaraña sale de la araña invocada.
		var hitbox := DamageHitbox3D.new()
		hitbox.damage = amount
		hitbox.collision_mask = 0
		stage.add_child(hitbox)
		hitbox.attacker = attacker
		hitbox.set_enabled(true)
		var applied := bee.hurtbox.receive_hit(hitbox)
		hits.append(Vector2(float(HIT_FRAMES[index]) / TICKS_PER_SECOND, applied))
		print("BURST_HIT t=%.2f tipo=%s pedido=%d recibido=%d" % [hits.back().x, kind, amount, applied])
		hitbox.queue_free()
	var maximum := 0
	for hit in hits:
		var window_damage := 0
		for other in hits:
			if other.x >= hit.x and other.x < hit.x + WINDOW_SECONDS:
				window_damage += int(other.y)
		maximum = maxi(maximum, window_damage)
	print("BURST_MAX_1S=%d TOTAL=%d VIDA_FINAL=%d" % [maximum, bee.health.max_health - bee.health.current_health, bee.health.current_health])
	quit()

func _damage(kind: StringName) -> int:
	match kind:
		&"stomp": return TarantulaBoss01.STOMP_DAMAGE
		&"jump": return TarantulaBoss01.JUMP_DAMAGE
		&"hang": return TarantulaBoss01.HANG_DAMAGE
		&"contact": return TarantulaBoss01.CONTACT_DAMAGE
		&"shot": return TarantulaBoss01.SHOT_DAMAGE
		&"rain": return TarantulaBoss01.RAIN_DAMAGE
	return 0
